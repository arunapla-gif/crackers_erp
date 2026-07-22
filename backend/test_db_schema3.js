const { Client } = require('pg');

async function run() {
  const client = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    const res = await client.query(`SELECT COUNT(*) FROM crackers."SalesOrder";`);
    console.log("Count:", res.rows[0].count);
  } catch(e) {
    console.error(e.message);
  } finally {
    await client.end();
  }
}
run();
