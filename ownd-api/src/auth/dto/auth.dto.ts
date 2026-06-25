import { ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MinLength,
} from 'class-validator';

export class SignupDto {
  @ApiProperty({
    description: '邮箱',
    example: 'example@mail.com',
    required: true,
  })
  @IsEmail({}, { message: '邮箱格式不正确' })
  email: string;

  @ApiProperty({
    description: '密码',
    example: '123456',
    required: true,
    minimum: 6,
  })
  @IsString()
  @MinLength(6, { message: '密码至少需要 6 位' })
  password: string;

  @ApiProperty({
    description: '用户名',
    example: '张三',
    required: true,
  })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({
    description: '邮箱验证码',
    example: '123456',
    required: true,
  })
  @IsString()
  @IsNotEmpty({ message: '验证码不能为空' })
  code: string;
}

export class LoginDto {
  @ApiProperty({
    description: '用户名或邮箱',
    example: 'example@mail.com',
    required: true,
  })
  @IsString()
  @IsNotEmpty({ message: '用户名或邮箱不能为空' })
  email: string;

  @ApiProperty({ description: '密码', example: '123456', required: true })
  @IsString()
  @IsNotEmpty({ message: '密码不能为空' })
  password: string;
}

export class ResetPasswordDto {
  @ApiProperty({
    description: '邮箱',
    example: 'example@mail.com',
    required: true,
  })
  @IsEmail({}, { message: '邮箱格式不正确' })
  email: string;

  @ApiProperty({
    description: '新密码',
    example: '123456',
    required: true,
    minimum: 6,
  })
  @IsString()
  @MinLength(6, { message: '密码至少需要 6 位' })
  newPassword: string;

  @ApiProperty({
    description: '邮箱验证码',
    example: '123456',
    required: true,
  })
  @IsString()
  @IsNotEmpty({ message: '验证码不能为空' })
  code: string;
}

export class UpdateProfileDto {
  @ApiProperty({
    description: '用户名',
    example: '张三',
    required: false,
  })
  @IsString()
  @IsNotEmpty({ message: '请输入用户名' })
  @IsOptional()
  name?: string;

  @ApiProperty({
    description: '头像路径',
    example: '/ownd-items/avatar.png',
    required: false,
  })
  @IsString()
  @IsNotEmpty({ message: '头像信息不完整，请重新选择' })
  @IsOptional()
  avatarPath?: string | null;

  @ApiProperty({
    description: '提前提醒天数',
    example: 3,
    required: false,
  })
  @IsIn([1, 3, 7, 14, 30], { message: '请选择可用的提前提醒天数' })
  @IsOptional()
  notificationLeadDays?: number;

  @ApiProperty({
    description: '提醒时间',
    example: '08:00',
    required: false,
  })
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, {
    message: '请选择有效的提醒时间',
  })
  @IsOptional()
  notificationTime?: string;
}

export class ChangeEmailDto {
  @ApiProperty({
    description: '新邮箱',
    example: 'new@example.com',
    required: true,
  })
  @IsEmail({}, { message: '邮箱格式不正确' })
  email: string;

  @ApiProperty({
    description: '当前密码',
    example: '123456',
    required: true,
  })
  @IsString()
  @IsNotEmpty({ message: '请输入当前密码' })
  password: string;

  @ApiProperty({
    description: '新邮箱验证码',
    example: '123456',
    required: true,
  })
  @IsString()
  @IsNotEmpty({ message: '请输入验证码' })
  code: string;
}

export class ChangePasswordDto {
  @ApiProperty({
    description: '当前密码',
    example: '123456',
    required: true,
  })
  @IsString()
  @IsNotEmpty({ message: '请输入当前密码' })
  currentPassword: string;

  @ApiProperty({
    description: '新密码',
    example: '123456',
    required: true,
    minimum: 6,
  })
  @IsString()
  @MinLength(6, { message: '密码至少需要 6 位' })
  newPassword: string;
}
