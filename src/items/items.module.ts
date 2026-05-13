import { Module } from '@nestjs/common';
import { ItemsService } from './items.service';
import { ItemsController } from './items.controller';
import { ItemsCronService } from './items.cron';

@Module({
  controllers: [ItemsController],
  providers: [ItemsService, ItemsCronService],
})
export class ItemsModule {}
