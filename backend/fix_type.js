const { Client } = require('pg');

async function run() {
  const remoteClient = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await remoteClient.connect();
    console.log("Connected to Supabase.");

    const res = await remoteClient.query(`UPDATE crackers."Product" SET type = 'EP' WHERE type = 'EST'`);
    console.log(`Updated ${res.rowCount} products from EST to EP.`);
    
  } catch(e) {
    console.error(e.message);
  } finally {
    await remoteClient.end();
  }
}
run();
