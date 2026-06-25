import { Test, TestingModule } from '@nestjs/testing';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { ItemCycleCalculationMode, Prisma, PrismaClient } from '@prisma/client';
import dayjs from 'dayjs';
import { PrismaService } from '../prisma/prisma.service';
import { StatisticsService } from './statistics.service';

describe('StatisticsService', () => {
  let service: StatisticsService;
  let prisma: DeepMockProxy<PrismaClient>;
  type SummaryItem = Prisma.ItemGetPayload<{
    include: { itemHistories: true };
  }>;
  const mockItem = (overrides: Partial<SummaryItem>): SummaryItem => ({
    id: 'item',
    name: '测试物品',
    price: 0,
    renewalPrice: null,
    purchaseDate: new Date(),
    imagePath: null,
    notes: null,
    tags: [],
    userId: 'user-1',
    categoryId: null,
    platformId: null,
    currentCycleType: null,
    currentCycle: null,
    currentCycleMode: ItemCycleCalculationMode.CALENDAR,
    currentCycleDays: null,
    nextBillingDate: null,
    isAutoRenew: false,
    hasReminder: false,
    isBackup: false,
    backupDate: null,
    isScrapped: false,
    scrappedDate: null,
    warrantyEndDate: null,
    isVirtual: false,
    createdAt: new Date(),
    updatedAt: new Date(),
    itemHistories: [],
    ...overrides,
  });
  const cache = {
    get: jest.fn(),
    set: jest.fn(),
  };

  beforeEach(async () => {
    const mockPrisma = mockDeep<PrismaClient>();
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        StatisticsService,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: CACHE_MANAGER, useValue: cache },
      ],
    }).compile();

    service = module.get(StatisticsService);
    prisma = module.get(PrismaService);
    jest.clearAllMocks();
  });

  it('returns all overview counts from every item', async () => {
    const today = dayjs().startOf('day');
    cache.get.mockResolvedValue(null);
    prisma.item.findMany.mockResolvedValue([
      mockItem({
        price: 100,
        purchaseDate: today.subtract(10, 'day').toDate(),
      }),
      mockItem({
        price: 50,
        purchaseDate: today.subtract(5, 'day').toDate(),
        isScrapped: true,
        scrappedDate: today.subtract(1, 'day').toDate(),
      }),
      mockItem({
        price: 30,
        purchaseDate: today.subtract(2, 'day').toDate(),
        isVirtual: true,
        isAutoRenew: true,
        nextBillingDate: today.add(7, 'day').toDate(),
      }),
      mockItem({
        price: 20,
        purchaseDate: today.subtract(20, 'day').toDate(),
        isVirtual: true,
        isAutoRenew: false,
        nextBillingDate: today.subtract(1, 'day').toDate(),
      }),
      mockItem({
        price: 10,
        purchaseDate: today.subtract(1, 'day').toDate(),
        isScrapped: true,
      }),
    ]);

    await expect(service.getSummary('user-1')).resolves.toMatchObject({
      itemCount: 5,
      totalOriginalPrice: 210,
      scrapOrExpiredCount: 2,
      expiringSoonCount: 1,
    });
  });
});
