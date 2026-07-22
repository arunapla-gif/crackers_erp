const { Client } = require('pg');
async function run() {
  try {
    const c2 = new Client({ connectionString: 'postgresql://postgres:1103@localhost:5432/crackers_erp' });
    await c2.connect();
    const rows = await c2.query('SELECT * FROM "Product";');
    console.log(rows.rows);
    
    // Also check legacy_Chemical
    const chemRows = await c2.query('SELECT count(*) FROM crackers."legacy_Chemical"');
    console.log("Legacy chemical count in crackers schema:", chemRows.rows[0].count);
    await c2.end();
  } catch(e) {
    console.log(e.message);
  }
}
run();
