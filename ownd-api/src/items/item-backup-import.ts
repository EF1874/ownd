import { randomUUID } from 'crypto';
import {
  ItemCycleCalculationMode,
  ItemCycleType,
  ItemRecordType,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type BackupCategory = {
  uuid?: string;
  name?: string;
  iconPath?: string | null;
};

type BackupHistory = {
  type?: ItemRecordType | null;
  price?: number | null;
  startDate?: string | Date | null;
  endDate?: string | Date | null;
  cycleType?: ItemCycleType | null;
  cycle?: number | null;
  cycleMode?: ItemCycleCalculationMode | null;
  cycleDays?: number | null;
  recordDate?: string | Date | null;
  note?: string | null;
  isAutoRenew?: boolean | null;
};

type BackupDevice = {
  uuid?: string;
  name: string;
  price?: number | null;
  renewalPrice?: number | null;
  purchaseDate?: string | Date | null;
  notes?: string | null;
  tags?: string[];
  imagePath?: string | null;
  categoryUuid?: string | null;
  categoryName?: string | null;
  platform?: string | null;
  isVirtual?: boolean | null;
  cycleType?: ItemCycleType | null;
  currentCycle?: number | null;
  cycleMode?: ItemCycleCalculationMode | null;
  cycleDays?: number | null;
  nextBillingDate?: string | Date | null;
  isAutoRenew?: boolean | null;
  hasReminder?: boolean | null;
  backupDate?: string | Date | null;
  scrapDate?: string | Date | null;
  warrantyEndDate?: string | Date | null;
  history?: BackupHistory[];
};

export type BackupData = {
  categories?: BackupCategory[];
  devices?: BackupDevice[];
};

export async function importItemsBackup(
  prisma: PrismaService,
  userId: string,
  data: BackupData,
) {
  let createdCount = 0;
  let updatedCount = 0;
  const duplicates: string[] = [];

  await prisma.$transaction(async (tx) => {
    // 0. Ensure user templates are copied first inside the transaction
    const categoriesCount = await tx.category.count({ where: { userId } });
    if (categoriesCount === 0) {
      const templates = await tx.category.findMany({
        where: { userId: null },
      });
      const idMap = new Map<string, string>();
      for (const template of templates.filter((c) => !c.parentId)) {
        const created = await tx.category.create({
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
          const created = await tx.category.create({
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
      await tx.user.update({
        where: { id: userId },
        data: { categoryDefaultsInitialized: true },
      });
    }

    const platformsCount = await tx.platform.count({ where: { userId } });
    if (platformsCount === 0) {
      const templates = await tx.platform.findMany({
        where: { userId: null },
      });
      for (const template of templates) {
        await tx.platform.create({
          data: {
            name: template.name,
            icon: template.icon,
            color: template.color,
            userId,
          },
        });
      }
      await tx.user.update({
        where: { id: userId },
        data: { platformDefaultsInitialized: true },
      });
    }

    // 1. Restore categories
    const existingCategories = await tx.category.findMany({
      where: { OR: [{ userId }, { userId: null }] },
    });
    const userCategories = existingCategories.filter((c) => c.userId !== null);
    const templateCategories = existingCategories.filter(
      (c) => c.userId === null,
    );

    const userCategoryMap = new Map<string, string>(); // name -> id, id -> id
    for (const cat of userCategories) {
      userCategoryMap.set(cat.name, cat.id);
      userCategoryMap.set(cat.id, cat.id);
    }

    const templateCategoryMap = new Map<string, string>(); // id -> name, name -> name
    for (const cat of templateCategories) {
      templateCategoryMap.set(cat.id, cat.name);
      templateCategoryMap.set(cat.name, cat.name);
    }

    const rawCategories = data.categories ?? [];
    for (const cat of rawCategories) {
      if (!cat.name) continue;

      // If the user already has a category with this name, map cat.uuid to the user's category ID.
      if (userCategoryMap.has(cat.name)) {
        const userCatId = userCategoryMap.get(cat.name)!;
        if (cat.uuid) {
          userCategoryMap.set(cat.uuid, userCatId);
        }
        continue;
      }

      // Otherwise, check if there is a template category with this name.
      const templateCat = templateCategories.find((c) => c.name === cat.name);
      if (templateCat) {
        // Find or create parent if template category has a parent
        let parentId: string | null = null;
        if (templateCat.parentId) {
          const templateParent = templateCategories.find(
            (c) => c.id === templateCat.parentId,
          );
          if (templateParent) {
            // Ensure the parent is copied to the user's categories first
            if (userCategoryMap.has(templateParent.name)) {
              parentId = userCategoryMap.get(templateParent.name)!;
            } else {
              const newParent = await tx.category.create({
                data: {
                  name: templateParent.name,
                  icon: templateParent.icon,
                  isVirtual: templateParent.isVirtual,
                  userId,
                },
              });
              userCategoryMap.set(newParent.name, newParent.id);
              userCategoryMap.set(newParent.id, newParent.id);
              parentId = newParent.id;
            }
          }
        }

        // Create the user's copy of the template category
        const newCat = await tx.category.create({
          data: {
            name: cat.name,
            icon: cat.iconPath || templateCat.icon || 'MdiIcons.tag',
            isVirtual: templateCat.isVirtual,
            userId,
            parentId,
          },
        });
        userCategoryMap.set(newCat.name, newCat.id);
        userCategoryMap.set(newCat.id, newCat.id);
        if (cat.uuid) {
          userCategoryMap.set(cat.uuid, newCat.id);
        }
      } else {
        // Create custom category for the user
        const newCat = await tx.category.create({
          data: {
            name: cat.name,
            icon: cat.iconPath || 'MdiIcons.tag',
            userId,
          },
        });
        userCategoryMap.set(newCat.name, newCat.id);
        userCategoryMap.set(newCat.id, newCat.id);
        if (cat.uuid) {
          userCategoryMap.set(cat.uuid, newCat.id);
        }
      }
    }

    // 2. Restore platforms
    const existingPlatforms = await tx.platform.findMany({
      where: { OR: [{ userId }, { userId: null }] },
    });
    const userPlatforms = existingPlatforms.filter((p) => p.userId !== null);
    const templatePlatforms = existingPlatforms.filter(
      (p) => p.userId === null,
    );

    const userPlatformMap = new Map<string, string>(); // name -> id, id -> id
    for (const plat of userPlatforms) {
      userPlatformMap.set(plat.name, plat.id);
      userPlatformMap.set(plat.id, plat.id);
    }

    const templatePlatformMap = new Map<string, string>(); // id -> name, name -> name
    for (const plat of templatePlatforms) {
      templatePlatformMap.set(plat.id, plat.name);
      templatePlatformMap.set(plat.name, plat.name);
    }

    // 3. Process devices
    const processedIds: string[] = [];

    const rawDevices = data.devices ?? [];

    for (const dev of rawDevices) {
      const oldUuid = dev.uuid;

      let itemUuid = oldUuid ?? randomUUID();
      let isUpdate = false;

      const purchaseDate = dev.purchaseDate
        ? new Date(dev.purchaseDate)
        : new Date();

      if (oldUuid) {
        const existingItem = await tx.item.findUnique({
          where: { id: oldUuid },
          select: { userId: true },
        });
        if (existingItem) {
          if (existingItem.userId === userId) {
            isUpdate = true;
          } else {
            // Belongs to someone else, check for duplicate first to prevent duplicate imports
            const existingDuplicate = await tx.item.findFirst({
              where: {
                userId,
                name: dev.name,
                price: dev.price || 0,
                purchaseDate: purchaseDate,
                id: { notIn: processedIds },
              },
              select: { id: true },
            });
            if (existingDuplicate) {
              itemUuid = existingDuplicate.id;
              isUpdate = true;
            } else {
              itemUuid = randomUUID();
            }
          }
        } else {
          // UUID doesn't exist, check for duplicate first to prevent duplicate imports
          const existingDuplicate = await tx.item.findFirst({
            where: {
              userId,
              name: dev.name,
              price: dev.price || 0,
              purchaseDate: purchaseDate,
              id: { notIn: processedIds },
            },
            select: { id: true },
          });
          if (existingDuplicate) {
            itemUuid = existingDuplicate.id;
            isUpdate = true;
          }
        }
      } else {
        // No UUID in backup, check for duplicate first to prevent duplicate imports
        const existingDuplicate = await tx.item.findFirst({
          where: {
            userId,
            name: dev.name,
            price: dev.price || 0,
            purchaseDate: purchaseDate,
            id: { notIn: processedIds },
          },
          select: { id: true },
        });
        if (existingDuplicate) {
          itemUuid = existingDuplicate.id;
          isUpdate = true;
        } else {
          itemUuid = randomUUID();
        }
      }

      processedIds.push(itemUuid);

      if (isUpdate) {
        updatedCount++;
        if (!duplicates.includes(dev.name)) {
          duplicates.push(dev.name);
        }
      } else {
        createdCount++;
      }

      // Resolve Category to user-owned Category
      let categoryId: string | null = null;

      // 1. Try resolving using categoryUuid from backup
      if (dev.categoryUuid) {
        if (userCategoryMap.has(dev.categoryUuid)) {
          categoryId = userCategoryMap.get(dev.categoryUuid)!;
        } else if (templateCategoryMap.has(dev.categoryUuid)) {
          const templateName = templateCategoryMap.get(dev.categoryUuid)!;
          if (userCategoryMap.has(templateName)) {
            categoryId = userCategoryMap.get(templateName)!;
          }
        }
      }

      // 2. Try resolving using categoryName from backup
      if (!categoryId && dev.categoryName) {
        if (userCategoryMap.has(dev.categoryName)) {
          categoryId = userCategoryMap.get(dev.categoryName)!;
        } else if (templateCategoryMap.has(dev.categoryName)) {
          const templateName = templateCategoryMap.get(dev.categoryName)!;
          // Copy template category to user categories if missing
          const templateCat = templateCategories.find(
            (c) => c.name === templateName,
          );
          if (templateCat) {
            let parentId: string | null = null;
            if (templateCat.parentId) {
              const templateParent = templateCategories.find(
                (c) => c.id === templateCat.parentId,
              );
              if (templateParent) {
                if (userCategoryMap.has(templateParent.name)) {
                  parentId = userCategoryMap.get(templateParent.name)!;
                } else {
                  const newParent = await tx.category.create({
                    data: {
                      name: templateParent.name,
                      icon: templateParent.icon,
                      isVirtual: templateParent.isVirtual,
                      userId,
                    },
                  });
                  userCategoryMap.set(newParent.name, newParent.id);
                  userCategoryMap.set(newParent.id, newParent.id);
                  parentId = newParent.id;
                }
              }
            }

            const newCat = await tx.category.create({
              data: {
                name: templateCat.name,
                icon: templateCat.icon,
                isVirtual: templateCat.isVirtual,
                userId,
                parentId,
              },
            });
            userCategoryMap.set(newCat.name, newCat.id);
            userCategoryMap.set(newCat.id, newCat.id);
            categoryId = newCat.id;
          }
        }
      }

      // Resolve Platform to user-owned Platform
      let platformId: string | null = null;
      if (dev.platform) {
        if (userPlatformMap.has(dev.platform)) {
          platformId = userPlatformMap.get(dev.platform)!;
        } else if (templatePlatformMap.has(dev.platform)) {
          // Find template platform and copy it for the user
          const templateName = templatePlatformMap.get(dev.platform)!;
          const templatePlat = templatePlatforms.find(
            (p) => p.name === templateName,
          );
          if (templatePlat) {
            const newPlat = await tx.platform.create({
              data: {
                name: templatePlat.name,
                icon: templatePlat.icon,
                color: templatePlat.color,
                userId,
              },
            });
            userPlatformMap.set(newPlat.name, newPlat.id);
            userPlatformMap.set(newPlat.id, newPlat.id);
            platformId = newPlat.id;
          }
        } else {
          // Create a custom platform for this user
          const newPlat = await tx.platform.create({
            data: {
              name: dev.platform,
              icon: 'MdiIcons.store',
              color: '#9E9E9E',
              userId,
            },
          });
          userPlatformMap.set(newPlat.name, newPlat.id);
          userPlatformMap.set(newPlat.id, newPlat.id);
          platformId = newPlat.id;
        }
      }

      const isVirtual =
        dev.isVirtual ||
        dev.cycleType !== undefined ||
        dev.categoryName === '虚拟订阅';

      let nextBillingDate: Date | null = null;
      if (dev.nextBillingDate) nextBillingDate = new Date(dev.nextBillingDate);

      const itemData = {
        name: dev.name,
        price: dev.price || 0,
        renewalPrice: dev.renewalPrice ?? null,
        purchaseDate,
        notes: dev.notes,
        tags: dev.tags || [],
        imagePath: dev.imagePath,
        isVirtual,
        currentCycleType: dev.cycleType || null,
        currentCycle: dev.currentCycle || null,
        currentCycleMode: dev.cycleMode || ItemCycleCalculationMode.CALENDAR,
        currentCycleDays: dev.cycleDays || null,
        nextBillingDate,
        isAutoRenew: dev.isAutoRenew || false,
        hasReminder: dev.hasReminder || false,
        isBackup: !!dev.backupDate,
        backupDate: dev.backupDate ? new Date(dev.backupDate) : null,
        isScrapped: !!dev.scrapDate,
        scrappedDate: dev.scrapDate ? new Date(dev.scrapDate) : null,
        warrantyEndDate: dev.warrantyEndDate
          ? new Date(dev.warrantyEndDate)
          : null,
        userId,
        categoryId,
        platformId,
      };

      if (isUpdate) {
        // Overwrite / Update existing item
        await tx.item.update({
          where: { id: itemUuid },
          data: itemData,
        });
        // Delete existing history to replace it with backup history
        await tx.itemHistory.deleteMany({
          where: { itemId: itemUuid },
        });
      } else {
        // Create new item
        await tx.item.create({
          data: {
            id: itemUuid,
            ...itemData,
          },
        });
      }

      const rawHistory = dev.history ?? [];
      if (rawHistory.length > 0) {
        await tx.itemHistory.createMany({
          data: rawHistory.map((h) => ({
            type: h.type || ItemRecordType.RENEWAL,
            price: h.price || 0,
            startDate: h.startDate ? new Date(h.startDate) : null,
            endDate: h.endDate ? new Date(h.endDate) : null,
            cycleType: h.cycleType || null,
            cycle: h.cycle || null,
            cycleMode:
              h.cycleMode || dev.cycleMode || ItemCycleCalculationMode.CALENDAR,
            cycleDays: h.cycleDays || dev.cycleDays || null,
            recordDate: h.recordDate ? new Date(h.recordDate) : new Date(),
            note: h.note,
            isAutoRenew:
              h.isAutoRenew === true ||
              (typeof h.note === 'string' && h.note.startsWith('自动续费')),
            itemId: itemUuid,
          })),
        });
      }
    }
  });
  return {
    createdCount,
    updatedCount,
    duplicates,
  };
}
