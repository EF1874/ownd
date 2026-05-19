import {
  Controller,
  Post,
  Body,
  UnauthorizedException,
  HttpCode,
  HttpStatus,
  Get,
  UseGuards,
  Request as NestRequest,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { SignupDto, LoginDto } from './dto/auth.dto';
import { JwtAuthGuard } from '../common/guard/jwt.guard';
import { User } from '@prisma/client';
import { ApiBearerAuth, ApiResponse, ApiTags } from '@nestjs/swagger';
import { LoginResultEntity, UserEntity } from './entities/auth.entity';
import { Audit } from '../common/decorators/audit.decorator';

// 定义一个包含 user 的 Request 类型，或者使用全局声明
interface RequestWithUser extends Request {
  user: Omit<User, 'password'>;
}

@ApiTags('身份认证')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

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
    );
    return this.authService.login(user);
  }

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

  @ApiBearerAuth()
  @Get('profile')
  @UseGuards(JwtAuthGuard)
  @ApiResponse({ status: 200, description: '获取成功', type: UserEntity })
  getProfile(@NestRequest() req: RequestWithUser) {
    // 因为已经有了 Guard 和 Strategy，这里的 req.user 已经是数据库里的最新对象
    return req.user;
  }
}
