import { Test, TestingModule } from '@nestjs/testing';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { PrismaClient } from '@prisma/client';
import dayjs from 'dayjs';
import { PrismaService } from '../prisma/prisma.service';
import { StatisticsService } from './statistics.service';

describe('StatisticsService', () => {
  let service: StatisticsService;
  let prisma: DeepMockProxy<PrismaClient>;
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
      {
        price: 100,
        purchaseDate: today.subtract(10, 'day').toDate(),
        isScrapped: false,
        isVirtual: false,
        isAutoRenew: false,
        nextBillingDate: null,
        itemHistories: [],
      },
      {
        price: 50,
        purchaseDate: today.subtract(5, 'day').toDate(),
        isScrapped: true,
        isVirtual: false,
        isAutoRenew: false,
        nextBillingDate: null,
        itemHistories: [],
      },
      {
        price: 30,
        purchaseDate: today.subtract(2, 'day').toDate(),
        isScrapped: false,
        isVirtual: true,
        isAutoRenew: true,
        nextBillingDate: today.add(7, 'day').toDate(),
        itemHistories: [],
      },
      {
        price: 20,
        purchaseDate: today.subtract(20, 'day').toDate(),
        isScrapped: false,
        isVirtual: true,
        isAutoRenew: false,
        nextBillingDate: today.subtract(1, 'day').toDate(),
        itemHistories: [],
      },
    ] as any);

    await expect(service.getSummary('user-1')).resolves.toMatchObject({
      itemCount: 4,
      totalOriginalPrice: 200,
      scrapOrExpiredCount: 2,
      expiringSoonCount: 1,
    });
  });
});
