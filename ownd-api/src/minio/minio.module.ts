import { Module, Global, OnModuleInit } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { MinioService } from './minio.service';

@Global()
@Module({
  imports: [ConfigModule],
  providers: [MinioService],
  exports: [MinioService],
})
export class MinioModule implements OnModuleInit {
  constructor(private readonly minioService: MinioService) {}

  async onModuleInit() {
    // 启动时自动初始化：确保存储桶存在
    await this.minioService.initBucket();
  }
}
