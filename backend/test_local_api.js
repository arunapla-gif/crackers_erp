const axios = require('axios'); // wait, I don't have axios

// Write a raw Node.js fetch script
const http = require('http');

const req = http.request('http://localhost:5001/api/rep/dashboard', {
  headers: {
    'Authorization': 'Bearer test' // I'll modify server.js to bypass auth first
  }
}, (res) => {
  let body = '';
  res.on('data', d => body += d);
  res.on('end', () => {
    console.log("Status:", res.statusCode);
    console.log("Response:", body);
  });
});
req.end();
