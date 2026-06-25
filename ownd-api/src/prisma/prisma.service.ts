import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { Prisma, PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  constructor() {
    const databaseUrl = process.env.DATABASE_URL;

    // 强制检查：如果没有环境变量，直接拦截
    if (!databaseUrl) {
      throw new Error(
        '【致命错误】环境变量 DATABASE_URL 未定义！请检查 .env.development 文件。',
      );
    }

    const pool = new Pool({ connectionString: databaseUrl });
    const adapter = new PrismaPg(pool);
    super({ adapter });
  }

  async onModuleInit() {
    await this.$connect();
    await this.autoSeedTemplates();
    await this.healCorruptedItems();
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }

  private async autoSeedTemplates() {
    try {
      const categoriesCount = await this.category.count({
        where: { userId: null },
      });
      if (categoriesCount === 0) {
        console.log('检测到系统分类模板为空，正在自动灌入分类模板...');
        const { categories: templateCats } =
          await import('../common/constants/templates.js');

        for (const cat of templateCats) {
          const parent = await this.category.create({
            data: {
              name: cat.name,
              icon: cat.icon,
              userId: null,
            },
          });

          for (const child of [
            ...cat.children,
            { name: '其它', icon: 'MdiIcons.dotsHorizontal' },
          ]) {
            await this.category.create({
              data: {
                name: child.name,
                icon: child.icon,
                parentId: parent.id,
                userId: null,
              },
            });
          }
        }
        console.log('系统分类模板灌包完成。');
      }

      const platformsCount = await this.platform.count({
        where: { userId: null },
      });
      if (platformsCount === 0) {
        console.log('检测到系统平台模板为空，正在自动灌入平台模板...');
        const { platforms: templatePlats } =
          await import('../common/constants/templates.js');

        for (const plat of templatePlats) {
          await this.platform.create({
            data: {
              name: plat.name,
              icon: plat.icon,
              color: plat.color,
              userId: null,
            },
          });
        }
        console.log('系统平台模板灌包完成。');
      }
    } catch (err) {
      console.error('自动灌入模板出错：', err);
    }
  }

  private async healCorruptedItems() {
    try {
      // Find items pointing to template categories or platforms
      const items = await this.item.findMany({
        where: {
          OR: [{ category: { userId: null } }, { platform: { userId: null } }],
        },
        include: {
          category: true,
          platform: true,
        },
      });

      if (items.length === 0) return;

      console.log(
        `[Heal] Found ${items.length} items with template category/platform links. Healing...`,
      );

      // Group items by userId
      const userIds = Array.from(new Set(items.map((item) => item.userId)));

      for (const userId of userIds) {
        // Ensure user categories & platforms are initialized
        await this.ensureUserTemplates(userId);

        // Fetch user categories and platforms
        const userCategories = await this.category.findMany({
          where: { userId },
        });
        const userPlatforms = await this.platform.findMany({
          where: { userId },
        });

        const catMap = new Map(userCategories.map((c) => [c.name, c.id]));
        const platMap = new Map(userPlatforms.map((p) => [p.name, p.id]));

        const userItems = items.filter((item) => item.userId === userId);

        for (const item of userItems) {
          const updateData: Prisma.ItemUncheckedUpdateInput = {};

          if (item.category && item.category.userId === null) {
            const userCatId = catMap.get(item.category.name);
            if (userCatId) {
              updateData.categoryId = userCatId;
            }
          }

          if (item.platform && item.platform.userId === null) {
            const userPlatId = platMap.get(item.platform.name);
            if (userPlatId) {
              updateData.platformId = userPlatId;
            }
          }

          if (Object.keys(updateData).length > 0) {
            await this.item.update({
              where: { id: item.id },
              data: updateData,
            });
            console.log(
              `[Heal] Updated item '${item.name}' with user-specific category/platform.`,
            );
          }
        }
      }
      console.log('[Heal] Healing process completed.');
    } catch (err) {
      console.error('[Heal] Error during healing process:', err);
    }
  }

  private async ensureUserTemplates(userId: string) {
    const user = await this.user.findUnique({
      where: { id: userId },
      select: {
        categoryDefaultsInitialized: true,
        platformDefaultsInitialized: true,
      },
    });

    if (!user) return;

    const categoriesCount = await this.category.count({ where: { userId } });
    if (categoriesCount === 0) {
      console.log(`[Heal] Initializing categories for user ${userId}...`);
      const templates = await this.category.findMany({
        where: { userId: null },
      });
      const idMap = new Map<string, string>();
      for (const template of templates.filter((c) => !c.parentId)) {
        const created = await this.category.create({
          data: {
            name: template.name,
            icon: template.icon,
            isVirtual: template.isVirtual,
            userId,
          },
        });
        idMap.set(template.id, created.id);
      }
      for (const template of templates.filter((c) => c.parentId)) {
        const parentId = template.parentId
          ? idMap.get(template.parentId)
          : undefined;
        if (parentId) {
          const created = await this.category.create({
            data: {
              name: template.name,
              icon: template.icon,
              isVirtual: template.isVirtual,
              parentId,
              userId,
            },
          });
          idMap.set(template.id, created.id);
        }
      }
      await this.user.update({
        where: { id: userId },
        data: { categoryDefaultsInitialized: true },
      });
    }

    const platformsCount = await this.platform.count({ where: { userId } });
    if (platformsCount === 0) {
      console.log(`[Heal] Initializing platforms for user ${userId}...`);
      const templates = await this.platform.findMany({
        where: { userId: null },
      });
      for (const template of templates) {
        await this.platform.create({
          data: {
            name: template.name,
            icon: template.icon,
            color: template.color,
            userId,
          },
        });
      }
      await this.user.update({
        where: { id: userId },
        data: { platformDefaultsInitialized: true },
      });
    }
  }
}
