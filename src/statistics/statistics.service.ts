import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import dayjs from 'dayjs';

@Injectable()
export class StatisticsService {
  constructor(private prisma: PrismaService) {}

  /**
   * 获取用户资产概览统计
   */
  async getSummary(userId: string) {
    const items = await this.prisma.item.findMany({
      where: { userId },
      include: {
        itemHistories: true,
      },
    });

    let totalOriginalPrice = 0; // 购买总价
    let totalHistoryExpense = 0; // 历史记录总支出 (维修/续费等)
    let totalTco = 0; // 总持有成本

    items.forEach((item) => {
      totalOriginalPrice += item.price;
      const historySum = item.itemHistories.reduce(
        (sum, h) => sum + h.price,
        0,
      );
      totalHistoryExpense += historySum;
      totalTco += item.price + historySum;
    });

    // 计算日均支出 (基于所有物品的平均持有时间)
    // 算法对齐 Flutter: TCO / (今天 - 最早购买日期)
    const earliestItem = items.sort(
      (a, b) => dayjs(a.purchaseDate).unix() - dayjs(b.purchaseDate).unix(),
    )[0];

    let dailyAverage = 0;
    if (earliestItem) {
      const days = dayjs().diff(dayjs(earliestItem.purchaseDate), 'day');
      dailyAverage = totalTco / Math.max(days, 1);
    }

    return {
      itemCount: items.length,
      totalOriginalPrice,
      totalHistoryExpense,
      totalTco,
      dailyAverage: parseFloat(dailyAverage.toFixed(2)),
    };
  }

  /**
   * 获取单品统计详情
   */
  async getItemStats(userId: string, itemId: string) {
    const item = await this.prisma.item.findFirst({
      where: { id: itemId, userId },
      include: { itemHistories: true },
    });

    if (!item) return null;

    const totalHistory = item.itemHistories.reduce(
      (sum, h) => sum + h.price,
      0,
    );
    const tco = item.price + totalHistory;
    const days = dayjs().diff(dayjs(item.purchaseDate), 'day');

    return {
      tco,
      daysHeld: Math.max(days, 1),
      dailyCost: parseFloat((tco / Math.max(days, 1)).toFixed(2)),
    };
  }
}
