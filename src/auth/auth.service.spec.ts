import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { ConflictException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { User } from '@prisma/client';

describe('AuthService', () => {
  let service: AuthService;
  let usersService: UsersService;
  let jwtService: JwtService;

  const mockUsersService = {
    findByEmail: jest.fn(),
    create: jest.fn(),
  };

  const mockJwtService = {
    sign: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: mockUsersService },
        { provide: JwtService, useValue: mockJwtService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usersService = module.get<UsersService>(UsersService);
    jwtService = module.get<JwtService>(JwtService);
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

      mockUsersService.findByEmail.mockResolvedValue(user);

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
      mockUsersService.findByEmail.mockResolvedValue(user);

      const result = await service.validateUser(user.email, 'wrongPassword');

      expect(result).toBeNull();
    });

    it('should return null if user not found', async () => {
      mockUsersService.findByEmail.mockResolvedValue(null);

      const result = await service.validateUser('none@test.com', 'password');

      expect(result).toBeNull();
    });
  });

  describe('register', () => {
    it('should register a new user if email is not taken', async () => {
      const email = 'new@test.com';
      mockUsersService.findByEmail.mockResolvedValue(null);
      mockUsersService.create.mockResolvedValue({ id: '1', email } as User);

      const result = await service.register(email, 'pass123', 'Name');

      expect(usersService.create as jest.Mock).toHaveBeenCalledWith(
        email,
        'pass123',
        'Name',
      );
      expect(result).toEqual({ id: '1', email });
    });

    it('should throw ConflictException if email is taken', async () => {
      mockUsersService.findByEmail.mockResolvedValue({
        id: '1',
        email: 'taken@test.com',
      } as User);

      await expect(
        service.register('taken@test.com', 'pass', 'Name'),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('login', () => {
    it('should return an access_token', async () => {
      const user = { id: '1', email: 'test@test.com', name: 'Test' } as User;
      const mockToken = 'signed-token';
      mockJwtService.sign.mockReturnValue(mockToken);

      const result = await service.login(user);

      expect(jwtService.sign as jest.Mock).toHaveBeenCalled();
      expect(result).toEqual({
        access_token: mockToken,
        user: { id: '1', email: 'test@test.com', name: 'Test' },
      });
    });
  });
});
