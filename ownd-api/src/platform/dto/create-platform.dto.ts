import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNotEmpty, IsHexColor } from 'class-validator';

export class CreatePlatformDto {
  @ApiProperty({ description: '平台名称', example: '京东' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ description: '平台图标', example: 'shopping-cart' })
  @IsString()
  @IsNotEmpty()
  icon: string;

  @ApiProperty({ description: '主题颜色 (Hex)', example: '#FF0000' })
  @IsHexColor()
  @IsNotEmpty()
  color: string;
}
