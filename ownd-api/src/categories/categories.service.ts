import { Injectable, NotFoundException, Inject } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';
import { Category } from '@prisma/client';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import * as cacheManager from 'cache-manager';

type CategoryWithChildren = Category & { children?: CategoryWithChildren[] };

@Injectable()
export class CategoriesService {
  constructor(
    private prisma: PrismaService,
    @Inject(CACHE_MANAGER) private cacheManager: cacheManager.Cache,
  ) {}

  async create(userId: string, createCategoryDto: CreateCategoryDto) {
    // 如果有 parentId，需要验证父级分类是否存在
    if (createCategoryDto.parentId) {
      await this.findOne(createCategoryDto.parentId, userId);
    }

    const created = await this.prisma.category.create({
      data: {
        ...createCategoryDto,
        userId,
      },
    });
    await this.clearCache(userId);
    return created;
  }

  async findAll(userId: string) {
    const cacheKey = `user:${userId}:categories`;
    try {
      const cached =
        await this.cacheManager.get<CategoryWithChildren[]>(cacheKey);
      if (cached) {
        return cached;
      }
    } catch {
      // ignore
    }

    await this.ensureUserDefaultCategories(userId);

    const categories = await this.prisma.category.findMany({
      where: {
        userId,
      },
      orderBy: {
        createdAt: 'asc',
      },
    });

    const result = this.buildTree(categories);
    try {
      await this.cacheManager.set(cacheKey, result, 600000); // 缓存 10 分钟
    } catch {
      // ignore
    }
    return result;
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
    const category = await this.prisma.category.findFirst({
      where: {
        id,
        userId,
      },
    });

    if (!category) {
      throw new NotFoundException('分类不存在');
    }

    return category;
  }

  async update(
    id: string,
    userId: string,
    updateCategoryDto: UpdateCategoryDto,
  ) {
    await this.findOne(id, userId);
    if (updateCategoryDto.parentId) {
      await this.findOne(updateCategoryDto.parentId, userId);
    }

    const updated = await this.prisma.category.update({
      where: { id },
      data: updateCategoryDto,
    });
    await this.clearCache(userId);
    return updated;
  }

  async remove(id: string, userId: string) {
    await this.findOne(id, userId);

    const deleted = await this.prisma.category.delete({
      where: { id },
    });
    await this.clearCache(userId);
    return deleted;
  }

  private async clearCache(userId: string) {
    try {
      await this.cacheManager.del(`user:${userId}:categories`);
    } catch {
      // ignore
    }
  }

  private async ensureUserDefaultCategories(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { categoryDefaultsInitialized: true },
    });

    if (!user) {
      throw new NotFoundException('用户不存在');
    }

    const existingUserCategories = await this.prisma.category.count({
      where: { userId },
    });

    if (existingUserCategories === 0) {
      await this.copySystemCategoryTemplates(userId);
    }

    if (!user.categoryDefaultsInitialized) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { categoryDefaultsInitialized: true },
      });
    }
  }

  private async copySystemCategoryTemplates(userId: string) {
    const templates = await this.prisma.category.findMany({
      where: { userId: null },
      orderBy: { createdAt: 'asc' },
    });
    const idMap = new Map<string, string>();

    for (const template of templates.filter((category) => !category.parentId)) {
      const created = await this.prisma.category.create({
        data: {
          name: template.name,
          icon: template.icon,
          isVirtual: template.isVirtual,
          userId,
        },
      });
      idMap.set(template.id, created.id);
    }

    for (const template of templates.filter((category) => category.parentId)) {
      const parentId = template.parentId
        ? idMap.get(template.parentId)
        : undefined;
      if (!parentId) continue;

      const created = await this.prisma.category.create({
        data: {
          name: template.name,
          icon: template.icon,
          isVirtual: template.isVirtual,
          parentId,
          userId,
        },
      });
      idMap.set(template.id, created.id);
    }
  }
}
