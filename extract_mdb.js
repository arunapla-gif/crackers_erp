import fs from 'fs';
import MDBReader from 'mdb-reader';

try {
  const buffer = fs.readFileSync('ARUN SOFTWARE/JellyAccounts/395 ARUNACHALAM AGENCY/data/Masters.mdb');
  const reader = new MDBReader(buffer);
  
  const tableNames = reader.getTableNames();
  console.log("=== MASTERS.MDB TABLES ===");
  console.log(tableNames.join(", "));
  
  // Try to get structure of a few key tables if they exist
  if (tableNames.includes('Customers')) {
      const table = reader.getTable('Customers');
      console.log("\nColumns in Customers:");
      console.log(table.getColumnNames().join(", "));
  }
} catch (e) {
  console.error("Error reading Masters.mdb:", e);
}

try {
    const buffer2 = fs.readFileSync('ARUN SOFTWARE/JellyAccounts/395 ARUNACHALAM AGENCY/data/Transactions.mdb');
    const reader2 = new MDBReader(buffer2);
    const tableNames2 = reader2.getTableNames();
    console.log("\n=== TRANSACTIONS.MDB TABLES ===");
    console.log(tableNames2.join(", "));
} catch (e) {
    console.error("Error reading Transactions.mdb:", e);
}
