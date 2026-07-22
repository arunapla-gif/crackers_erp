const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const products = await prisma.product.findMany({
    select: { id: true, code: true, name: true, category: true, subCategory: true, type: true }
  });
  console.log(JSON.stringify(products, null, 2));
}
run();
