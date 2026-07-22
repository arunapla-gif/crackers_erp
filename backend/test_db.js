const { Client } = require('pg');
const client = new Client({
  connectionString: 'postgresql://postgres.gqfpfnqepdkletbbhwcx:IevuJqEtZ8V1eKhz@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require',
  ssl: { rejectUnauthorized: false }
});
async function run() {
  await client.connect();
  try {
    const res = await client.query('ALTER TABLE crackers."Customer" ADD COLUMN "repId" INTEGER;');
    console.log("Added repId to Customer");
  } catch(e) {
    console.log(e.message);
  }
  try {
    const res2 = await client.query('ALTER TABLE crackers."Customer" ADD CONSTRAINT "Customer_repId_fkey" FOREIGN KEY ("repId") REFERENCES crackers."User"("id") ON DELETE SET NULL ON UPDATE CASCADE;');
    console.log("Added foreign key to Customer");
  } catch(e) {
    console.log(e.message);
  }
  try {
    const res3 = await client.query('ALTER TABLE crackers."Invoice" ADD COLUMN "repId" INTEGER;');
    console.log("Added repId to Invoice");
  } catch(e) {
    console.log(e.message);
  }
  try {
    const res4 = await client.query('ALTER TABLE crackers."Invoice" ADD CONSTRAINT "Invoice_repId_fkey" FOREIGN KEY ("repId") REFERENCES crackers."User"("id") ON DELETE SET NULL ON UPDATE CASCADE;');
    console.log("Added foreign key to Invoice");
  } catch(e) {
    console.log(e.message);
  }
  try {
    const res5 = await client.query('CREATE TABLE crackers."SalesOrder" (id SERIAL PRIMARY KEY, "orderNumber" TEXT NOT NULL UNIQUE, "date" TIMESTAMP(3) NOT NULL, "customerId" INTEGER, "newCustomerName" TEXT, "newCustomerMobile" TEXT, "newCustomerCity" TEXT, "newCustomerState" TEXT, "repId" INTEGER NOT NULL, "status" TEXT NOT NULL DEFAULT \'Pending\', "totalAmount" DECIMAL(12,2), "notes" TEXT, "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP, "updatedAt" TIMESTAMP(3) NOT NULL);');
    console.log("Created SalesOrder");
  } catch(e) {
    console.log(e.message);
  }
  try {
    const res6 = await client.query('CREATE TABLE crackers."SalesOrderItem" (id SERIAL PRIMARY KEY, "salesOrderId" INTEGER NOT NULL, "productId" INTEGER, "productName" TEXT NOT NULL, "quantity" INTEGER NOT NULL, "rate" DECIMAL(12,2) NOT NULL, "total" DECIMAL(12,2) NOT NULL, FOREIGN KEY ("salesOrderId") REFERENCES crackers."SalesOrder"("id") ON DELETE CASCADE ON UPDATE CASCADE);');
    console.log("Created SalesOrderItem");
  } catch(e) {
    console.log(e.message);
  }
  try {
    const res7 = await client.query('ALTER TABLE crackers."SalesOrder" ADD CONSTRAINT "SalesOrder_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES crackers."Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;');
    console.log("Added foreign key customerId to SalesOrder");
  } catch(e) {
    console.log(e.message);
  }
  try {
    const res8 = await client.query('ALTER TABLE crackers."SalesOrder" ADD CONSTRAINT "SalesOrder_repId_fkey" FOREIGN KEY ("repId") REFERENCES crackers."User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;');
    console.log("Added foreign key repId to SalesOrder");
  } catch(e) {
    console.log(e.message);
  }
  await client.end();
}
run();
