import { ApiProperty } from '@nestjs/swagger';
import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsDate,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';
import { ItemCycleType, ItemRecordType } from '@prisma/client';

export class CreateItemHistoryDto {
  @ApiProperty({ description: '记录类型', enum: ItemRecordType })
  @IsEnum(ItemRecordType)
  type: ItemRecordType;

  @ApiProperty({ description: '变动金额', example: 99.0 })
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty({ description: '记录日期', required: false })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  recordDate?: Date;

  @ApiProperty({ description: '备注', required: false })
  @IsString()
  @IsOptional()
  note?: string;

  // 以下为 RENEWAL 类型专属字段
  @ApiProperty({ description: '周期开始日期 (续费专用)', required: false })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  startDate?: Date;

  @ApiProperty({ description: '周期结束日期 (续费专用)', required: false })
  @IsOptional()
  @Type(() => Date)
  @IsDate()
  endDate?: Date;

  @ApiProperty({
    description: '周期类型 (续费专用)',
    enum: ItemCycleType,
    required: false,
  })
  @IsOptional()
  @IsEnum(ItemCycleType)
  cycleType?: ItemCycleType;

  @ApiProperty({ description: '周期数值 (续费专用)', required: false })
  @IsOptional()
  @IsNumber()
  @Min(1)
  cycle?: number;
}
