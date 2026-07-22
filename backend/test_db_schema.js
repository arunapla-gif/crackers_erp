const { Client } = require('pg');

async function run() {
  const client = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    const res = await client.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_schema = 'crackers' AND table_name = 'SalesOrder';
    `);
    console.log("Columns in SalesOrder:");
    res.rows.forEach(r => console.log(r.column_name, r.data_type));
  } catch(e) {
    console.error(e.message);
  } finally {
    await client.end();
  }
}
run();
