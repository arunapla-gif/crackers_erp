const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  try {
    console.log("Deleting all Sales Orders...");
    const result = await prisma.salesOrder.deleteMany({});
    console.log(`Successfully deleted ${result.count} Sales Orders!`);
  } catch(e) {
    console.error("Error:", e.message);
  } finally {
    await prisma.$disconnect();
  }
}
run();
