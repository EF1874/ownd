import { Controller, Get, Query } from '@nestjs/common';
import { ApiOperation, ApiQuery, ApiResponse, ApiTags } from '@nestjs/swagger';
import { AppUpdatesService } from './app-updates.service';
import { AppUpdateDto } from './dto/app-update.dto';

@ApiTags('应用更新')
@Controller('app-updates')
export class AppUpdatesController {
  constructor(private readonly appUpdatesService: AppUpdatesService) {}

  @Get('latest')
  @ApiOperation({ summary: '获取最新应用版本信息' })
  @ApiQuery({ name: 'platform', required: false, example: 'android' })
  @ApiResponse({ status: 200, type: AppUpdateDto })
  getLatest(@Query('platform') platform?: string): Promise<AppUpdateDto> {
    return this.appUpdatesService.getLatest(platform);
  }
}
