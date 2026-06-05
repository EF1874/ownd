import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User } from '@prisma/client'; // 引入 Prisma 自动生成的类型

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async validateUser(
    usernameOrEmail: string,
    pass: string,
  ): Promise<Omit<User, 'password'> | null> {
    const user = await this.usersService.findByNameOrEmail(usernameOrEmail);
    if (user && (await bcrypt.compare(pass, user.password))) {
      // Omit 代表去掉 password 后的 User 对象
      const { password: _, ...result } = user;
      return result;
    }
    return null;
  }

  // 其他方法暂时保持原样，核心是引入了 User 类型
  async login(user: Partial<User>) {
    const payload = { email: user.email, sub: user.id };
    return await Promise.resolve({
      access_token: this.jwtService.sign(payload),
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
      },
    });
  }

  async register(email: string, pass: string, name?: string) {
    const existingUser = await this.usersService.findByEmail(email);
    if (existingUser) {
      throw new ConflictException('该邮箱已被注册');
    }
    if (name) {
      const existingUserByName = await this.usersService.findByNameOrEmail(name);
      if (existingUserByName) {
        throw new ConflictException('该用户名已被占用');
      }
    }
    return this.usersService.create(email, pass, name);
  }

  async resetPassword(email: string, name: string, pass: string) {
    const user = await this.usersService.findByEmail(email);
    if (!user || user.name !== name) {
      throw new NotFoundException('邮箱或用户名匹配不正确');
    }
    await this.usersService.updatePassword(user.id, pass);
  }
}
