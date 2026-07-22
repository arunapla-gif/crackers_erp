const { Client } = require('pg');

async function run() {
  const client = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    await client.query(`ALTER TABLE crackers."Product" ADD COLUMN IF NOT EXISTS "subCategory" TEXT;`);
    console.log("Successfully added subCategory to Product table");
  } catch(e) {
    console.error(e.message);
  } finally {
    await client.end();
  }
}
run();
