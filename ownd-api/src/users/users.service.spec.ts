import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { AssetPurpose, AssetRefType, AssetStatus, User } from '@prisma/client';
import { CACHE_MANAGER } from '@nestjs/cache-manager';

type UserCreateArgs = {
  data: {
    email: string;
    name?: string;
    password: string;
  };
};

describe('UsersService', () => {
  let service: UsersService;

  const mockPrismaService = {
    $transaction: jest.fn(),
    user: {
      create: jest.fn(),
      findUnique: jest.fn(),
      update: jest.fn(),
    },
    asset: {
      updateMany: jest.fn(),
    },
  };

  const mockCacheManager = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: PrismaService, useValue: mockPrismaService },
        {
          provide: CACHE_MANAGER,
          useValue: mockCacheManager,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  beforeEach(() => {
    mockPrismaService.$transaction.mockImplementation(
      (callback: (tx: typeof mockPrismaService) => unknown) =>
        callback(mockPrismaService),
    );
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should hash password and create a user', async () => {
      const email = 'test@example.com';
      const password = 'rawPassword123';
      const name = 'Test User';

      const mockUser = { id: 'uuid', email, name } as User;
      mockPrismaService.user.create.mockResolvedValue(mockUser);

      const result = await service.create(email, password, name);

      const callArgs = mockPrismaService.user.create.mock.calls[0] as [
        UserCreateArgs,
      ];
      expect(callArgs[0].data.email).toBe(email);
      expect(callArgs[0].data.name).toBe(name);
      const passwordSentToPrisma = callArgs[0].data.password;
      expect(typeof passwordSentToPrisma).toBe('string');
      expect(passwordSentToPrisma).not.toBe(password);

      const isMatch = await bcrypt.compare(password, passwordSentToPrisma);
      expect(isMatch).toBe(true);
      expect(result).toEqual(mockUser);
    });
  });

  describe('findByEmail', () => {
    it('should return a user if found', async () => {
      const email = 'test@example.com';
      const mockUser = { id: '1', email } as User;
      mockPrismaService.user.findUnique.mockResolvedValue(mockUser);

      const result = await service.findByEmail(email);

      expect(mockPrismaService.user.findUnique).toHaveBeenCalledWith({
        where: { email },
      });
      expect(result).toEqual(mockUser);
    });

    it('should return null if not found', async () => {
      const email = 'none@example.com';
      mockPrismaService.user.findUnique.mockResolvedValue(null);

      const result = await service.findByEmail(email);

      expect(result).toBeNull();
    });
  });

  describe('updateProfile', () => {
    it('should update profile fields and clear cached profile', async () => {
      const mockUser = {
        id: '1',
        email: 'test@example.com',
        name: 'New Name',
        avatarPath: '/ownd-items/avatar.png',
      } as User;
      mockPrismaService.user.update.mockResolvedValue(mockUser);

      const result = await service.updateProfile('1', {
        name: 'New Name',
        avatarPath: '/ownd-items/avatar.png',
      });

      expect(mockPrismaService.user.update).toHaveBeenCalledWith({
        where: { id: '1' },
        data: {
          name: 'New Name',
          avatarPath: '/ownd-items/avatar.png',
        },
      });
      expect(mockCacheManager.del).toHaveBeenCalledWith('user:profile:1');
      expect(result).toEqual(mockUser);
    });
  });

  describe('updateEmail', () => {
    it('should update email and clear cached profile', async () => {
      mockPrismaService.user.update.mockResolvedValue({
        id: '1',
        email: 'new@example.com',
      } as User);

      await service.updateEmail('1', 'new@example.com');

      expect(mockPrismaService.user.update).toHaveBeenCalledWith({
        where: { id: '1' },
        data: { email: 'new@example.com' },
      });
      expect(mockCacheManager.del).toHaveBeenCalledWith('user:profile:1');
    });
  });

  describe('updateAvatar', () => {
    it('should activate the new avatar asset and orphan the old one', async () => {
      mockPrismaService.user.findUnique.mockResolvedValue({
        avatarPath: '/ownd-items/old.png',
      });
      mockPrismaService.user.update.mockResolvedValue({
        id: '1',
        email: 'test@example.com',
        name: 'Test',
        avatarPath: '/ownd-items/new.png',
      } as User);

      const result = await service.updateAvatar('1', '/ownd-items/new.png');

      expect(mockPrismaService.user.update).toHaveBeenCalledWith({
        where: { id: '1' },
        data: { avatarPath: '/ownd-items/new.png' },
      });
      expect(mockPrismaService.asset.updateMany).toHaveBeenCalledWith({
        where: {
          userId: '1',
          path: '/ownd-items/old.png',
          purpose: AssetPurpose.USER_AVATAR,
        },
        data: {
          status: AssetStatus.ORPHAN,
          refType: null,
          refId: null,
        },
      });
      expect(mockPrismaService.asset.updateMany).toHaveBeenCalledWith({
        where: { userId: '1', path: '/ownd-items/new.png' },
        data: {
          purpose: AssetPurpose.USER_AVATAR,
          status: AssetStatus.ACTIVE,
          refType: AssetRefType.USER,
          refId: '1',
        },
      });
      expect(mockCacheManager.del).toHaveBeenCalledWith('user:profile:1');
      expect(result.avatarPath).toBe('/ownd-items/new.png');
    });
  });
});
