const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
const jwt = require('jsonwebtoken');

async function main() {
  const token = jwt.sign({ id: 1, role: 'ADMIN' }, 'crackers-erp-super-secret-key-2026', { expiresIn: '1d' });
  try {
    const res = await fetch('https://crackers-erp-api.onrender.com/api/customers', {
      method: 'POST',
      headers: { 
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        id: 792,
        name: 'TEST CUSTOMER',
        repId: 2
      })
    });
    const data = await res.json();
    console.log(res.status, data);
  } catch(e) {
    console.error(e.message);
  }
}
main().catch(console.error).finally(() => prisma.$disconnect());
