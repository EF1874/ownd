import { ForbiddenException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { Category } from '@prisma/client';

type CategoryWithChildren = Category & { children?: CategoryWithChildren[] };

@Injectable()
export class CategoriesService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createCategoryDto: CreateCategoryDto) {
    // 如果有 parentId，需要验证父级分类是否存在
    if (createCategoryDto.parentId) {
      const parent = await this.findOne(createCategoryDto.parentId, userId);
      if (!parent) {
        throw new ForbiddenException('父级分类不存在或无权访问');
      }
    }

    return this.prisma.category.create({
      data: {
        ...createCategoryDto,
        userId,
      },
    });
  }

  async findAll(userId: string) {
    const categories = await this.prisma.category.findMany({
      where: {
        userId: userId,
      },
    });

    return this.buildTree(categories);
  }

  buildTree(categories: CategoryWithChildren[]) {
    const map = new Map<string, CategoryWithChildren>();
    categories.forEach((category) => {
      map.set(category.id, category);
    });

    return categories.filter((category) => {
      if (category.parentId) {
        const parent = map.get(category.parentId);
        if (parent) {
          if (!parent.children) {
            parent.children = [];
          }
          parent.children.push(category);
          return false;
        }
      }
      return true;
    });
  }

  async findOne(id: string, userId: string) {
    return this.prisma.category.findFirst({
      where: {
        id,
        userId,
      },
    });
  }

  async update(
    id: string,
    userId: string,
    updateCategoryDto: UpdateCategoryDto,
  ) {
    return this.prisma.category.update({
      where: { id, userId },
      data: updateCategoryDto,
    });
  }

  async remove(id: string, userId: string) {
    return this.prisma.category.delete({
      where: { id, userId },
    });
  }
}
