const { Client } = require('pg');

async function run() {
  const client = new Client({ 
    connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
    ssl: { rejectUnauthorized: false }
  });

  try {
    await client.connect();
    
    await client.query(`DROP TABLE IF EXISTS crackers."SalesOrderItem" CASCADE;`);
    console.log("Dropped SalesOrderItem");
    
    await client.query(`DROP TABLE IF EXISTS crackers."SalesOrder" CASCADE;`);
    console.log("Dropped SalesOrder");

    await client.query(`
      CREATE TABLE crackers."SalesOrder" (
        "id" SERIAL NOT NULL,
        "repId" INTEGER NOT NULL,
        "customerId" INTEGER,
        "newCustomerData" JSONB,
        "status" TEXT NOT NULL DEFAULT 'PENDING',
        "subtotal" DECIMAL(12,2) NOT NULL DEFAULT 0.00,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "SalesOrder_pkey" PRIMARY KEY ("id")
      );
    `);
    console.log("Created SalesOrder");

    await client.query(`
      CREATE TABLE crackers."SalesOrderItem" (
        "id" SERIAL NOT NULL,
        "salesOrderId" INTEGER NOT NULL,
        "productId" INTEGER,
        "product" TEXT NOT NULL,
        "qty" INTEGER NOT NULL DEFAULT 1,
        "rate" DECIMAL(10,2) NOT NULL DEFAULT 0.00,
        "total" DECIMAL(12,2) NOT NULL DEFAULT 0.00,
        "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
        "updatedAt" TIMESTAMP(3) NOT NULL,
        CONSTRAINT "SalesOrderItem_pkey" PRIMARY KEY ("id")
      );
    `);
    console.log("Created SalesOrderItem");

    await client.query(`
      ALTER TABLE crackers."SalesOrder" ADD CONSTRAINT "SalesOrder_repId_fkey" FOREIGN KEY ("repId") REFERENCES crackers."User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
    `);
    console.log("Added foreign key repId to SalesOrder");

    await client.query(`
      ALTER TABLE crackers."SalesOrder" ADD CONSTRAINT "SalesOrder_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES crackers."Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;
    `);
    console.log("Added foreign key customerId to SalesOrder");

    await client.query(`
      ALTER TABLE crackers."SalesOrderItem" ADD CONSTRAINT "SalesOrderItem_salesOrderId_fkey" FOREIGN KEY ("salesOrderId") REFERENCES crackers."SalesOrder"("id") ON DELETE CASCADE ON UPDATE CASCADE;
    `);
    console.log("Added foreign key salesOrderId to SalesOrderItem");

  } catch(e) {
    console.error(e.message);
  } finally {
    await client.end();
  }
}
run();
