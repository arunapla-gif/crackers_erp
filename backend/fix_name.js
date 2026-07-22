const { Client } = require('pg');
async function run() {
  const remoteClient = new Client({ connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require', ssl: { rejectUnauthorized: false } });
  await remoteClient.connect();
  const res = await remoteClient.query(`SELECT id, name FROM crackers."Product" WHERE name LIKE '200%'`);
  console.log(res.rows);
  await remoteClient.end();
}
run();
