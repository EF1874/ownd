const fs = require('fs');
const path = require('path');
const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config({ path: '.env.development' });
const databaseUrl = process.env.DATABASE_URL;

const rawData = {
  "devices": [
    {
      "uuid": "0b21514d-3a0e-4f4a-a2ab-87d924d26955",
      "name": "小米",
      "categoryName": "手机",
      "price": 606,
      "purchaseDate": "2025-12-08T10:09:21.821103",
      "platform": "",
      "warrantyEndDate": null,
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 606,
      "history": []
    },
    {
      "uuid": "fd50caeb-6d75-49a1-8584-23ab6d4a5bf9",
      "name": "小米14",
      "categoryName": "手机",
      "price": 4606,
      "purchaseDate": "2023-11-07T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2024-11-06T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": false,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 4606,
      "history": []
    },
    {
      "uuid": "13726ceb-ce6e-4c9b-a262-84e4b9cdd4b3",
      "name": "Thinkbook 14+",
      "categoryName": "笔记本电脑",
      "price": 7989,
      "purchaseDate": "2023-05-14T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2025-05-13T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 7989,
      "history": []
    },
    {
      "uuid": "5ea906c0-5687-4896-8833-b5cdd5429fc2",
      "name": "电竞叛客 RTX5070Ti X3W Max",
      "categoryName": "显卡 (GPU)",
      "price": 5749,
      "purchaseDate": "2025-11-11T00:00:00.000",
      "platform": "抖音",
      "warrantyEndDate": "2028-11-01T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 5749,
      "history": []
    },
    {
      "uuid": "92cce67e-be9a-4827-8338-c75d304513a1",
      "name": "索尼WH-1000XM4",
      "categoryName": "头戴式耳机",
      "price": 2495,
      "purchaseDate": "2021-01-23T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2022-01-22T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 2495,
      "history": []
    },
    {
      "uuid": "c6ed083c-c742-464d-92fb-17ebdaea84f2",
      "name": "索尼WF-1000XM4",
      "categoryName": "入耳式耳机/AirPods",
      "price": 1269,
      "purchaseDate": "2021-11-01T00:00:00.000",
      "platform": "拼多多",
      "warrantyEndDate": "2022-10-31T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 1269,
      "history": []
    },
    {
      "uuid": "e657ce25-2035-4722-828f-8f891cba02b8",
      "name": "iphone SE 3",
      "categoryName": "手机",
      "price": 3698,
      "purchaseDate": "2022-06-04T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2023-06-03T00:00:00.000",
      "scrapDate": null,
      "backupDate": "2023-11-07T00:00:00.000",
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": false,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 3698,
      "history": []
    },
    {
      "uuid": "ab56d9ac-4a3d-4a77-8a29-e938a46a8f3e",
      "name": "索尼Xperia 5 ii",
      "categoryName": "手机",
      "price": 5135,
      "purchaseDate": "2020-11-25T00:00:00.000",
      "platform": "闲鱼",
      "warrantyEndDate": "2021-10-01T00:00:00.000",
      "scrapDate": null,
      "backupDate": "2022-06-04T00:00:00.000",
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": false,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 5135,
      "history": []
    },
    {
      "uuid": "6f208a68-d63d-4c12-93ee-90ff00dfc935",
      "name": "主机（CPU内存电源等等）",
      "categoryName": "台式主机",
      "price": 6666.3,
      "purchaseDate": "2025-05-16T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": null,
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 6666.3,
      "history": []
    },
    {
      "uuid": "19baa1d5-1726-462f-9162-4dcfb0434937",
      "name": "HKC 27寸显示器",
      "categoryName": "显示器",
      "price": 648.98,
      "purchaseDate": "2025-05-24T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2026-05-23T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": false,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 648.98,
      "history": []
    },
    {
      "uuid": "b1f152ac-f808-4d00-922c-8542c522e073",
      "name": "飞利浦 32寸显示器",
      "categoryName": "显示器",
      "price": 2799,
      "purchaseDate": "2021-07-23T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2022-07-22T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": false,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 2799,
      "history": []
    },
    {
      "uuid": "6c609a3d-7397-46b2-a4c3-e37df3ba64ce",
      "name": "速比特公路车",
      "categoryName": "自行车",
      "price": 6999,
      "purchaseDate": "2024-04-03T00:00:00.000",
      "platform": "线下实体店",
      "warrantyEndDate": null,
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 6999,
      "history": []
    },
    {
      "uuid": "ae412d6c-ff86-471f-be9e-073c1ac595e1",
      "name": "美的热水器",
      "categoryName": "热水器",
      "price": 959.15,
      "purchaseDate": "2025-10-02T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2033-10-01T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 959.15,
      "history": []
    },
    {
      "uuid": "3a3dac24-2744-4252-87a9-1b58e2807dca",
      "name": "小米骨传导耳机",
      "categoryName": "头戴式耳机",
      "price": 379.75,
      "purchaseDate": "2025-05-02T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2026-05-01T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 379.75,
      "history": []
    },
    {
      "uuid": "6520506e-9d40-489a-abcb-ef08a743a4ac",
      "name": "拜耳电动牙刷",
      "categoryName": "电动牙刷",
      "price": 211.65,
      "purchaseDate": "2025-04-12T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2027-04-11T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 211.65,
      "history": []
    },
    {
      "uuid": "f10147a4-5abf-4046-90f1-0c39b20a97a0",
      "name": "小米洗衣机",
      "categoryName": "洗衣机",
      "price": 720.8,
      "purchaseDate": "2025-03-29T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2028-03-28T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 720.8,
      "history": []
    },
    {
      "uuid": "8252d360-622d-4b91-b116-c64b5dfeceab",
      "name": "海康威视行车记录仪",
      "categoryName": "相机",
      "price": 399.8,
      "purchaseDate": "2024-10-31T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2025-10-30T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 399.8,
      "history": []
    },
    {
      "uuid": "f5b35b66-b48b-4b9d-b185-2793e604892e",
      "name": "Xbox手柄",
      "categoryName": "游戏手柄",
      "price": 397.97,
      "purchaseDate": "2022-11-07T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": "2023-11-06T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 397.97,
      "history": []
    },
    {
      "uuid": "87283f65-75c7-4596-bd23-5567191eba97",
      "name": "骑行头盔",
      "categoryName": "自行车",
      "price": 297.51,
      "purchaseDate": "2023-07-29T00:00:00.000",
      "platform": "京东",
      "warrantyEndDate": null,
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 297.51,
      "history": []
    },
    {
      "uuid": "d1929af4-0095-44c1-9dd8-210d27c16e79",
      "name": "Xbox手柄",
      "categoryName": "游戏手柄",
      "price": 297.92,
      "purchaseDate": "2024-06-01T00:00:00.000",
      "platform": "淘宝",
      "warrantyEndDate": "2025-05-31T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 297.92,
      "history": []
    },
    {
      "uuid": "ddb1027a-4700-4df3-b32e-338239ba815c",
      "name": "公路车码表",
      "categoryName": "自行车",
      "price": 569,
      "purchaseDate": "2024-04-04T00:00:00.000",
      "platform": "淘宝",
      "warrantyEndDate": "2026-04-03T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 569,
      "history": []
    },
    {
      "uuid": "e19ac249-4974-4a14-9dd4-572daafd507e",
      "name": "狼蛛F75机械键盘",
      "categoryName": "机械键盘",
      "price": 198.79,
      "purchaseDate": "2023-11-11T00:00:00.000",
      "platform": "淘宝",
      "warrantyEndDate": "2024-11-10T00:00:00.000",
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 198.79,
      "history": []
    },
    {
      "uuid": "e92d8e0f-1d28-45eb-b5bf-a10a2381eff7",
      "name": "一加5T",
      "categoryName": "手机",
      "price": 3069,
      "purchaseDate": "2018-01-17T00:00:00.000",
      "platform": "",
      "warrantyEndDate": null,
      "scrapDate": "2019-04-19T00:00:00.000",
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": false,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 3069,
      "history": []
    },
    {
      "uuid": "cdd180f2-92c4-42f9-a35b-ba7e0e95fe52",
      "name": "三星盖世9",
      "categoryName": "手机",
      "price": 4808,
      "purchaseDate": "2018-11-25T00:00:00.000",
      "platform": "淘宝",
      "warrantyEndDate": null,
      "scrapDate": "2020-11-25T00:00:00.000",
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": false,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 4808,
      "history": []
    },
    {
      "uuid": "893a5fcf-b2b6-48db-bcd4-cf418aab2f96",
      "name": "手机",
      "categoryName": "手机",
      "price": 4576,
      "purchaseDate": "2025-12-08T17:45:06.949142",
      "platform": "",
      "warrantyEndDate": null,
      "scrapDate": null,
      "backupDate": null,
      "customIconPath": null,
      "cycleType": null,
      "isAutoRenew": true,
      "nextBillingDate": null,
      "reminderDays": 1,
      "hasReminder": false,
      "firstPeriodPrice": null,
      "periodPrice": null,
      "totalAccumulatedPrice": 4576,
      "history": []
    }
  ]
};

// Main task runner
async function main() {
  // 1. Generate imported_backup.json
  const categoriesMap = new Map();
  let tempCategoryId = 1;
  
  rawData.devices.forEach(d => {
    if (d.categoryName && !categoriesMap.has(d.categoryName)) {
      categoriesMap.set(d.categoryName, {
        uuid: `cat-uuid-${tempCategoryId++}`,
        name: d.categoryName,
        iconPath: "MdiIcons.tag"
      });
    }
  });
  
  const backupJson = {
    version: 3,
    source: "ownd-api",
    timestamp: new Date().toISOString(),
    categories: Array.from(categoriesMap.values()),
    devices: rawData.devices.map(d => {
      const cat = categoriesMap.get(d.categoryName);
      return {
        uuid: d.uuid,
        name: d.name,
        price: d.price,
        purchaseDate: d.purchaseDate,
        categoryName: d.categoryName,
        categoryUuid: cat ? cat.uuid : null,
        platform: d.platform || "其它",
        warrantyEndDate: d.warrantyEndDate,
        scrapDate: d.scrapDate,
        backupDate: d.backupDate,
        imagePath: null,
        notes: null,
        tags: [],
        cycleType: d.cycleType,
        currentCycle: 1,
        isAutoRenew: d.isAutoRenew,
        nextBillingDate: d.nextBillingDate,
        history: []
      };
    })
  };
  
  const backupPath = path.join(__dirname, '..', 'imported_backup.json');
  fs.writeFileSync(backupPath, JSON.stringify(backupJson, null, 2), 'utf-8');
  console.log(`Successfully generated backup file: ${backupPath}`);
  
  // 2. Direct database sync for local testing
  const pool = new Pool({ connectionString: databaseUrl });
  const adapter = new PrismaPg(pool);
  const prisma = new PrismaClient({ adapter });
  
  try {
    const email = '284264018@qq.com';
    let user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      const hashedPassword = await bcrypt.hash('123456', 10);
      user = await prisma.user.create({
        data: {
          email,
          name: '284264018',
          password: hashedPassword
        }
      });
      console.log(`Created user ${email} with password '123456'`);
    } else {
      console.log(`User ${email} already exists`);
    }
    
    // Copy templates for this user to make sure Category/Platform relations resolve correctly
    // Initialize system categories/platforms copy if not done
    await ensureUserTemplates(prisma, user.id);
    
    // Retrieve categories and platforms maps for the user
    const dbCategories = await prisma.category.findMany({ where: { userId: user.id } });
    const dbPlatforms = await prisma.platform.findMany({ where: { userId: user.id } });
    
    const dbCatMap = new Map(dbCategories.map(c => [c.name, c.id]));
    const dbPlatMap = new Map(dbPlatforms.map(p => [p.name, p.id]));
    
    let importedCount = 0;
    for (const d of rawData.devices) {
      // Find categoryId
      let categoryId = dbCatMap.get(d.categoryName) || null;
      if (!categoryId && d.categoryName) {
        // Create custom category for this user
        const newCat = await prisma.category.create({
          data: {
            name: d.categoryName,
            userId: user.id,
            icon: 'MdiIcons.tag'
          }
        });
        categoryId = newCat.id;
        dbCatMap.set(d.categoryName, categoryId);
      }
      
      // Find platformId
      const platformName = d.platform || '其它';
      let platformId = dbPlatMap.get(platformName) || null;
      if (!platformId) {
        // Create custom platform for this user
        const newPlat = await prisma.platform.create({
          data: {
            name: platformName,
            userId: user.id,
            icon: 'MdiIcons.store',
            color: '#9E9E9E'
          }
        });
        platformId = newPlat.id;
        dbPlatMap.set(platformName, platformId);
      }
      
      // Check if item already exists
      const existingItem = await prisma.item.findUnique({
        where: { id: d.uuid }
      });
      
      if (!existingItem) {
        await prisma.item.create({
          data: {
            id: d.uuid,
            name: d.name,
            price: d.price,
            purchaseDate: new Date(d.purchaseDate),
            userId: user.id,
            categoryId,
            platformId,
            isAutoRenew: d.isAutoRenew,
            nextBillingDate: d.nextBillingDate ? new Date(d.nextBillingDate) : null,
            warrantyEndDate: d.warrantyEndDate ? new Date(d.warrantyEndDate) : null,
            isScrapped: !!d.scrapDate,
            scrappedDate: d.scrapDate ? new Date(d.scrapDate) : null,
            isBackup: !!d.backupDate,
            backupDate: d.backupDate ? new Date(d.backupDate) : null,
            isVirtual: d.isAutoRenew // default to virtual if auto-renewing
          }
        });
        importedCount++;
      }
    }
    
    console.log(`Synced ${importedCount} new items to user ${email} database records.`);
  } catch (dbErr) {
    console.error('Error syncing to database:', dbErr);
  } finally {
    await prisma.$disconnect();
    await pool.end();
  }
}

// Ensure categories/platforms are copied
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

main();
