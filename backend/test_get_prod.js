const jwt = require('jsonwebtoken');
async function run() {
  const token = jwt.sign({ id: 1, role: 'ADMIN' }, 'crackers-erp-super-secret-key-2026', { expiresIn: '1d' });
  try {
    const res = await fetch('https://crackers-erp-api.onrender.com/api/products', {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const data = await res.json();
    console.log("Status:", res.status);
    console.log("Total Products:", data.length);
    console.log("EST Products:", data.filter(p => p.type === 'EST').length);
    console.log("INV Products:", data.filter(p => p.type === 'INV').length);
  } catch(e) {
    console.error(e.message);
  }
}
run();
