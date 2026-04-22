import { ApiHideProperty, ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsNumber } from 'class-validator';

import { Transform, Type } from 'class-transformer';

export class CreateItemDto {
  @ApiProperty({ description: '物品名称', example: '手机', required: true })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ description: '物品价格', example: 1000, required: true })
  @IsNumber()
  @IsNotEmpty()
  @Type(() => Number)
  price: number;

  @ApiProperty({ description: '物品备注', example: '这是一个很好的手机' })
  @IsString()
  @IsOptional()
  notes?: string;

  // 标签数组
  @ApiProperty({ description: '物品标签', example: ['电子产品', '手机'] })
  @Transform(({ value }): string[] => {
    if (typeof value === 'string') {
      return value.split(',').map((tag) => tag.trim());
    }
    return value;
  })
  @IsString({ each: true })
  @IsOptional()
  tags?: string[];

  @ApiProperty({
    description: '所属分类ID',
    example: 'c51502cf-608a-478e-8268-f9f5c27c7a2e',
  })
  @IsString()
  @IsOptional()
  categoryId?: string;

  @IsOptional()
  @IsString()
  @ApiHideProperty()
  imagePath?: string;

  @ApiProperty({
    type: 'string',
    format: 'binary',
    description: '物品图片文件',
    required: false,
  })
  @IsOptional()
  file?: Express.Multer.File;
}
