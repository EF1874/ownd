import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  UseGuards,
  Request,
} from '@nestjs/common';
import { PlatformService } from './platform.service';
import { CreatePlatformDto } from './dto/create-platform.dto';
import { UpdatePlatformDto } from './dto/update-platform.dto';
import { JwtAuthGuard } from '../common/guard/jwt.guard';
import { Audit } from '../common/decorators/audit.decorator';
import { User } from '@prisma/client';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';

interface RequestWithUser extends Request {
  user: User;
}

@ApiTags('平台管理')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('platform')
export class PlatformController {
  constructor(private readonly platformService: PlatformService) {}

  @Post()
  @Audit('创建平台')
  @ApiOperation({ summary: '创建自定义平台' })
  @ApiResponse({ status: 201, description: '创建成功' })
  create(
    @Body() createPlatformDto: CreatePlatformDto,
    @Request() req: RequestWithUser,
  ) {
    return this.platformService.create(req.user.id, createPlatformDto);
  }

  @Get()
  @ApiOperation({ summary: '获取可用平台列表 (含系统预设+个人自定义)' })
  findAll(@Request() req: RequestWithUser) {
    return this.platformService.findAll(req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: '获取平台详情' })
  findOne(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.platformService.findOne(id, req.user.id);
  }

  @Patch(':id')
  @Audit('更新平台')
  @ApiOperation({ summary: '更新自定义平台' })
  update(
    @Param('id') id: string,
    @Body() updatePlatformDto: UpdatePlatformDto,
    @Request() req: RequestWithUser,
  ) {
    return this.platformService.update(id, req.user.id, updatePlatformDto);
  }

  @Delete(':id')
  @Audit('删除平台')
  @ApiOperation({ summary: '删除自定义平台' })
  remove(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.platformService.remove(id, req.user.id);
  }
}
