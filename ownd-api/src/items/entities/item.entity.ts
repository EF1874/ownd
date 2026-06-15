import { ApiProperty } from '@nestjs/swagger';
import { Item, ItemCycleCalculationMode, ItemCycleType } from '@prisma/client';
import { CategoryEntity } from '../../categories/entities/category.entity';
import { PlatformEntity } from '../../platform/entities/platform.entity';
import { ItemHistoryEntity } from './item-history.entity';
import { Type } from 'class-transformer';

export class ItemEntity implements Item {
  @ApiProperty({ description: '物品ID', example: 'uuid' })
  id: string;

  @ApiProperty({ description: '物品名称', example: '手机' })
  name: string;

  @ApiProperty({ description: '物品价格', example: 1000 })
  price: number;

  @ApiProperty({ description: '续费价格', example: 20, nullable: true })
  renewalPrice: number | null;

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

  @ApiProperty({
    description: '平台ID',
    example: 'platform-uuid',
    nullable: true,
  })
  platformId: string | null;

  @ApiProperty({
    description: '平台详情',
    type: () => PlatformEntity,
    nullable: true,
  })
  platform?: PlatformEntity;

  @ApiProperty({ description: '周期类型', enum: ItemCycleType, nullable: true })
  currentCycleType: ItemCycleType | null;

  @ApiProperty({ description: '当前周期', nullable: true })
  currentCycle: number | null;

  @ApiProperty({
    description: '周期计算方式',
    enum: ItemCycleCalculationMode,
  })
  currentCycleMode: ItemCycleCalculationMode;

  @ApiProperty({ description: '固定天数周期', nullable: true })
  currentCycleDays: number | null;

  @ApiProperty({ description: '下一个账单日期', nullable: true })
  nextBillingDate: Date | null;

  @ApiProperty({ description: '是否自动续订', default: false })
  isAutoRenew: boolean;

  @ApiProperty({ description: '提前提醒天数，0 表示不提醒', default: 0 })
  reminderDays: number;

  @ApiProperty({
    description: '是否为闲置或备用',
    default: false,
  })
  isBackup: boolean;

  @ApiProperty({ description: '闲置日期', nullable: true })
  backupDate: Date | null;

  @ApiProperty({
    description: '是否已停用或处理',
    default: false,
  })
  isScrapped: boolean;

  @ApiProperty({ description: '报废日期', nullable: true })
  scrappedDate: Date | null;

  @ApiProperty({ description: '过保日期', nullable: true })
  warrantyEndDate: Date | null;

  @ApiProperty({ description: '是否为虚拟物品/订阅', default: false })
  isVirtual: boolean;

  @ApiProperty({
    description: '物品历史记录',
    type: () => [ItemHistoryEntity],
  })
  @Type(() => ItemHistoryEntity)
  itemHistories: ItemHistoryEntity[];
}
