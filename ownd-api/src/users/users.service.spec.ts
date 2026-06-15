import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { User } from '@prisma/client';
import { CACHE_MANAGER } from '@nestjs/cache-manager';

describe('UsersService', () => {
  let service: UsersService;
  let prisma: PrismaService;

  const mockPrismaService = {
    user: {
      create: jest.fn(),
      findUnique: jest.fn(),
    },
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: PrismaService, useValue: mockPrismaService },
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

    service = module.get<UsersService>(UsersService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  afterEach(() => {
    jest.clearAllMocks();
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

      expect(prisma.user.create as jest.Mock).toHaveBeenCalledWith({
        data: expect.objectContaining({
          email,
          name,
          password: expect.any(String) as string,
        }),
      });

      const callArgs = (prisma.user.create as jest.Mock).mock.calls[0] as [
        { data: { password: string } },
      ];
      const passwordSentToPrisma = callArgs[0].data.password;
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

      expect(prisma.user.findUnique as jest.Mock).toHaveBeenCalledWith({
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
});
