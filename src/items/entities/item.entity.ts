import { ApiProperty } from '@nestjs/swagger';
import { Item } from '@prisma/client';
import { CategoryEntity } from 'src/categories/entities/category.entity';

export class ItemEntity implements Item {
  @ApiProperty({ description: '物品ID', example: 'uuid' })
  id: string;

  @ApiProperty({ description: '物品名称', example: '手机' })
  name: string;

  @ApiProperty({ description: '物品价格', example: 1000 })
  price: number;

  @ApiProperty({ description: '购买日期' })
  purchaseDate: Date;

  @ApiProperty({
    description: '图片路径',
    example: '/path/to/image.png',
    nullable: true,
  })
  imagePath: string | null;

  @ApiProperty({ description: '备注', example: '这是一个手机', nullable: true })
  notes: string | null;

  @ApiProperty({ description: '标签列表', example: ['电子产品', '手机'] })
  tags: string[];

  @ApiProperty({ description: '所属用户ID', example: 'user-uuid' })
  userId: string;

  @ApiProperty({
    description: '所属分类ID',
    example: 'category-uuid',
    nullable: true,
  })
  categoryId: string | null;

  @ApiProperty({
    description: '所属分类详情',
    type: () => CategoryEntity,
    nullable: true,
  })
  category?: CategoryEntity;

  @ApiProperty({ description: '创建时间' })
  createdAt: Date;

  @ApiProperty({ description: '更新时间' })
  updatedAt: Date;
}
