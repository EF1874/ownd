import { BadRequestException, Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Minio from 'minio';
import path from 'path';

@Injectable()
export class MinioService {
  private readonly client: Minio.Client;
  private readonly bucketName: string;
  private readonly logger = new Logger(MinioService.name);

  private getRequiredConfig(
    key: 'MINIO_ENDPOINT' | 'MINIO_ROOT_USER' | 'MINIO_ROOT_PASSWORD',
  ): string {
    const value = this.configService.get<string>(key);
    if (value) {
      return value;
    }

    const message = `Missing MinIO config: ${key}`;
    this.logger.error(`${message}. Please check environment variables.`);
    throw new Error(message);
  }

  constructor(private configService: ConfigService) {
    const endPoint = this.getRequiredConfig('MINIO_ENDPOINT');
    const accessKey = this.getRequiredConfig('MINIO_ROOT_USER');
    const secretKey = this.getRequiredConfig('MINIO_ROOT_PASSWORD');
    const port = Number(this.configService.get<string>('MINIO_PORT') ?? 9000);
    const useSSL = this.configService.get<string>('MINIO_USE_SSL') === 'true';

    this.client = new Minio.Client({
      port,
      endPoint,
      accessKey,
      secretKey,
      useSSL,
    });
    this.bucketName =
      this.configService.get<string>('MINIO_BUCKET') ?? 'ownd-items';
  }

  async initBucket() {
    try {
      const exists = await this.client.bucketExists(this.bucketName);
      if (!exists) {
        await this.client.makeBucket(this.bucketName);
        this.logger.log(`Bucket "${this.bucketName}" created successfully.`);
      }
    } catch (error) {
      this.logger.error('Failed to initialize MinIO bucket', error);
      throw error;
    }
  }

  async uploadFile(file: Express.Multer.File) {
    // 生成随机文件名，防止冲突
    const ext = path.extname(file.originalname); // 获取扩展名如 .png
    const fileName = `${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`;

    await this.client.putObject(
      this.bucketName,
      fileName,
      file.buffer,
      file.size,
      { 'Content-Type': file.mimetype },
    );

    // 返回文件存储的路径（之后会存入数据库）
    return `/${this.bucketName}/${fileName}`;
  }

  async getFile(fileName: string) {
    if (fileName.includes('/') || fileName.includes('\\')) {
      throw new BadRequestException('图片不存在或已被删除');
    }

    const stat = await this.client.statObject(this.bucketName, fileName);
    const stream = await this.client.getObject(this.bucketName, fileName);
    return {
      stream,
      contentType:
        stat.metaData?.['content-type'] ?? 'application/octet-stream',
    };
  }

  async deleteFile(storedPath?: string | null) {
    if (!storedPath) return;

    const prefix = `/${this.bucketName}/`;
    if (!storedPath.startsWith(prefix)) return;

    const fileName = storedPath.slice(prefix.length);
    if (!fileName || fileName.includes('/') || fileName.includes('\\')) {
      throw new BadRequestException('图片不存在或已被删除');
    }

    try {
      await this.client.removeObject(this.bucketName, fileName);
    } catch (error) {
      this.logger.error('Failed to delete image', error);
      throw new BadRequestException('图片删除失败，请稍后重试');
    }
  }

  async checkHealth() {
    try {
      await this.client.bucketExists(this.bucketName);
      return true;
    } catch (error) {
      this.logger.error('Failed to check MinIO health', error);
      throw error;
    }
  }
}
