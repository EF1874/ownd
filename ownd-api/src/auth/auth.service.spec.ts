import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { ConflictException, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { User } from '@prisma/client';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { ConfigService } from '@nestjs/config';

describe('AuthService', () => {
  let service: AuthService;

  const mockUsersService = {
    findByEmail: jest.fn(),
    findByNameOrEmail: jest.fn(),
    findByName: jest.fn(),
    findById: jest.fn(),
    create: jest.fn(),
    updateProfile: jest.fn(),
    updateAvatar: jest.fn(),
    updateEmail: jest.fn(),
    updatePassword: jest.fn(),
    updatePreferences: jest.fn(),
  };

  const mockJwtService = {
    sign: jest.fn(),
  };

  const mockCacheManager = {
    get: jest.fn(),
    set: jest.fn(),
    del: jest.fn(),
  };

  const mockConfigService = {
    get: jest.fn((_key: string, fallback?: string) => fallback),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: mockUsersService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: CACHE_MANAGER, useValue: mockCacheManager },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  describe('validateUser', () => {
    it('should return user without password if password matches', async () => {
      const password = 'password123';
      const hashedPassword = await bcrypt.hash(password, 10);
      const user = {
        id: '1',
        email: 'test@test.com',
        password: hashedPassword,
        name: 'Test',
        createdAt: new Date(),
        updatedAt: new Date(),
      } as User;

      mockUsersService.findByNameOrEmail.mockResolvedValue(user);

      const result = await service.validateUser(user.email, password);

      const { password: _password, ...expectedResult } = user;
      expect(result).toEqual(expectedResult);
    });

    it('should return null if password does not match', async () => {
      const user = {
        id: '1',
        email: 'test@test.com',
        password: 'hashedPassword',
      } as User;
      mockUsersService.findByNameOrEmail.mockResolvedValue(user);

      const result = await service.validateUser(user.email, 'wrongPassword');

      expect(result).toBeNull();
    });

    it('should return null if user not found', async () => {
      mockUsersService.findByNameOrEmail.mockResolvedValue(null);

      const result = await service.validateUser('none@test.com', 'password');

      expect(result).toBeNull();
    });
  });

  describe('register', () => {
    it('should register a new user if email is not taken', async () => {
      const email = 'new@test.com';
      mockCacheManager.get.mockResolvedValue('123456');
      mockUsersService.findByEmail.mockResolvedValue(null);
      mockUsersService.findByNameOrEmail.mockResolvedValue(null);
      mockUsersService.create.mockResolvedValue({ id: '1', email } as User);

      const result = await service.register(email, 'pass123', 'Name', '123456');

      expect(mockUsersService.create).toHaveBeenCalledWith(
        email,
        'pass123',
        'Name',
      );
      expect(result).toEqual({ id: '1', email });
    });

    it('should throw ConflictException if email is taken', async () => {
      mockCacheManager.get.mockResolvedValue('123456');
      mockUsersService.findByEmail.mockResolvedValue({
        id: '1',
        email: 'taken@test.com',
      } as User);

      await expect(
        service.register('taken@test.com', 'pass', 'Name', '123456'),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('login', () => {
    it('should return an access_token', async () => {
      const user = { id: '1', email: 'test@test.com', name: 'Test' } as User;
      const mockToken = 'signed-token';
      mockJwtService.sign.mockReturnValue(mockToken);

      const result = await service.login(user);

      expect(mockJwtService.sign).toHaveBeenCalledWith(
        { email: user.email, sub: user.id },
        { expiresIn: '30d' },
      );
      expect(result).toEqual({
        access_token: mockToken,
        user: {
          id: '1',
          email: 'test@test.com',
          name: 'Test',
          avatarPath: null,
          notificationLeadDays: 3,
          notificationTime: '08:00',
        },
      });
    });
  });

  describe('updateProfile', () => {
    it('should reject a username used by another account', async () => {
      mockUsersService.findByName.mockResolvedValue({
        id: '2',
        name: 'Taken',
      } as User);

      await expect(
        service.updateProfile('1', { name: 'Taken' }),
      ).rejects.toThrow(ConflictException);
    });

    it('should update profile when the username is available', async () => {
      const user = { id: '1', email: 'test@test.com', name: 'New' } as User;
      mockUsersService.findByName.mockResolvedValue(null);
      mockUsersService.updateProfile.mockResolvedValue(user);
      mockJwtService.sign.mockReturnValue('token');

      const result = await service.updateProfile('1', { name: 'New' });

      expect(mockUsersService.updateProfile).toHaveBeenCalledWith('1', {
        name: 'New',
      });
      expect(result.user.name).toBe('New');
    });
  });

  describe('changeEmail', () => {
    it('should require the current password and new email code', async () => {
      const password = 'old-pass';
      const hashedPassword = await bcrypt.hash(password, 10);
      mockUsersService.findById.mockResolvedValue({
        id: '1',
        email: 'old@test.com',
        password: hashedPassword,
      } as User);
      mockCacheManager.get.mockResolvedValue('123456');
      mockUsersService.findByEmail.mockResolvedValue(null);
      mockUsersService.updateEmail.mockResolvedValue({
        id: '1',
        email: 'new@test.com',
        name: 'Test',
      } as User);
      mockJwtService.sign.mockReturnValue('token');

      const result = await service.changeEmail('1', {
        email: 'new@test.com',
        password,
        code: '123456',
      });

      expect(mockUsersService.updateEmail).toHaveBeenCalledWith(
        '1',
        'new@test.com',
      );
      expect(mockCacheManager.del).toHaveBeenCalledWith(
        'verification_code:new@test.com',
      );
      expect(result.user.email).toBe('new@test.com');
    });

    it('should reject a wrong current password', async () => {
      const hashedPassword = await bcrypt.hash('right-pass', 10);
      mockUsersService.findById.mockResolvedValue({
        id: '1',
        email: 'old@test.com',
        password: hashedPassword,
      } as User);

      await expect(
        service.changeEmail('1', {
          email: 'new@test.com',
          password: 'wrong-pass',
          code: '123456',
        }),
      ).rejects.toThrow(UnauthorizedException);
      expect(mockUsersService.updateEmail).not.toHaveBeenCalled();
    });
  });

  describe('updateAvatar', () => {
    it('should update avatar through the asset-aware user method', async () => {
      mockUsersService.updateAvatar.mockResolvedValue({
        id: '1',
        email: 'test@test.com',
        name: 'Test',
        avatarPath: '/ownd-items/avatar.png',
      } as User);
      mockJwtService.sign.mockReturnValue('token');

      const result = await service.updateAvatar('1', '/ownd-items/avatar.png');

      expect(mockUsersService.updateAvatar).toHaveBeenCalledWith(
        '1',
        '/ownd-items/avatar.png',
      );
      expect(result.user.avatarPath).toBe('/ownd-items/avatar.png');
    });
  });

  describe('changePassword', () => {
    it('should update password after checking the current password', async () => {
      const password = 'old-pass';
      const hashedPassword = await bcrypt.hash(password, 10);
      mockUsersService.findById.mockResolvedValue({
        id: '1',
        email: 'test@test.com',
        password: hashedPassword,
      } as User);
      mockUsersService.updatePassword.mockResolvedValue({ id: '1' } as User);

      const result = await service.changePassword('1', {
        currentPassword: password,
        newPassword: 'new-pass',
      });

      expect(mockUsersService.updatePassword).toHaveBeenCalledWith(
        '1',
        'new-pass',
      );
      expect(result).toEqual({ success: true, message: '密码已更新' });
    });
  });
});
