import { Injectable, ConflictException, NotFoundException, BadRequestException, Inject } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcrypt';
import { User } from '@prisma/client';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import * as cacheManager from 'cache-manager';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { UpdateUserPreferencesDto } from './dto/auth.dto';

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
    @Inject(CACHE_MANAGER) private cacheManager: cacheManager.Cache,
    private configService: ConfigService,
  ) {}

  async validateUser(
    usernameOrEmail: string,
    pass: string,
  ): Promise<Omit<User, 'password'> | null> {
    const user = await this.usersService.findByNameOrEmail(usernameOrEmail);
    if (user && (await bcrypt.compare(pass, user.password))) {
      const { password: _, ...result } = user;
      return result;
    }
    return null;
  }

  async login(user: Partial<User>) {
    const payload = { email: user.email, sub: user.id };
    return await Promise.resolve({
      access_token: this.jwtService.sign(payload, { expiresIn: '30d' }),
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        notificationLeadDays: user.notificationLeadDays ?? 3,
        notificationTime: user.notificationTime ?? '08:00',
      },
    });
  }

  async updatePreferences(userId: string, dto: UpdateUserPreferencesDto) {
    const user = await this.usersService.updatePreferences(userId, dto);
    return this.login(user);
  }

  private getTransporter() {
    const host = this.configService.get<string>('SMTP_HOST');
    const port = Number(this.configService.get<string>('SMTP_PORT', '465'));
    const secure = this.configService.get<string>('SMTP_SECURE') === 'true';
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASS');

    if (!host || !user || !pass) {
      return null;
    }

    return nodemailer.createTransport({
      host,
      port,
      secure,
      auth: {
        user,
        pass,
      },
    });
  }

  async sendVerificationCode(email: string, type?: string): Promise<void> {
    if (type === 'signup') {
      const user = await this.usersService.findByEmail(email);
      if (user) {
        throw new ConflictException('该邮箱已被注册');
      }
    } else if (type === 'reset') {
      const user = await this.usersService.findByEmail(email);
      if (!user) {
        throw new NotFoundException('该邮箱未注册');
      }
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const key = `verification_code:${email}`;
    await this.cacheManager.set(key, code, 300000); // 5 minutes TTL in milliseconds

    const transporter = this.getTransporter();
    const smtpFrom = this.configService.get<string>('SMTP_FROM', '"物记" <sender@example.com>');

    let subject = '【物记】验证码';
    let textBody = `您的验证码是：${code}。该验证码有效期为 5 分钟，请勿泄露给他人。`;
    let htmlBody = `<p>您的验证码是：<strong>${code}</strong>。</p><p>该验证码有效期为 5 分钟，请勿泄露给他人。</p>`;

    if (type === 'signup') {
      subject = '【物记】注册验证码';
      textBody = `您好！感谢您注册物记。您的注册验证码是：${code}。该验证码有效期为 5 分钟，请勿泄露给他人。`;
      htmlBody = `<p>您好！感谢您注册物记。</p><p>您的注册验证码是：<strong>${code}</strong>。</p><p>该验证码有效期为 5 分钟，请勿泄露给他人。</p>`;
    } else if (type === 'reset') {
      subject = '【物记】重置密码验证码';
      textBody = `您好！您正在申请重置密码。您的找回密码验证码是：${code}。该验证码有效期为 5 分钟，如果是您本人操作，请在页面中输入；如果非您本人操作，请忽略此邮件。`;
      htmlBody = `<p>您好！您正在申请重置密码。</p><p>您的找回密码验证码是：<strong>${code}</strong>。</p><p>该验证码有效期为 5 分钟，如果是您本人操作，请在页面中输入；如果非您本人操作，请忽略此邮件。</p>`;
    }

    if (transporter && !this.configService.get<string>('SMTP_HOST', '').includes('example.com')) {
      try {
        await transporter.sendMail({
          from: smtpFrom,
          to: email,
          subject,
          text: textBody,
          html: htmlBody,
        });
        console.log(`[VERIFICATION CODE] Sent real email to ${email} successfully (${type || 'default'}).`);
      } catch (error) {
        console.error(`[VERIFICATION CODE] Failed to send real email to ${email}:`, error);
        // Fallback to console log in case of SMTP failure
        console.log(`\n========================================`);
        console.log(`[VERIFICATION CODE] (SMTP FAILED FALLBACK) Sent to: ${email}`);
        console.log(`[CODE]: ${code}`);
        console.log(`========================================\n`);
      }
    } else {
      // Fallback/Dev mode
      console.log(`\n========================================`);
      console.log(`[VERIFICATION CODE] (DEV CONSOLE FALLBACK) Sent to: ${email}`);
      console.log(`[CODE]: ${code}`);
      console.log(`========================================\n`);
    }
  }

  async verifyCode(email: string, code: string): Promise<void> {
    const key = `verification_code:${email}`;
    const cachedCode = await this.cacheManager.get<string>(key);
    if (!cachedCode) {
      throw new BadRequestException('验证码已过期或未发送');
    }
    if (cachedCode !== code) {
      throw new BadRequestException('验证码不正确');
    }
    await this.cacheManager.del(key);
  }

  async register(email: string, pass: string, name: string, code: string) {
    await this.verifyCode(email, code);
    const existingUser = await this.usersService.findByEmail(email);
    if (existingUser) {
      throw new ConflictException('该邮箱已被注册');
    }
    const existingUserByName = await this.usersService.findByNameOrEmail(name);
    if (existingUserByName) {
      throw new ConflictException('该用户名已被占用');
    }
    return this.usersService.create(email, pass, name);
  }

  async resetPassword(email: string, pass: string, code: string) {
    await this.verifyCode(email, code);
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      throw new NotFoundException('该邮箱未注册');
    }
    await this.usersService.updatePassword(user.id, pass);
  }
}
