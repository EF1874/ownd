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
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { CategoriesService } from './categories.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { JwtAuthGuard } from '../common/guard/jwt.guard';
import { Audit } from '../common/decorators/audit.decorator';
import { User } from '@prisma/client';
import { CategoryEntity } from './entities/category.entity';

interface RequestWithUser extends Request {
  user: User;
}

@ApiTags('分类管理')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('categories')
export class CategoriesController {
  constructor(private readonly categoriesService: CategoriesService) {}

  @Post()
  @Audit('创建分类')
  @ApiOperation({ summary: '创建分类' })
  @ApiResponse({ status: 201, type: CategoryEntity })
  create(
    @Body() createCategoryDto: CreateCategoryDto,
    @Request() req: RequestWithUser,
  ) {
    return this.categoriesService.create(req.user.id, createCategoryDto);
  }

  @Get()
  @ApiOperation({ summary: '获取全部分类（树状结构）' })
  @ApiResponse({ status: 200, type: [CategoryEntity] })
  findAll(@Request() req: RequestWithUser) {
    return this.categoriesService.findAll(req.user.id);
  }

  @Get(':id')
  @ApiOperation({ summary: '获取分类详情' })
  @ApiResponse({ status: 200, type: CategoryEntity })
  findOne(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.categoriesService.findOne(id, req.user.id);
  }

  @Patch(':id')
  @Audit('更新分类')
  @ApiOperation({ summary: '更新分类信息' })
  @ApiResponse({ status: 200, type: CategoryEntity })
  update(
    @Param('id') id: string,
    @Body() updateCategoryDto: UpdateCategoryDto,
    @Request() req: RequestWithUser,
  ) {
    return this.categoriesService.update(id, req.user.id, updateCategoryDto);
  }

  @Delete(':id')
  @Audit('删除分类')
  @ApiOperation({ summary: '删除分类（级联删除子类）' })
  @ApiResponse({ status: 200, description: '删除成功' })
  remove(@Param('id') id: string, @Request() req: RequestWithUser) {
    return this.categoriesService.remove(id, req.user.id);
  }
}
