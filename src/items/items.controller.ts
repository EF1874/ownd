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
} from '@nestjs/common';
import { ItemsService } from './items.service';
import { CreateItemDto } from './dto/create-item.dto';
import { JwtAuthGuard } from '../common/guard/jwt.guard';
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
  @ApiOperation({ summary: '获取全部物品' })
  @ApiResponse({ status: 200, type: [ItemEntity] })
  findAll(@Request() req: RequestWithUser) {
    return this.itemsService.findAll(req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: '获取物品详情' })
  @ApiResponse({ status: 200, type: ItemEntity })
  findOne(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.itemsService.findOne(id, req.user.id);
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

    return this.itemsService.update(id, req.user.id, {
      ...updateItemDto,
      imagePath,
    });
  }

  @Delete(':id')
  @ApiOperation({ summary: '删除物品' })
  @ApiResponse({ status: 200, description: '删除成功' })
  remove(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.itemsService.remove(id, req.user.id);
  }

  // 保留单独上传图片的接口，用于纯图片更新场景
  @Post(':id/image')
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
    await this.itemsService.findOne(id, req.user.id);
    const savedPath = await this.minioService.uploadFile(file);
    return this.itemsService.updateImagePath(id, req.user.id, savedPath);
  }
}
