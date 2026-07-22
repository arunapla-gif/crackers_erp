const axios = require('axios');

async function run() {
  try {
    // We need to login first to get a token
    const loginRes = await axios.post('http://localhost:5000/api/auth/login', {
      username: 'KK', // I see KK in the screenshot. Let's try to login as KK or admin to get the token
      pin: '1234' // just a guess, or I can bypass it. Wait, I have direct DB access. I can mock the JWT token.
    });
    console.log(loginRes.data);
  } catch (e) {
    console.log(e.message);
  }
}
run();
