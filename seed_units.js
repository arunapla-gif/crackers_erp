const { PrismaClient } = require('../TRANSPORT ERP/backend/node_modules/@prisma/client');
const prisma = new PrismaClient();

const UNIT_HIERARCHY = {
  'Cases': [
    { label: 'Cases of Fireworks', code: 'C/S', color: 'emerald' },
    { label: 'Double Cap', code: 'C/S', color: 'emerald' },
    { label: 'Serpent Eggs (Cases)', code: 'C/S', color: 'emerald' }
  ],
  'Cartons': [
    { label: 'Cartons of Fireworks', code: 'C/N', color: 'amber' },
    { label: 'Single Cap', code: 'C/N', color: 'amber' },
    { label: 'Ring Cap', code: 'C/N', color: 'amber' },
    { label: 'Serpent Eggs (Cartons)', code: 'C/N', color: 'amber' }
  ],
  'Bundles': [
    { label: 'Bundles of Sparklers', code: 'BD/S', color: 'rose' },
    { label: 'Gunny Bundles of Printed Material', code: 'BD/S', color: 'rose' }
  ],
  'Boxes': [
    { label: 'Boxes', code: 'BOX', color: 'slate' }
  ],
  'Drums': [
    { label: 'Drums', code: 'DRUM', color: 'slate' }
  ],
  'Other': [
    { label: 'Other', code: 'OTH', color: 'slate' }
  ]
};

async function main() {
  for (const [cat, items] of Object.entries(UNIT_HIERARCHY)) {
    for (const item of items) {
      await prisma.unitMaster.upsert({
        where: { category_description: { category: cat, description: item.label } },
        update: {},
        create: {
          category: cat,
          description: item.label,
          code: item.code,
          color: item.color
        }
      });
    }
  }
  console.log('seeded units');
}

main().catch(console.error).finally(() => prisma.$disconnect());
