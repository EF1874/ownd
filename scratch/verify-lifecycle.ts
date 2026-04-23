import { PrismaClient, ItemCycleType, ItemRecordType } from '@prisma/client';
import dayjs from 'dayjs';
import * as dotenv from 'dotenv';

dotenv.config({ path: '.env.development' });
const prisma = new PrismaClient();

async function main() {
  console.log('🚀 开始验证物品生命周期逻辑...');

  // 0. 获取或创建一个测试用户
  let user = await prisma.user.findFirst();
  if (!user) {
    console.log('📝 未找到用户，正在创建测试用户...');
    user = await prisma.user.create({
      data: {
        email: 'test@example.com',
        name: 'testuser',
        password: 'password123',
      },
    });
  }
  const testUserId = user.id;
  console.log(`👤 使用测试用户 ID: ${testUserId}`);

  // 1. 模拟创建虚拟订阅物品 (月付)
  console.log('\n--- 场景 A: 创建虚拟订阅 (月付) ---');
  const purchaseDate = new Date('2024-01-01');
  const price = 15.0;
  const cycleValue = 1;
  const cycleType = ItemCycleType.MONTH;

  // 模拟计算逻辑 (同步 Service 中的逻辑)
  const d = dayjs(purchaseDate);
  const endDate = d.add(cycleValue, 'month').subtract(1, 'ms').toDate();
  const nextBillingDate = dayjs(endDate).add(1, 'day').toDate();

  console.log(`初始日期: ${purchaseDate.toISOString()}`);
  console.log(`预期结束日期: ${endDate.toISOString()}`);
  console.log(`预期下笔账单: ${nextBillingDate.toISOString()}`);

  const newItem = await prisma.item.create({
    data: {
      name: '测试订阅 (Netflix)',
      price: price,
      purchaseDate: purchaseDate,
      userId: testUserId,
      isVirtual: true,
      currentCycleType: cycleType,
      currentCycle: cycleValue,
      nextBillingDate: nextBillingDate,
      itemHistories: {
        create: [
          {
            type: ItemRecordType.RENEWAL,
            price: price,
            startDate: purchaseDate,
            endDate: endDate,
            cycleType: cycleType,
            cycle: cycleValue,
            note: '系统验证创建',
          },
        ],
      },
    },
    include: {
      itemHistories: true,
    },
  });

  console.log('✅ 虚拟物品创建成功 ID:', newItem.id);
  console.log('📊 历史记录条数:', newItem.itemHistories.length);
  console.log('📅 下次扣费日期:', newItem.nextBillingDate?.toISOString());

  // 2. 验证非虚拟物品的生命周期字段
  console.log('\n--- 场景 B: 创建实物及其保修日期 ---');
  const warrantyEnd = dayjs().add(1, 'year').toDate();
  const physicalItem = await prisma.item.create({
    data: {
      name: '测试实物 (iPhone)',
      price: 6999,
      userId: testUserId,
      isVirtual: false,
      warrantyEndDate: warrantyEnd,
      isBackup: true,
      backupDate: new Date(),
    },
  });

  console.log('✅ 实物创建成功 ID:', physicalItem.id);
  console.log('🛡️ 保修截止:', physicalItem.warrantyEndDate?.toISOString());
  console.log('📦 闲置状态:', physicalItem.isBackup);

  console.log('\n✨ 验证结束！');
}

main()
  .catch((e) => {
    console.error('❌ 验证失败:', e);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
