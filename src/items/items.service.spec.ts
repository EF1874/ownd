import { Test, TestingModule } from '@nestjs/testing';
import { ItemsService } from './items.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotFoundException } from '@nestjs/common';
import { mockDeep, DeepMockProxy } from 'jest-mock-extended';
import { PrismaClient, Item } from '@prisma/client';
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
        data: { ...dto, userId },
      });
      expect(result).toEqual(mockResult);
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
      });
      expect(result).toEqual(mockItems);
    });
  });

  describe('findOne', () => {
    it('当物品存在且属于该用户时应该返回该物品', async () => {
      const userId = 'user-1';
      const itemId = 'item-1';
      const mockItem = createMockItem({ id: itemId, userId });

      prisma.item.findFirst.mockResolvedValue(mockItem);

      const result = await service.findOne(itemId, userId);

      expect(prisma.item.findFirst).toHaveBeenCalledWith({
        where: { id: itemId, userId },
      });
      expect(result).toEqual(mockItem);
    });

    it('当物品不存在或不属于该用户时应该抛出 NotFoundException', async () => {
      prisma.item.findFirst.mockResolvedValue(null);

      await expect(service.findOne('wrong-id', 'user-1')).rejects.toThrow(
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

      const result = await service.update(itemId, userId, dto);

      expect(prisma.item.update).toHaveBeenCalledWith({
        where: { id: itemId, userId },
        data: dto,
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

      await service.remove(itemId, userId);

      expect(prisma.item.delete).toHaveBeenCalledWith({
        where: { id: itemId, userId },
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

      const result = await service.updateImagePath(itemId, userId, imagePath);

      expect(prisma.item.update).toHaveBeenCalledWith({
        where: { id: itemId, userId },
        data: { imagePath },
      });
      expect(result.imagePath).toBe(imagePath);
    });
  });
});
