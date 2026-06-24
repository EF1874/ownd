import { Module } from '@nestjs/common';
import { MinioModule } from '../minio/minio.module';
import { AssetsService } from './assets.service';

@Module({
  imports: [MinioModule],
  providers: [AssetsService],
  exports: [AssetsService],
})
export class AssetsModule {}
