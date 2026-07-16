const { PrismaClient } = require('../TRANSPORT ERP/backend/node_modules/@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const units = await prisma.unitMaster.findMany();
  console.log(JSON.stringify(units, null, 2));
}

main().catch(console.error).finally(() => prisma.$disconnect());
