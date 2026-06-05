const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const { Pool } = require('pg');
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
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    console.log(`User ${email} not found`);
    return;
  }
  console.log(`User found: ${user.id}`);
  
  const items = await prisma.item.findMany({
    where: { userId: user.id },
    include: {
      category: true,
      platform: true
    }
  });
  
  console.log(`Total items found: ${items.length}`);
  items.forEach(item => {
    console.log(`Item: ${item.name}`);
    console.log(`  Category: ${item.category ? item.category.name : 'NULL'} (ID: ${item.categoryId}, userId: ${item.category ? item.category.userId : 'N/A'})`);
    console.log(`  Platform: ${item.platform ? item.platform.name : 'NULL'} (ID: ${item.platformId}, userId: ${item.platform ? item.platform.userId : 'N/A'})`);
  });
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
