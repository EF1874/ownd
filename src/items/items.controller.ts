import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { ItemsService } from './items.service';
import { CreateItemDto } from './dto/create-item.dto';
import { JwtAuthGuard } from '../common/guard/jwt.guard';
import { User } from '@prisma/client';
import { UpdateItemDto } from './dto/update-item.dto';
import { MinioService } from '../minio/minio.service';

interface RequestWithUser extends Request {
  user: User;
}

@Controller('items')
export class ItemsController {
  constructor(
    private readonly itemsService: ItemsService,
    private readonly minioService: MinioService,
  ) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  create(
    @Body() createItemDto: CreateItemDto,
    @Request() req: RequestWithUser,
  ) {
    return this.itemsService.create(req.user.id, createItemDto);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  findAll(@Request() req: RequestWithUser) {
    return this.itemsService.findAll(req.user.id);
  }

  @Get(':id')
  @UseGuards(JwtAuthGuard)
  findOne(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.itemsService.findOne(id, req.user.id);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard)
  update(
    @Param('id') id: string,
    @Body() updateItemDto: UpdateItemDto,
    @Request() req: RequestWithUser,
  ) {
    return this.itemsService.update(id, req.user.id, updateItemDto);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard)
  remove(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.itemsService.remove(id, req.user.id);
  }

  @Post(':id/image')
  @UseGuards(JwtAuthGuard)
  @UseInterceptors(FileInterceptor('file'))
  async uploadImage(
    @Param('id') id: string,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          // 限制 1MB 以内 (1024 * 1024)
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 }),
          // 限制只允许常见的图片 MIME 类型
          new FileTypeValidator({ fileType: /image\/(jpeg|jpg|png)/ }),
        ],
      }),
    )
    file: Express.Multer.File,
    @Request() req: RequestWithUser,
  ) {
    // 1. 先验证该物品是否属于该用户（复用 findOne 的逻辑）
    await this.itemsService.findOne(id, req.user.id);

    // 2. 上传文件到 MinIO
    const imagePath = await this.minioService.uploadFile(file);

    // 3. 更新数据库中的 imagePath
    return this.itemsService.updateImagePath(id, req.user.id, imagePath);
  }
}
