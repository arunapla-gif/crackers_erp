const { PrismaClient } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

const prisma = new PrismaClient();
const exportDir = path.join(__dirname, '../ARUN SOFTWARE/legacy_data_export');

async function importData() {
    console.log("Starting Legacy Data Import...");

    try {
        // Clear existing to avoid duplicates if run multiple times
        await prisma.legacy_ChemicalParticular.deleteMany({});
        await prisma.legacy_PurchaseCharge.deleteMany({});
        await prisma.legacy_EstimateCharge.deleteMany({});
        await prisma.legacy_EstimateParticular.deleteMany({});
        await prisma.legacy_Estimate.deleteMany({});
        await prisma.legacy_Payment.deleteMany({});
        await prisma.legacy_WorkentryParticular.deleteMany({});
        await prisma.legacy_Workentry.deleteMany({});
        await prisma.legacy_Advance.deleteMany({});
        await prisma.legacy_PayrollProduct.deleteMany({});
        await prisma.legacy_Employee.deleteMany({});
        await prisma.legacy_PurchaseParticular.deleteMany({});
        await prisma.legacy_Purchase.deleteMany({});
        await prisma.legacy_Chemical.deleteMany({});
        await prisma.legacy_Supplier.deleteMany({});
        await prisma.legacy_Customer.deleteMany({});
        console.log("Cleared old tables...");

        // Customers
        const customersData = JSON.parse(fs.readFileSync(path.join(exportDir, 'Masters_CustomerDB.json')));
        console.log(`Importing ${customersData.length} Customers...`);
        for (const row of customersData) {
            await prisma.legacy_Customer.create({
                data: {
                    AutoNumber: row.AutoNumber,
                    CustomerID: row.CustomerID,
                    Customername: row.Customername,
                    Address1: row.Address1,
                    Address2: row.Address2,
                    Address3: row.Address3,
                    Contactnumber: row.Contactnumber,
                    Contactnumber2: row.Contactnumber2,
                    CustomerType: row.CustomerType,
                    Narration: row.Narration,
                    Email: row.Email,
                    Openingbalance: row.Openingbalance?.toString(),
                    Status: row.Status,
                    Licno: row.Licno,
                    Panno: row.Panno
                }
            });
        }
        
        // Suppliers
        const suppliersData = JSON.parse(fs.readFileSync(path.join(exportDir, 'Masters_SupplierDB.json')));
        console.log(`Importing ${suppliersData.length} Suppliers...`);
        for (const row of suppliersData) {
            await prisma.legacy_Supplier.create({
                data: {
                    AutoNumber: row.AutoNumber,
                    SupplierID: row.SupplierID,
                    Suppliername: row.Suppliername,
                    Address1: row.Address1,
                    Address2: row.Address2,
                    Address3: row.Address3,
                    Contactnumber: row.Contactnumber,
                    Contactnumber2: row.Contactnumber2,
                    Email: row.Email,
                    Narration: row.Narration,
                    Whatsapp: row.Whatsapp,
                    Openingbalance: row.Openingbalance?.toString(),
                    Status: row.Status
                }
            });
        }

        // Chemicals
        const chemicalsData = JSON.parse(fs.readFileSync(path.join(exportDir, 'Masters_ChemicalsDB.json')));
        console.log(`Importing ${chemicalsData.length} Chemicals...`);
        for (const row of chemicalsData) {
            await prisma.legacy_Chemical.create({
                data: {
                    Autonumber: row.Autonumber,
                    ProductId: row.ProductId,
                    Productname: row.Productname,
                    Status: row.Status,
                    TotalOpening: row.TotalOpening?.toString()
                }
            });
        }

        // Purchases
        const purchasesData = JSON.parse(fs.readFileSync(path.join(exportDir, 'Transactions_PurchaseDB.json')));
        console.log(`Importing ${purchasesData.length} Purchases...`);
        for (const row of purchasesData) {
            await prisma.legacy_Purchase.create({
                data: {
                    Autonumber: row.Autonumber,
                    PurchaseID: row.PurchaseID,
                    Purchasedate: row.Purchasedate,
                    Supplieraccountnumber: row.Supplieraccountnumber,
                    Netamount: row.Netamount?.toString(),
                    Subtotal: row.Subtotal?.toString(),
                    Status: row.Status,
                    Invoicedate: row.Invoicedate,
                    Duedate: row.Duedate,
                    Invoiceno: row.Invoiceno,
                    Narration: row.Narration,
                    Purchasetype: row.Purchasetype,
                    Financeyear: row.Financeyear
                }
            });
        }

        // Purchase Particulars
        const particularsData = JSON.parse(fs.readFileSync(path.join(exportDir, 'Transactions_PurchaseParticularsDB.json')));
        console.log(`Importing ${particularsData.length} Purchase Particulars...`);
        for (const row of particularsData) {
            await prisma.legacy_PurchaseParticular.create({
                data: {
                    Autonumber: row.Autonumber,
                    PurchaseID: row.PurchaseID,
                    Purchasedate: row.Purchasedate,
                    Productname: row.Productname,
                    Productnarrationtext1: row.Productnarrationtext1,
                    Productnarrationtext2: row.Productnarrationtext2,
                    Productnarrationtext3: row.Productnarrationtext3,
                    HSNCode: row.HSNCode,
                    Purchaserate: row.Purchaserate?.toString(),
                    Qty: row.Qty?.toString(),
                    UOM: row.UOM,
                    Amount: row.Amount?.toString(),
                    Discount: row.Discount?.toString(),
                    DiscountAmount: row.DiscountAmount?.toString(),
                    CGSTPercentage: row['CGST%']?.toString(),
                    CGSTAmount: row.CGSTAmount?.toString(),
                    SGSTPercentage: row['SGST%']?.toString(),
                    SGSTAmount: row.SGSTAmount?.toString(),
                    IGSTPercentage: row['IGST%']?.toString(),
                    IGSTAmount: row.IGSTAmount?.toString(),
                    TotalAmount: row.TotalAmount?.toString(),
                    Status: row.Status,
                    Purchasetype: row.Purchasetype,
                    StockQty: row.StockQty?.toString(),
                    ParticularID: row.ParticularID,
                    GodownID: row.GodownID,
                    Financeyear: row.Financeyear
                }
            });
        }

        // 6. Legacy Payroll Employees
        const legacyEmpPath = path.join(exportDir, 'Payroll_Masters_EmployeeMasterDB.json');
        if (fs.existsSync(legacyEmpPath)) {
            console.log('Migrating Legacy Payroll Employees...');
            const emps = JSON.parse(fs.readFileSync(legacyEmpPath, 'utf8'));
            for (const e of emps) {
                await prisma.legacy_Employee.create({
                    data: {
                        EmployeeID: e.EmployeeID,
                        EmployeeName: e.EmployeeName,
                        Status: e.Status,
                        BonusPercentage: String(e.BonusPercentage || ''),
                        City: e.City
                    }
                });
            }
        }

        // 7. Legacy Payroll Products (Particulars)
        const legacyPayProdPath = path.join(exportDir, 'Payroll_Masters_ParticularmasteerDB.json');
        if (fs.existsSync(legacyPayProdPath)) {
            console.log('Migrating Legacy Payroll Products...');
            const prods = JSON.parse(fs.readFileSync(legacyPayProdPath, 'utf8'));
            for (const p of prods) {
                await prisma.legacy_PayrollProduct.create({
                    data: {
                        ParticularID: String(p.ParticularID || ''),
                        Particularname: String(p.Particularname || ''),
                        Status: p.Status,
                        GroupID: p.GroupID,
                        ProductRate: String(p.ProductRate || ''),
                        RatePer: p.RatePer,
                        Unit: String(p.Unit || '')
                    }
                });
            }
        }

        // 8. Legacy Advances
        const legacyAdvPath = path.join(exportDir, 'Payroll_Transactions_AdvanceDB.json');
        if (fs.existsSync(legacyAdvPath)) {
            console.log('Migrating Legacy Advances...');
            const advs = JSON.parse(fs.readFileSync(legacyAdvPath, 'utf8'));
            for (const a of advs) {
                await prisma.legacy_Advance.create({
                    data: {
                        Id: a.Id,
                        Date: a.Date,
                        EmployeeID: a.EmployeeID,
                        Amount: String(a.Amount || ''),
                        Narration: String(a.Narration || ''),
                        Status: a.Status,
                        Paidamount: String(a.Paidamount || '')
                    }
                });
            }
        }

        // 9. Legacy Work Entries
        const legacyWkPath = path.join(exportDir, 'Payroll_Transactions_WorkentryDB.json');
        if (fs.existsSync(legacyWkPath)) {
            console.log('Migrating Legacy Work Entries (this might take a moment)...');
            const works = JSON.parse(fs.readFileSync(legacyWkPath, 'utf8'));
            
            const batchSize = 1000;
            for (let i = 0; i < works.length; i += batchSize) {
                const batch = works.slice(i, i + batchSize).map(w => ({
                    ID: w.ID,
                    EmployeeId: w.EmployeeId,
                    Workerdate: w.Workerdate,
                    Netamount: String(w.Netamount || ''),
                    Amount: String(w.Amount || ''),
                    Others: String(w.Others || ''),
                    AdvancePaid: String(w.AdvancePaid || ''),
                    AdvanceReceive: String(w.AdvanceReceive || ''),
                    status: w.status
                }));
                await prisma.legacy_Workentry.createMany({ data: batch });
            }
        }

        // 10. Legacy Work Entry Particulars
        const legacyWkPartPath = path.join(exportDir, 'Payroll_Transactions_WorkentryParticularsDB.json');
        if (fs.existsSync(legacyWkPartPath)) {
            console.log('Migrating Legacy Work Entry Particulars (this might take a moment)...');
            const parts = JSON.parse(fs.readFileSync(legacyWkPartPath, 'utf8'));
            
            const batchSize = 1000;
            for (let i = 0; i < parts.length; i += batchSize) {
                const batch = parts.slice(i, i + batchSize).map(p => ({
                    ID: p.ID,
                    Workerdate: p.Workerdate,
                    EmployeeId: p.EmployeeId,
                    Amount: String(p.Amount || ''),
                    Others: String(p.Others || ''),
                    Netamount: String(p.Netamount || ''),
                    SNo: p.SNo,
                    Wagesdate: p.Wagesdate,
                    ProductID: p.ProductID,
                    Qty: p.Qty ? parseFloat(p.Qty) : 0,
                    Rate: String(p.Rate || ''),
                    Rateper: p.Rateper,
                    Unit: String(p.Unit || '')
                }));
                await prisma.legacy_WorkentryParticular.createMany({ data: batch });
            }
        }

        // 11. Legacy Payments
        const payPath = path.join(exportDir, 'Transactions_PaymentDB.json');
        if (fs.existsSync(payPath)) {
            console.log('Migrating Legacy Payments...');
            const pays = JSON.parse(fs.readFileSync(payPath, 'utf8'));
            for (const p of pays) {
                await prisma.legacy_Payment.create({
                    data: {
                        PaymentID: p.PaymentID,
                        Paymentdate: p.Paymentdate,
                        Suppliername: p.Suppliername,
                        Paymentamount: String(p.Paymentamount || ''),
                        Narration: String(p.Narration || ''),
                        Paymenttype: p.Paymenttype,
                        Invoiceno: String(p.Invoiceno || ''),
                        Status: p.Status
                    }
                });
            }
        }

        // 12. Legacy Estimates
        const estPath = path.join(exportDir, 'Transactions_EstimateDB.json');
        if (fs.existsSync(estPath)) {
            console.log('Migrating Legacy Estimates...');
            const ests = JSON.parse(fs.readFileSync(estPath, 'utf8'));
            for (const e of ests) {
                await prisma.legacy_Estimate.create({
                    data: {
                        SalesID: e.SalesID,
                        Salesdate: e.Salesdate,
                        Customeraccountnumber: e.Customeraccountnumber,
                        Netamount: String(e.Netamount || ''),
                        Subtotal: String(e.Subtotal || ''),
                        Salestype: e.Salestype,
                        Transport: e.Transport,
                        Status: e.Status
                    }
                });
            }
        }

        // 13. Legacy Estimate Particulars
        const estPartPath = path.join(exportDir, 'Transactions_EstimateparticularsDB.json');
        if (fs.existsSync(estPartPath)) {
            console.log('Migrating Legacy Estimate Particulars...');
            const parts = JSON.parse(fs.readFileSync(estPartPath, 'utf8'));
            for (const p of parts) {
                await prisma.legacy_EstimateParticular.create({
                    data: {
                        SalesID: p.SalesID,
                        Productname: String(p.Productname || ''),
                        Salesrate: String(p.Salesrate || ''),
                        Cases: p.Cases,
                        Quantity: p.Quantity,
                        Totalamount: String(p.Totalamount || ''),
                        Status: p.Status
                    }
                });
            }
        }

        // 14. Legacy Estimate Charges
        const estChgPath = path.join(exportDir, 'Transactions_EstimatechargesDB.json');
        if (fs.existsSync(estChgPath)) {
            console.log('Migrating Legacy Estimate Charges...');
            const chgs = JSON.parse(fs.readFileSync(estChgPath, 'utf8'));
            for (const c of chgs) {
                await prisma.legacy_EstimateCharge.create({
                    data: {
                        SalesID: c.SalesID,
                        ChargeName: String(c.ChargeName || ''),
                        ChargeAmount1: String(c.ChargeAmount1 || ''),
                        ChargeAmount2: String(c.ChargeAmount2 || ''),
                        Status: c.Status
                    }
                });
            }
        }

        // 15. Legacy Purchase Charges
        const purChgPath = path.join(exportDir, 'Transactions_PurchaseChargesDB.json');
        if (fs.existsSync(purChgPath)) {
            console.log('Migrating Legacy Purchase Charges...');
            const chgs = JSON.parse(fs.readFileSync(purChgPath, 'utf8'));
            for (const c of chgs) {
                await prisma.legacy_PurchaseCharge.create({
                    data: {
                        PurchaseID: c.PurchaseID,
                        ChargeName: String(c.ChargeName || ''),
                        ChargeAmount1: String(c.ChargeAmount1 || ''),
                        ChargeAmount2: String(c.ChargeAmount2 || ''),
                        Status: c.Status
                    }
                });
            }
        }

        // 16. Legacy Chemical Particulars
        const chemPartPath = path.join(exportDir, 'Masters_ChemicalsParticularsDB.json');
        if (fs.existsSync(chemPartPath)) {
            console.log('Migrating Legacy Chemical Particulars...');
            const parts = JSON.parse(fs.readFileSync(chemPartPath, 'utf8'));
            for (const p of parts) {
                await prisma.legacy_ChemicalParticular.create({
                    data: {
                        ProductId: p.ProductId,
                        GodownID: p.GodownID,
                        Opening: String(p.Opening || ''),
                        Status: p.Status
                    }
                });
            }
        }

        console.log("\nALL LEGACY DATA IMPORTED SUCCESSFULLY!");
    } catch (e) {
        console.error("Error importing data:", e);
    } finally {
        await prisma.$disconnect();
    }
}

importData();
