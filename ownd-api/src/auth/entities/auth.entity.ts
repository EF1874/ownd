import { ApiProperty } from '@nestjs/swagger';

export class UserEntity {
  @ApiProperty({ description: '用户ID', example: 'uuid' })
  id: string;

  @ApiProperty({ description: '邮箱', example: 'test@example.com' })
  email: string;

  @ApiProperty({ description: '用户名', example: '张三', nullable: true })
  name: string | null;

  @ApiProperty({ description: '创建时间' })
  createdAt: Date;

  @ApiProperty({ description: '更新时间' })
  updatedAt: Date;
}

export class LoginResultEntity {
  @ApiProperty({ description: 'JWT 访问令牌' })
  accessToken: string;

  @ApiProperty({ description: '用户信息', type: UserEntity })
  user: UserEntity;
}
