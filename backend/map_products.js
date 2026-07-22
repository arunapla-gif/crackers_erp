const { Client } = require('pg');

async function run() {
  const remoteClient = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await remoteClient.connect();
    console.log("Connected to Supabase.");

    // Helper to get ID
    async function getId(name) {
      const res = await remoteClient.query(`SELECT id FROM crackers."Product" WHERE name = $1`, [name]);
      return res.rowCount > 0 ? res.rows[0].id : null;
    }

    const id10000_6000 = await getId('10000 (6000)');
    const id5000_3500 = await getId('5000 (3500)');

    if (!id10000_6000 || !id5000_3500) {
      console.log("Could not find base products. Available names:");
      const all = await remoteClient.query(`SELECT name FROM crackers."Product" WHERE type = 'EP' AND name LIKE '%000%'`);
      console.log(all.rows.map(r => r.name));
      return;
    }

    // Map 10000(7000) and 10000(8000) -> 10000(6000)
    await remoteClient.query(`UPDATE crackers."Product" SET "factoryAliasId" = $1 WHERE name IN ('10000 (7000)', '10000 (8000)')`, [id10000_6000]);
    
    // Map 5000(4000) -> 5000(3500)
    await remoteClient.query(`UPDATE crackers."Product" SET "factoryAliasId" = $1 WHERE name = '5000 (4000)'`, [id5000_3500]);

    console.log("Successfully mapped products!");

  } catch(e) {
    console.error(e.message);
  } finally {
    await remoteClient.end();
  }
}
run();
