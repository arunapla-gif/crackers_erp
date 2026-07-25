const https = require('https');

const gstin = '33AAUFA0456C1ZR';
const apiKey = '7eWP3WelRNexYGJ172L3Hb8JNrY2';
const url1 = `https://b2b.appyflow.in/api/verifyGST?gstNo=${gstin}&key_secret=${apiKey}`;
const url2 = `https://appyflow.in/api/verifyGST?gstNo=${gstin}&key_secret=${apiKey}`;

function testUrl(url) {
  return new Promise((resolve) => {
    https.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          resolve({ url, status: res.statusCode, data: JSON.parse(data) });
        } catch (e) {
          resolve({ url, status: res.statusCode, data: data });
        }
      });
    }).on('error', e => resolve({ url, error: e.message }));
  });
}

async function run() {
  console.log("Testing b2b.appyflow.in...");
  const res1 = await testUrl(url1);
  console.log(JSON.stringify(res1, null, 2));

  console.log("Testing appyflow.in...");
  const res2 = await testUrl(url2);
  console.log(JSON.stringify(res2, null, 2));
}

run();
