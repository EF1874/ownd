/* eslint-disable @typescript-eslint/no-unsafe-argument */
import { Test, TestingModule } from '@nestjs/testing';
import { CategoriesService } from './categories.service';
import { PrismaService } from '../prisma/prisma.service';
import { NotFoundException } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';

describe('CategoriesService', () => {
  let service: CategoriesService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      category: {
        count: jest.fn(),
        findFirst: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CategoriesService,
        { provide: PrismaService, useValue: prisma },
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

    it('创建带父级的分类时，若父级不可访问应报错', async () => {
      const dto = { name: '手机', parentId: 'parent-id' };
      const userId = 'u1';
      // 模拟 findFirst 没找到（说明 id 不存在或 userId 不匹配）
      prisma.category.findFirst.mockResolvedValue(null);

      await expect(service.create(userId, dto as any)).rejects.toThrow(
        NotFoundException,
      );
    });

    it('应该允许用户分类挂到自己的父级下', async () => {
      const dto = { name: '自定义订阅', parentId: 'parent-id' };
      const userId = 'u1';
      prisma.category.findFirst.mockResolvedValue({
        id: 'parent-id',
        userId,
      });
      prisma.category.create.mockResolvedValue({ id: '2', ...dto, userId });

      await service.create(userId, dto as any);

      expect(prisma.category.create).toHaveBeenCalledWith({
        data: { ...dto, userId },
      });
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
      prisma.user.findUnique.mockResolvedValue({
        categoryDefaultsInitialized: true,
      });
      prisma.category.findMany.mockResolvedValue(mockData);

      const result = await service.findAll(userId);

      expect(prisma.category.findMany).toHaveBeenCalledWith({
        where: { userId },
        orderBy: { createdAt: 'asc' },
      });
      expect(result.length).toBe(1); // 只有一个顶级节点
      expect(result[0].name).toBe('电子产品');
      expect(result[0].children?.length).toBe(2); // 手机和电脑
      expect(result[0].children?.[0]?.children?.length).toBe(1); // iPhone
    });

    it('首次读取时应把系统模板复制为用户自己的分类', async () => {
      const userId = 'u1';
      prisma.user.findUnique.mockResolvedValue({
        categoryDefaultsInitialized: false,
      });
      prisma.category.count.mockResolvedValue(0);
      prisma.category.findMany
        .mockResolvedValueOnce([
          {
            id: 'tpl-root',
            name: '数码电子',
            icon: 'MdiIcons.cellphone',
            parentId: null,
            userId: null,
            isVirtual: false,
          },
          {
            id: 'tpl-child',
            name: '手机',
            icon: 'MdiIcons.cellphone',
            parentId: 'tpl-root',
            userId: null,
            isVirtual: false,
          },
        ])
        .mockResolvedValueOnce([
          { id: 'user-root', name: '数码电子', parentId: null, userId },
          { id: 'user-child', name: '手机', parentId: 'user-root', userId },
        ]);
      prisma.category.create
        .mockResolvedValueOnce({ id: 'user-root' })
        .mockResolvedValueOnce({ id: 'user-child' });

      const result = await service.findAll(userId);

      expect(prisma.category.create).toHaveBeenNthCalledWith(1, {
        data: {
          name: '数码电子',
          icon: 'MdiIcons.cellphone',
          isVirtual: false,
          userId,
        },
      });
      expect(prisma.category.create).toHaveBeenNthCalledWith(2, {
        data: {
          name: '手机',
          icon: 'MdiIcons.cellphone',
          isVirtual: false,
          parentId: 'user-root',
          userId,
        },
      });
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: userId },
        data: { categoryDefaultsInitialized: true },
      });
      expect(result).toHaveLength(1);
    });

    it('老账号读取分类时应补齐新增的系统模板子分类', async () => {
      const userId = 'u1';
      prisma.user.findUnique.mockResolvedValue({
        categoryDefaultsInitialized: true,
      });
      prisma.category.count.mockResolvedValue(2);
      prisma.category.findMany
        .mockResolvedValueOnce([
          {
            id: 'tpl-root',
            name: '虚拟订阅',
            icon: 'MdiIcons.youtubeSubscription',
            parentId: null,
            userId: null,
            isVirtual: true,
          },
          {
            id: 'tpl-child',
            name: '咖啡月卡',
            icon: 'MdiIcons.coffeeMaker',
            parentId: 'tpl-root',
            userId: null,
            isVirtual: false,
          },
        ])
        .mockResolvedValueOnce([
          {
            id: 'user-root',
            name: '虚拟订阅',
            icon: 'MdiIcons.youtubeSubscription',
            parentId: null,
            userId,
            isVirtual: true,
          },
        ])
        .mockResolvedValueOnce([
          { id: 'user-root', name: '虚拟订阅', parentId: null, userId },
          { id: 'user-child', name: '咖啡月卡', parentId: 'user-root', userId },
        ]);
      prisma.category.create.mockResolvedValue({
        id: 'user-child',
        name: '咖啡月卡',
      });

      const result = await service.findAll(userId);

      expect(prisma.category.create).toHaveBeenCalledWith({
        data: {
          name: '咖啡月卡',
          icon: 'MdiIcons.coffeeMaker',
          isVirtual: false,
          parentId: 'user-root',
          userId,
        },
      });
      expect(result[0].children?.[0]?.name).toBe('咖啡月卡');
    });
  });

  describe('update/remove', () => {
    it('允许修改用户自己的默认分类副本', async () => {
      prisma.category.findFirst.mockResolvedValue({ id: '1', userId: 'u1' });
      prisma.category.update.mockResolvedValue({
        id: '1',
        userId: 'u1',
        name: '新名称',
      });

      const result = await service.update('1', 'u1', { name: '新名称' });

      expect(result.name).toBe('新名称');
    });

    it('允许删除用户自己的默认分类副本', async () => {
      prisma.category.findFirst.mockResolvedValue({ id: '1', userId: 'u1' });
      prisma.category.delete.mockResolvedValue({ id: '1' });

      await service.remove('1', 'u1');

      expect(prisma.category.delete).toHaveBeenCalledWith({
        where: { id: '1' },
      });
    });
  });
});
