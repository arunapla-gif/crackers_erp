const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  try {
    await prisma.$executeRawUnsafe(`ALTER TABLE crackers."Product" ADD COLUMN "boxesPerCase" INTEGER NOT NULL DEFAULT 1;`);
    console.log("Successfully altered Product table to add boxesPerCase");
  } catch (err) {
    console.error("Error altering table:", err.message);
  } finally {
    await prisma.$disconnect();
  }
}
run();
