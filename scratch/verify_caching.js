const fs = require('fs');
const path = require('path');

const billingFile = path.join(__dirname, '../frontend/src/pages/Billing.jsx');

if (fs.existsSync(billingFile)) {
  const content = fs.readFileSync(billingFile, 'utf8');
  
  const checks = [
    { name: 'useProducts hook', regex: /useProducts\(\)/ },
    { name: 'useCustomers hook', regex: /useCustomers\(\)/ },
    { name: 'useSaveInvoice mutation', regex: /useSaveInvoice\(\)/ },
    { name: 'Removed raw API fetch for products', regex: /erpApi\.getProducts\(\)\.then/, expectMissing: true },
  ];

  let passed = 0;
  checks.forEach(check => {
    const found = check.regex.test(content);
    if (check.expectMissing ? !found : found) {
      console.log(`✅ Passed: ${check.name}`);
      passed++;
    } else {
      console.log(`❌ Failed: ${check.name}`);
    }
  });

  if (passed === checks.length) {
    console.log('\nAll caching architecture validations passed!');
    process.exit(0);
  } else {
    console.log('\nValidation failed.');
    process.exit(1);
  }
} else {
  console.log('Billing.jsx not found');
  process.exit(1);
}
