const fs = require('fs');
const path = require('path');
const MDBReader = require('mdb-reader').default;

const payrollDataPath = path.join(__dirname, '../ARUN SOFTWARE/JellyAccounts/Amutha fireworks Payroll/data');
const exportPath = path.join(__dirname, '../ARUN SOFTWARE/legacy_data_export');

function exportDatabase(dbPath, prefix) {
    if (!fs.existsSync(dbPath)) {
        console.error("Database not found at", dbPath);
        return;
    }
    const buffer = fs.readFileSync(dbPath);
    const reader = new MDBReader(buffer);
    const tableNames = reader.getTableNames();
    
    console.log(`Exporting ${tableNames.length} tables from ${dbPath}...`);
    
    tableNames.forEach(tableName => {
        // Skip system tables
        if (tableName.startsWith('MSys')) return;
        
        try {
            const table = reader.getTable(tableName);
            const data = table.getData();
            const outputFile = path.join(exportPath, `Payroll_${prefix}_${tableName}.json`);
            fs.writeFileSync(outputFile, JSON.stringify(data, null, 2));
            console.log(`✅ Saved ${tableName} (${data.length} records)`);
        } catch (err) {
            console.error(`❌ Failed to export table ${tableName}:`, err.message);
        }
    });
}

console.log("Starting legacy Payroll database extraction...");
exportDatabase(path.join(payrollDataPath, 'Masters.mdb'), 'Masters');
exportDatabase(path.join(payrollDataPath, 'Amutha Fireworks/Transactions.mdb'), 'Transactions');
console.log("Extraction complete!");
