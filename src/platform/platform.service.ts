import {
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePlatformDto } from './dto/create-platform.dto';
import { UpdatePlatformDto } from './dto/update-platform.dto';

@Injectable()
export class PlatformService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createPlatformDto: CreatePlatformDto) {
    return this.prisma.platform.create({
      data: {
        ...createPlatformDto,
        userId,
      },
    });
  }

  async findAll(userId: string) {
    return this.prisma.platform.findMany({
      where: {
        OR: [{ userId: null }, { userId: userId }],
      },
      orderBy: {
        createdAt: 'asc',
      },
    });
  }

  async findOne(id: string, userId: string) {
    const platform = await this.prisma.platform.findUnique({
      where: { id },
    });

    if (!platform) {
      throw new NotFoundException('平台不存在');
    }

    // 鉴权：只能查看系统的或自己的
    if (platform.userId !== null && platform.userId !== userId) {
      throw new ForbiddenException('你没有权限查看此平台');
    }

    return platform;
  }

  async update(
    id: string,
    userId: string,
    updatePlatformDto: UpdatePlatformDto,
  ) {
    const platform = await this.prisma.platform.findUnique({
      where: { id },
    });

    if (!platform) {
      throw new NotFoundException('平台不存在');
    }

    // 关键逻辑：系统预设平台禁止修改
    if (platform.userId === null) {
      throw new ForbiddenException('系统预设平台禁止修改');
    }

    // 关键逻辑：不能修改他人的私有平台
    if (platform.userId !== userId) {
      throw new ForbiddenException('你没有权限修改此平台');
    }

    return this.prisma.platform.update({
      where: { id },
      data: updatePlatformDto,
    });
  }

  async remove(id: string, userId: string) {
    const platform = await this.prisma.platform.findUnique({
      where: { id },
    });

    if (!platform) {
      throw new NotFoundException('平台不存在');
    }

    // 关键逻辑：系统预设平台禁止删除
    if (platform.userId === null) {
      throw new ForbiddenException('系统预设平台禁止删除');
    }

    if (platform.userId !== userId) {
      throw new ForbiddenException('你没有权限删除此平台');
    }

    return this.prisma.platform.delete({
      where: { id },
    });
  }
}
