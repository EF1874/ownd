import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  Inject,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { CreateItemHistoryDto } from './dto/create-item-history.dto';
import { ItemCycleType, ItemRecordType, Prisma } from '@prisma/client';
import dayjs from 'dayjs';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import * as cacheManager from 'cache-manager';
import { randomUUID } from 'crypto';

type ItemWithRelations = Prisma.ItemGetPayload<{
  include: {
    category: { include: { parent: true } };
    platform: true;
    itemHistories: {
      orderBy: { startDate: 'desc' };
      take: 1;
    };
  };
}>;

@Injectable()
export class ItemsService {
  constructor(
    private prisma: PrismaService,
    @Inject(CACHE_MANAGER) private cacheManager: cacheManager.Cache,
  ) {}

  private readonly itemInclude = {
    category: { include: { parent: true } },
    platform: true,
    itemHistories: true,
  } satisfies Prisma.ItemInclude;

  async create(userId: string, createItemDto: CreateItemDto) {
    const { platformId, categoryId, imagePath, ...data } = createItemDto;

    await this.ensureCategoryAccess(userId, categoryId);
    await this.ensurePlatformAccess(userId, platformId);

    // 1. 初始化变量
    let nextBillingDate: Date | null = null;
    const itemHistoriesCreate: Prisma.ItemHistoryCreateWithoutItemInput[] = [];

    // 2. 如果是虚拟物品/订阅，计算下一期并准备首期记录
    if (data.isVirtual && data.currentCycleType && data.currentCycle) {
      const startDate = data.purchaseDate || new Date();

      // 计算结束日期（当前期的最后一天）
      const endDate = this.calculateNextDate(
        startDate,
        data.currentCycleType,
        data.currentCycle,
      );

      // 下一期账单日 = 结束日期 + 1天
      const nextDate = dayjs(endDate).add(1, 'day');
      nextBillingDate = nextDate.toDate();

      // 准备首期历史记录
      itemHistoriesCreate.push({
        type: ItemRecordType.RENEWAL,
        price: data.price,
        startDate: startDate,
        endDate: endDate,
        cycleType: data.currentCycleType,
        cycle: data.currentCycle,
        note: '系统初始创建',
      });
    }

    // 3. 事务性创建物品和历史记录
    const created = await this.prisma.item.create({
      data: {
        ...data,
        imagePath,
        nextBillingDate,
        user: { connect: { id: userId } },
        category: categoryId ? { connect: { id: categoryId } } : undefined,
        platform: platformId ? { connect: { id: platformId } } : undefined,
        itemHistories:
          itemHistoriesCreate.length > 0
            ? { create: itemHistoriesCreate }
            : undefined,
      },
      include: this.itemInclude,
    });
    await this.clearCache(userId);
    return created;
  }

  /**
   * 计算周期的结束日期
   */
  public calculateNextDate(
    start: Date,
    type: ItemCycleType,
    value: number,
  ): Date {
    const d = dayjs(start);
    switch (type) {
      case ItemCycleType.DAY:
        return d.add(value, 'day').subtract(1, 'ms').toDate();
      case ItemCycleType.WEEK:
        return d.add(value, 'week').subtract(1, 'ms').toDate();
      case ItemCycleType.MONTH:
        return d.add(value, 'month').subtract(1, 'ms').toDate();
      case ItemCycleType.QUARTER:
        return d
          .add(value * 3, 'month')
          .subtract(1, 'ms')
          .toDate();
      case ItemCycleType.YEAR:
        return d.add(value, 'year').subtract(1, 'ms').toDate();
      default:
        return start;
    }
  }

  async findAll(
    userId: string,
    query?: {
      search?: string;
      page?: number;
      limit?: number;
      categoryId?: string;
      platformId?: string;
      tag?: string;
      sortBy?: string;
      sortOrder?: 'asc' | 'desc';
    },
  ) {
    const isFiltered = query && Object.keys(query).some(k => query[k] !== undefined);
    const cacheKey = `user:${userId}:items`;

    if (!isFiltered) {
      try {
        const cached = await this.cacheManager.get<ItemWithRelations[]>(cacheKey);
        if (cached) {
          return cached;
        }
      } catch {
        // ignore
      }
    }

    const where: Prisma.ItemWhereInput = { userId };
    const andConditions: Prisma.ItemWhereInput[] = [];

    if (query?.search) {
      andConditions.push({
        OR: [
          { name: { contains: query.search, mode: 'insensitive' } },
          { notes: { contains: query.search, mode: 'insensitive' } },
        ],
      });
    }

    if (query?.categoryId) {
      const categoryIds = query.categoryId.split(',');
      andConditions.push({
        OR: [
          { categoryId: { in: categoryIds } },
          { category: { parentId: { in: categoryIds } } },
        ],
      });
    }

    if (query?.platformId) {
      andConditions.push({ platformId: query.platformId });
    }

    if (query?.tag) {
      const tags = query.tag.split(',');
      andConditions.push({ tags: { hasEvery: tags } });
    }

    if (andConditions.length > 0) {
      where.AND = andConditions;
    }

    // Determine sorting
    let orderBy: Prisma.ItemOrderByWithRelationInput = { purchaseDate: 'desc' }; // default
    const order = query?.sortOrder === 'asc' ? 'asc' : 'desc';

    if (query?.sortBy) {
      if (query.sortBy === 'price') {
        orderBy = { price: order };
      } else if (query.sortBy === 'expiry') {
        orderBy = { nextBillingDate: order };
      } else if (query.sortBy === 'date') {
        orderBy = { purchaseDate: order };
      }
    }

    // Pagination
    let skip: number | undefined = undefined;
    let take: number | undefined = undefined;

    if (query?.page && query?.limit) {
      const page = Number(query.page);
      const limit = Number(query.limit);
      skip = (page - 1) * limit;
      take = limit;
    }

    const items = await this.prisma.item.findMany({
      where,
      include: {
        category: { include: { parent: true } },
        platform: true,
        itemHistories: {
          orderBy: { startDate: 'desc' },
          take: 1, // 默认只带出最新的一条记录用于展示
        },
      },
      orderBy,
      skip,
      take,
    });

    if (!isFiltered) {
      try {
        await this.cacheManager.set(cacheKey, items, 600000); // 缓存 10 分钟
      } catch {
        // ignore
      }
    }

    return items;
  }

  async findOne(userId: string, id: string) {
    const item = await this.prisma.item.findFirst({
      where: { id, userId },
      include: {
        category: { include: { parent: true } },
        platform: true,
        itemHistories: {
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!item) {
      throw new NotFoundException(`物品 ID ${id} 未找到`);
    }

    return item;
  }

  async update(userId: string, id: string, updateItemDto: UpdateItemDto) {
    // 先检查是否存在
    await this.findOne(userId, id);

    const { platformId, categoryId, imagePath, ...data } = updateItemDto;

    await this.ensureCategoryAccess(userId, categoryId);
    await this.ensurePlatformAccess(userId, platformId);

    const updated = await this.prisma.item.update({
      where: { id },
      data: {
        ...data,
        imagePath,
        category: categoryId ? { connect: { id: categoryId } } : undefined,
        platform: platformId ? { connect: { id: platformId } } : undefined,
      },
      include: {
        category: { include: { parent: true } },
        platform: true,
      },
    });
    await this.clearCache(userId);
    return updated;
  }

  private async ensureCategoryAccess(userId: string, categoryId?: string) {
    if (!categoryId) return;

    const category = await this.prisma.category.findFirst({
      where: {
        id: categoryId,
        userId,
      },
    });

    if (!category) {
      throw new ForbiddenException('分类不存在或无权访问');
    }
  }

  private async ensurePlatformAccess(userId: string, platformId?: string) {
    if (!platformId) return;

    const platform = await this.prisma.platform.findFirst({
      where: {
        id: platformId,
        userId,
      },
    });

    if (!platform) {
      throw new ForbiddenException('平台不存在或无权访问');
    }
  }

  async updateImagePath(userId: string, id: string, imagePath: string) {
    await this.findOne(userId, id);
    const updated = await this.prisma.item.update({
      where: { id },
      data: { imagePath },
    });
    await this.clearCache(userId);
    return updated;
  }

  async remove(userId: string, id: string) {
    // 先检查是否存在
    await this.findOne(userId, id);

    const deleted = await this.prisma.item.delete({
      where: { id },
    });
    await this.clearCache(userId);
    return deleted;
  }

  // --- 历史记录管理 (ItemHistory) ---

  async addHistory(userId: string, itemId: string, dto: CreateItemHistoryDto) {
    // 1. 鉴权：确保物品属于该用户
    await this.findOne(userId, itemId);

    // 2. 事务处理：创建历史记录 + (如果是续费) 更新物品账单日
    const result = await this.prisma.$transaction(async (tx) => {
      const history = await tx.itemHistory.create({
        data: {
          ...dto,
          itemId,
        },
      });

      // 如果是续费记录，且提供了结束日期，则更新物品的下期账单日
      if (dto.type === ItemRecordType.RENEWAL && dto.endDate) {
        const nextDate = dayjs(dto.endDate).add(1, 'day').toDate();
        await tx.item.update({
          where: { id: itemId },
          data: { nextBillingDate: nextDate },
        });
      }

      return history;
    });
    await this.clearCache(userId);
    return result;
  }

  async findHistories(userId: string, itemId: string) {
    // 鉴权
    await this.findOne(userId, itemId);

    return this.prisma.itemHistory.findMany({
      where: { itemId },
      orderBy: { recordDate: 'desc' },
    });
  }

  async removeHistory(userId: string, itemId: string, historyId: string) {
    // 鉴权：先确保物品属于用户
    await this.findOne(userId, itemId);

    // 再确保历史记录属于该物品
    const history = await this.prisma.itemHistory.findUnique({
      where: { id: historyId },
    });

    if (!history || history.itemId !== itemId) {
      throw new NotFoundException('历史记录不存在或不属于该物品');
    }

    const deleted = await this.prisma.itemHistory.delete({
      where: { id: historyId },
    });
    await this.clearCache(userId);
    return deleted;
  }

  async importBackup(userId: string, data: any) {
    let createdCount = 0;
    let updatedCount = 0;
    const duplicates: string[] = [];

    await this.prisma.$transaction(async (tx) => {
      // 0. Ensure user templates are copied first inside the transaction
      const categoriesCount = await tx.category.count({ where: { userId } });
      if (categoriesCount === 0) {
        const templates = await tx.category.findMany({ where: { userId: null } });
        const idMap = new Map<string, string>();
        for (const template of templates.filter((c) => !c.parentId)) {
          const created = await tx.category.create({
            data: {
              name: template.name,
              icon: template.icon,
              isVirtual: template.isVirtual,
              userId,
            },
          });
          idMap.set(template.id, created.id);
        }
        for (const template of templates.filter((c) => c.parentId)) {
          const parentId = template.parentId
            ? idMap.get(template.parentId)
            : undefined;
          if (parentId) {
            const created = await tx.category.create({
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
        await tx.user.update({
          where: { id: userId },
          data: { categoryDefaultsInitialized: true },
        });
      }

      const platformsCount = await tx.platform.count({ where: { userId } });
      if (platformsCount === 0) {
        const templates = await tx.platform.findMany({ where: { userId: null } });
        for (const template of templates) {
          await tx.platform.create({
            data: {
              name: template.name,
              icon: template.icon,
              color: template.color,
              userId,
            },
          });
        }
        await tx.user.update({
          where: { id: userId },
          data: { platformDefaultsInitialized: true },
        });
      }

      // 1. Restore categories
      const existingCategories = await tx.category.findMany({
        where: { OR: [{ userId }, { userId: null }] },
      });
      const userCategories = existingCategories.filter((c) => c.userId !== null);
      const templateCategories = existingCategories.filter((c) => c.userId === null);

      const userCategoryMap = new Map<string, string>(); // name -> id, id -> id
      for (const cat of userCategories) {
        userCategoryMap.set(cat.name, cat.id);
        userCategoryMap.set(cat.id, cat.id);
      }

      const templateCategoryMap = new Map<string, string>(); // id -> name, name -> name
      for (const cat of templateCategories) {
        templateCategoryMap.set(cat.id, cat.name);
        templateCategoryMap.set(cat.name, cat.name);
      }

      const rawCategories = data.categories || [];
      for (const cat of rawCategories) {
        if (!cat.name) continue;

        // If the user already has a category with this name, map cat.uuid to the user's category ID.
        if (userCategoryMap.has(cat.name)) {
          const userCatId = userCategoryMap.get(cat.name)!;
          if (cat.uuid) {
            userCategoryMap.set(cat.uuid, userCatId);
          }
          continue;
        }

        // Otherwise, check if there is a template category with this name.
        const templateCat = templateCategories.find((c) => c.name === cat.name);
        if (templateCat) {
          // Find or create parent if template category has a parent
          let parentId: string | null = null;
          if (templateCat.parentId) {
            const templateParent = templateCategories.find((c) => c.id === templateCat.parentId);
            if (templateParent) {
              // Ensure the parent is copied to the user's categories first
              if (userCategoryMap.has(templateParent.name)) {
                parentId = userCategoryMap.get(templateParent.name)!;
              } else {
                const newParent = await tx.category.create({
                  data: {
                    name: templateParent.name,
                    icon: templateParent.icon,
                    isVirtual: templateParent.isVirtual,
                    userId,
                  },
                });
                userCategoryMap.set(newParent.name, newParent.id);
                userCategoryMap.set(newParent.id, newParent.id);
                parentId = newParent.id;
              }
            }
          }

          // Create the user's copy of the template category
          const newCat = await tx.category.create({
            data: {
              name: cat.name,
              icon: cat.iconPath || templateCat.icon || 'MdiIcons.tag',
              isVirtual: templateCat.isVirtual,
              userId,
              parentId,
            },
          });
          userCategoryMap.set(newCat.name, newCat.id);
          userCategoryMap.set(newCat.id, newCat.id);
          if (cat.uuid) {
            userCategoryMap.set(cat.uuid, newCat.id);
          }
        } else {
          // Create custom category for the user
          const newCat = await tx.category.create({
            data: {
              name: cat.name,
              icon: cat.iconPath || 'MdiIcons.tag',
              userId,
            },
          });
          userCategoryMap.set(newCat.name, newCat.id);
          userCategoryMap.set(newCat.id, newCat.id);
          if (cat.uuid) {
            userCategoryMap.set(cat.uuid, newCat.id);
          }
        }
      }

      // 2. Restore platforms
      const existingPlatforms = await tx.platform.findMany({
        where: { OR: [{ userId }, { userId: null }] },
      });
      const userPlatforms = existingPlatforms.filter((p) => p.userId !== null);
      const templatePlatforms = existingPlatforms.filter((p) => p.userId === null);

      const userPlatformMap = new Map<string, string>(); // name -> id, id -> id
      for (const plat of userPlatforms) {
        userPlatformMap.set(plat.name, plat.id);
        userPlatformMap.set(plat.id, plat.id);
      }

      const templatePlatformMap = new Map<string, string>(); // id -> name, name -> name
      for (const plat of templatePlatforms) {
        templatePlatformMap.set(plat.id, plat.name);
        templatePlatformMap.set(plat.name, plat.name);
      }

      // 3. Process devices
      const existingItems = await tx.item.findMany({
        where: { userId },
        select: { id: true },
      });
      const existingIds = new Set(existingItems.map((item) => item.id));
      const processedIds: string[] = [];

      const rawDevices = data.devices || [];

      for (const dev of rawDevices) {
        const oldUuid = dev.uuid;

        let itemUuid = oldUuid;
        let isUpdate = false;

        const purchaseDate = dev.purchaseDate
          ? new Date(dev.purchaseDate)
          : new Date();

        if (oldUuid) {
          const existingItem = await tx.item.findUnique({
            where: { id: oldUuid },
            select: { userId: true },
          });
          if (existingItem) {
            if (existingItem.userId === userId) {
              isUpdate = true;
            } else {
              // Belongs to someone else, check for duplicate first to prevent duplicate imports
              const existingDuplicate = await tx.item.findFirst({
                where: {
                  userId,
                  name: dev.name,
                  price: dev.price || 0,
                  purchaseDate: purchaseDate,
                  id: { notIn: processedIds },
                },
                select: { id: true },
              });
              if (existingDuplicate) {
                itemUuid = existingDuplicate.id;
                isUpdate = true;
              } else {
                itemUuid = randomUUID();
              }
            }
          } else {
            // UUID doesn't exist, check for duplicate first to prevent duplicate imports
            const existingDuplicate = await tx.item.findFirst({
              where: {
                userId,
                name: dev.name,
                price: dev.price || 0,
                purchaseDate: purchaseDate,
                id: { notIn: processedIds },
              },
              select: { id: true },
            });
            if (existingDuplicate) {
              itemUuid = existingDuplicate.id;
              isUpdate = true;
            }
          }
        } else {
          // No UUID in backup, check for duplicate first to prevent duplicate imports
          const existingDuplicate = await tx.item.findFirst({
            where: {
              userId,
              name: dev.name,
              price: dev.price || 0,
              purchaseDate: purchaseDate,
              id: { notIn: processedIds },
            },
            select: { id: true },
          });
          if (existingDuplicate) {
            itemUuid = existingDuplicate.id;
            isUpdate = true;
          } else {
            itemUuid = randomUUID();
          }
        }

        processedIds.push(itemUuid);

        if (isUpdate) {
          updatedCount++;
          if (!duplicates.includes(dev.name)) {
            duplicates.push(dev.name);
          }
        } else {
          createdCount++;
        }

        // Resolve Category to user-owned Category
        let categoryId: string | null = null;
        
        // 1. Try resolving using categoryUuid from backup
        if (dev.categoryUuid) {
          if (userCategoryMap.has(dev.categoryUuid)) {
            categoryId = userCategoryMap.get(dev.categoryUuid)!;
          } else if (templateCategoryMap.has(dev.categoryUuid)) {
            const templateName = templateCategoryMap.get(dev.categoryUuid)!;
            if (userCategoryMap.has(templateName)) {
              categoryId = userCategoryMap.get(templateName)!;
            }
          }
        }

        // 2. Try resolving using categoryName from backup
        if (!categoryId && dev.categoryName) {
          if (userCategoryMap.has(dev.categoryName)) {
            categoryId = userCategoryMap.get(dev.categoryName)!;
          } else if (templateCategoryMap.has(dev.categoryName)) {
            const templateName = templateCategoryMap.get(dev.categoryName)!;
            // Copy template category to user categories if missing
            const templateCat = templateCategories.find((c) => c.name === templateName);
            if (templateCat) {
              let parentId: string | null = null;
              if (templateCat.parentId) {
                const templateParent = templateCategories.find((c) => c.id === templateCat.parentId);
                if (templateParent) {
                  if (userCategoryMap.has(templateParent.name)) {
                    parentId = userCategoryMap.get(templateParent.name)!;
                  } else {
                    const newParent = await tx.category.create({
                      data: {
                        name: templateParent.name,
                        icon: templateParent.icon,
                        isVirtual: templateParent.isVirtual,
                        userId,
                      },
                    });
                    userCategoryMap.set(newParent.name, newParent.id);
                    userCategoryMap.set(newParent.id, newParent.id);
                    parentId = newParent.id;
                  }
                }
              }

              const newCat = await tx.category.create({
                data: {
                  name: templateCat.name,
                  icon: templateCat.icon,
                  isVirtual: templateCat.isVirtual,
                  userId,
                  parentId,
                },
              });
              userCategoryMap.set(newCat.name, newCat.id);
              userCategoryMap.set(newCat.id, newCat.id);
              categoryId = newCat.id;
            }
          }
        }

        // Resolve Platform to user-owned Platform
        let platformId: string | null = null;
        if (dev.platform) {
          if (userPlatformMap.has(dev.platform)) {
            platformId = userPlatformMap.get(dev.platform)!;
          } else if (templatePlatformMap.has(dev.platform)) {
            // Find template platform and copy it for the user
            const templateName = templatePlatformMap.get(dev.platform)!;
            const templatePlat = templatePlatforms.find((p) => p.name === templateName);
            if (templatePlat) {
              const newPlat = await tx.platform.create({
                data: {
                  name: templatePlat.name,
                  icon: templatePlat.icon,
                  color: templatePlat.color,
                  userId,
                },
              });
              userPlatformMap.set(newPlat.name, newPlat.id);
              userPlatformMap.set(newPlat.id, newPlat.id);
              platformId = newPlat.id;
            }
          } else {
            // Create a custom platform for this user
            const newPlat = await tx.platform.create({
              data: {
                name: dev.platform,
                icon: 'MdiIcons.store',
                color: '#9E9E9E',
                userId,
              },
            });
            userPlatformMap.set(newPlat.name, newPlat.id);
            userPlatformMap.set(newPlat.id, newPlat.id);
            platformId = newPlat.id;
          }
        }

        const isVirtual =
          dev.isVirtual ||
          dev.cycleType !== undefined ||
          dev.categoryName === '虚拟订阅';

        let nextBillingDate: Date | null = null;
        if (dev.nextBillingDate) nextBillingDate = new Date(dev.nextBillingDate);

        const itemData = {
          name: dev.name,
          price: dev.price || 0,
          purchaseDate,
          notes: dev.notes,
          tags: dev.tags || [],
          imagePath: dev.imagePath,
          isVirtual,
          currentCycleType: dev.cycleType || null,
          currentCycle: dev.currentCycle || null,
          nextBillingDate,
          isAutoRenew: dev.isAutoRenew || false,
          isBackup: dev.backupDate !== undefined,
          backupDate: dev.backupDate ? new Date(dev.backupDate) : null,
          isScrapped: dev.scrapDate !== undefined,
          scrappedDate: dev.scrapDate ? new Date(dev.scrapDate) : null,
          warrantyEndDate: dev.warrantyEndDate
            ? new Date(dev.warrantyEndDate)
            : null,
          userId,
          categoryId,
          platformId,
        };

        if (isUpdate) {
          // Overwrite / Update existing item
          await tx.item.update({
            where: { id: itemUuid },
            data: itemData,
          });
          // Delete existing history to replace it with backup history
          await tx.itemHistory.deleteMany({
            where: { itemId: itemUuid },
          });
        } else {
          // Create new item
          await tx.item.create({
            data: {
              id: itemUuid,
              ...itemData,
            },
          });
        }

        const rawHistory = dev.history || [];
        if (rawHistory.length > 0) {
          await tx.itemHistory.createMany({
            data: rawHistory.map((h: any) => ({
              type: h.type || 'RENEWAL',
              price: h.price || 0,
              startDate: h.startDate ? new Date(h.startDate) : null,
              endDate: h.endDate ? new Date(h.endDate) : null,
              cycleType: h.cycleType || null,
              cycle: h.cycle || null,
              recordDate: h.recordDate ? new Date(h.recordDate) : new Date(),
              note: h.note,
              itemId: itemUuid,
            })),
          });
        }
      }
    });
    await this.clearCache(userId);
    return {
      createdCount,
      updatedCount,
      duplicates,
    };
  }

  private async clearCache(userId: string) {
    try {
      await this.cacheManager.del(`user:${userId}:items`);
      await this.cacheManager.del(`user:stats:${userId}`);
      await this.cacheManager.del(`user:${userId}:categories`);
      await this.cacheManager.del(`user:platforms:${userId}`);
    } catch {
      // ignore
    }
  }
}
