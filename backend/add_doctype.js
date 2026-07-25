const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:5432/postgres'
});

async function run() {
  await client.connect();
  try {
    console.log("Adding docType column...");
    await client.query(`ALTER TABLE crackers."BillingSeries" ADD COLUMN "docType" TEXT NOT NULL DEFAULT 'INV';`);
    console.log("Successfully added docType column!");
  } catch(e) {
    console.log("Error:", e.message);
  } finally {
    await client.end();
  }
}
run();
