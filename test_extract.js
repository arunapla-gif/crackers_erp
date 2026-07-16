import fs from 'fs';
import MDBReader from 'mdb-reader';

try {
  const buffer = fs.readFileSync('ARUN SOFTWARE/JellyAccounts/395 ARUNACHALAM AGENCY/data/Masters.mdb');
  const reader = new MDBReader(buffer);
  
  const table = reader.getTable('CustomerDB');
  const rows = table.getData();
  
  console.log("CustomerDB row count:", rows.length);
  if (rows.length > 0) {
      console.log("First row:", rows[0]);
  }
} catch (e) {
  console.error("Error:", e);
}
