const https = require('https');

const req = https.request('https://crackers-erp-backend.onrender.com/api/rep/dashboard', {
  method: 'GET'
}, (res) => {
  console.log("Status for /api/rep/dashboard:", res.statusCode);
});
req.end();
