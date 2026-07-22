const { Client } = require('pg');

async function run() {
  const remoteClient = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await remoteClient.connect();
    console.log("Connected to Supabase.");

    // 1. Rename 100 (85) to 100 (80)
    const res1 = await remoteClient.query(`UPDATE crackers."Product" SET name = '100 (80)' WHERE name = '100 (85)' AND type = 'EP'`);
    console.log(`Updated ${res1.rowCount} products to 100 (80).`);

    // 2. Rename 200 (170) to 200 (160)
    const res2 = await remoteClient.query(`UPDATE crackers."Product" SET name = '200 (160)' WHERE name = '200 (170)' AND type = 'EP'`);
    console.log(`Updated ${res2.rowCount} products to 200 (160).`);

    // 3. Add 10000 (7000) under 700 Count
    const check1 = await remoteClient.query(`SELECT id FROM crackers."Product" WHERE name = '10000 (7000)'`);
    if (check1.rowCount === 0) {
      await remoteClient.query(`
        INSERT INTO crackers."Product" 
        (code, name, type, hsn, tax, rate, unit_qty, unit, status, "createdAt", "updatedAt", category, pack_unit)
        VALUES ('EST024', '10000 (7000)', 'EP', '3604', '0.00', '0.00', 1, 'Box', 'Active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '700 Count', 'Box')
      `);
      console.log("Inserted 10000 (7000)");
    }

    // 4. Add 5000 (4000) under 800 Count
    const check2 = await remoteClient.query(`SELECT id FROM crackers."Product" WHERE name = '5000 (4000)'`);
    if (check2.rowCount === 0) {
      await remoteClient.query(`
        INSERT INTO crackers."Product" 
        (code, name, type, hsn, tax, rate, unit_qty, unit, status, "createdAt", "updatedAt", category, pack_unit)
        VALUES ('EST025', '5000 (4000)', 'EP', '3604', '0.00', '0.00', 1, 'Box', 'Active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '800 Count', 'Box')
      `);
      console.log("Inserted 5000 (4000)");
    }

    // 5. Add 10000 (8000) under 800 Count
    const check3 = await remoteClient.query(`SELECT id FROM crackers."Product" WHERE name = '10000 (8000)'`);
    if (check3.rowCount === 0) {
      await remoteClient.query(`
        INSERT INTO crackers."Product" 
        (code, name, type, hsn, tax, rate, unit_qty, unit, status, "createdAt", "updatedAt", category, pack_unit)
        VALUES ('EST026', '10000 (8000)', 'EP', '3604', '0.00', '0.00', 1, 'Box', 'Active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, '800 Count', 'Box')
      `);
      console.log("Inserted 10000 (8000)");
    }

  } catch(e) {
    console.error(e.message);
  } finally {
    await remoteClient.end();
  }
}
run();
