import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { ItemsService } from './items.service';
import { ItemRecordType, Prisma } from '@prisma/client';
import dayjs from 'dayjs';

type ItemWithHistories = Prisma.ItemGetPayload<{
  include: { itemHistories: true };
}>;

@Injectable()
export class ItemsCronService {
  private readonly logger = new Logger(ItemsCronService.name);

  constructor(
    private prisma: PrismaService,
    private itemsService: ItemsService,
  ) {}

  @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
  async handleAutoRenewal() {
    this.logger.log('开始执行自动续费扫描...');

    const expiredItems = await this.prisma.item.findMany({
      where: {
        isVirtual: true,
        isAutoRenew: true,
        nextBillingDate: {
          lte: new Date(),
        },
      },
      include: {
        itemHistories: true,
      },
    });

    if (expiredItems.length === 0) {
      this.logger.log('未发现需要自动续费的物品。');
      return;
    }

    for (const item of expiredItems) {
      try {
        await this.renewItem(item);
        this.logger.log(`物品 [${item.name}] 续费成功。`);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.logger.error(`物品 [${item.name}] 续费失败: ${message}`);
      }
    }
  }

  private async renewItem(item: ItemWithHistories) {
    if (!item.currentCycleType || !item.currentCycle || !item.nextBillingDate) {
      throw new Error('缺失周期配置或账单日，无法自动续费');
    }

    const startDate = item.nextBillingDate;
    const endDate = this.itemsService.calculateNextDate(
      startDate,
      item.currentCycleType,
      item.currentCycle,
    );
    const nextDate = dayjs(endDate).add(1, 'day').toDate();

    await this.prisma.$transaction(async (tx) => {
      await tx.itemHistory.create({
        data: {
          itemId: item.id,
          type: ItemRecordType.RENEWAL,
          price: item.price,
          startDate,
          endDate,
          cycleType: item.currentCycleType,
          cycle: item.currentCycle,
          note: `自动续费 (原定于 ${dayjs(startDate).format('YYYY-MM-DD')})`,
        },
      });

      await tx.item.update({
        where: { id: item.id },
        data: { nextBillingDate: nextDate },
      });
    });
  }
}
