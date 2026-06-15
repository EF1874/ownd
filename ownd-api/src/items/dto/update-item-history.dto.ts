import { PartialType } from '@nestjs/swagger';
import { CreateItemHistoryDto } from './create-item-history.dto';

export class UpdateItemHistoryDto extends PartialType(CreateItemHistoryDto) {}
