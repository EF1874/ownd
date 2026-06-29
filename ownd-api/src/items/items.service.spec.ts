import { Test, TestingModule } from '@nestjs/testing';
import { ItemsService } from './items.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import {
  AssetPurpose,
  AssetRefType,
  AssetStatus,
  PrismaClient,
  Item,
  ItemCycleCalculationMode,
  ItemCycleType,
  ItemRecordType,
} from '@prisma/client';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';

describe('ItemsService', () => {
  let service: ItemsService;
  let prisma: DeepMockProxy<PrismaClient>;

  const runTransaction = (callbackOrPromises: unknown): unknown => {
    if (typeof callbackOrPromises === 'function') {
      return (
        callbackOrPromises as (tx: DeepMockProxy<PrismaClient>) => unknown
      )(prisma);
    }
    if (Array.isArray(callbackOrPromises)) {
      return Promise.all(callbackOrPromises as Promise<unknown>[]);
    }
    return callbackOrPromises;
  };
  const mockTransaction = () => {
    prisma.$transaction.mockImplementation(
      runTransaction as Parameters<
        typeof prisma.$transaction.mockImplementation
      >[0],
    );
  };

  beforeEach(async () => {
    const mockPrisma = mockDeep<PrismaClient>();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ItemsService,
        {
          provide: PrismaService,
          useValue: mockPrisma,
        },
        {
          provide: CACHE_MANAGER,
          useValue: {
            get: jest.fn(),
            set: jest.fn(),
            del: jest.fn(),
          },
        },
      ],
    }).compile();

    service = module.get<ItemsService>(ItemsService);
    prisma = module.get(PrismaService);
    mockTransaction();
  });

  // 辅助函数：创建一个符合 Prisma.Item 结构的 Mock 对象
  const createMockItem = (overrides: Partial<Item> = {}): Item => ({
    id: 'item-1',
    name: '测试物品',
    price: 100,
    renewalPrice: null,
    userId: 'user-1',
    imagePath: null,
    notes: null,
    tags: [],
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
    purchaseDate: new Date(),
    createdAt: new Date(),
    updatedAt: new Date(),
    ...overrides,
  });
  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('应该成功创建一个物品', async () => {
      const dto: CreateItemDto = { name: '测试物品', price: 100 };
      const userId = 'user-1';
      const mockResult = createMockItem({ ...dto, userId });

      prisma.item.create.mockResolvedValue(mockResult);

      const result = await service.create(userId, dto);

      expect(prisma.item.create.mock.calls[0]?.[0]).toEqual({
        data: {
          ...dto,
          imagePath: undefined,
          nextBillingDate: null,
          user: { connect: { id: userId } },
          category: undefined,
          platform: undefined,
          itemHistories: undefined,
        },
        include: {
          category: { include: { parent: true } },
          platform: true,
          itemHistories: true,
        },
      });
      expect(prisma.asset.updateMany.mock.calls).toHaveLength(0);
      expect(result).toEqual(mockResult);
    });

    it('创建物品时应该把上传图片登记为物品图片资产', async () => {
      const imagePath = '/ownd-items/test.png';
      const dto: CreateItemDto = {
        name: '测试物品',
        price: 100,
        imagePath,
      };
      const userId = 'user-1';
      const mockResult = createMockItem({ ...dto, userId });

      prisma.item.create.mockResolvedValue(mockResult);

      await service.create(userId, dto);

      expect(prisma.asset.updateMany.mock.calls[0]?.[0]).toEqual({
        where: { userId, path: imagePath },
        data: {
          purpose: AssetPurpose.ITEM_IMAGE,
          status: AssetStatus.ACTIVE,
          refType: AssetRefType.ITEM,
          refId: mockResult.id,
        },
      });
    });

    it('应该按开通日和周期计算订阅到期日', async () => {
      const purchaseDate = new Date('2026-06-12T00:00:00.000Z');
      const dto: CreateItemDto = {
        name: '月付订阅',
        price: 30,
        isVirtual: true,
        purchaseDate,
        currentCycleType: ItemCycleType.MONTH,
        currentCycle: 1,
        hasReminder: true,
      };
      const userId = 'user-1';

      prisma.item.create.mockResolvedValue(createMockItem({ ...dto, userId }));

      await service.create(userId, dto);

      const createCall = prisma.item.create.mock.calls[0][0];
      expect(createCall.data.nextBillingDate).toEqual(
        new Date('2026-07-11T00:00:00.000Z'),
      );
      expect(createCall.data.itemHistories).toEqual({
        create: [
          expect.objectContaining({
            startDate: purchaseDate,
            endDate: new Date('2026-07-11T00:00:00.000Z'),
            cycleType: ItemCycleType.MONTH,
            cycle: 1,
            price: 30,
          }),
        ],
      });
    });
  });

  describe('findAll', () => {
    const mockOrderedItems = (
      orderedItems: Item[],
      fetchedItems: Item[] = [...orderedItems].reverse(),
    ) => {
      prisma.$queryRaw.mockResolvedValueOnce(
        orderedItems.map((item) => ({ id: item.id })),
      );
      prisma.item.findMany.mockResolvedValueOnce(fetchedItems);
    };

    const latestSqlQuery = () => {
      const calls = prisma.$queryRaw.mock.calls;
      const query = calls[calls.length - 1]?.[0] as
        | { strings?: readonly string[]; values?: readonly unknown[] }
        | undefined;
      return {
        text: query?.strings?.join('') ?? '',
        values: [...(query?.values ?? [])],
      };
    };

    it('应该返回用户的所有物品', async () => {
      const userId = 'user-1';
      const mockItems = [createMockItem({ userId })];

      mockOrderedItems(mockItems);

      const result = await service.findAll(userId);

      expect(prisma.$queryRaw.mock.calls).toHaveLength(1);
      expect(latestSqlQuery().text).toContain('FROM "Item" i');
      expect(prisma.item.findMany.mock.calls[0]?.[0]).toMatchObject({
        where: { id: { in: ['item-1'] } },
      });
      expect(result).toEqual(mockItems);
    });

    it('应该支持按物品名称、平台、分类、标签和备注搜索', async () => {
      const userId = 'user-1';
      const mockItems = [createMockItem({ userId })];

      mockOrderedItems(mockItems);

      const result = await service.findAll(userId, { search: ' 京东 ' });

      const query = latestSqlQuery();
      expect(query.text).toContain('ILIKE');
      expect(query.text).toContain('i."tags" @> ARRAY[');
      expect(query.values).toContain('京东');
      expect(query.values).toContain('%京东%');
      expect(result).toEqual(mockItems);
    });

    it('应该支持筛选即将到期或续费的虚拟订阅', async () => {
      const userId = 'user-1';
      const mockItems = [
        createMockItem({
          userId,
          isVirtual: true,
          nextBillingDate: new Date(),
        }),
      ];

      mockOrderedItems(mockItems);

      const result = await service.findAll(userId, { expiringSoon: true });

      const query = latestSqlQuery();
      expect(query.text).toContain('i."isVirtual" = true');
      expect(query.text).toContain('i."nextBillingDate" >=');
      expect(query.text).toContain('i."nextBillingDate" <=');
      expect(result).toEqual(mockItems);
    });

    it('应该支持状态筛选和分类筛选同时生效', async () => {
      const userId = 'user-1';
      const mockItems = [
        createMockItem({
          userId,
          isVirtual: true,
          isAutoRenew: false,
          nextBillingDate: new Date('2026-06-01T00:00:00.000Z'),
        }),
      ];

      mockOrderedItems(mockItems);

      const result = await service.findAll(userId, {
        categoryId: 'category-1',
        status: 'expired-subscriptions',
      });

      const query = latestSqlQuery();
      expect(query.values).toContain('category-1');
      expect(query.text).toContain('c."parentId" IN');
      expect(query.text).toContain('i."isVirtual" = true');
      expect(query.text).toContain('i."isAutoRenew" = false');
      expect(result).toEqual(mockItems);
    });

    it('筛选已报废实物应由后端按报废状态过滤', async () => {
      const userId = 'user-1';
      const mockItems = [
        createMockItem({
          userId,
          isVirtual: true,
          isScrapped: true,
          scrappedDate: new Date('2026-06-01T00:00:00.000Z'),
        }),
      ];

      mockOrderedItems(mockItems);

      const result = await service.findAll(userId, {
        status: 'scrapped-items',
      });

      const query = latestSqlQuery();
      expect(query.text).toContain('i."isScrapped" = true');
      expect(query.text).toContain('i."scrappedDate" IS NOT NULL');
      expect(result).toEqual(mockItems);
    });

    it('默认排序应该让订阅优先按到期临近排列，实物再按购买时间从晚到早排列，失效物品置底', async () => {
      const userId = 'user-1';
      const now = new Date();
      const newItem = createMockItem({
        id: 'new-item',
        userId,
        name: '新买实物',
        purchaseDate: new Date(now.getTime() - 1 * 86400000),
      });
      const oldItem = createMockItem({
        id: 'old-item',
        userId,
        name: '旧实物',
        purchaseDate: new Date(now.getTime() - 90 * 86400000),
      });
      const virtualDeviceWithoutDueDate = createMockItem({
        id: 'virtual-device-without-due-date',
        userId,
        name: '没有到期日的实体物品',
        isVirtual: true,
        nextBillingDate: null,
        purchaseDate: new Date(now.getTime() - 365 * 86400000),
      });
      const soonSubscription = createMockItem({
        id: 'soon-subscription',
        userId,
        name: '快到期订阅',
        isVirtual: true,
        nextBillingDate: new Date(now.getTime() + 2 * 86400000),
      });
      const laterSubscription = createMockItem({
        id: 'later-subscription',
        userId,
        name: '晚到期订阅',
        isVirtual: true,
        nextBillingDate: new Date(now.getTime() + 30 * 86400000),
      });
      const recentlyExpiredSubscription = createMockItem({
        id: 'recently-expired-subscription',
        userId,
        name: '刚到期订阅',
        isVirtual: true,
        isAutoRenew: false,
        nextBillingDate: new Date(now.getTime() - 1 * 86400000),
      });
      const longExpiredSubscription = createMockItem({
        id: 'long-expired-subscription',
        userId,
        name: '很早到期订阅',
        isVirtual: true,
        isAutoRenew: false,
        nextBillingDate: new Date(now.getTime() - 30 * 86400000),
      });
      const scrappedItem = createMockItem({
        id: 'scrapped-item',
        userId,
        name: '报废实物',
        isScrapped: true,
        scrappedDate: new Date(now.getTime() - 1 * 86400000),
        purchaseDate: new Date(now.getTime() - 365 * 86400000),
      });

      mockOrderedItems(
        [
          soonSubscription,
          laterSubscription,
          newItem,
          oldItem,
          virtualDeviceWithoutDueDate,
          recentlyExpiredSubscription,
          longExpiredSubscription,
          scrappedItem,
        ],
        [
          newItem,
          scrappedItem,
          virtualDeviceWithoutDueDate,
          oldItem,
          laterSubscription,
          longExpiredSubscription,
          soonSubscription,
          recentlyExpiredSubscription,
        ],
      );

      const result = await service.findAll(userId, { page: 1, limit: 20 });

      const query = latestSqlQuery();
      expect(query.text).toContain('ORDER BY');
      expect(query.text).toContain('LIMIT');
      expect(query.text).toContain('OFFSET');
      expect(query.text).toContain('i."nextBillingDate" IS NOT NULL');
      expect(query.text).toContain('DATE_PART');
      expect(query.text).toContain('i."purchaseDate"');
      expect(query.text).toContain('DESC NULLS LAST');
      expect(result.map((item) => item.id)).toEqual([
        'soon-subscription',
        'later-subscription',
        'new-item',
        'old-item',
        'virtual-device-without-due-date',
        'recently-expired-subscription',
        'long-expired-subscription',
        'scrapped-item',
      ]);
    });

    it('手动按购买日期排序时订阅应该使用最新一期开始日期', async () => {
      const userId = 'user-1';
      const item = createMockItem({
        id: 'item',
        userId,
        name: '实物',
        purchaseDate: new Date('2026-06-01T00:00:00.000Z'),
      });
      const subscription = createMockItem({
        id: 'subscription',
        userId,
        name: '订阅',
        isVirtual: true,
        purchaseDate: new Date('2026-01-01T00:00:00.000Z'),
      });

      mockOrderedItems([subscription, item], [item, subscription]);

      const result = await service.findAll(userId, {
        sortBy: 'date',
        sortOrder: 'desc',
      });

      expect(latestSqlQuery().text).toContain(
        'COALESCE(latest_start."startDate", i."purchaseDate")',
      );
      expect(result.map((device) => device.id)).toEqual([
        'subscription',
        'item',
      ]);
    });
  });

  describe('findOne', () => {
    it('当物品存在且属于该用户时应该返回该物品', async () => {
      const userId = 'user-1';
      const itemId = 'item-1';
      const mockItem = createMockItem({ id: itemId, userId });

      prisma.item.findFirst.mockResolvedValue(mockItem);

      const result = await service.findOne(userId, itemId);

      expect(prisma.item.findFirst.mock.calls[0]?.[0]).toEqual({
        where: { id: itemId, userId },
        include: {
          category: { include: { parent: true } },
          platform: true,
          itemHistories: {
            orderBy: { createdAt: 'desc' },
          },
        },
      });
      expect(result).toEqual(mockItem);
    });

    it('当物品不存在或不属于该用户时应该抛出 NotFoundException', async () => {
      prisma.item.findFirst.mockResolvedValue(null);

      await expect(service.findOne('user-1', 'wrong-id')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('update', () => {
    it('应该成功更新属于该用户的物品', async () => {
      const userId = 'user-1';
      const itemId = 'item-1';
      const dto: UpdateItemDto = { name: '新名字' };

      prisma.item.update.mockResolvedValue(
        createMockItem({ id: itemId, userId, ...dto }),
      );

      prisma.item.findFirst.mockResolvedValue(
        createMockItem({ id: itemId, userId }),
      );

      const result = await service.update(userId, itemId, dto);

      expect(prisma.item.update.mock.calls[0]?.[0]).toEqual({
        where: { id: itemId },
        data: {
          ...dto,
          imagePath: undefined,
          category: undefined,
          platform: undefined,
        },
        include: {
          category: { include: { parent: true } },
          platform: true,
          itemHistories: true,
        },
      });
      expect(prisma.asset.updateMany.mock.calls).toHaveLength(0);
      expect(result.name).toBe(dto.name);
    });
  });

  describe('remove', () => {
    it('应该成功删除属于该用户的物品', async () => {
      const userId = 'user-1';
      const itemId = 'item-1';

      prisma.item.delete.mockResolvedValue(
        createMockItem({ id: itemId, userId }),
      );

      prisma.item.findFirst.mockResolvedValue(
        createMockItem({ id: itemId, userId }),
      );

      await service.remove(userId, itemId);

      expect(prisma.item.delete.mock.calls[0]?.[0]).toEqual({
        where: { id: itemId },
      });
    });
  });

  describe('updateImagePath', () => {
    it('应该成功更新物品的图片路径', async () => {
      const userId = 'user-1';
      const itemId = 'item-1';
      const imagePath = '/ownd-items/test.png';

      prisma.item.update.mockResolvedValue(
        createMockItem({ id: itemId, userId, imagePath }),
      );

      prisma.item.findFirst.mockResolvedValue(
        createMockItem({ id: itemId, userId }),
      );

      const result = await service.updateImagePath(userId, itemId, imagePath);

      expect(prisma.item.update.mock.calls[0]?.[0]).toEqual({
        where: { id: itemId },
        data: { imagePath },
      });
      expect(prisma.asset.updateMany.mock.calls[0]?.[0]).toEqual({
        where: { userId, path: imagePath },
        data: {
          purpose: AssetPurpose.ITEM_IMAGE,
          status: AssetStatus.ACTIVE,
          refType: AssetRefType.ITEM,
          refId: itemId,
        },
      });
      expect(result.imagePath).toBe(imagePath);
    });

    it('应该支持清空物品图片路径', async () => {
      const userId = 'user-1';
      const itemId = 'item-1';
      const oldPath = '/ownd-items/test.png';

      prisma.item.update.mockResolvedValue(
        createMockItem({ id: itemId, userId, imagePath: null }),
      );

      prisma.item.findFirst.mockResolvedValue(
        createMockItem({
          id: itemId,
          userId,
          imagePath: oldPath,
        }),
      );

      const result = await service.updateImagePath(userId, itemId, null);

      expect(prisma.item.update.mock.calls[0]?.[0]).toEqual({
        where: { id: itemId },
        data: { imagePath: null },
      });
      expect(prisma.asset.updateMany.mock.calls[0]?.[0]).toEqual({
        where: { userId, path: oldPath },
        data: {
          status: AssetStatus.ORPHAN,
          refType: null,
          refId: null,
        },
      });
      expect(result.imagePath).toBeNull();
    });
  });

  describe('addHistory', () => {
    const userId = 'user-1';
    const itemId = 'item-1';
    const latestHistory = {
      id: 'history-1',
      itemId,
      type: ItemRecordType.RENEWAL,
      price: 30,
      recordDate: new Date('2026-06-12T00:00:00.000Z'),
      startDate: new Date('2026-06-12T00:00:00.000Z'),
      endDate: new Date('2026-07-11T00:00:00.000Z'),
      cycleType: ItemCycleType.MONTH,
      cycle: 1,
      cycleMode: ItemCycleCalculationMode.CALENDAR,
      cycleDays: null,
      note: null,
      isAutoRenew: false,
      createdAt: new Date('2026-06-12T00:00:00.000Z'),
      updatedAt: new Date('2026-06-12T00:00:00.000Z'),
    };

    beforeEach(() => {
      prisma.item.findFirst.mockResolvedValue(createMockItem({ id: itemId }));
    });

    it('应该拒绝到期日期早于开始日期的续费记录', async () => {
      await expect(
        service.addHistory(userId, itemId, {
          type: ItemRecordType.RENEWAL,
          price: 30,
          startDate: new Date('2026-07-12T00:00:00.000Z'),
          endDate: new Date('2026-07-11T00:00:00.000Z'),
          cycleType: ItemCycleType.MONTH,
          cycle: 1,
        }),
      ).rejects.toThrow(BadRequestException);

      expect(prisma.itemHistory.findFirst.mock.calls).toHaveLength(0);
    });

    it('应该拒绝和上一期日期重复的续费记录', async () => {
      prisma.itemHistory.findFirst.mockResolvedValue(latestHistory);

      await expect(
        service.addHistory(userId, itemId, {
          type: ItemRecordType.RENEWAL,
          price: 30,
          startDate: new Date('2026-07-11T00:00:00.000Z'),
          endDate: new Date('2026-08-10T00:00:00.000Z'),
          cycleType: ItemCycleType.MONTH,
          cycle: 1,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('应该允许紧接上一期后的续费记录并更新最后到期日', async () => {
      const newHistory = {
        ...latestHistory,
        id: 'history-2',
        startDate: new Date('2026-07-12T00:00:00.000Z'),
        endDate: new Date('2026-08-11T00:00:00.000Z'),
      };
      prisma.itemHistory.findFirst
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(newHistory);
      prisma.itemHistory.create.mockResolvedValue(newHistory);
      prisma.item.update.mockResolvedValue(
        createMockItem({ id: itemId, nextBillingDate: newHistory.endDate }),
      );
      mockTransaction();

      const result = await service.addHistory(userId, itemId, {
        type: ItemRecordType.RENEWAL,
        price: 30,
        startDate: newHistory.startDate,
        endDate: newHistory.endDate,
        cycleType: ItemCycleType.MONTH,
        cycle: 1,
      });

      expect(prisma.itemHistory.create.mock.calls[0]?.[0]).toMatchObject({
        data: {
          itemId,
          startDate: newHistory.startDate,
          endDate: newHistory.endDate,
        },
      });
      expect(prisma.item.update.mock.calls[0]?.[0]).toEqual({
        where: { id: itemId },
        data: { nextBillingDate: newHistory.endDate },
      });
      expect(result).toEqual(newHistory);
    });
  });

  describe('updateHistory', () => {
    const userId = 'user-1';
    const itemId = 'item-1';
    const historyId = 'history-1';
    const history = {
      id: historyId,
      itemId,
      type: ItemRecordType.RENEWAL,
      price: 30,
      recordDate: new Date('2026-06-12T00:00:00.000Z'),
      startDate: new Date('2026-06-12T00:00:00.000Z'),
      endDate: new Date('2026-07-11T00:00:00.000Z'),
      cycleType: ItemCycleType.MONTH,
      cycle: 1,
      cycleMode: ItemCycleCalculationMode.CALENDAR,
      cycleDays: null,
      note: null,
      isAutoRenew: false,
      createdAt: new Date('2026-06-12T00:00:00.000Z'),
      updatedAt: new Date('2026-06-12T00:00:00.000Z'),
    };

    beforeEach(() => {
      prisma.item.findFirst.mockResolvedValue(createMockItem({ id: itemId }));
      prisma.itemHistory.findUnique.mockResolvedValue(history);
      mockTransaction();
    });

    it('应该更新订阅记录并按最新记录重算到期日', async () => {
      const updatedHistory = {
        ...history,
        price: 35,
        endDate: new Date('2026-07-15T00:00:00.000Z'),
      };
      prisma.itemHistory.findFirst
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce(updatedHistory);
      prisma.itemHistory.update.mockResolvedValue(updatedHistory);

      const result = await service.updateHistory(userId, itemId, historyId, {
        type: ItemRecordType.RENEWAL,
        price: 35,
        endDate: updatedHistory.endDate,
      });

      expect(prisma.itemHistory.update.mock.calls[0]?.[0]).toMatchObject({
        where: { id: historyId },
        data: {
          price: 35,
          endDate: updatedHistory.endDate,
        },
      });
      expect(prisma.item.update.mock.calls[0]?.[0]).toEqual({
        where: { id: itemId },
        data: { nextBillingDate: updatedHistory.endDate },
      });
      expect(result).toEqual(updatedHistory);
    });
  });

  describe('removeHistory', () => {
    const userId = 'user-1';
    const itemId = 'item-1';
    const historyId = 'history-2';
    const deletedHistory = {
      id: historyId,
      itemId,
      type: ItemRecordType.RENEWAL,
      price: 30,
      recordDate: new Date('2026-07-12T00:00:00.000Z'),
      startDate: new Date('2026-07-12T00:00:00.000Z'),
      endDate: new Date('2026-08-11T00:00:00.000Z'),
      cycleType: ItemCycleType.MONTH,
      cycle: 1,
      cycleMode: ItemCycleCalculationMode.CALENDAR,
      cycleDays: null,
      note: null,
      isAutoRenew: false,
      createdAt: new Date('2026-07-12T00:00:00.000Z'),
      updatedAt: new Date('2026-07-12T00:00:00.000Z'),
    };
    const previousHistory = {
      ...deletedHistory,
      id: 'history-1',
      startDate: new Date('2026-06-12T00:00:00.000Z'),
      endDate: new Date('2026-07-11T00:00:00.000Z'),
    };

    beforeEach(() => {
      prisma.item.findFirst.mockResolvedValue(createMockItem({ id: itemId }));
      prisma.itemHistory.findUnique.mockResolvedValue(deletedHistory);
      prisma.itemHistory.delete.mockResolvedValue(deletedHistory);
      mockTransaction();
    });

    it('应该删除订阅记录并把到期日回退到剩余记录的最后一期', async () => {
      prisma.itemHistory.findFirst.mockResolvedValue(previousHistory);

      const result = await service.removeHistory(userId, itemId, historyId);

      expect(prisma.itemHistory.delete.mock.calls[0]?.[0]).toEqual({
        where: { id: historyId },
      });
      expect(prisma.item.update.mock.calls[0]?.[0]).toEqual({
        where: { id: itemId },
        data: { nextBillingDate: previousHistory.endDate },
      });
      expect(result).toEqual(deletedHistory);
    });
  });
});
