import { Controller, Get, Param, UseGuards, Request } from '@nestjs/common';
import { StatisticsService } from './statistics.service';
import { JwtAuthGuard } from '../common/guard/jwt.guard';
import { User } from '@prisma/client';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';

interface RequestWithUser extends Request {
  user: User;
}

@ApiTags('统计报表')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('statistics')
export class StatisticsController {
  constructor(private readonly statisticsService: StatisticsService) {}

  @Get('summary')
  @ApiOperation({ summary: '获取资产总览统计' })
  getSummary(@Request() req: RequestWithUser) {
    return this.statisticsService.getSummary(req.user.id);
  }

  @Get('item/:id')
  @ApiOperation({ summary: '获取单品财务统计' })
  getItemStats(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.statisticsService.getItemStats(req.user.id, id);
  }
}
