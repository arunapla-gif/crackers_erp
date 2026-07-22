const https = require('https');

const data = JSON.stringify({
  username: 'KK',
  pin: '1234'
});

const req = https.request('https://crackers-erp-backend.onrender.com/api/users/login', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
}, (res) => {
  let body = '';
  res.on('data', (d) => body += d);
  res.on('end', () => {
    console.log("Login Response:", body);
    try {
      const parsed = JSON.parse(body);
      if (parsed.token) {
        // Now fetch dashboard
        const req2 = https.request('https://crackers-erp-backend.onrender.com/api/rep/dashboard', {
          headers: {
            'Authorization': 'Bearer ' + parsed.token
          }
        }, (res2) => {
          let body2 = '';
          res2.on('data', (d) => body2 += d);
          res2.on('end', () => {
            console.log("Dashboard Status:", res2.statusCode);
            console.log("Dashboard Response:", body2);
          });
        });
        req2.end();
      }
    } catch(e) {
      console.log("Error parsing:", e);
    }
  });
});

req.on('error', (e) => {
  console.error(e);
});
req.write(data);
req.end();
