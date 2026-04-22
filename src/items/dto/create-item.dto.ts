import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsOptional, IsNumber } from 'class-validator';

export class CreateItemDto {
  @ApiProperty({ description: '物品名称', example: '手机', required: true })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ description: '物品价格', example: '1000', required: true })
  @IsNumber()
  @IsNotEmpty()
  price: number;

  @ApiProperty({ description: '物品备注', example: '这是一个很好的手机' })
  @IsString()
  @IsOptional()
  notes?: string;

  // 标签数组
  @ApiProperty({ description: '物品标签', example: ['电子产品', '手机'] })
  @IsString({ each: true })
  @IsOptional()
  tags?: string[];
}
