const https = require('https');

const req = https.request('https://crackers-erp-api.onrender.com/api/rep/dashboard', {
  method: 'GET'
}, (res) => {
  console.log("Status:", res.statusCode);
});
req.end();
