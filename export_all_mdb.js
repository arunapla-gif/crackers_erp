import fs from 'fs';
import path from 'path';
import MDBReader from 'mdb-reader';

const outputDir = 'ARUN SOFTWARE/legacy_data_export';

if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
}

function exportDatabase(dbPath, dbName) {
    try {
        console.log(`\nOpening ${dbName}...`);
        const buffer = fs.readFileSync(dbPath);
        const reader = new MDBReader(buffer);
        
        const tableNames = reader.getTableNames();
        
        for (const tableName of tableNames) {
            try {
                const table = reader.getTable(tableName);
                const data = table.getData();
                
                const outputFile = path.join(outputDir, `${dbName}_${tableName}.json`);
                fs.writeFileSync(outputFile, JSON.stringify(data, null, 2));
                
                console.log(`  - Exported ${tableName} (${data.length} rows)`);
            } catch (err) {
                console.error(`  - ERROR exporting ${tableName}:`, err.message);
            }
        }
    } catch (e) {
        console.error(`Failed to process ${dbName}:`, e.message);
    }
}

// Export Masters
exportDatabase('ARUN SOFTWARE/JellyAccounts/395 ARUNACHALAM AGENCY/data/Masters.mdb', 'Masters');

// Export Transactions
exportDatabase('ARUN SOFTWARE/JellyAccounts/395 ARUNACHALAM AGENCY/data/Transactions.mdb', 'Transactions');

console.log("\nExport complete! Data saved to ARUN SOFTWARE/legacy_data_export/");
