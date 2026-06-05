const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const { Pool } = require('pg');
require('dotenv').config({ path: '.env.development' });

const databaseUrl = process.env.DATABASE_URL;
const pool = new Pool({ connectionString: databaseUrl });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  const users = await prisma.user.findMany();
  const nameCounts = {};
  
  for (const u of users) {
    let nameToUse = u.name ? u.name.trim() : '';
    if (!nameToUse) {
      // Use email prefix if username is missing
      nameToUse = u.email.split('@')[0];
    }
    
    if (nameCounts[nameToUse]) {
      nameCounts[nameToUse] += 1;
      const finalName = `${nameToUse}_${u.id.substring(0, 4)}`;
      await prisma.user.update({
        where: { id: u.id },
        data: { name: finalName }
      });
      console.log(`User ${u.email} has duplicate name, renamed from '${u.name}' to '${finalName}'`);
      nameCounts[finalName] = 1;
    } else {
      nameCounts[nameToUse] = 1;
      if (u.name !== nameToUse) {
        await prisma.user.update({
          where: { id: u.id },
          data: { name: nameToUse }
        });
        console.log(`User ${u.email} name updated from '${u.name}' to '${nameToUse}'`);
      }
    }
  }
  console.log('Deduplication completed.');
}

main()
  .catch(e => console.error('Deduplication error:', e))
  .finally(async () => {
    await prisma.$disconnect();
    await pool.end();
  });
