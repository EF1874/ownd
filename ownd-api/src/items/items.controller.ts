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
  Res,
} from '@nestjs/common';
import { ItemsService } from './items.service';
import { CreateItemDto } from './dto/create-item.dto';
import { CreateItemHistoryDto } from './dto/create-item-history.dto';
import { UpdateItemHistoryDto } from './dto/update-item-history.dto';
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
import type { Response } from 'express';
import { AssetPurpose } from '@prisma/client';
import { AssetsService } from '../assets/assets.service';

interface RequestWithUser extends Request {
  user: User;
}

const imageMaxSize = 5 * 1024 * 1024;
const imageFileType = /image\/(jpeg|jpg|png)/;

@ApiTags('物品管理')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('items')
export class ItemsController {
  constructor(
    private readonly itemsService: ItemsService,
    private readonly minioService: MinioService,
    private readonly assetsService: AssetsService,
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
          new MaxFileSizeValidator({ maxSize: imageMaxSize }),
          new FileTypeValidator({ fileType: imageFileType }),
        ],
        fileIsRequired: false,
      }),
    )
    file?: Express.Multer.File,
  ) {
    let imagePath: string | undefined = undefined;
    if (file) {
      imagePath = await this.uploadTrackedItemImage(req.user.id, file);
    }

    try {
      return await this.itemsService.create(req.user.id, {
        ...createItemDto,
        imagePath,
      });
    } catch (error) {
      await this.assetsService.discardUpload(imagePath);
      throw error;
    }
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

  @Get('images/:fileName')
  @ApiOperation({ summary: '获取物品图片' })
  @ApiResponse({ status: 200, description: '获取成功' })
  async getImage(@Param('fileName') fileName: string, @Res() res: Response) {
    const { stream, contentType } = await this.minioService.getFile(fileName);
    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'private, max-age=86400');
    stream.pipe(res);
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
          new MaxFileSizeValidator({ maxSize: imageMaxSize }),
          new FileTypeValidator({ fileType: imageFileType }),
        ],
        fileIsRequired: false,
      }),
    )
    file?: Express.Multer.File,
  ) {
    const previousItem =
      file || updateItemDto.imagePath !== undefined
        ? await this.itemsService.findOne(req.user.id, id)
        : null;
    let imagePath: string | undefined = undefined;
    if (file) {
      imagePath = await this.uploadTrackedItemImage(req.user.id, file);
    }

    try {
      const updated = await this.itemsService.update(req.user.id, id, {
        ...updateItemDto,
        imagePath,
      });
      if (
        previousItem?.imagePath &&
        previousItem.imagePath !== updated.imagePath
      ) {
        await this.assetsService.releasePath(previousItem.imagePath);
      }
      return updated;
    } catch (error) {
      await this.assetsService.discardUpload(imagePath);
      throw error;
    }
  }

  @Delete(':id')
  @Audit('删除物品')
  @ApiOperation({ summary: '删除物品' })
  @ApiResponse({ status: 200, description: '删除成功' })
  async remove(@Param('id') id: string, @Request() req: RequestWithUser) {
    const item = await this.itemsService.findOne(req.user.id, id);
    const deleted = await this.itemsService.remove(req.user.id, id);
    await this.assetsService.releasePath(item.imagePath);
    return deleted;
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
          new MaxFileSizeValidator({ maxSize: imageMaxSize }),
          new FileTypeValidator({ fileType: imageFileType }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Request() req: RequestWithUser,
  ) {
    const item = await this.itemsService.findOne(req.user.id, id);
    const savedPath = await this.uploadTrackedItemImage(req.user.id, file);

    try {
      const updated = await this.itemsService.updateImagePath(
        req.user.id,
        id,
        savedPath,
      );
      if (item.imagePath && item.imagePath !== savedPath) {
        await this.assetsService.releasePath(item.imagePath);
      }
      return updated;
    } catch (error) {
      await this.assetsService.discardUpload(savedPath);
      throw error;
    }
  }

  @Delete(':id/image')
  @Audit('删除物品图片')
  @ApiOperation({ summary: '删除物品图片' })
  @ApiResponse({ status: 200, description: '删除成功' })
  async removeImage(@Param('id') id: string, @Request() req: RequestWithUser) {
    const item = await this.itemsService.findOne(req.user.id, id);
    const updated = await this.itemsService.updateImagePath(
      req.user.id,
      id,
      null,
    );
    await this.assetsService.releasePath(item.imagePath);
    return updated;
  }

  private async uploadTrackedItemImage(
    userId: string,
    file: Express.Multer.File,
  ) {
    const path = await this.minioService.uploadFile(file);
    try {
      await this.assetsService.registerUpload({
        userId,
        path,
        purpose: AssetPurpose.ITEM_IMAGE,
        file,
      });
      return path;
    } catch (error) {
      await this.minioService.deleteFile(path).catch(() => undefined);
      throw error;
    }
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

  @Patch(':id/histories/:historyId')
  @Audit('更新物品历史记录')
  @ApiOperation({ summary: '更新物品的某条历史记录' })
  @ApiResponse({ status: 200, description: '更新成功' })
  updateHistory(
    @Param('id') id: string,
    @Param('historyId') historyId: string,
    @Body() updateItemHistoryDto: UpdateItemHistoryDto,
    @Request() req: RequestWithUser,
  ) {
    return this.itemsService.updateHistory(
      req.user.id,
      id,
      historyId,
      updateItemHistoryDto,
    );
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
