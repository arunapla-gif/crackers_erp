const { Client } = require('pg');

const products = [
  { name: '100 (75)', code: 'EST001', cat: 'Standard Walas' },
  { name: '200 (120)', code: 'EST002', cat: 'Standard Walas' },
  { name: '300 (200)', code: 'EST003', cat: 'Standard Walas' },
  { name: '600 (400)', code: 'EST004', cat: 'Standard Walas' },
  { name: '1000 (400)', code: 'EST005', cat: 'Standard Walas' },
  { name: '2000 (800)', code: 'EST006', cat: 'Standard Walas' },
  { name: '5000 (2000)', code: 'EST007', cat: 'Standard Walas' },
  { name: '10000 (4000)', code: 'EST008', cat: 'Standard Walas' },
  
  { name: '1000 (400) [Core & Cellophane]', code: 'EST009', cat: 'Core & Cellophane' },
  { name: '2000 (800) [Core & Cellophane]', code: 'EST010', cat: 'Core & Cellophane' },
  { name: '5000 (2000) [Core & Cellophane]', code: 'EST011', cat: 'Core & Cellophane' },
  { name: '10000 (4000) [Core & Cellophane]', code: 'EST012', cat: 'Core & Cellophane' },
  
  { name: '1000 (600)', code: 'EST013', cat: 'Standard Walas' },
  { name: '2000 (1200)', code: 'EST014', cat: 'Standard Walas' },
  { name: '5000 (3000)', code: 'EST015', cat: 'Standard Walas' },
  { name: '10000 (6000)', code: 'EST016', cat: 'Standard Walas' },
  
  { name: '1000 (700)', code: 'EST017', cat: 'Standard Walas' },
  { name: '2000 (1400)', code: 'EST018', cat: 'Standard Walas' },
  { name: '5000 (3500)', code: 'EST019', cat: 'Standard Walas' },
  
  { name: '100 (85)', code: 'EST020', cat: 'Standard Walas' },
  { name: '200 (170)', code: 'EST021', cat: 'Standard Walas' },
  { name: '1000 (800)', code: 'EST022', cat: 'Standard Walas' },
  { name: '2000 (1600)', code: 'EST023', cat: 'Standard Walas' }
];

async function run() {
  const remoteClient = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await remoteClient.connect();
    console.log("Connected to Supabase.");

    for (const p of products) {
      // Check if exists
      const exists = await remoteClient.query('SELECT id FROM crackers."Product" WHERE code = $1 OR name = $2', [p.code, p.name]);
      if (exists.rows.length === 0) {
        await remoteClient.query(`
          INSERT INTO crackers."Product" 
          (code, name, type, hsn, tax, rate, unit_qty, unit, status, "createdAt", "updatedAt", category, pack_unit)
          VALUES ($1, $2, 'EST', '3604', '0.00', '0.00', 1, 'Box', 'Active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, $3, 'Box')
        `, [p.code, p.name, p.cat]);
        console.log(`Inserted ${p.name}`);
      } else {
        console.log(`Skipped ${p.name}, already exists.`);
      }
    }
  } catch(e) {
    console.error(e.message);
  } finally {
    await remoteClient.end();
  }
}
run();
