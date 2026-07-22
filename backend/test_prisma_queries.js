const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function run() {
  try {
    const repId = 12; // Assuming KK is a rep. Let's just find a user who is a rep.
    const user = await prisma.user.findFirst({ where: { role: 'REP' } });
    if (!user) {
      console.log("No rep found");
      return;
    }
    console.log("Found rep:", user.username, user.id);

    const approvedOrders = await prisma.salesOrder.findMany({
      where: { repId: user.id, status: 'APPROVED' },
      select: { subtotal: true }
    });
    console.log("approvedOrders:", approvedOrders);

    const pendingOrdersCount = await prisma.salesOrder.count({
      where: { repId: user.id, status: 'PENDING' }
    });
    console.log("pending count:", pendingOrdersCount);

    const totalCustomers = await prisma.customer.count({
      where: { repId: user.id }
    });
    console.log("total customers:", totalCustomers);

    const recentOrders = await prisma.salesOrder.findMany({
      where: { repId: user.id },
      orderBy: { createdAt: 'desc' },
      take: 5,
      include: {
        customer: { select: { name: true } }
      }
    });
    console.log("recentOrders:", recentOrders);

  } catch (e) {
    console.error("Prisma error:", e.message);
  } finally {
    await prisma.$disconnect();
  }
}
run();
