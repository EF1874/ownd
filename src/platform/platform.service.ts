import {
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePlatformDto } from './dto/create-platform.dto';
import { UpdatePlatformDto } from './dto/update-platform.dto';

@Injectable()
export class PlatformService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createPlatformDto: CreatePlatformDto) {
    return this.prisma.platform.create({
      data: {
        ...createPlatformDto,
        userId,
      },
    });
  }

  async findAll(userId: string) {
    await this.ensureUserDefaultPlatforms(userId);

    return this.prisma.platform.findMany({
      where: {
        userId,
      },
      orderBy: {
        createdAt: 'asc',
      },
    });
  }

  async findOne(id: string, userId: string) {
    const platform = await this.prisma.platform.findUnique({
      where: { id },
    });

    if (!platform) {
      throw new NotFoundException('平台不存在');
    }

    if (platform.userId !== userId) {
      throw new ForbiddenException('你没有权限查看此平台');
    }

    return platform;
  }

  async update(
    id: string,
    userId: string,
    updatePlatformDto: UpdatePlatformDto,
  ) {
    const platform = await this.prisma.platform.findUnique({
      where: { id },
    });

    if (!platform) {
      throw new NotFoundException('平台不存在');
    }

    if (platform.userId !== userId) {
      throw new ForbiddenException('你没有权限修改此平台');
    }

    return this.prisma.platform.update({
      where: { id },
      data: updatePlatformDto,
    });
  }

  async remove(id: string, userId: string) {
    const platform = await this.prisma.platform.findUnique({
      where: { id },
    });

    if (!platform) {
      throw new NotFoundException('平台不存在');
    }

    if (platform.userId !== userId) {
      throw new ForbiddenException('你没有权限删除此平台');
    }

    return this.prisma.platform.delete({
      where: { id },
    });
  }

  private async ensureUserDefaultPlatforms(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { platformDefaultsInitialized: true },
    });

    if (!user) {
      throw new NotFoundException('用户不存在');
    }
    if (user.platformDefaultsInitialized) {
      return;
    }

    const existingUserPlatforms = await this.prisma.platform.count({
      where: { userId },
    });

    if (existingUserPlatforms === 0) {
      await this.copySystemPlatformTemplates(userId);
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: { platformDefaultsInitialized: true },
    });
  }

  private async copySystemPlatformTemplates(userId: string) {
    const templates = await this.prisma.platform.findMany({
      where: { userId: null },
      orderBy: { createdAt: 'asc' },
    });

    for (const template of templates) {
      await this.prisma.platform.create({
        data: {
          name: template.name,
          icon: template.icon,
          color: template.color,
          userId,
        },
      });
    }
  }
}
