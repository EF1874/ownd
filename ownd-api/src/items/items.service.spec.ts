import { Test, TestingModule } from '@nestjs/testing';
import { ItemsService } from './items.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import {
  PrismaClient,
  Item,
  ItemCycleType,
  ItemRecordType,
} from '@prisma/client';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';

describe('ItemsService', () => {
  let service: ItemsService;
  let prisma: DeepMockProxy<PrismaClient>;

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
  });

  // 辅助函数：创建一个符合 Prisma.Item 结构的 Mock 对象
  const createMockItem = (overrides: Partial<Item> = {}): Item => ({
    id: 'item-1',
    name: '测试物品',
    price: 100,
    userId: 'user-1',
    imagePath: null,
    notes: null,
    tags: [],
    categoryId: null,
    platformId: null,
    currentCycleType: null,
    currentCycle: null,
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

      expect(prisma.item.create).toHaveBeenCalledWith({
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
      expect(result).toEqual(mockResult);
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
    it('应该返回用户的所有物品', async () => {
      const userId = 'user-1';
      const mockItems = [createMockItem({ userId })];

      prisma.item.findMany.mockResolvedValue(mockItems);

      const result = await service.findAll(userId);

      expect(prisma.item.findMany).toHaveBeenCalledWith({
        where: { userId },
        include: {
          category: { include: { parent: true } },
          platform: true,
          itemHistories: {
            orderBy: { startDate: 'desc' },
            take: 1,
          },
        },
        orderBy: { purchaseDate: 'desc' },
        skip: undefined,
        take: undefined,
      });
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

      prisma.item.findMany.mockResolvedValue(mockItems);

      const result = await service.findAll(userId, { expiringSoon: true });

      expect(prisma.item.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: {
            userId,
            AND: [
              {
                isVirtual: true,
                nextBillingDate: {
                  gte: expect.any(Date),
                  lte: expect.any(Date),
                },
              },
            ],
          },
        }),
      );
      expect(result).toEqual(mockItems);
    });
  });

  describe('findOne', () => {
    it('当物品存在且属于该用户时应该返回该物品', async () => {
      const userId = 'user-1';
      const itemId = 'item-1';
      const mockItem = createMockItem({ id: itemId, userId });

      prisma.item.findFirst.mockResolvedValue(mockItem);

      const result = await service.findOne(userId, itemId);

      expect(prisma.item.findFirst).toHaveBeenCalledWith({
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

      expect(prisma.item.update).toHaveBeenCalledWith({
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

      expect(prisma.item.delete).toHaveBeenCalledWith({
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

      expect(prisma.item.update).toHaveBeenCalledWith({
        where: { id: itemId },
        data: { imagePath },
      });
      expect(result.imagePath).toBe(imagePath);
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
      note: null,
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

      expect(prisma.itemHistory.findFirst).not.toHaveBeenCalled();
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
      prisma.$transaction.mockImplementation(async (callback) =>
        callback(prisma),
      );

      const result = await service.addHistory(userId, itemId, {
        type: ItemRecordType.RENEWAL,
        price: 30,
        startDate: newHistory.startDate,
        endDate: newHistory.endDate,
        cycleType: ItemCycleType.MONTH,
        cycle: 1,
      });

      expect(prisma.itemHistory.create).toHaveBeenCalledWith({
        data: expect.objectContaining({
          itemId,
          startDate: newHistory.startDate,
          endDate: newHistory.endDate,
        }),
      });
      expect(prisma.item.update).toHaveBeenCalledWith({
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
      note: null,
      createdAt: new Date('2026-06-12T00:00:00.000Z'),
      updatedAt: new Date('2026-06-12T00:00:00.000Z'),
    };

    beforeEach(() => {
      prisma.item.findFirst.mockResolvedValue(createMockItem({ id: itemId }));
      prisma.itemHistory.findUnique.mockResolvedValue(history);
      prisma.$transaction.mockImplementation(async (callback) =>
        callback(prisma),
      );
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

      expect(prisma.itemHistory.update).toHaveBeenCalledWith({
        where: { id: historyId },
        data: expect.objectContaining({
          price: 35,
          endDate: updatedHistory.endDate,
        }),
      });
      expect(prisma.item.update).toHaveBeenCalledWith({
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
      note: null,
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
      prisma.$transaction.mockImplementation(async (callback) =>
        callback(prisma),
      );
    });

    it('应该删除订阅记录并把到期日回退到剩余记录的最后一期', async () => {
      prisma.itemHistory.findFirst.mockResolvedValue(previousHistory);

      const result = await service.removeHistory(userId, itemId, historyId);

      expect(prisma.itemHistory.delete).toHaveBeenCalledWith({
        where: { id: historyId },
      });
      expect(prisma.item.update).toHaveBeenCalledWith({
        where: { id: itemId },
        data: { nextBillingDate: previousHistory.endDate },
      });
      expect(result).toEqual(deletedHistory);
    });
  });
});
