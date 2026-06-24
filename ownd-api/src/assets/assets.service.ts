import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { AssetPurpose, AssetStatus } from '@prisma/client';
import dayjs from 'dayjs';
import { MinioService } from '../minio/minio.service';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class AssetsService {
  private readonly logger = new Logger(AssetsService.name);

  constructor(
    private prisma: PrismaService,
    private minioService: MinioService,
  ) {}

  async registerUpload(params: {
    userId: string;
    path: string;
    purpose: AssetPurpose;
    file: Express.Multer.File;
  }) {
    return this.prisma.asset.create({
      data: {
        userId: params.userId,
        path: params.path,
        purpose: params.purpose,
        status: AssetStatus.ORPHAN,
        mimeType: params.file.mimetype,
        size: params.file.size,
      },
    });
  }

  async discardUpload(path?: string | null) {
    if (!path) return;

    try {
      await this.minioService.deleteFile(path);
      await this.prisma.asset.deleteMany({ where: { path } });
    } catch (error) {
      await this.safeMarkOrphan(path);
      this.logDeleteFailure(path, error);
    }
  }

  async releasePath(path?: string | null) {
    if (!path) return;

    await this.safeMarkOrphan(path);
    await this.discardUpload(path);
  }

  @Cron(CronExpression.EVERY_DAY_AT_1AM)
  async cleanupOrphans() {
    const cutoff = dayjs().subtract(24, 'hour').toDate();
    const assets = await this.prisma.asset.findMany({
      where: {
        status: AssetStatus.ORPHAN,
        updatedAt: { lt: cutoff },
      },
      take: 200,
      orderBy: { updatedAt: 'asc' },
    });

    for (const asset of assets) {
      await this.discardUpload(asset.path);
    }
  }

  private async markOrphan(path: string) {
    await this.prisma.asset.updateMany({
      where: { path },
      data: {
        status: AssetStatus.ORPHAN,
        refType: null,
        refId: null,
      },
    });
  }

  private async safeMarkOrphan(path: string) {
    try {
      await this.markOrphan(path);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.warn(`Failed to mark asset orphan ${path}: ${message}`);
    }
  }

  private logDeleteFailure(path: string, error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    this.logger.warn(`Failed to delete unused asset ${path}: ${message}`);
  }
}
