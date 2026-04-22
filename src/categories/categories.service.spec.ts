/* eslint-disable @typescript-eslint/no-unsafe-argument */
import { Test, TestingModule } from '@nestjs/testing';
import { CategoriesService } from './categories.service';
import { PrismaService } from '../prisma/prisma.service';
import { ForbiddenException } from '@nestjs/common';

describe('CategoriesService', () => {
  let service: CategoriesService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      category: {
        findFirst: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CategoriesService,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = module.get<CategoriesService>(CategoriesService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('应该成功创建一个顶级分类', async () => {
      const dto = { name: '电子产品' };
      const userId = 'u1';
      prisma.category.create.mockResolvedValue({ id: '1', ...dto, userId });

      const result = await service.create(userId, dto as any);
      expect(result.name).toBe('电子产品');
      expect(prisma.category.create).toHaveBeenCalled();
    });

    it('创建带父级的分类时，若父级不属于当前用户应报错', async () => {
      const dto = { name: '手机', parentId: 'parent-id' };
      const userId = 'u1';
      // 模拟 findFirst 没找到（说明 id 不存在或 userId 不匹配）
      prisma.category.findFirst.mockResolvedValue(null);

      await expect(service.create(userId, dto as any)).rejects.toThrow(
        ForbiddenException,
      );
    });
  });

  describe('findAll & buildTree', () => {
    it('应该能正确构建嵌套的分类树', async () => {
      const userId = 'u1';
      const mockData = [
        { id: '1', name: '电子产品', parentId: null, userId },
        { id: '2', name: '手机', parentId: '1', userId },
        { id: '3', name: '电脑', parentId: '1', userId },
        { id: '4', name: 'iPhone', parentId: '2', userId },
      ];
      prisma.category.findMany.mockResolvedValue(mockData);

      const result = await service.findAll(userId);

      expect(result.length).toBe(1); // 只有一个顶级节点
      expect(result[0].name).toBe('电子产品');
      expect(result[0].children?.length).toBe(2); // 手机和电脑
      expect(result[0].children?.[0]?.children?.length).toBe(1); // iPhone
    });
  });
});
