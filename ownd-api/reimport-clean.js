const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config({ path: '.env.development' });

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error('DATABASE_URL is not defined');
  process.exit(1);
}

const pool = new Pool({ connectionString: databaseUrl });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  const email = '284264018@qq.com';
  
  // 1. Find or create user
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    const hashedPassword = await bcrypt.hash('123456', 10);
    user = await prisma.user.create({
      data: {
        email,
        name: '284264018',
        password: hashedPassword,
        categoryDefaultsInitialized: true,
        platformDefaultsInitialized: true
      }
    });
    console.log(`Created user ${email}`);
  } else {
    console.log(`User ${email} exists (ID: ${user.id})`);
  }

  // 2. Clear existing items and custom categories/platforms to prevent duplicates/conflicts
  console.log('Clearing existing database items and custom categories/platforms for user...');
  await prisma.itemHistory.deleteMany({
    where: { item: { userId: user.id } }
  });
  await prisma.item.deleteMany({
    where: { userId: user.id }
  });
  await prisma.category.deleteMany({
    where: { userId: user.id }
  });
  await prisma.platform.deleteMany({
    where: { userId: user.id }
  });

  // 3. Read imported_backup.json
  const backupPath = path.join(__dirname, '..', 'imported_backup.json');
  if (!fs.existsSync(backupPath)) {
    console.error(`Backup file not found at: ${backupPath}`);
    process.exit(1);
  }
  const backupData = JSON.parse(fs.readFileSync(backupPath, 'utf8'));

  // 4. Copy templates first if needed
  await ensureUserTemplates(prisma, user.id);

  // 5. Restore categories and map them
  const categoryMap = new Map();
  const dbCategories = await prisma.category.findMany({
    where: { OR: [{ userId: user.id }, { userId: null }] }
  });
  for (const cat of dbCategories) {
    categoryMap.set(cat.name, cat.id);
    categoryMap.set(cat.id, cat.id);
  }

  const rawCategories = backupData.categories || [];
  for (const cat of rawCategories) {
    if (cat.name && categoryMap.has(cat.name)) {
      const dbId = categoryMap.get(cat.name);
      if (cat.uuid) {
        categoryMap.set(cat.uuid, dbId);
      }
      continue;
    }
    const newCat = await prisma.category.create({
      data: {
        name: cat.name,
        icon: cat.iconPath || 'MdiIcons.tag',
        userId: user.id
      }
    });
    categoryMap.set(newCat.name, newCat.id);
    if (cat.uuid) {
      categoryMap.set(cat.uuid, newCat.id);
    }
  }

  // 6. Restore platforms
  const platformMap = new Map();
  const dbPlatforms = await prisma.platform.findMany({
    where: { OR: [{ userId: user.id }, { userId: null }] }
  });
  for (const plat of dbPlatforms) {
    platformMap.set(plat.name, plat.id);
  }

  // 7. Insert items
  const rawDevices = backupData.devices || [];
  let successCount = 0;

  for (const dev of rawDevices) {
    let categoryId = null;
    if (dev.categoryUuid) {
      categoryId = categoryMap.get(dev.categoryUuid) || null;
    }
    if (!categoryId && dev.categoryName) {
      categoryId = categoryMap.get(dev.categoryName) || null;
    }

    let platformId = null;
    const platformName = dev.platform || '其它';
    if (platformMap.has(platformName)) {
      platformId = platformMap.get(platformName);
    } else {
      const newPlat = await prisma.platform.create({
        data: {
          name: platformName,
          icon: 'MdiIcons.store',
          color: '#9E9E9E',
          userId: user.id
        }
      });
      platformMap.set(newPlat.name, newPlat.id);
      platformId = newPlat.id;
    }

    const isVirtual =
      dev.isVirtual ||
      dev.cycleType !== undefined ||
      dev.categoryName === '虚拟订阅';

    await prisma.item.create({
      data: {
        id: dev.uuid,
        name: dev.name,
        price: dev.price || 0,
        purchaseDate: dev.purchaseDate ? new Date(dev.purchaseDate) : new Date(),
        notes: dev.notes,
        tags: dev.tags || [],
        imagePath: dev.imagePath,
        isVirtual: !!isVirtual,
        currentCycleType: dev.cycleType || null,
        currentCycle: dev.currentCycle || null,
        nextBillingDate: dev.nextBillingDate ? new Date(dev.nextBillingDate) : null,
        isAutoRenew: dev.isAutoRenew || false,
        isBackup: dev.backupDate !== undefined,
        backupDate: dev.backupDate ? new Date(dev.backupDate) : null,
        isScrapped: dev.scrapDate !== undefined,
        scrappedDate: dev.scrapDate ? new Date(dev.scrapDate) : null,
        warrantyEndDate: dev.warrantyEndDate ? new Date(dev.warrantyEndDate) : null,
        userId: user.id,
        categoryId,
        platformId
      }
    });
    successCount++;
  }

  console.log(`Successfully imported ${successCount} items with category and platform info populated correctly.`);
}

async function ensureUserTemplates(prisma, userId) {
  const categoriesCount = await prisma.category.count({ where: { userId } });
  if (categoriesCount === 0) {
    const templates = await prisma.category.findMany({ where: { userId: null } });
    const idMap = new Map();
    for (const template of templates.filter(c => !c.parentId)) {
      const created = await prisma.category.create({
        data: { name: template.name, icon: template.icon, isVirtual: template.isVirtual, userId }
      });
      idMap.set(template.id, created.id);
    }
    for (const template of templates.filter(c => c.parentId)) {
      const parentId = template.parentId ? idMap.get(template.parentId) : undefined;
      if (parentId) {
        const created = await prisma.category.create({
          data: { name: template.name, icon: template.icon, isVirtual: template.isVirtual, parentId, userId }
        });
        idMap.set(template.id, created.id);
      }
    }
    await prisma.user.update({ where: { id: userId }, data: { categoryDefaultsInitialized: true } });
    console.log('Categories initialized from templates');
  }

  const platformsCount = await prisma.platform.count({ where: { userId } });
  if (platformsCount === 0) {
    const templates = await prisma.platform.findMany({ where: { userId: null } });
    for (const template of templates) {
      await prisma.platform.create({
        data: { name: template.name, icon: template.icon, color: template.color, userId }
      });
    }
    await prisma.user.update({ where: { id: userId }, data: { platformDefaultsInitialized: true } });
    console.log('Platforms initialized from templates');
  }
}

main()
  .catch(e => console.error('Error during import script:', e))
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
