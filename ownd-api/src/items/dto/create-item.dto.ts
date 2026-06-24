import { ApiProperty } from '@nestjs/swagger';
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsNumber,
  IsUUID,
  IsDate,
  IsBoolean,
  IsArray,
  IsEnum,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ItemCycleCalculationMode, ItemCycleType } from '@prisma/client';

export class CreateItemDto {
  @ApiProperty({ description: '图片路径', required: false })
  @IsString()
  @IsOptional()
  imagePath?: string;

  @ApiProperty({ description: '物品名称', example: '手机', required: true })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ description: '物品价格', example: 1000, required: true })
  @IsNumber()
  @IsNotEmpty()
  price: number;

  @ApiProperty({ description: '续费价格', example: 20, required: false })
  @IsNumber()
  @Type(() => Number)
  @IsOptional()
  @Min(0, { message: '续费价格不能小于0' })
  renewalPrice?: number;

  @ApiProperty({ description: '购买日期', example: '2023-01-01' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  purchaseDate?: Date;

  @ApiProperty({ description: '所属分类ID', example: 'uuid', required: false })
  @IsUUID()
  @IsOptional()
  categoryId?: string;

  @ApiProperty({ description: '备注', required: false })
  @IsString()
  @IsOptional()
  notes?: string;

  @ApiProperty({ description: '标签', required: false, isArray: true })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  tags?: string[];

  @ApiProperty({
    description: '图片文件',
    type: 'string',
    format: 'binary',
    required: false,
  })
  @IsOptional()
  file?: any; // 在 DTO 层面使用 any 或更宽泛的类型，避免全局命名空间冲突

  @ApiProperty({ description: '所属平台ID', example: 'uuid', required: false })
  @IsUUID()
  @IsOptional()
  platformId?: string;

  @ApiProperty({ description: '是否为虚拟物品/订阅', default: false })
  @IsBoolean()
  @IsOptional()
  isVirtual?: boolean;

  @ApiProperty({
    description: '当前周期类型',
    enum: ItemCycleType,
    required: false,
  })
  @IsEnum(ItemCycleType)
  @IsOptional()
  currentCycleType?: ItemCycleType;

  @ApiProperty({ description: '当前周期数值', example: 1, required: false })
  @IsNumber()
  @Type(() => Number)
  @IsOptional()
  @Min(1, { message: '当前周期数值必须大于0' })
  currentCycle?: number;

  @ApiProperty({
    description: '周期计算方式',
    enum: ItemCycleCalculationMode,
    required: false,
  })
  @IsEnum(ItemCycleCalculationMode)
  @IsOptional()
  currentCycleMode?: ItemCycleCalculationMode;

  @ApiProperty({ description: '固定天数周期', example: 30, required: false })
  @IsNumber()
  @Type(() => Number)
  @IsOptional()
  @Min(1, { message: '固定天数必须大于0' })
  currentCycleDays?: number;

  @ApiProperty({
    description: '本期到期日',
    example: '2026-07-11',
    required: false,
  })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  nextBillingDate?: Date;

  @ApiProperty({ description: '是否自动续订', default: false })
  @IsBoolean()
  @IsOptional()
  isAutoRenew?: boolean;

  @ApiProperty({ description: '是否开启到期提醒', default: false })
  @IsBoolean()
  @IsOptional()
  hasReminder?: boolean;

  @ApiProperty({ description: '保修截止日期', example: '2025-12-31' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  warrantyEndDate?: Date;

  @ApiProperty({ description: '是否为闲置或备用', default: false })
  @IsBoolean()
  @IsOptional()
  isBackup?: boolean;

  @ApiProperty({ description: '闲置日期' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  backupDate?: Date;

  @ApiProperty({ description: '是否已报废/停用', default: false })
  @IsBoolean()
  @IsOptional()
  isScrapped?: boolean;

  @ApiProperty({ description: '报废日期' })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  scrappedDate?: Date;
}
