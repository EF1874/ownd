import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  // 注册：创建新用户
  async create(email: string, pass: string, name?: string) {
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

  // 查找：根据邮箱找到用户（登录验证用）
  async findByEmail(email: string) {
    return this.prisma.user.findUnique({
      where: { email },
    });
  }
}
