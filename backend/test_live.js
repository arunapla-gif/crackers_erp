const axios = require('axios');

async function run() {
  try {
    const loginRes = await axios.post('https://crackers-erp-backend.onrender.com/api/auth/login', {
      username: 'KK',
      pin: '1234' // Wait, I don't know the PIN.
    });
    console.log(loginRes.data);
  } catch (e) {
    console.log(e.message);
  }
}
run();
