import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateItemDto } from './dto/create-item.dto';
import { UpdateItemDto } from './dto/update-item.dto';

@Injectable()
export class ItemsService {
  constructor(private prisma: PrismaService) {}

  async create(userId: string, createItemDto: CreateItemDto) {
    const { file: _, ...data } = createItemDto;
    return this.prisma.item.create({
      data: {
        ...data,
        userId: userId,
      },
    });
  }

  async findAll(userId: string) {
    return this.prisma.item.findMany({
      where: {
        userId: userId,
      },
      include: {
        category: true,
      },
    });
  }

  async findOne(id: string, userId: string) {
    const item = await this.prisma.item.findFirst({
      where: {
        id,
        userId, // 关键：只能查询属于自己的物品
      },
      include: {
        category: true,
      },
    });

    if (!item) {
      throw new NotFoundException(`物品 ID ${id} 不存在或无权访问`);
    }

    return item;
  }

  async update(id: string, userId: string, updateItemDto: UpdateItemDto) {
    // 【地雷区】：我在这里故意只用了 id 来查询。
    // 如果不加上 userId，任何登录用户都能修改其他人的物品吗？请尝试修复它。
    return this.prisma.item.update({
      where: { id, userId },
      data: { ...updateItemDto },
    });
  }

  async remove(id: string, userId: string) {
    // 【地雷区】：同上，这里也漏掉了归属权校验。
    return this.prisma.item.delete({
      where: { id, userId },
    });
  }

  async updateImagePath(id: string, userId: string, imagePath: string) {
    // 通过 id 和 userId 进行双重校验，确保你改的是自己的东西
    return this.prisma.item.update({
      where: { id, userId },
      data: { imagePath },
    });
  }
}
