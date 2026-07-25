const jwt = require('jsonwebtoken');

const token = jwt.sign(
  { id: 1, username: 'admin', role: 'admin' }, 
  'crackers-erp-super-secret-key-2026', 
  { expiresIn: '24h' }
);

console.log(token);
