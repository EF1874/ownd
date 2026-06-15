import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppUpdatesController } from './app-updates.controller';
import { AppUpdatesService } from './app-updates.service';

@Module({
  imports: [ConfigModule],
  controllers: [AppUpdatesController],
  providers: [AppUpdatesService],
})
export class AppUpdatesModule {}
