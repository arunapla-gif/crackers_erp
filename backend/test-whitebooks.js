require('dotenv').config();

async function run() {
  try {
    const email = process.env.WHITEBOOKS_EMAIL?.trim();
    const username = process.env.WHITEBOOKS_USERNAME?.trim();
    const password = process.env.WHITEBOOKS_PASSWORD?.trim();
    const gstin = process.env.WHITEBOOKS_GSTIN?.trim();
    const clientId = process.env.WHITEBOOKS_CLIENT_ID?.trim();
    const clientSecret = process.env.WHITEBOOKS_CLIENT_SECRET?.trim();

    console.log("Credentials configured:");
    console.log("Email:", email);
    console.log("Username:", username);
    console.log("GSTIN:", gstin);

    const authUrl = `https://api.whitebooks.in/ewaybillapi/v1.03/authenticate?email=${encodeURIComponent(email)}&username=${encodeURIComponent(username)}&password=${encodeURIComponent(password)}`;
    
    console.log("\nFetching auth token...");
    const authResponse = await fetch(authUrl, {
      method: "GET",
      headers: { "Content-Type": "application/json", "client_id": clientId, "client_secret": clientSecret, "gstin": gstin, "ip_address": "127.0.0.1" }
    });
    
    const authData = await authResponse.json();
    
    if (!authResponse.ok || authData.status_cd === "0") {
       console.error("Auth Failed:", authData);
       return;
    }
    
    console.log("Auth Success! Token received.");

    const token = authData.authtoken || authData.data?.authtoken || authData.AuthToken || '';
    
    console.log("\nThe credentials work perfectly! E-way bill API is ready to be used.");
  } catch (err) {
    console.error("Error:", err.message);
  }
}

run();
