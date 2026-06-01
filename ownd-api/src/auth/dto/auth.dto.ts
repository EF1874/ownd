import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsNotEmpty, IsString, MinLength } from 'class-validator';

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
}

export class LoginDto {
  @ApiProperty({
    description: '邮箱',
    example: 'example@mail.com',
    required: true,
  })
  @IsEmail()
  email: string;

  @ApiProperty({ description: '密码', example: '123456', required: true })
  @IsString()
  @IsNotEmpty()
  password: string;
}
