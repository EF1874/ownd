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
    const { file: _file, ...data } = updateItemDto;
    return this.prisma.item.update({
      where: { id, userId },
      data: data,
    });
  }

  async remove(id: string, userId: string) {
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
