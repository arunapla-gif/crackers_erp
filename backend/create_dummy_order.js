const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  try {
    const repId = 2; // KK
    const order = await prisma.salesOrder.create({
      data: {
        repId,
        customerId: null,
        newCustomerData: { name: 'Demo Customer', city: 'Sivakasi' },
        subtotal: 15000,
        status: 'PENDING',
        items: {
          create: [
            { product: 'Demo Product 1', qty: 10, rate: 1000, total: 10000 },
            { product: 'Demo Product 2', qty: 10, rate: 500, total: 5000 }
          ]
        }
      }
    });
    console.log("Created order:", order);
  } catch (e) {
    console.error("Prisma error:", e.message);
  } finally {
    await prisma.$disconnect();
  }
}
run();
