import {
  Inject,
  Injectable,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePlatformDto } from './dto/create-platform.dto';
import { UpdatePlatformDto } from './dto/update-platform.dto';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import * as cacheManager from 'cache-manager';
import { platforms as platformTemplates } from '../common/constants/templates';

const platformOrder = new Map(
  platformTemplates.map((platform, index) => [platform.name, index]),
);
platformOrder.set('抖音电商', platformOrder.get('抖音') ?? 0);

@Injectable()
export class PlatformService {
  constructor(
    private prisma: PrismaService,
    @Inject(CACHE_MANAGER) private cacheManager: cacheManager.Cache,
  ) {}

  async create(userId: string, createPlatformDto: CreatePlatformDto) {
    const result = await this.prisma.platform.create({
      data: {
        ...createPlatformDto,
        userId,
      },
    });
    await this.clearCache(userId);
    return result;
  }

  async findAll(userId: string) {
    const defaultsChanged = await this.ensureUserDefaultPlatforms(userId);
    const normalized = await this.normalizeUserPlatforms(userId);
    const cacheKey = `user:platforms:${userId}`;
    const shouldBypassCache = defaultsChanged || normalized;

    if (shouldBypassCache) {
      await this.clearCache(userId);
    } else {
      try {
        const cached =
          await this.cacheManager.get<import('@prisma/client').Platform[]>(
            cacheKey,
          );
        if (cached) {
          return this.sortPlatforms(cached);
        }
      } catch {
        // ignore
      }
    }

    const platforms = this.sortPlatforms(
      await this.prisma.platform.findMany({
        where: {
          userId,
        },
        orderBy: {
          createdAt: 'asc',
        },
      }),
    );

    try {
      await this.cacheManager.set(cacheKey, platforms, 600000); // 缓存 10 分钟
    } catch {
      // ignore
    }

    return platforms;
  }

  async findOne(id: string, userId: string) {
    const platform = await this.prisma.platform.findUnique({
      where: { id },
    });

    if (!platform) {
      throw new NotFoundException('平台不存在');
    }

    if (platform.userId !== userId) {
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

    if (platform.userId !== userId) {
      throw new ForbiddenException('你没有权限修改此平台');
    }

    const result = await this.prisma.platform.update({
      where: { id },
      data: updatePlatformDto,
    });
    await this.clearCache(userId);
    return result;
  }

  async remove(id: string, userId: string) {
    const platform = await this.prisma.platform.findUnique({
      where: { id },
    });

    if (!platform) {
      throw new NotFoundException('平台不存在');
    }

    if (platform.userId !== userId) {
      throw new ForbiddenException('你没有权限删除此平台');
    }

    const result = await this.prisma.platform.delete({
      where: { id },
    });
    await this.clearCache(userId);
    return result;
  }

  private async clearCache(userId: string) {
    try {
      await this.cacheManager.del(`user:platforms:${userId}`);
    } catch {
      // ignore
    }
  }

  private async ensureUserDefaultPlatforms(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { platformDefaultsInitialized: true },
    });

    if (!user) {
      throw new NotFoundException('用户不存在');
    }

    let changed = false;
    const existingUserPlatforms = await this.prisma.platform.count({
      where: { userId },
    });

    if (existingUserPlatforms === 0) {
      await this.copySystemPlatformTemplates(userId);
      changed = true;
    }

    if (!user.platformDefaultsInitialized) {
      await this.prisma.user.update({
        where: { id: userId },
        data: { platformDefaultsInitialized: true },
      });
    }

    return changed;
  }

  private async copySystemPlatformTemplates(userId: string) {
    const templates = await this.prisma.platform.findMany({
      where: { userId: null },
      orderBy: { createdAt: 'asc' },
    });

    for (const template of templates) {
      await this.prisma.platform.create({
        data: {
          name: template.name,
          icon: template.icon,
          color: template.color,
          userId,
        },
      });
    }
  }

  private async normalizeUserPlatforms(userId: string) {
    const platforms = await this.prisma.platform.findMany({
      where: { userId, name: { in: ['抖音电商', '抖音'] } },
      orderBy: { createdAt: 'asc' },
    });
    if (platforms.length === 0) return false;

    let changed = false;
    const keep =
      platforms.find((platform) => platform.name === '抖音') ?? platforms[0];
    if (keep.name !== '抖音') {
      await this.prisma.platform.update({
        where: { id: keep.id },
        data: { name: '抖音' },
      });
      changed = true;
    }

    for (const platform of platforms) {
      if (platform.id === keep.id) continue;
      await this.prisma.item.updateMany({
        where: { userId, platformId: platform.id },
        data: { platformId: keep.id },
      });
      await this.prisma.platform.delete({ where: { id: platform.id } });
      changed = true;
    }

    return changed;
  }

  private sortPlatforms<T extends { name: string; createdAt: Date }>(
    platforms: T[],
  ) {
    return [...platforms].sort((a, b) => {
      if (a.name === '其它' && b.name !== '其它') return 1;
      if (a.name !== '其它' && b.name === '其它') return -1;
      const orderA = platformOrder.get(a.name);
      const orderB = platformOrder.get(b.name);
      if (orderA !== undefined && orderB !== undefined) return orderA - orderB;
      if (orderA !== undefined) return -1;
      if (orderB !== undefined) return 1;
      return a.createdAt.getTime() - b.createdAt.getTime();
    });
  }
}
