import { Inject, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import * as cacheManager from 'cache-manager';

@Injectable()
export class UsersService {
  constructor(
    private prisma: PrismaService,
    @Inject(CACHE_MANAGER) private cacheManager: cacheManager.Cache,
  ) {}

  // 注册：创建新用户
  async create(email: string, pass: string, name: string) {
    // 关键：绝对不能在数据库存明文密码！使用 bcrypt 加密。
    const hashedPassword = await bcrypt.hash(pass, 10);

    const { password: _, ...user } = await this.prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
      },
    });

    return user;
  }

  /**
   * 用于登录验证
   * @param email 用户邮箱
   * @returns 用户对象
   */
  async findByEmail(email: string) {
    return this.prisma.user.findUnique({
      where: { email },
    });
  }

  async findByNameOrEmail(usernameOrEmail: string) {
    return this.prisma.user.findFirst({
      where: {
        OR: [{ email: usernameOrEmail }, { name: usernameOrEmail }],
      },
    });
  }

  /**
   * @param userId 用户ID
   * @returns 用户对象
   */
  async findById(userId: string) {
    const cacheKey = `user:profile:${userId}`;
    try {
      const cached =
        await this.cacheManager.get<import('@prisma/client').User>(cacheKey);
      if (cached) {
        return cached;
      }
    } catch {
      // ignore
    }

    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (user) {
      try {
        await this.cacheManager.set(cacheKey, user, 300000); // 缓存 5 分钟
      } catch {
        // ignore
      }
    }

    return user;
  }

  async updatePassword(userId: string, pass: string) {
    const hashedPassword = await bcrypt.hash(pass, 10);
    return this.prisma.user.update({
      where: { id: userId },
      data: { password: hashedPassword },
    });
  }
}
