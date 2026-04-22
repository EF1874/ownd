import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as Minio from 'minio';
import path from 'path';

@Injectable()
export class MinioService {
  private readonly client: Minio.Client;
  private readonly bucketName: string;
  private readonly logger = new Logger(MinioService.name);

  constructor(private configService: ConfigService) {
    const endPoint = this.configService.get<string>('MINIO_ENDPOINT');

    if (!endPoint) {
      this.logger.error(
        'MINIO_ENDPOINT is not defined in environment variables!',
      );
    }

    this.client = new Minio.Client({
      endPoint: endPoint || '',
      port: 9000,
      useSSL: false,
      accessKey: this.configService.get<string>('MINIO_ROOT_USER'),
      secretKey: this.configService.get<string>('MINIO_ROOT_PASSWORD'),
    });

    this.bucketName = 'ownd-items';
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
}
