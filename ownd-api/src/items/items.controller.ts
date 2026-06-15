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
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
  Query,
} from '@nestjs/common';
import { ItemsService } from './items.service';
import { CreateItemDto } from './dto/create-item.dto';
import { CreateItemHistoryDto } from './dto/create-item-history.dto';
import { JwtAuthGuard } from '../common/guard/jwt.guard';
import { Audit } from '../common/decorators/audit.decorator';
import { User } from '@prisma/client';
import { UpdateItemDto } from './dto/update-item.dto';
import { MinioService } from '../minio/minio.service';
import {
  ApiBearerAuth,
  ApiConsumes,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { FileInterceptor } from '@nestjs/platform-express';
import { ItemEntity } from './entities/item.entity';

interface RequestWithUser extends Request {
  user: User;
}

@ApiTags('物品管理')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('items')
export class ItemsController {
  constructor(
    private readonly itemsService: ItemsService,
    private readonly minioService: MinioService,
  ) {}

  @Post('import')
  @Audit('导入备份数据')
  @ApiOperation({ summary: '批量导入/恢复备份数据' })
  @ApiResponse({ status: 201, description: '导入成功' })
  importBackup(@Body() body: any, @Request() req: RequestWithUser) {
    return this.itemsService.importBackup(req.user.id, body);
  }

  @Post()
  @ApiOperation({ summary: '创建物品 (支持同时上传图片)' })
  @ApiConsumes('multipart/form-data')
  @ApiResponse({ status: 201, type: ItemEntity })
  @UseInterceptors(FileInterceptor('file'))
  async create(
    @Body() createItemDto: CreateItemDto,
    @Request() req: RequestWithUser,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 }),
          new FileTypeValidator({ fileType: /image\/(jpeg|jpg|png)/ }),
        ],
        fileIsRequired: false,
      }),
    )
    file?: Express.Multer.File,
  ) {
    let imagePath: string | undefined = undefined;
    if (file) {
      imagePath = await this.minioService.uploadFile(file);
    }

    return this.itemsService.create(req.user.id, {
      ...createItemDto,
      imagePath,
    });
  }

  @Get()
  @ApiOperation({ summary: '获取全部物品 (支持分页、搜索、筛选和排序)' })
  @ApiResponse({ status: 200, type: [ItemEntity] })
  findAll(
    @Request() req: RequestWithUser,
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('categoryId') categoryId?: string,
    @Query('platformId') platformId?: string,
    @Query('tag') tag?: string,
    @Query('expiringSoon') expiringSoon?: string,
    @Query('sortBy') sortBy?: string,
    @Query('sortOrder') sortOrder?: 'asc' | 'desc',
  ) {
    return this.itemsService.findAll(req.user.id, {
      search,
      page: page ? Number(page) : undefined,
      limit: limit ? Number(limit) : undefined,
      categoryId,
      platformId,
      tag,
      expiringSoon: expiringSoon === 'true',
      sortBy,
      sortOrder,
    });
  }

  @Get(':id')
  @ApiOperation({ summary: '获取物品详情' })
  @ApiResponse({ status: 200, type: ItemEntity })
  findOne(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.itemsService.findOne(req.user.id, id);
  }

  @Patch(':id')
  @ApiOperation({ summary: '更新物品 (支持同时更新图片)' })
  @ApiConsumes('multipart/form-data')
  @ApiResponse({ status: 200, type: ItemEntity })
  @UseInterceptors(FileInterceptor('file'))
  async update(
    @Param('id') id: string,
    @Body() updateItemDto: UpdateItemDto,
    @Request() req: RequestWithUser,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 }),
          new FileTypeValidator({ fileType: /image\/(jpeg|jpg|png)/ }),
        ],
        fileIsRequired: false,
      }),
    )
    file?: Express.Multer.File,
  ) {
    let imagePath: string | undefined = undefined;
    if (file) {
      imagePath = await this.minioService.uploadFile(file);
    }

    return this.itemsService.update(req.user.id, id, {
      ...updateItemDto,
      imagePath,
    });
  }

  @Delete(':id')
  @Audit('删除物品')
  @ApiOperation({ summary: '删除物品' })
  @ApiResponse({ status: 200, description: '删除成功' })
  remove(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.itemsService.remove(req.user.id, id);
  }

  // 保留单独上传图片的接口，用于纯图片更新场景
  @Post(':id/image')
  @Audit('更新物品图片')
  @ApiOperation({ summary: '仅更新物品图片' })
  @ApiConsumes('multipart/form-data')
  @ApiResponse({ status: 201, description: '图片上传成功' })
  @UseInterceptors(FileInterceptor('file'))
  async uploadImage(
    @Param('id') id: string,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 }),
          new FileTypeValidator({ fileType: /image\/(jpeg|jpg|png)/ }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Request() req: RequestWithUser,
  ) {
    await this.itemsService.findOne(req.user.id, id);
    const savedPath = await this.minioService.uploadFile(file);
    return this.itemsService.updateImagePath(req.user.id, id, savedPath);
  }

  // --- 历史记录 (ItemHistory) 端点 ---

  @Post(':id/histories')
  @Audit('添加物品历史记录')
  @ApiOperation({ summary: '为物品添加历史记录 (续费/维修/升级)' })
  @ApiResponse({ status: 201, description: '添加成功' })
  addHistory(
    @Param('id') id: string,
    @Body() createItemHistoryDto: CreateItemHistoryDto,
    @Request() req: RequestWithUser,
  ) {
    return this.itemsService.addHistory(req.user.id, id, createItemHistoryDto);
  }

  @Get(':id/histories')
  @ApiOperation({ summary: '获取物品的所有历史记录' })
  @ApiResponse({ status: 200, description: '获取成功' })
  findAllHistories(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.itemsService.findHistories(req.user.id, id);
  }

  @Delete(':id/histories/:historyId')
  @Audit('删除物品历史记录')
  @ApiOperation({ summary: '删除物品的某条历史记录' })
  @ApiResponse({ status: 200, description: '删除成功' })
  removeHistory(
    @Param('id') id: string,
    @Param('historyId') historyId: string,
    @Request() req: RequestWithUser,
  ) {
    return this.itemsService.removeHistory(req.user.id, id, historyId);
  }
}
