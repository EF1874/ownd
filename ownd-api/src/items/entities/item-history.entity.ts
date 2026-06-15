import { ApiProperty } from '@nestjs/swagger';
import {
  ItemHistory,
  ItemRecordType,
  ItemCycleType,
  ItemCycleCalculationMode,
} from '@prisma/client';

export class ItemHistoryEntity implements ItemHistory {
  @ApiProperty({ description: '记录ID', example: 'uuid' })
  id: string;

  @ApiProperty({ description: '记录类型', enum: ItemRecordType })
  type: ItemRecordType;

  @ApiProperty({ description: '金额', example: 15.0 })
  price: number;

  @ApiProperty({ description: '所属物品ID' })
  itemId: string;

  @ApiProperty({ description: '记录日期', required: false, nullable: true })
  recordDate: Date | null;

  @ApiProperty({ description: '周期开始日期', required: false, nullable: true })
  startDate: Date | null;

  @ApiProperty({ description: '周期结束日期', required: false, nullable: true })
  endDate: Date | null;

  @ApiProperty({
    description: '周期类型',
    enum: ItemCycleType,
    required: false,
    nullable: true,
  })
  cycleType: ItemCycleType | null;

  @ApiProperty({ description: '周期数值', required: false, nullable: true })
  cycle: number | null;

  @ApiProperty({ description: '周期计算方式', enum: ItemCycleCalculationMode })
  cycleMode: ItemCycleCalculationMode;

  @ApiProperty({ description: '固定天数周期', required: false, nullable: true })
  cycleDays: number | null;

  @ApiProperty({ description: '备注', required: false, nullable: true })
  note: string | null;

  @ApiProperty({ description: '是否由系统自动续费生成' })
  isAutoRenew: boolean;

  @ApiProperty({ description: '创建时间' })
  createdAt: Date;

  @ApiProperty({ description: '更新时间' })
  updatedAt: Date;
}
