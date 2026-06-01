import { ApiProperty } from '@nestjs/swagger';
import { Platform } from '@prisma/client';
import { UserEntity } from '../../auth/entities/auth.entity';

export class PlatformEntity implements Platform {
  @ApiProperty({ description: '平台ID', example: 'uuid' })
  id: string;

  @ApiProperty({ description: '平台名称', example: '微信' })
  name: string;

  @ApiProperty({ description: '平台图标', example: '/path/to/icon.png' })
  icon: string;

  @ApiProperty({ description: '平台颜色', example: '#000000' })
  color: string;

  @ApiProperty({
    description: '所属用户ID',
    example: 'user-uuid',
    nullable: true,
  })
  userId: string | null;

  @ApiProperty({
    description: '所属用户',
    type: () => UserEntity,
    nullable: true,
  })
  user?: UserEntity;

  @ApiProperty({ description: '创建时间' })
  createdAt: Date;

  @ApiProperty({ description: '更新时间' })
  updatedAt: Date;
}
