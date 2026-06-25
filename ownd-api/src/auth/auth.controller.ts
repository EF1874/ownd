import {
  Controller,
  Post,
  Patch,
  Body,
  Delete,
  UnauthorizedException,
  BadRequestException,
  HttpCode,
  HttpStatus,
  Get,
  UseGuards,
  UseInterceptors,
  UploadedFile,
  ParseFilePipe,
  MaxFileSizeValidator,
  FileTypeValidator,
  Request as NestRequest,
  Inject,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import {
  SignupDto,
  LoginDto,
  ResetPasswordDto,
  UpdateProfileDto,
  ChangeEmailDto,
  ChangePasswordDto,
} from './dto/auth.dto';
import { JwtAuthGuard } from '../common/guard/jwt.guard';
import { User } from '@prisma/client';
import {
  ApiBearerAuth,
  ApiConsumes,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { LoginResultEntity } from './entities/auth.entity';
import { Audit } from '../common/decorators/audit.decorator';
import { JwtService } from '@nestjs/jwt';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import * as cacheManager from 'cache-manager';
import { ExtractJwt } from 'passport-jwt';
import { Throttle } from '@nestjs/throttler';
import { MinioService } from '../minio/minio.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { AssetPurpose } from '@prisma/client';
import { AssetsService } from '../assets/assets.service';

// 定义一个包含 user 的 Request 类型，或者使用全局声明
interface RequestWithUser extends Request {
  user: Omit<User, 'password'>;
}

const imageMaxSize = 5 * 1024 * 1024;
const imageFileType = /image\/(jpeg|jpg|png)/;

@ApiTags('身份认证')
@Controller('auth')
export class AuthController {
  constructor(
    private authService: AuthService,
    private jwtService: JwtService,
    @Inject(CACHE_MANAGER) private cacheManager: cacheManager.Cache,
    private readonly minioService: MinioService,
    private readonly assetsService: AssetsService,
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
  async sendCode(@Body('email') email: string, @Body('type') type?: string) {
    if (!email) {
      throw new BadRequestException('邮箱不能为空');
    }
    await this.authService.sendVerificationCode(email, type);
    return { success: true, message: '验证码发送成功' };
  }

  @ApiBearerAuth()
  @Get('profile')
  @UseGuards(JwtAuthGuard)
  @ApiResponse({
    status: 200,
    description: '获取成功',
    type: LoginResultEntity,
  })
  getProfile(@NestRequest() req: RequestWithUser) {
    return this.authService.login(req.user);
  }

  @ApiBearerAuth()
  @Patch('profile')
  @UseGuards(JwtAuthGuard)
  @ApiResponse({
    status: 200,
    description: '保存成功',
    type: LoginResultEntity,
  })
  updateProfile(
    @NestRequest() req: RequestWithUser,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.authService.updateProfile(req.user.id, dto);
  }

  @ApiBearerAuth()
  @Patch('profile/email')
  @UseGuards(JwtAuthGuard)
  @ApiResponse({
    status: 200,
    description: '邮箱更新成功',
    type: LoginResultEntity,
  })
  changeEmail(
    @NestRequest() req: RequestWithUser,
    @Body() dto: ChangeEmailDto,
  ) {
    return this.authService.changeEmail(req.user.id, dto);
  }

  @ApiBearerAuth()
  @Patch('profile/password')
  @UseGuards(JwtAuthGuard)
  @ApiResponse({ status: 200, description: '密码更新成功' })
  changePassword(
    @NestRequest() req: RequestWithUser,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.authService.changePassword(req.user.id, dto);
  }

  @ApiBearerAuth()
  @Post('profile/avatar')
  @UseGuards(JwtAuthGuard)
  @ApiConsumes('multipart/form-data')
  @ApiResponse({
    status: 201,
    description: '头像更新成功',
    type: LoginResultEntity,
  })
  @UseInterceptors(FileInterceptor('file'))
  async uploadAvatar(
    @NestRequest() req: RequestWithUser,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: imageMaxSize }),
          new FileTypeValidator({ fileType: imageFileType }),
        ],
      }),
    )
    file: Express.Multer.File,
  ) {
    const oldAvatarPath = req.user.avatarPath;
    const avatarPath = await this.uploadTrackedAvatar(req.user.id, file);
    let result: Awaited<ReturnType<AuthService['updateAvatar']>>;
    try {
      result = await this.authService.updateAvatar(req.user.id, avatarPath);
    } catch (error) {
      await this.assetsService.discardUpload(avatarPath);
      throw error;
    }
    if (oldAvatarPath && oldAvatarPath !== avatarPath) {
      await this.assetsService.releasePath(oldAvatarPath);
    }
    return result;
  }

  @ApiBearerAuth()
  @Delete('profile/avatar')
  @UseGuards(JwtAuthGuard)
  @ApiResponse({
    status: 200,
    description: '头像删除成功',
    type: LoginResultEntity,
  })
  async removeAvatar(@NestRequest() req: RequestWithUser) {
    const oldAvatarPath = req.user.avatarPath;
    const result = await this.authService.updateAvatar(req.user.id, null);
    if (oldAvatarPath) {
      await this.assetsService.releasePath(oldAvatarPath);
    }
    return result;
  }

  private async uploadTrackedAvatar(userId: string, file: Express.Multer.File) {
    const path = await this.minioService.uploadFile(file);
    try {
      await this.assetsService.registerUpload({
        userId,
        path,
        purpose: AssetPurpose.USER_AVATAR,
        file,
      });
      return path;
    } catch (error) {
      await this.minioService.deleteFile(path).catch(() => undefined);
      throw error;
    }
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
