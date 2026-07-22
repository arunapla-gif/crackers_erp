const { Client } = require('pg');

async function run() {
  const remoteClient = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await remoteClient.connect();
    console.log("Connected to Supabase.");

    // EST001 to EST008: 400 Count
    await remoteClient.query(`UPDATE crackers."Product" SET category = '400 Count' WHERE code IN ('EST001', 'EST002', 'EST003', 'EST004', 'EST005', 'EST006', 'EST007', 'EST008')`);
    
    // EST009 to EST012: 400 Count (Core & Cellophane)
    await remoteClient.query(`UPDATE crackers."Product" SET category = '400 Count (Core & Cellophane)' WHERE code IN ('EST009', 'EST010', 'EST011', 'EST012')`);
    
    // EST013 to EST016: 600 Count
    await remoteClient.query(`UPDATE crackers."Product" SET category = '600 Count' WHERE code IN ('EST013', 'EST014', 'EST015', 'EST016')`);
    
    // EST017 to EST019: 700 Count
    await remoteClient.query(`UPDATE crackers."Product" SET category = '700 Count' WHERE code IN ('EST017', 'EST018', 'EST019')`);
    
    // EST020 to EST023: 800 Count
    await remoteClient.query(`UPDATE crackers."Product" SET category = '800 Count' WHERE code IN ('EST020', 'EST021', 'EST022', 'EST023')`);

    console.log("Categories updated successfully.");
  } catch(e) {
    console.error(e.message);
  } finally {
    await remoteClient.end();
  }
}
run();
