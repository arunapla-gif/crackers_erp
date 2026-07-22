const { Client } = require('pg');

async function run() {
  const localClient = new Client({ connectionString: 'postgresql://postgres:1103@localhost:5432/crackers_erp' });
  const remoteClient = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await localClient.connect();
    await remoteClient.connect();

    const res = await localClient.query('SELECT * FROM "Product";');
    const products = res.rows;
    console.log(`Found ${products.length} products locally.`);

    for (const p of products) {
      // Check if exists
      const exists = await remoteClient.query('SELECT id FROM crackers."Product" WHERE code = $1', [p.code]);
      if (exists.rows.length === 0) {
        await remoteClient.query(`
          INSERT INTO crackers."Product" 
          (code, name, type, hsn, tax, rate, unit_qty, unit, status, "createdAt", "updatedAt", category, pack_unit)
          VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
        `, [p.code, p.name, p.type, p.hsn, p.tax, p.rate, p.unit_qty, p.unit, p.status, p.createdAt, p.updatedAt, p.category, p.pack_unit]);
        console.log(`Migrated ${p.name}`);
      } else {
        console.log(`Skipped ${p.name}, already exists.`);
      }
    }
  } catch(e) {
    console.error(e.message);
  } finally {
    await localClient.end();
    await remoteClient.end();
  }
}
run();
