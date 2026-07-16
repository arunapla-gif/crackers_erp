require('dotenv').config();

async function run() {
  const email = process.env.WHITEBOOKS_EMAIL?.trim();
  const username = process.env.WHITEBOOKS_USERNAME?.trim();
  const password = process.env.WHITEBOOKS_PASSWORD?.trim();
  const gstin = process.env.WHITEBOOKS_GSTIN?.trim();
  const clientId = process.env.WHITEBOOKS_CLIENT_ID?.trim();
  const clientSecret = process.env.WHITEBOOKS_CLIENT_SECRET?.trim();

  const authUrl = `https://api.whitebooks.in/ewaybillapi/v1.03/authenticate?email=${encodeURIComponent(email)}&username=${encodeURIComponent(username)}&password=${encodeURIComponent(password)}`;
  const authResponse = await fetch(authUrl, {
    method: "GET",
    headers: { "Content-Type": "application/json", "client_id": clientId, "client_secret": clientSecret, "gstin": gstin, "ip_address": "127.0.0.1" }
  });
  
  const authData = await authResponse.json();
  console.log("AuthData:", JSON.stringify(authData, null, 2));
}
run();
