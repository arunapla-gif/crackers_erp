const { Prisma } = require('@prisma/client');
const val = new Prisma.Decimal(150.50);
console.log(parseFloat(val || 0));
