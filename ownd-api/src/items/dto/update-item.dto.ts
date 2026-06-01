import { PartialType } from '@nestjs/swagger';
import { CreateItemDto } from './create-item.dto';

// PartialType 会自动将 CreateItemDto 中的所有字段变为可选 (@IsOptional)
// 这在进行 PATCH 更新时非常方便
export class UpdateItemDto extends PartialType(CreateItemDto) {}
