import { ApiProperty } from '@nestjs/swagger';
import { Category } from '@prisma/client';

export class CategoryEntity implements Category {
  @ApiProperty({ description: '分类ID', example: 'uuid' })
  id: string;

  @ApiProperty({ description: '分类名称', example: '电子产品' })
  name: string;

  @ApiProperty({
    description: '分类图标',
    example: 'icon-name',
    nullable: true,
  })
  icon: string | null;

  @ApiProperty({ description: '用户ID', example: 'user-uuid' })
  userId: string;

  @ApiProperty({
    description: '父级分类ID',
    example: 'parent-uuid',
    nullable: true,
  })
  parentId: string | null;

  @ApiProperty({ description: '创建时间' })
  createAt: Date;

  @ApiProperty({ description: '更新时间' })
  updateAt: Date;

  @ApiProperty({
    description: '子分类列表',
    type: [CategoryEntity],
    required: false,
  })
  children?: CategoryEntity[];
}
