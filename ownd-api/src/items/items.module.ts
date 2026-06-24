import { Module } from '@nestjs/common';
import { AssetsModule } from '../assets/assets.module';
import { MinioModule } from '../minio/minio.module';
import { ItemsService } from './items.service';
import { ItemsController } from './items.controller';
import { ItemsCronService } from './items.cron';

@Module({
  imports: [AssetsModule, MinioModule],
  controllers: [ItemsController],
  providers: [ItemsService, ItemsCronService],
})
export class ItemsModule {}
