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
  console.log(`User ID: ${user.id}`);
  
  const categories = await prisma.category.findMany({
    where: { OR: [{ userId: user.id }, { userId: null }] }
  });
  console.log(`\n=== Categories (${categories.length}) ===`);
  categories.forEach(c => {
    console.log(`- [${c.id}] Name: ${c.name}, userId: ${c.userId}, parentId: ${c.parentId}`);
  });

  const platforms = await prisma.platform.findMany({
    where: { OR: [{ userId: user.id }, { userId: null }] }
  });
  console.log(`\n=== Platforms (${platforms.length}) ===`);
  platforms.forEach(p => {
    console.log(`- [${p.id}] Name: ${p.name}, userId: ${p.userId}`);
  });
}

main()
  .catch(console.error)
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
