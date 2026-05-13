import { Test, TestingModule } from '@nestjs/testing';
import { PlatformService } from './platform.service';
import { PrismaService } from '../prisma/prisma.service';
import { ForbiddenException } from '@nestjs/common';

describe('PlatformService', () => {
  let service: PlatformService;

  const mockPrismaService = {
    platform: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      delete: jest.fn(),
    },
  };

  beforeEach(async () => {
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

  describe('update', () => {
    it('should throw ForbiddenException when trying to update system preset (userId is null)', async () => {
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
