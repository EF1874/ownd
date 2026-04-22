import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class CreateCategoryDto {
  @ApiProperty({ description: '分类名称', example: '电子产品' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ description: '分类图标', example: 'electronic' })
  @IsString()
  @IsOptional()
  icon?: string;

  @ApiProperty({ description: '父级分类ID', example: '1' })
  @IsString()
  @IsOptional()
  parentId: string;
}
