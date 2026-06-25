import {
  ForbiddenException,
  Injectable,
  NotFoundException,
  BadRequestException,
  Inject,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';
import { CreateItemHistoryDto } from './dto/create-item-history.dto';
import { UpdateItemHistoryDto } from './dto/update-item-history.dto';
import {
  AssetPurpose,
  AssetRefType,
  AssetStatus,
  ItemCycleCalculationMode,
  ItemCycleType,
  ItemRecordType,
  Prisma,
} from '@prisma/client';
import dayjs from 'dayjs';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import * as cacheManager from 'cache-manager';
import { BackupData, importItemsBackup } from './item-backup-import';
import { FindItemsQuery, listItems } from './item-list-query';

type RenewalHistoryDateInput = {
  type?: ItemRecordType | null;
  startDate?: Date | null;
  endDate?: Date | null;
};

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

    // 2. 如果是虚拟物品/订阅，计算本期到期日并准备首期记录
    if (data.isVirtual) {
      const currentCycleType = data.currentCycleType ?? ItemCycleType.MONTH;
      const currentCycle = data.currentCycle ?? 1;
      const currentCycleMode =
        data.currentCycleMode ?? ItemCycleCalculationMode.CALENDAR;
      const startDate = data.purchaseDate || new Date();

      // 本期到期日 = 开通日按周期推进后的前一天。
      const endDate =
        data.nextBillingDate ??
        this.calculatePeriodEndDate(
          startDate,
          currentCycleType,
          currentCycle,
          currentCycleMode,
          data.currentCycleDays,
        );

      nextBillingDate = endDate;
      data.currentCycleType = currentCycleType;
      data.currentCycle = currentCycle;
      data.currentCycleMode = currentCycleMode;

      // 准备首期历史记录
      itemHistoriesCreate.push({
        type: ItemRecordType.RENEWAL,
        price: data.price,
        startDate: startDate,
        endDate: endDate,
        cycleType: currentCycleType,
        cycle: currentCycle,
        cycleMode: currentCycleMode,
        cycleDays: data.currentCycleDays,
      });
    }

    // 3. 事务性创建物品和历史记录
    const created = await this.prisma.$transaction(async (tx) => {
      const item = await tx.item.create({
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

      await this.attachItemImageAsset(tx, userId, item.id, imagePath);
      return item;
    });
    await this.clearCache(userId);
    return created;
  }

  /**
   * 计算周期的结束日期
   */
  public calculatePeriodEndDate(
    start: Date,
    type: ItemCycleType,
    value: number,
    mode: ItemCycleCalculationMode = ItemCycleCalculationMode.CALENDAR,
    fixedDays?: number | null,
  ): Date {
    const d = dayjs(start);
    if (mode === ItemCycleCalculationMode.FIXED_DAYS) {
      const days = fixedDays ?? this.defaultFixedCycleDays(type, value);
      return d.add(days, 'day').subtract(1, 'day').toDate();
    }
    switch (type) {
      case ItemCycleType.DAY:
        return d.add(value, 'day').subtract(1, 'day').toDate();
      case ItemCycleType.WEEK:
        return d.add(value, 'week').subtract(1, 'day').toDate();
      case ItemCycleType.MONTH:
        return d.add(value, 'month').subtract(1, 'day').toDate();
      case ItemCycleType.QUARTER:
        return d
          .add(value * 3, 'month')
          .subtract(1, 'day')
          .toDate();
      case ItemCycleType.HALF_YEAR:
        return d
          .add(value * 6, 'month')
          .subtract(1, 'day')
          .toDate();
      case ItemCycleType.YEAR:
        return d.add(value, 'year').subtract(1, 'day').toDate();
      default:
        return start;
    }
  }

  private defaultFixedCycleDays(type: ItemCycleType, value: number): number {
    switch (type) {
      case ItemCycleType.DAY:
        return value;
      case ItemCycleType.WEEK:
        return value * 7;
      case ItemCycleType.MONTH:
        return value * 30;
      case ItemCycleType.QUARTER:
        return value * 90;
      case ItemCycleType.HALF_YEAR:
        return value * 180;
      case ItemCycleType.YEAR:
        return value * 365;
    }
  }

  public calculateNextDate(
    start: Date,
    type: ItemCycleType,
    value: number,
  ): Date {
    return this.calculatePeriodEndDate(start, type, value);
  }

  async findAll(userId: string, query?: FindItemsQuery) {
    return listItems(
      { prisma: this.prisma, cacheManager: this.cacheManager },
      userId,
      query,
    );
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
    const existing = await this.findOne(userId, id);

    const { platformId, categoryId, imagePath, ...data } = updateItemDto;

    await this.ensureCategoryAccess(userId, categoryId);
    await this.ensurePlatformAccess(userId, platformId);

    const updated = await this.prisma.$transaction(async (tx) => {
      const item = await tx.item.update({
        where: { id },
        data: {
          ...data,
          imagePath,
          category: categoryId ? { connect: { id: categoryId } } : undefined,
          platform: platformId ? { connect: { id: platformId } } : undefined,
        },
        include: this.itemInclude,
      });

      if (imagePath !== undefined) {
        await this.syncItemImageAsset(
          tx,
          userId,
          id,
          existing.imagePath,
          imagePath,
        );
      }
      return item;
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

  async updateImagePath(userId: string, id: string, imagePath: string | null) {
    const existing = await this.findOne(userId, id);
    const updated = await this.prisma.$transaction(async (tx) => {
      const item = await tx.item.update({
        where: { id },
        data: { imagePath },
      });
      await this.syncItemImageAsset(
        tx,
        userId,
        id,
        existing.imagePath,
        imagePath,
      );
      return item;
    });
    await this.clearCache(userId);
    return updated;
  }

  private async syncItemImageAsset(
    tx: Prisma.TransactionClient,
    userId: string,
    itemId: string,
    oldPath: string | null,
    newPath: string | null | undefined,
  ) {
    if (oldPath && oldPath !== newPath) {
      await tx.asset.updateMany({
        where: { userId, path: oldPath },
        data: {
          status: AssetStatus.ORPHAN,
          refType: null,
          refId: null,
        },
      });
    }

    await this.attachItemImageAsset(tx, userId, itemId, newPath);
  }

  private async attachItemImageAsset(
    tx: Prisma.TransactionClient,
    userId: string,
    itemId: string,
    imagePath: string | null | undefined,
  ) {
    if (!imagePath) return;

    await tx.asset.updateMany({
      where: { userId, path: imagePath },
      data: {
        purpose: AssetPurpose.ITEM_IMAGE,
        status: AssetStatus.ACTIVE,
        refType: AssetRefType.ITEM,
        refId: itemId,
      },
    });
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
    await this.validateRenewalHistoryDates(itemId, dto);

    // 2. 事务处理：创建历史记录 + (如果是续费) 更新物品账单日
    const result = await this.prisma.$transaction(async (tx) => {
      const history = await tx.itemHistory.create({
        data: {
          ...dto,
          itemId,
        },
      });

      // 如果是续费记录，且提供了结束日期，则更新物品的本期到期日
      if (dto.type === ItemRecordType.RENEWAL && dto.endDate) {
        await tx.item.update({
          where: { id: itemId },
          data: {
            nextBillingDate: await this.latestRenewalEndDate(itemId, tx),
          },
        });
      }

      return history;
    });
    await this.clearCache(userId);
    return result;
  }

  private async validateRenewalHistoryDates(
    itemId: string,
    dto: RenewalHistoryDateInput,
    ignoredHistoryId?: string,
  ) {
    if (dto.type !== ItemRecordType.RENEWAL) return;

    const startDate = dto.startDate
      ? dayjs(dto.startDate).startOf('day')
      : null;
    const endDate = dto.endDate ? dayjs(dto.endDate).startOf('day') : null;

    if (startDate && endDate && endDate.isBefore(startDate)) {
      throw new BadRequestException('到期日期不能早于开始日期');
    }

    if (startDate && endDate) {
      const overlappingHistory = await this.prisma.itemHistory.findFirst({
        where: {
          itemId,
          type: ItemRecordType.RENEWAL,
          id: ignoredHistoryId ? { not: ignoredHistoryId } : undefined,
          startDate: { not: null, lte: endDate.toDate() },
          endDate: { not: null, gte: startDate.toDate() },
        },
      });
      if (overlappingHistory) {
        throw new BadRequestException('订阅日期不能和其他记录重叠');
      }
      return;
    }
  }

  async findHistories(userId: string, itemId: string) {
    // 鉴权
    await this.findOne(userId, itemId);

    return this.prisma.itemHistory.findMany({
      where: { itemId },
      orderBy: { recordDate: 'desc' },
    });
  }

  async updateHistory(
    userId: string,
    itemId: string,
    historyId: string,
    dto: UpdateItemHistoryDto,
  ) {
    await this.findOne(userId, itemId);
    const history = await this.prisma.itemHistory.findUnique({
      where: { id: historyId },
    });

    if (!history || history.itemId !== itemId) {
      throw new NotFoundException('历史记录不存在或不属于该物品');
    }

    const nextHistory = {
      ...history,
      ...dto,
      type: dto.type ?? history.type,
      price: dto.price ?? history.price,
    };
    await this.validateRenewalHistoryDates(itemId, nextHistory, historyId);

    const updated = await this.prisma.$transaction(async (tx) => {
      const saved = await tx.itemHistory.update({
        where: { id: historyId },
        data: dto,
      });
      await tx.item.update({
        where: { id: itemId },
        data: {
          nextBillingDate: await this.latestRenewalEndDate(itemId, tx),
        },
      });
      return saved;
    });
    await this.clearCache(userId);
    return updated;
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

    const deleted = await this.prisma.$transaction(async (tx) => {
      const removed = await tx.itemHistory.delete({
        where: { id: historyId },
      });
      await tx.item.update({
        where: { id: itemId },
        data: {
          nextBillingDate: await this.latestRenewalEndDate(itemId, tx),
        },
      });
      return removed;
    });
    await this.clearCache(userId);
    return deleted;
  }

  private async latestRenewalEndDate(
    itemId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const latest = await tx.itemHistory.findFirst({
      where: {
        itemId,
        type: ItemRecordType.RENEWAL,
        endDate: { not: null },
      },
      orderBy: { endDate: 'desc' },
    });
    return latest?.endDate ?? null;
  }

  async importBackup(userId: string, data: BackupData) {
    const result = await importItemsBackup(this.prisma, userId, data);
    await this.clearCache(userId);
    return result;
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
