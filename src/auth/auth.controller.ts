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
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';

// 定义一个包含 user 的 Request 类型，或者使用全局声明
interface RequestWithUser extends Request {
  user: Omit<User, 'password'>;
}

@ApiTags('身份认证')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('signup')
  async signUp(@Body() signupDto: SignupDto) {
    return this.authService.register(
      signupDto.email,
      signupDto.password,
      signupDto.name,
    );
  }

  @Post('login')
  @HttpCode(HttpStatus.OK)
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
  getProfile(@NestRequest() req: RequestWithUser) {
    // 因为已经有了 Guard 和 Strategy，这里的 req.user 已经是数据库里的最新对象
    return req.user;
  }
}
