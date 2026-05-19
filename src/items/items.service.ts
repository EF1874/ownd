import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { CreateItemHistoryDto } from './dto/create-item-history.dto';
import { ItemCycleType, ItemRecordType, Prisma } from '@prisma/client';
import dayjs from 'dayjs';

@Injectable()
export class ItemsService {
  constructor(private prisma: PrismaService) {}

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
    return this.prisma.item.create({
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

  async findAll(userId: string) {
    return this.prisma.item.findMany({
      where: { userId },
      include: {
        category: { include: { parent: true } },
        platform: true,
        itemHistories: {
          orderBy: { startDate: 'desc' },
          take: 1, // 默认只带出最新的一条记录用于展示
        },
      },
    });
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

    return this.prisma.item.update({
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
    return this.prisma.item.update({
      where: { id },
      data: { imagePath },
    });
  }

  async remove(userId: string, id: string) {
    // 先检查是否存在
    await this.findOne(userId, id);

    return this.prisma.item.delete({
      where: { id },
    });
  }

  // --- 历史记录管理 (ItemHistory) ---

  async addHistory(userId: string, itemId: string, dto: CreateItemHistoryDto) {
    // 1. 鉴权：确保物品属于该用户
    await this.findOne(userId, itemId);

    // 2. 事务处理：创建历史记录 + (如果是续费) 更新物品账单日
    return this.prisma.$transaction(async (tx) => {
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

    return this.prisma.itemHistory.delete({
      where: { id: historyId },
    });
  }
}
