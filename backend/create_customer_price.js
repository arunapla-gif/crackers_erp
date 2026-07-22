const { Client } = require('pg');

async function run() {
  const remoteClient = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await remoteClient.connect();
    console.log("Connected to Supabase.");

    await remoteClient.query(`
      CREATE TABLE IF NOT EXISTS crackers."CustomerPrice" (
        "id" SERIAL NOT NULL,
        "customerId" INTEGER NOT NULL,
        "productId" INTEGER NOT NULL,
        "rate" DECIMAL(10,2) NOT NULL,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "CustomerPrice_pkey" PRIMARY KEY ("id")
      );
    `);
    console.log("Created CustomerPrice table.");

    await remoteClient.query(`
      CREATE UNIQUE INDEX IF NOT EXISTS "CustomerPrice_customerId_productId_key" ON crackers."CustomerPrice"("customerId", "productId");
    `);
    console.log("Created unique index.");

    try {
      await remoteClient.query(`
        ALTER TABLE crackers."CustomerPrice" ADD CONSTRAINT "CustomerPrice_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES crackers."Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;
      `);
      console.log("Added customerId foreign key constraint.");
    } catch(e) {
      if (e.code === '42710') { console.log("customer fk exists"); } else { throw e; }
    }

    try {
      await remoteClient.query(`
        ALTER TABLE crackers."CustomerPrice" ADD CONSTRAINT "CustomerPrice_productId_fkey" FOREIGN KEY ("productId") REFERENCES crackers."Product"("id") ON DELETE CASCADE ON UPDATE CASCADE;
      `);
      console.log("Added productId foreign key constraint.");
    } catch(e) {
      if (e.code === '42710') { console.log("product fk exists"); } else { throw e; }
    }

  } catch(e) {
    console.error(e.message);
  } finally {
    await remoteClient.end();
  }
}
run();
