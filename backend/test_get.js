const jwt = require('jsonwebtoken');

async function main() {
  const token = jwt.sign({ id: 1, role: 'ADMIN' }, 'crackers-erp-super-secret-key-2026', { expiresIn: '1d' });
  try {
    const res = await fetch('https://crackers-erp-api.onrender.com/api/customers', {
      method: 'GET',
      headers: { 
        'Authorization': `Bearer ${token}`
      }
    });
    const data = await res.json();
    console.log(res.status);
    console.log(data);
  } catch(e) {
    console.error(e.message);
  }
}
main();
