const { Client } = require('pg');

async function run() {
  const remoteClient = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await remoteClient.connect();
    console.log("Connected to Supabase.");

    await remoteClient.query(`ALTER TABLE crackers."Product" ADD COLUMN IF NOT EXISTS "factoryAliasId" INTEGER`);
    console.log("Added factoryAliasId to Product table");

    // Add foreign key constraint
    try {
      await remoteClient.query(`
        ALTER TABLE crackers."Product" 
        ADD CONSTRAINT "Product_factoryAliasId_fkey" FOREIGN KEY ("factoryAliasId") REFERENCES crackers."Product"("id") ON DELETE SET NULL ON UPDATE CASCADE
      `);
      console.log("Added foreign key constraint");
    } catch(e) {
      if (e.code === '42710') {
        console.log("Constraint already exists");
      } else {
        throw e;
      }
    }

  } catch(e) {
    console.error(e.message);
  } finally {
    await remoteClient.end();
  }
}
run();
