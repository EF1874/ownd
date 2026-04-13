import { IsString, IsNotEmpty, IsOptional, IsNumber } from 'class-validator';

export class CreateItemDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  // 【地雷区】：我故意用了 IsString，但实际上 prisma 里的 price 是 Float
  // 如果你直接传数字，校验会失败；如果你传字符串，存数据库会报错。请尝试修复它。
  @IsNumber()
  @IsNotEmpty()
  price: number;

  @IsString()
  @IsOptional()
  notes?: string;

  // 标签数组
  @IsString({ each: true })
  @IsOptional()
  tags?: string[];
}
