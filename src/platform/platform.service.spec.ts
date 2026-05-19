import { Test, TestingModule } from '@nestjs/testing';
import { PlatformService } from './platform.service';
import { PrismaService } from '../prisma/prisma.service';
import { ForbiddenException } from '@nestjs/common';

describe('PlatformService', () => {
  let service: PlatformService;

  const mockPrismaService = {
    platform: {
      count: jest.fn(),
      findUnique: jest.fn(),
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

  beforeEach(async () => {
    jest.clearAllMocks();

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PlatformService,
        { provide: PrismaService, useValue: mockPrismaService },
      ],
    }).compile();

    service = module.get<PlatformService>(PlatformService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('findAll', () => {
    it('should copy system platform templates on first read', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        platformDefaultsInitialized: false,
      });
      mockPrismaService.platform.count.mockResolvedValue(0);
      mockPrismaService.platform.findMany
        .mockResolvedValueOnce([
          {
            id: 'tpl-1',
            name: '京东',
            icon: 'MdiIcons.dog',
            color: '#E4393C',
            userId: null,
          },
        ])
        .mockResolvedValueOnce([
          {
            id: 'user-1-platform',
            name: '京东',
            icon: 'MdiIcons.dog',
            color: '#E4393C',
            userId: 'user-1',
          },
        ]);

      const result = await service.findAll('user-1');

      expect(mockPrismaService.platform.create).toHaveBeenCalledWith({
        data: {
          name: '京东',
          icon: 'MdiIcons.dog',
          color: '#E4393C',
          userId: 'user-1',
        },
      });
      expect(mockPrismaService.user.update).toHaveBeenCalledWith({
        where: { id: 'user-1' },
        data: { platformDefaultsInitialized: true },
      });
      expect(result).toHaveLength(1);
    });

    it('should return only user platforms after initialization', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        platformDefaultsInitialized: true,
      });
      mockPrismaService.platform.findMany.mockResolvedValue([
        { id: 'p1', userId: 'user-1' },
      ]);

      await service.findAll('user-1');

      expect(mockPrismaService.platform.findMany).toHaveBeenCalledWith({
        where: { userId: 'user-1' },
        orderBy: { createdAt: 'asc' },
      });
    });
  });

  describe('update', () => {
    it('should throw ForbiddenException when trying to update a platform not owned by the user', async () => {
      mockPrismaService.platform.findUnique.mockResolvedValue({
        id: '1',
        userId: null,
      });

      await expect(service.update('1', 'user-1', {})).rejects.toThrow(
        ForbiddenException,
      );
    });

    it("should throw ForbiddenException when trying to update other user's platform", async () => {
      mockPrismaService.platform.findUnique.mockResolvedValue({
        id: '2',
        userId: 'user-2',
      });

      await expect(service.update('2', 'user-1', {})).rejects.toThrow(
        ForbiddenException,
      );
    });

    it('should allow update when platform belongs to user', async () => {
      const platform = { id: '3', userId: 'user-1', name: 'Old' };
      mockPrismaService.platform.findUnique.mockResolvedValue(platform);
      mockPrismaService.platform.update.mockResolvedValue({
        ...platform,
        name: 'New',
      });

      const result = await service.update('3', 'user-1', { name: 'New' });
      expect(result.name).toBe('New');
    });
  });
});
