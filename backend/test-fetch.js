const http = require('http');

http.get('http://localhost:5001/api/ewaybill/reports/recent?days=2', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => console.log(data));
});
