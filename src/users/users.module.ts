import { Module } from '@nestjs/common';
import { UsersService } from './users.service';

@Module({
  providers: [UsersService],
  exports: [UsersService], // 必须导出，否则 AuthModule 找不到它
})
export class UsersModule {}
