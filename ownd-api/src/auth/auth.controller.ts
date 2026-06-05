import {
  Controller,
  Post,
  Body,
  UnauthorizedException,
  BadRequestException,
  HttpCode,
  HttpStatus,
  Get,
  UseGuards,
  Request as NestRequest,
  Inject,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { SignupDto, LoginDto, ResetPasswordDto } from './dto/auth.dto';
import { JwtAuthGuard } from '../common/guard/jwt.guard';
import { User } from '@prisma/client';
import { ApiBearerAuth, ApiResponse, ApiTags } from '@nestjs/swagger';
import { LoginResultEntity, UserEntity } from './entities/auth.entity';
import { Audit } from '../common/decorators/audit.decorator';
import { JwtService } from '@nestjs/jwt';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import * as cacheManager from 'cache-manager';
import { ExtractJwt } from 'passport-jwt';
import { Throttle } from '@nestjs/throttler';

// 定义一个包含 user 的 Request 类型，或者使用全局声明
interface RequestWithUser extends Request {
  user: Omit<User, 'password'>;
}

@ApiTags('身份认证')
@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private jwtService: JwtService,
    @Inject(CACHE_MANAGER) private cacheManager: cacheManager.Cache,
  ) {}

  @Throttle({ default: { limit: 15, ttl: 60000 } })
  @Post('signup')
  @Audit('用户注册')
  @ApiResponse({
    status: 201,
    description: '注册成功',
    type: LoginResultEntity,
  })
  async signUp(@Body() signupDto: SignupDto) {
    const user = await this.authService.register(
      signupDto.email,
      signupDto.password,
      signupDto.name,
      signupDto.code,
    );
    return this.authService.login(user);
  }

  @Throttle({ default: { limit: 15, ttl: 60000 } })
  @Post('login')
  @Audit('用户登录')
  @HttpCode(HttpStatus.OK)
  @ApiResponse({
    status: 200,
    description: '登录成功',
    type: LoginResultEntity,
  })
  async login(@Body() loginDto: LoginDto) {
    const user = await this.authService.validateUser(
      loginDto.email,
      loginDto.password,
    );
    if (!user) {
      throw new UnauthorizedException('邮箱或密码错误');
    }
    return this.authService.login(user);
  }

  @Throttle({ default: { limit: 15, ttl: 60000 } })
  @Post('reset-password')
  @Audit('重置密码')
  @HttpCode(HttpStatus.OK)
  @ApiResponse({ status: 200, description: '重置成功' })
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
    await this.authService.resetPassword(
      resetPasswordDto.email,
      resetPasswordDto.newPassword,
      resetPasswordDto.code,
    );
    return { success: true, message: '密码重置成功' };
  }

  @Throttle({ default: { limit: 5, ttl: 60000 } })
  @Post('send-code')
  @HttpCode(HttpStatus.OK)
  @ApiResponse({ status: 200, description: '验证码发送成功' })
  async sendCode(
    @Body('email') email: string,
    @Body('type') type?: string,
  ) {
    if (!email) {
      throw new BadRequestException('邮箱不能为空');
    }
    await this.authService.sendVerificationCode(email, type);
    return { success: true, message: '验证码发送成功' };
  }

  @ApiBearerAuth()
  @Get('profile')
  @UseGuards(JwtAuthGuard)
  @ApiResponse({ status: 200, description: '获取成功', type: UserEntity })
  getProfile(@NestRequest() req: RequestWithUser) {
    // 因为已经有了 Guard 和 Strategy，这里的 req.user 已经是数据库里的最新对象
    return req.user;
  }

  @ApiBearerAuth()
  @UseGuards(JwtAuthGuard)
  @Post('logout')
  @Audit('用户登出')
  @HttpCode(HttpStatus.OK)
  @ApiResponse({ status: 200, description: '登出成功' })
  async logout(@NestRequest() req: any) {
    const token = ExtractJwt.fromAuthHeaderAsBearerToken()(req);
    if (token) {
      try {
        const decoded: unknown = this.jwtService.decode(token);
        if (
          decoded &&
          typeof decoded === 'object' &&
          'exp' in decoded &&
          typeof (decoded as Record<string, unknown>).exp === 'number'
        ) {
          const exp = (decoded as Record<string, unknown>).exp as number;
          const now = Math.floor(Date.now() / 1000);
          const ttl = exp - now;

          if (ttl > 0) {
            await this.cacheManager.set(`blacklist:${token}`, true, ttl * 1000);
          }
        }
      } catch {
        // ignore
      }
    }
    return { success: true, message: '登出成功' };
  }
}
