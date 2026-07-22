const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  const products = await prisma.product.findMany({
    where: { type: 'EP' }
  });
  
  for (const product of products) {
    if (product.category && product.category.includes('Count')) {
      await prisma.product.update({
        where: { id: product.id },
        data: {
          subCategory: product.category.toUpperCase(),
          category: 'STANDARD WALAS'
        }
      });
      console.log(`Updated ${product.name}: STANDARD WALAS -> ${product.category.toUpperCase()}`);
    }
  }
}
run();
