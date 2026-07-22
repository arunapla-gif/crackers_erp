const { Client } = require('pg');
async function run() {
  try {
    const c2 = new Client({ connectionString: 'postgresql://postgres:1103@localhost:5432/transport_erp' });
    await c2.connect();
    const rows = await c2.query('SELECT count(*) FROM crackers."Product"');
    console.log("Products in transport_erp crackers schema:", rows.rows[0].count);
    await c2.end();
  } catch(e) {
    console.log("No crackers.Product in transport_erp");
  }
}
run();
