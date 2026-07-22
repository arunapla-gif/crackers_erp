const express = require('express');
const cors = require('cors');
const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

const JWT_SECRET = process.env.JWT_SECRET || 'crackers-erp-super-secret-key-2026';

// Seed Admin User
async function seedAdmin() {
  try {
    const adminExists = await prisma.user.findFirst({ where: { role: 'ADMIN' } });
    if (!adminExists) {
      const hashedPin = await bcrypt.hash('1234', 10);
      await prisma.user.create({
        data: {
          username: 'admin',
          pin: hashedPin,
          role: 'ADMIN',
          status: 'Active',
          permissions: {
            "billing": { "view": true, "add": true, "edit": true, "delete": true },
            "customers": { "view": true, "add": true, "edit": true, "delete": true },
            "suppliers": { "view": true, "add": true, "edit": true, "delete": true },
            "products": { "view": true, "add": true, "edit": true, "delete": true },
            "transporters": { "view": true, "add": true, "edit": true, "delete": true },
            "godowns": { "view": true, "add": true, "edit": true, "delete": true },
            "purchase": { "view": true, "add": true, "edit": true, "delete": true },
            "stock": { "view": true, "add": true, "edit": true, "delete": true },
            "vehicles": { "view": true, "add": true, "edit": true, "delete": true },
            "transfers": { "view": true, "add": true, "edit": true, "delete": true },
            "production": { "view": true, "add": true, "edit": true, "delete": true },
            "materials": { "view": true, "add": true, "edit": true, "delete": true },
            "machines": { "view": true, "add": true, "edit": true, "delete": true },
            "reports": { "view": true, "add": true, "edit": true, "delete": true },
            "employees": { "view": true, "add": true, "edit": true, "delete": true },
            "payroll": { "view": true, "add": true, "edit": true, "delete": true }
          }
        }
      });
      console.log('Seeded default admin user (admin / 1234)');
    }
  } catch (err) {
    console.error('Error seeding admin:', err);
  }
}
seedAdmin();

// Auth Routes
app.post('/api/login', async (req, res) => {
  const { username, pin } = req.body;
  try {
    const user = await prisma.user.findUnique({ where: { username } });
    if (!user) return res.status(401).json({ error: 'Invalid username or PIN' });
    if (user.status !== 'Active') return res.status(401).json({ error: 'Account is inactive' });

    const validPin = await bcrypt.compare(pin, user.pin);
    if (!validPin) return res.status(401).json({ error: 'Invalid username or PIN' });

    const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '24h' });
    
    // Don't send PIN hash back
    const { pin: _, ...userWithoutPin } = user;
    res.json({ token, user: userWithoutPin });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Health check endpoint for cron jobs (Render keep-alive)
app.get('/api/ping', (req, res) => {
  res.status(200).send('pong');
});

// --- SECURITY MIDDLEWARE ---
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Access denied. No token provided.' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ error: 'Invalid or expired token.' });
    req.user = user;
    next();
  });
};

const requireAdmin = (req, res, next) => {
  if (req.user && req.user.role === 'ADMIN') {
    next();
  } else {
    return res.status(403).json({ error: 'Admin privileges required.' });
  }
};

// Apply authentication to all routes below this point
app.use(authenticateToken);

// Apply admin requirement to sensitive routes
app.use('/api/users', requireAdmin);
app.use('/api/system-credentials', requireAdmin);
// ---------------------------

// User Management Routes
app.get('/api/users', async (req, res) => {
  try {
    const users = await prisma.user.findMany({
      select: { id: true, username: true, role: true, permissions: true, status: true, createdAt: true }
    });
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/reps', async (req, res) => {
  try {
    const reps = await prisma.user.findMany({
      where: { role: 'REP', status: 'Active' },
      select: { id: true, username: true }
    });
    res.json(reps);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/users', async (req, res) => {
  const { id, username, pin, role, status, permissions } = req.body;
  try {
    let hashedPin = undefined;
    if (pin) {
      hashedPin = await bcrypt.hash(pin, 10);
    }
    
    if (id) {
      // Update
      const dataToUpdate = { username, role, status, permissions };
      if (hashedPin) dataToUpdate.pin = hashedPin;
      
      const user = await prisma.user.update({
        where: { id: parseInt(id) },
        data: dataToUpdate
      });
      res.json(user);
    } else {
      // Create
      if (!pin) return res.status(400).json({ error: 'PIN is required for new users' });
      const user = await prisma.user.create({
        data: { username, pin: hashedPin, role, status, permissions }
      });
      res.json(user);
    }
  } catch (err) {
    if (err.code === 'P2002') return res.status(400).json({ error: 'Username already exists' });
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/users/:id', async (req, res) => {
  try {
    await prisma.user.delete({ where: { id: parseInt(req.params.id) } });
    res.json({ message: 'User deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Customers Routes
app.get('/api/customers', async (req, res) => {
  try {
    const where = {};
    if (req.user && req.user.role === 'REP') {
      where.repId = req.user.id;
    }
    const customers = await prisma.customer.findMany({ where });
    res.json(customers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/customers', async (req, res) => {
  const { id, name, mobile, reference, address, city, district, state, pincode, id_number, gstin, status, addresses, repId } = req.body;
  const currentStatus = status || 'Active';
  try {
    const dataObj = { 
      name, mobile, reference, address, city, district, state, pincode, id_number, gstin, status: currentStatus, addresses,
      repId: repId ? parseInt(repId) : null
    };

    if (id) {
      const customer = await prisma.customer.update({
        where: { id: parseInt(id) },
        data: dataObj
      });
      return res.json(customer);
    } else {
      const customer = await prisma.customer.upsert({
        where: { name },
        update: dataObj,
        create: dataObj,
      });
      return res.json(customer);
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Suppliers Routes
app.get('/api/suppliers', async (req, res) => {
  try {
    const suppliers = await prisma.supplier.findMany();
    res.json(suppliers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/suppliers', async (req, res) => {
  const { id, name, mobile, reference, address, city, district, state, pincode, id_number, gstin, status, addresses } = req.body;
  const currentStatus = status || 'Active';
  try {
    if (id) {
      const supplier = await prisma.supplier.update({
        where: { id: parseInt(id) },
        data: { name, mobile, reference, address, city, district, state, pincode, id_number, gstin, status: currentStatus, addresses }
      });
      return res.json(supplier);
    } else {
      const supplier = await prisma.supplier.upsert({
        where: { name },
        update: { mobile, reference, address, city, district, state, pincode, id_number, gstin, status: currentStatus, addresses },
        create: { name, mobile, reference, address, city, district, state, pincode, id_number, gstin, status: currentStatus, addresses },
      });
      return res.json(supplier);
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Products Routes
app.get('/api/products', async (req, res) => {
  try {
    const products = await prisma.product.findMany();
    
    // Rep Restriction Logic
    if (req.user && req.user.role === 'REP') {
      const allowedCategories = req.user.permissions?.allowedCategories;
      if (Array.isArray(allowedCategories) && allowedCategories.length > 0) {
        const filteredProducts = products.filter(p => allowedCategories.includes(p.category));
        return res.json(filteredProducts);
      }
    }
    
    res.json(products);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Customer Prices Route
app.get('/api/customers/:id/prices', async (req, res) => {
  try {
    const prices = await prisma.customerPrice.findMany({
      where: { customerId: parseInt(req.params.id) }
    });
    res.json(prices);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/customers/:id/prices', requireAdmin, async (req, res) => {
  const { prices } = req.body; // Array of { productId, rate }
  const customerId = parseInt(req.params.id);
  
  try {
    await prisma.$transaction(async (tx) => {
      // Clear old prices for these products or all?
      // Better to upsert individual rows to not lose data on partial saves, 
      // but if the UI sends the whole sheet, we can clear and recreate.
      await tx.customerPrice.deleteMany({
        where: { customerId }
      });
      
      const validPrices = prices.filter(p => p.rate !== null && p.rate !== undefined && p.rate !== '');
      if (validPrices.length > 0) {
        await tx.customerPrice.createMany({
          data: validPrices.map(p => ({
            customerId,
            productId: parseInt(p.productId),
            rate: parseFloat(p.rate)
          }))
        });
      }
    });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/products/next-code', async (req, res) => {
  try {
    const { type } = req.query;
    const prefix = type || 'INV';
    
    const products = await prisma.product.findMany({ select: { code: true } });
    
    const maxNum = products.reduce((max, p) => {
      if (p.code.startsWith(prefix)) {
        const match = p.code.match(/(\d+)$/);
        if (match) {
          const num = parseInt(match[1]);
          return num > max ? num : max;
        }
      }
      return max;
    }, 0);
    
    const nextNum = maxNum + 1;
    const nextCode = `${prefix}${String(nextNum).padStart(3, '0')}`;
    res.json({ code: nextCode });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/products', async (req, res) => {
  const { code, name, type, category, hsn, tax, rate, unit_qty, unit, pack_unit, status, factoryAliasId } = req.body;
  try {
    const product = await prisma.product.upsert({
      where: { code },
      update: { name, type, category, hsn, tax, rate, unit_qty, unit, pack_unit, status, factoryAliasId },
      create: { code, name, type, category, hsn, tax, rate, unit_qty, unit, pack_unit, status, factoryAliasId },
    });
    res.json(product);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Invoices Routes
app.get('/api/invoices/:number', async (req, res) => {
  try {
    const invoice = await prisma.invoice.findUnique({
      where: { number: req.params.number },
      include: { items: true, charges: true, companyProfile: true }
    });
    if (!invoice) return res.status(404).json({ error: 'Invoice not found' });
    res.json(invoice);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/invoices', async (req, res) => {
  const { series, number, date, customer, customerAddress, state, vehicleNo, distance, transporterId, ewayBillNo, companyProfileId, dispatchAddress, subtotal, cgst, sgst, igst, tax, grand_total, items, charges, repId } = req.body;
  try {
    const invoice = await prisma.$transaction(async (tx) => {
      const isNew = !(await tx.invoice.findUnique({ where: { number } }));
      
      const dataObj = { 
        series, date: new Date(date), customer, customerAddress, state, vehicleNo, distance: distance ? parseInt(distance) : null, transporterId, ewayBillNo, companyProfileId: companyProfileId ? parseInt(companyProfileId) : null, dispatchAddress, subtotal, cgst, sgst, igst, tax, grand_total,
        repId: repId ? parseInt(repId) : null
      };

      const inv = await tx.invoice.upsert({
        where: { number },
        update: dataObj,
        create: { number, ...dataObj },
      });

      if (isNew && series && companyProfileId) {
        const billingSeries = await tx.billingSeries.findFirst({
          where: { companyProfileId: parseInt(companyProfileId), prefix: series }
        });
        if (billingSeries) {
          let remaining = number;
          if (number.startsWith(series)) {
            remaining = number.substring(series.length);
          }
          const match = remaining.match(/(\d+)/);
          const parsedNum = match ? parseInt(match[1]) : 0;
          
          if (parsedNum >= billingSeries.lastNumber) {
            await tx.billingSeries.update({
              where: { id: billingSeries.id },
              data: { lastNumber: parsedNum }
            });
          }
        }
      }

      // Clear old items and charges if updating
      await tx.invoiceItem.deleteMany({ where: { invoiceId: inv.id } });
      await tx.invoiceCharge.deleteMany({ where: { invoiceId: inv.id } });

      // Insert new items
      if (items && items.length > 0) {
        await tx.invoiceItem.createMany({
          data: items.map(item => ({
            invoiceId: inv.id,
            productId: item.productId || null,
            product: item.product,
            hsn: item.hsn,
            qty: item.qty,
            rate: item.rate,
            tax: item.tax,
            total: item.total
          }))
        });
      }

      // Insert new charges
      if (charges && charges.length > 0) {
        await tx.invoiceCharge.createMany({
          data: charges.map(charge => ({
            invoiceId: inv.id,
            name: charge.name,
            source: charge.source,
            mode: charge.mode,
            type: charge.type,
            value: charge.value,
            amount: charge.amount
          }))
        });
      }

      return inv;
    });
    res.json(invoice);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// E-Way Bill Generation via GSTZen
app.post('/api/invoices/:number/ewaybill', async (req, res) => {
  try {
    const invoice = await prisma.invoice.findUnique({
      where: { number: req.params.number },
      include: { items: true, companyProfile: true }
    });

    if (!invoice) return res.status(404).json({ error: 'Invoice not found' });

    // TODO: Implement Whitebooks E-Way Bill generation using the credentials
    // from process.env (WHITEBOOKS_USERNAME, WHITEBOOKS_PASSWORD, etc.)
    
    return res.status(501).json({ error: 'E-Way Bill generation via Whitebooks API is pending implementation.' });

  } catch (err) {
    console.error("E-Way Bill Generation Error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// System Credentials Route
app.get('/api/system-credentials', async (req, res) => {
  try {
    res.json({
      WHITEBOOKS_USERNAME: process.env.WHITEBOOKS_USERNAME,
      WHITEBOOKS_PASSWORD: process.env.WHITEBOOKS_PASSWORD,
      WHITEBOOKS_GSTIN: process.env.WHITEBOOKS_GSTIN,
      WHITEBOOKS_CLIENT_ID: process.env.WHITEBOOKS_CLIENT_ID,
      WHITEBOOKS_EMAIL: process.env.WHITEBOOKS_EMAIL,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Godowns Routes
app.get('/api/godowns', async (req, res) => {
  try {
    const godowns = await prisma.godown.findMany({ orderBy: { name: 'asc' } });
    res.json(godowns);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/godowns', async (req, res) => {
  try {
    const { name } = req.body;
    const godown = await prisma.godown.upsert({
      where: { name },
      update: { name },
      create: { name }
    });
    res.json(godown);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Transporters Routes
app.get('/api/transporters', async (req, res) => {
  try {
    const transporters = await prisma.transporter.findMany({ orderBy: { name: 'asc' } });
    res.json(transporters);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/transporters', async (req, res) => {
  const { gstin, name, address, city, district, state, pincode, status } = req.body;
  try {
    const transporter = await prisma.transporter.upsert({
      where: { gstin },
      update: { name, address, city, district, state, pincode, status },
      create: { gstin, name, address, city, district, state, pincode, status },
    });
    res.json(transporter);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Purchases Routes
app.post('/api/purchases', async (req, res) => {
  const { id, number, date, supplier, billNo, qty, subtotal, tax, cgst, sgst, igst, discount, value, items, status } = req.body;
  const currentStatus = status || 'Active';
  try {
    const result = await prisma.$transaction(async (tx) => {
      // 1. If updating, reverse old stock first
      if (id) {
        const oldPurchase = await tx.purchase.findUnique({
          where: { id: parseInt(id) },
          include: { items: true }
        });
        
        if (oldPurchase && oldPurchase.status === 'Active') {
          for (const oldItem of oldPurchase.items) {
            const stock = await tx.stockLedger.findUnique({
              where: { godownId_product: { godownId: oldItem.godownId, product: oldItem.product } }
            });
            if (stock) {
              const newQty = stock.qty - oldItem.qty;
              const newValue = parseFloat(stock.value) - parseFloat(oldItem.amount);
              await tx.stockLedger.update({
                where: { id: stock.id },
                data: { 
                  qty: newQty, 
                  value: newValue, 
                  avgRate: newQty > 0 ? newValue / newQty : 0 
                }
              });
            }
          }
        }
        // Delete old items
        await tx.purchaseItem.deleteMany({ where: { purchaseId: parseInt(id) } });
      }

      // 2. Upsert Purchase
      const purchase = await tx.purchase.upsert({
        where: { number },
        update: { date: new Date(date), supplier, billNo, qty, subtotal, tax, cgst: cgst || 0, sgst: sgst || 0, igst: igst || 0, discount, value, status: currentStatus },
        create: { number, date: new Date(date), supplier, billNo, qty, subtotal, tax, cgst: cgst || 0, sgst: sgst || 0, igst: igst || 0, discount, value, status: currentStatus },
      });

      // 3. Insert new items
      if (items && items.length > 0) {
        await tx.purchaseItem.createMany({
          data: items.map(item => ({
            purchaseId: purchase.id,
            godownId: item.godownId,
            productId: item.productId || null,
            product: item.product,
            packs: item.packs || 0,
            pack_unit: item.pack_unit || null,
            pricing_unit: item.pricing_unit || null,
            qty: item.qty,
            rate: item.rate,
            amount: item.amount,
            discount: item.discount || 0,
            tax_rate: item.tax_rate || 18,
            tax_amt: item.tax_amt || 0,
            net_amount: item.net_amount || item.amount
          }))
        });
      }

      // 4. If Active, increment stock ledger
      if (currentStatus === 'Active') {
        for (const item of items) {
          const existingStock = await tx.stockLedger.findUnique({
            where: { godownId_product: { godownId: item.godownId, product: item.product } }
          });

          if (existingStock) {
            const newQty = existingStock.qty + item.qty;
            const newValue = parseFloat(existingStock.value) + parseFloat(item.amount);
            const newAvgRate = newQty > 0 ? newValue / newQty : 0;
            await tx.stockLedger.update({
              where: { id: existingStock.id },
              data: { qty: newQty, value: newValue, avgRate: newAvgRate }
            });
          } else {
            await tx.stockLedger.create({
              data: {
                godownId: item.godownId,
                productId: item.productId || null,
                product: item.product,
                qty: item.qty,
                value: item.amount,
                avgRate: item.rate
              }
            });
          }
        }
      }

      return await tx.purchase.findUnique({ where: { id: purchase.id }, include: { items: true } });
    });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/purchases/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const result = await prisma.$transaction(async (tx) => {
      const purchase = await tx.purchase.findUnique({
        where: { id: parseInt(req.params.id) },
        include: { items: true }
      });

      if (!purchase || purchase.status === status) return purchase;

      await tx.purchase.update({
        where: { id: purchase.id },
        data: { status }
      });

      for (const item of purchase.items) {
        const stock = await tx.stockLedger.findUnique({
          where: { godownId_product: { godownId: item.godownId, product: item.product } }
        });

        if (stock) {
          let newQty, newValue;
          if (status === 'Inactive') {
            newQty = stock.qty - item.qty;
            newValue = parseFloat(stock.value) - parseFloat(item.amount);
          } else {
            newQty = stock.qty + item.qty;
            newValue = parseFloat(stock.value) + parseFloat(item.amount);
          }
          await tx.stockLedger.update({
            where: { id: stock.id },
            data: { 
              qty: newQty, 
              value: newValue, 
              avgRate: newQty > 0 ? newValue / newQty : 0 
            }
          });
        }
      }
      return purchase;
    });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Stock Ledger Routes
app.get('/api/stock', async (req, res) => {
  try {
    const stock = await prisma.stockLedger.findMany({
      include: { godown: true },
      where: { qty: { gt: 0 } },
      orderBy: { product: 'asc' }
    });
    res.json(stock);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Vehicles Routes
app.get('/api/vehicles', async (req, res) => {
  try {
    const vehicles = await prisma.vehicle.findMany({ orderBy: { no: 'asc' } });
    res.json(vehicles);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/vehicles', async (req, res) => {
  try {
    const { no, name, owner_name, owner_phone, drivers } = req.body;
    const vehicle = await prisma.vehicle.upsert({
      where: { no },
      update: { name, owner_name, owner_phone, drivers },
      create: { no, name, owner_name, owner_phone, drivers }
    });
    res.json(vehicle);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Transfers Routes
app.post('/api/transfers', async (req, res) => {
  const { number, date, vehicleId, driverName, remarks, qty, items } = req.body;
  try {
    const result = await prisma.$transaction(async (tx) => {
      // 1. Check stock availability for all items first
      for (const item of items) {
        const sourceStock = await tx.stockLedger.findUnique({
          where: { godownId_product: { godownId: item.fromGodownId, product: item.product } }
        });

        if (!sourceStock || sourceStock.qty < item.qty) {
          throw new Error(`Insufficient stock for ${item.product} in source godown.`);
        }
      }

      // 2. Create the transfer document
      const transfer = await tx.stockTransfer.create({
        data: {
          number, date: new Date(date), vehicleId, driverName, remarks, qty,
          items: {
            create: items.map(item => ({
              fromGodownId: item.fromGodownId,
              toGodownId: item.toGodownId,
              productId: item.productId || null,
              product: item.product,
              qty: item.qty,
              rate: item.rate,
              value: item.value
            }))
          }
        },
        include: { items: true }
      });

      // 3. Update Stock Ledger for both Godowns
      for (const item of items) {
        // Decrement source
        const sourceStock = await tx.stockLedger.findUnique({
          where: { godownId_product: { godownId: item.fromGodownId, product: item.product } }
        });
        await tx.stockLedger.update({
          where: { id: sourceStock.id },
          data: {
            qty: sourceStock.qty - item.qty,
            value: parseFloat(sourceStock.value) - parseFloat(item.value),
            avgRate: (sourceStock.qty - item.qty) > 0 ? (parseFloat(sourceStock.value) - parseFloat(item.value)) / (sourceStock.qty - item.qty) : item.rate
          }
        });

        // Increment destination
        const destStock = await tx.stockLedger.findUnique({
          where: { godownId_product: { godownId: item.toGodownId, product: item.product } }
        });

        if (destStock) {
          const newQty = destStock.qty + item.qty;
          const newValue = parseFloat(destStock.value) + parseFloat(item.value);
          await tx.stockLedger.update({
            where: { id: destStock.id },
            data: {
              qty: newQty,
              value: newValue,
              avgRate: newQty > 0 ? newValue / newQty : item.rate
            }
          });
        } else {
          await tx.stockLedger.create({
            data: {
              godownId: item.toGodownId,
              productId: item.productId || null,
              product: item.product,
              qty: item.qty,
              value: item.value,
              avgRate: item.rate
            }
          });
        }
      }

      return transfer;
    });
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// History Routes for Reports
app.get('/api/history/invoices', async (req, res) => {
  try {
    const where = {};
    if (req.user && req.user.role === 'REP') {
      where.repId = req.user.id;
    }
    const invoices = await prisma.invoice.findMany({
      where,
      orderBy: { date: 'desc' },
      include: { items: true, charges: true }
    });
    res.json(invoices);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/history/purchases', async (req, res) => {
  try {
    const purchases = await prisma.purchase.findMany({
      orderBy: { date: 'desc' },
      include: { items: { include: { godown: true } } }
    });
    res.json(purchases);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/history/transfers', async (req, res) => {
  try {
    const transfers = await prisma.stockTransfer.findMany({
      orderBy: { date: 'desc' },
      include: { 
        vehicle: true,
        items: { include: { fromGodown: true, toGodown: true } } 
      }
    });
    res.json(transfers);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Employees Routes
app.get('/api/employees', async (req, res) => {
  try {
    const employees = await prisma.employee.findMany();
    res.json(employees);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/employees', async (req, res) => {
  const { id, name, mobile, role, salary, paymentType, unit, status } = req.body;
  const currentStatus = status || 'Active';
  try {
    if (id) {
      const employee = await prisma.employee.update({
        where: { id: parseInt(id) },
        data: { name, mobile, role, salary: parseFloat(salary || 0), paymentType: paymentType || 'Monthly', unit: unit || null, status: currentStatus }
      });
      return res.json(employee);
    } else {
      const employee = await prisma.employee.create({
        data: { name, mobile, role, salary: parseFloat(salary || 0), paymentType: paymentType || 'Monthly', unit: unit || null, status: currentStatus }
      });
      return res.json(employee);
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/employees/:id', async (req, res) => {
  try {
    await prisma.employee.delete({ where: { id: parseInt(req.params.id) } });
    res.json({ message: 'Employee deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Payroll Routes
app.get('/api/payrolls', async (req, res) => {
  try {
    const payrolls = await prisma.payroll.findMany({
      include: { employee: true },
      orderBy: { createdAt: 'desc' }
    });
    res.json(payrolls);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/payrolls', async (req, res) => {
  const { employeeId, month, paymentType, daysWorked, basicSalary, allowance, deduction, netSalary, status, periodStr } = req.body;
  try {
    const result = await prisma.$transaction(async (tx) => {
      const payroll = await tx.payroll.create({
        data: {
          employeeId: parseInt(employeeId),
          month,
          paymentType: paymentType || 'Monthly',
          daysWorked: parseInt(daysWorked || 0),
          basicSalary: parseFloat(basicSalary || 0),
          allowance: parseFloat(allowance || 0),
          deduction: parseFloat(deduction || 0),
          netSalary: parseFloat(netSalary || 0),
          status: status || 'Paid'
        },
        include: { employee: true }
      });

      const deductAmt = parseFloat(deduction || 0);
      if (deductAmt > 0) {
        // Log it as RECOVERED advance
        await tx.employeeAdvance.create({
          data: {
            employeeId: parseInt(employeeId),
            date: new Date(),
            type: "RECOVERED",
            amount: deductAmt,
            description: `Payroll Deduction (${periodStr || month})`
          }
        });

        // Decrement advance balance
        const emp = await tx.employee.findUnique({ where: { id: parseInt(employeeId) }});
        if (emp) {
          const newBalance = parseFloat(emp.advanceBalance) - deductAmt;
          await tx.employee.update({
            where: { id: parseInt(employeeId) },
            data: { advanceBalance: newBalance >= 0 ? newBalance : 0 }
          });
        }
      }

      return payroll;
    });

    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Employee Advances Routes
app.get('/api/advances/:employeeId', async (req, res) => {
  try {
    const advances = await prisma.employeeAdvance.findMany({
      where: { employeeId: parseInt(req.params.employeeId) },
      orderBy: { date: 'desc' }
    });
    res.json(advances);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/advances', async (req, res) => {
  const { employeeId, date, amount, description } = req.body;
  try {
    const result = await prisma.$transaction(async (tx) => {
      const advance = await tx.employeeAdvance.create({
        data: {
          employeeId: parseInt(employeeId),
          date: new Date(date),
          type: "GIVEN",
          amount: parseFloat(amount),
          description: description || "Advance Given"
        }
      });

      const emp = await tx.employee.findUnique({ where: { id: parseInt(employeeId) } });
      if (emp) {
        await tx.employee.update({
          where: { id: parseInt(employeeId) },
          data: { advanceBalance: parseFloat(emp.advanceBalance) + parseFloat(amount) }
        });
      }

      return advance;
    });
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Daily Production Routes
app.get('/api/production/daily', async (req, res) => {
  try {
    const records = await prisma.dailyProduction.findMany({
      include: { employee: true, items: true },
      orderBy: { date: 'desc' }
    });
    res.json(records);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/production/daily', async (req, res) => {
  const { id, date, employeeId, totalAmount, items } = req.body;
  try {
    if (id) {
      // First delete existing items
      await prisma.dailyProductionItem.deleteMany({ where: { dailyProductionId: parseInt(id) } });
      const record = await prisma.dailyProduction.update({
        where: { id: parseInt(id) },
        data: {
          date: new Date(date),
          employeeId: parseInt(employeeId),
          totalAmount: parseFloat(totalAmount || 0),
          items: {
            create: items.map(item => ({
              itemName: item.itemName,
              quantity: parseInt(item.quantity || 0),
              pieceRate: parseFloat(item.pieceRate || 0),
              total: parseFloat(item.total || 0)
            }))
          }
        },
        include: { items: true, employee: true }
      });
      return res.json(record);
    } else {
      const record = await prisma.dailyProduction.create({
        data: {
          date: new Date(date),
          employeeId: parseInt(employeeId),
          totalAmount: parseFloat(totalAmount || 0),
          items: {
            create: items.map(item => ({
              itemName: item.itemName,
              quantity: parseInt(item.quantity || 0),
              pieceRate: parseFloat(item.pieceRate || 0),
              total: parseFloat(item.total || 0)
            }))
          }
        },
        include: { items: true, employee: true }
      });
      return res.json(record);
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/production/daily/:id', async (req, res) => {
  try {
    await prisma.dailyProduction.delete({ where: { id: parseInt(req.params.id) } });
    res.json({ message: 'Daily production deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/production/aggregate', async (req, res) => {
  const { employeeId, startDate, endDate } = req.query; // 'YYYY-MM-DD' format
  try {
    if (!employeeId || !startDate || !endDate) {
      return res.status(400).json({ error: 'employeeId, startDate, and endDate are required' });
    }
    
    // Parse the dates
    const start = new Date(startDate);
    start.setHours(0, 0, 0, 0);
    const end = new Date(endDate);
    end.setHours(23, 59, 59, 999);

    const aggregate = await prisma.dailyProduction.aggregate({
      where: {
        employeeId: parseInt(employeeId),
        date: {
          gte: start,
          lte: end,
        }
      },
      _sum: {
        totalAmount: true
      }
    });

    const details = await prisma.dailyProduction.findMany({
      where: {
        employeeId: parseInt(employeeId),
        date: { gte: start, lte: end }
      },
      include: {
        items: true
      },
      orderBy: { date: 'asc' }
    });

    res.json({ totalAmount: aggregate._sum.totalAmount || 0, details });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Company Profiles (Branches) Routes
app.get('/api/company-profiles', async (req, res) => {
  try {
    const profiles = await prisma.companyProfile.findMany({ 
      orderBy: { name: 'asc' },
      include: { billingSeries: true }
    });
    res.json(profiles);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/company-profiles', async (req, res) => {
  const { id, name, gstin, address, city, district, state, pincode, status, addresses } = req.body;
  try {
    if (id) {
      const profile = await prisma.companyProfile.update({
        where: { id: parseInt(id) },
        data: { name, gstin, address, city, district, state, pincode, status: status || 'Active', addresses: addresses || [] }
      });
      res.json(profile);
    } else {
      const profile = await prisma.companyProfile.create({
        data: { name, gstin, address, city, district, state, pincode, status: status || 'Active', addresses: addresses || [] }
      });
      res.json(profile);
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/company-profiles/:id', async (req, res) => {
  try {
    await prisma.companyProfile.delete({ where: { id: parseInt(req.params.id) } });
    res.json({ message: 'Profile deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Billing Series Routes
app.post('/api/billing-series', async (req, res) => {
  const { id, companyProfileId, prefix, name, lastNumber, status } = req.body;
  try {
    if (id) {
      const series = await prisma.billingSeries.update({
        where: { id: parseInt(id) },
        data: { prefix, name, lastNumber: parseInt(lastNumber || 0), status: status || 'Active' }
      });
      res.json(series);
    } else {
      const series = await prisma.billingSeries.create({
        data: { companyProfileId: parseInt(companyProfileId), prefix, name, lastNumber: parseInt(lastNumber || 0), status: status || 'Active' }
      });
      res.json(series);
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.delete('/api/billing-series/:id', async (req, res) => {
  try {
    await prisma.billingSeries.delete({ where: { id: parseInt(req.params.id) } });
    res.json({ message: 'Billing series deleted' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// LEGACY ERP ROUTES (READ-ONLY)
// ==========================================

app.get('/api/legacy/customers', async (req, res) => {
  try {
    const data = await prisma.legacy_Customer.findMany({
      orderBy: { id: 'asc' }
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/suppliers', async (req, res) => {
  try {
    const data = await prisma.legacy_Supplier.findMany({
      orderBy: { id: 'asc' }
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/purchases', async (req, res) => {
  try {
    const data = await prisma.legacy_Purchase.findMany({
      orderBy: { id: 'desc' }
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/purchases/:purchaseId/particulars', async (req, res) => {
  try {
    const data = await prisma.legacy_PurchaseParticular.findMany({
      where: { PurchaseID: parseInt(req.params.purchaseId) }
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Legacy Payroll endpoints
app.get('/api/legacy/employees', async (req, res) => {
  try {
    const data = await prisma.legacy_Employee.findMany({
      orderBy: { id: 'asc' }
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/workentries', async (req, res) => {
  try {
    const data = await prisma.legacy_Workentry.findMany({
      orderBy: { id: 'desc' },
      take: 200 // Limit to avoid massive payload
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/workentries/:workId/particulars', async (req, res) => {
  try {
    const data = await prisma.legacy_WorkentryParticular.findMany({
      where: { ID: parseInt(req.params.workId) }
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/payroll-products', async (req, res) => {
  try {
    const data = await prisma.legacy_PayrollProduct.findMany({
      orderBy: { id: 'asc' }
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Extra Legacy endpoints
app.get('/api/legacy/payments', async (req, res) => {
  try {
    const data = await prisma.legacy_Payment.findMany({
      orderBy: { id: 'desc' }
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/estimates', async (req, res) => {
  try {
    const data = await prisma.legacy_Estimate.findMany({
      orderBy: { id: 'desc' }
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/estimates/:salesId/details', async (req, res) => {
  try {
    const salesId = parseInt(req.params.salesId);
    const particulars = await prisma.legacy_EstimateParticular.findMany({
      where: { SalesID: salesId }
    });
    const charges = await prisma.legacy_EstimateCharge.findMany({
      where: { SalesID: salesId }
    });
    res.json({ particulars, charges });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/purchases/:purchaseId/charges', async (req, res) => {
  try {
    const data = await prisma.legacy_PurchaseCharge.findMany({
      where: { PurchaseID: parseInt(req.params.purchaseId) }
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/analytics', async (req, res) => {
  try {
    const purchases = await prisma.legacy_Purchase.findMany({ select: { Netamount: true } });
    const totalPurchases = purchases.reduce((sum, p) => sum + (parseFloat(p.Netamount) || 0), 0);

    const estimates = await prisma.legacy_Estimate.findMany({ select: { Netamount: true } });
    const totalEstimates = estimates.reduce((sum, e) => sum + (parseFloat(e.Netamount) || 0), 0);

    const wages = await prisma.legacy_Workentry.findMany({ select: { Netamount: true } });
    const totalWages = wages.reduce((sum, w) => sum + (parseFloat(w.Netamount) || 0), 0);

    const payments = await prisma.legacy_Payment.findMany({ select: { Paymentamount: true } });
    const totalPayments = payments.reduce((sum, p) => sum + (parseFloat(p.Paymentamount) || 0), 0);

    const counts = {
      customers: await prisma.legacy_Customer.count(),
      suppliers: await prisma.legacy_Supplier.count(),
      employees: await prisma.legacy_Employee.count(),
      purchases: purchases.length,
      estimates: estimates.length,
      workentries: wages.length
    };

    res.json({ financials: { totalPurchases, totalEstimates, totalWages, totalPayments }, counts });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/analytics/products', async (req, res) => {
  try {
    const items = await prisma.legacy_PurchaseParticular.findMany({
      select: { Productname: true },
      distinct: ['Productname'],
      where: { Productname: { not: null } }
    });
    res.json(items.map(i => i.Productname).filter(Boolean).sort());
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/legacy/analytics/price-trends', async (req, res) => {
  try {
    const { product } = req.query;
    if (!product) return res.status(400).json({ error: 'Product name required' });

    const history = await prisma.legacy_PurchaseParticular.findMany({
      where: { Productname: product },
      select: { Purchasedate: true, Purchaserate: true, Qty: true },
    });

    // We need to parse dates because they are stored as strings "DD-MM-YYYY"
    const parsedHistory = history.map(h => {
      let dStr = h.Purchasedate || '';
      let parts = dStr.split('-');
      let dt = parts.length === 3 ? new Date(`${parts[2]}-${parts[1]}-${parts[0]}`) : new Date(0);
      return {
        date: dStr,
        parsedDate: dt,
        rate: parseFloat(h.Purchaserate) || 0,
        qty: parseFloat(h.Qty) || 0
      };
    }).sort((a, b) => a.parsedDate - b.parsedDate);

    // Calculate percent change from previous purchase
    const trends = parsedHistory.map((item, idx, arr) => {
      let prevRate = idx > 0 ? arr[idx-1].rate : item.rate;
      let pctChange = prevRate > 0 ? ((item.rate - prevRate) / prevRate) * 100 : 0;
      return {
        date: item.date,
        rate: item.rate,
        qty: item.qty,
        pctChange: pctChange.toFixed(2)
      };
    });

    res.json(trends);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ==========================================
// E-WAY BILL REPORTING
// ==========================================

app.get('/api/ewaybill/reports/recent', async (req, res) => {
  try {
    const days = parseInt(req.query.days) || 7;
    const email = process.env.WHITEBOOKS_EMAIL?.trim();
    const username = process.env.WHITEBOOKS_USERNAME?.trim();
    const password = process.env.WHITEBOOKS_PASSWORD?.trim();
    const gstin = process.env.WHITEBOOKS_GSTIN?.trim();
    const clientId = process.env.WHITEBOOKS_CLIENT_ID?.trim();
    const clientSecret = process.env.WHITEBOOKS_CLIENT_SECRET?.trim();

    if (!email || !username || !password || !gstin) {
      return res.status(400).json({ error: "Whitebooks credentials not configured in .env" });
    }

    // 1. Authenticate with Whitebooks
    const authUrl = `https://api.whitebooks.in/ewaybillapi/v1.03/authenticate?email=${encodeURIComponent(email)}&username=${encodeURIComponent(username)}&password=${encodeURIComponent(password)}`;
    const authResponse = await fetch(authUrl, {
      method: "GET",
      headers: { "Content-Type": "application/json", "client_id": clientId, "client_secret": clientSecret, "gstin": gstin, "ip_address": "127.0.0.1" }
    });
    
    const authData = await authResponse.json();
    if (!authResponse.ok || authData.status_cd === "0") {
       return res.status(500).json({ error: "Whitebooks Auth Failed", details: authData });
    }
    
    const token = authData.authtoken || authData.data?.authtoken || authData.AuthToken || "";
    
    if (!token) {
      return res.status(500).json({ error: "Whitebooks API did not return an AuthToken", details: authData });
    }

    // 2. Loop through the last N days
    const results = [];
    const errors = [];
    
    for (let i = 0; i < days; i++) {
       const dateObj = new Date();
       dateObj.setDate(dateObj.getDate() - i);
       // Format to DD/MM/YYYY
       const dd = String(dateObj.getDate()).padStart(2, '0');
       const mm = String(dateObj.getMonth() + 1).padStart(2, '0');
       const yyyy = dateObj.getFullYear();
       const dateStr = `${dd}/${mm}/${yyyy}`;

       // Note: Standard NIC API requires payload encryption here. 
       // If Whitebooks handles it automatically via query param, it works. 
       // Otherwise it will return an encryption required error.
       const ewayUrl = `https://api.whitebooks.in/ewaybillapi/v1.03/ewayapi/GetEwayBillsByDate?date=${dateStr}`;
       
       try {
         const ewayResp = await fetch(ewayUrl, {
           method: "GET",
           headers: { 
             "Content-Type": "application/json", 
             "client_id": clientId, 
             "client_secret": clientSecret, 
             "gstin": gstin, 
             "authtoken": token 
           }
         });
         const ewayData = await ewayResp.json();
         if (ewayData.status_cd === "1") {
           // Success! Add to results
           results.push({ date: dateStr, data: ewayData.data });
         } else {
           errors.push({ date: dateStr, error: ewayData.error || ewayData });
         }
       } catch (err) {
         errors.push({ date: dateStr, error: err.message });
       }
    }

    res.json({ 
       message: `Fetched past ${days} days`, 
       totalDaysSuccess: results.length,
       totalDaysFailed: errors.length,
       data: results,
       errors: errors
    });

  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Rep Dashboard Route
app.get('/api/rep/dashboard', async (req, res) => {
  try {
    if (!req.user || req.user.role !== 'REP') {
      return res.status(403).json({ error: "Access denied. Reps only." });
    }
    
    const repId = req.user.id;

    // 1. Total Approved Sales
    const approvedOrders = await prisma.salesOrder.findMany({
      where: { repId, status: 'APPROVED' },
      select: { subtotal: true }
    });
    const totalSales = approvedOrders.reduce((sum, order) => sum + parseFloat(order.subtotal || 0), 0);

    // 2. Pending Orders Count
    const pendingOrdersCount = await prisma.salesOrder.count({
      where: { repId, status: 'PENDING' }
    });

    // 3. Total Assigned Customers
    const totalCustomers = await prisma.customer.count({
      where: { repId }
    });

    // 4. Recent Orders
    const recentOrders = await prisma.salesOrder.findMany({
      where: { repId },
      orderBy: { createdAt: 'desc' },
      take: 5,
      include: {
        customer: { select: { name: true } }
      }
    });
    
    const recentOrdersFormatted = recentOrders.map(ro => ({
      id: ro.id,
      customerName: ro.customer ? ro.customer.name : 'New Customer',
      status: ro.status,
      subtotal: ro.subtotal,
      date: ro.createdAt
    }));

    res.json({
      totalSales,
      pendingOrdersCount,
      totalCustomers,
      recentOrders: recentOrdersFormatted
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Sales Orders Routes
app.get('/api/sales-orders/pending', async (req, res) => {
  try {
    const where = { status: 'PENDING' };
    if (req.user && req.user.role === 'REP') {
      where.repId = req.user.id;
    }
    const orders = await prisma.salesOrder.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: { rep: { select: { username: true } }, customer: true, items: true }
    });
    res.json(orders);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/sales-orders/approved', async (req, res) => {
  try {
    const where = { status: 'APPROVED' };
    if (req.user && req.user.role === 'REP') {
      where.repId = req.user.id;
    }
    const orders = await prisma.salesOrder.findMany({
      where,
      orderBy: { updatedAt: 'desc' },
      include: { rep: { select: { username: true } }, customer: true, items: true },
      take: 50 // Limit to recent approved
    });
    res.json(orders);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/api/sales-orders/:id/factory-view', async (req, res) => {
  try {
    const order = await prisma.salesOrder.findUnique({
      where: { id: parseInt(req.params.id) },
      include: { customer: true, items: true }
    });
    
    if (!order) return res.status(404).json({ error: 'Order not found' });
    
    // Translate items
    const translatedItems = await Promise.all(order.items.map(async (item) => {
      if (!item.productId) return { ...item, rate: 0, total: 0 };
      
      const prod = await prisma.product.findUnique({
        where: { id: item.productId },
        include: { factoryAlias: true }
      });
      
      if (prod && prod.factoryAlias) {
        return {
          ...item,
          productId: prod.factoryAlias.id,
          product: prod.factoryAlias.name, // The physical box
          rate: 0,
          total: 0
        };
      }
      
      return { ...item, rate: 0, total: 0 };
    }));
    
    res.json({
      ...order,
      subtotal: 0,
      items: translatedItems
    });
    
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/sales-orders', async (req, res) => {
  try {
    const { customerId, newCustomerData, subtotal, items } = req.body;
    let repId = req.user.id; 
    
    const order = await prisma.salesOrder.create({
      data: {
        repId,
        customerId: customerId ? parseInt(customerId) : null,
        newCustomerData: newCustomerData || null,
        subtotal,
        items: {
          create: items.map(item => ({
            productId: item.productId,
            product: item.product,
            qty: item.qty,
            rate: item.rate,
            total: item.total
          }))
        }
      },
      include: { items: true }
    });
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/sales-orders/:id/approve-customer', requireAdmin, async (req, res) => {
  try {
    const orderId = parseInt(req.params.id);
    const order = await prisma.salesOrder.findUnique({ where: { id: orderId } });
    if (!order || !order.newCustomerData) return res.status(400).json({ error: 'No new customer data in this order' });

    const customerData = typeof order.newCustomerData === 'string' ? JSON.parse(order.newCustomerData) : order.newCustomerData;
    
    const customer = await prisma.customer.create({
      data: {
        name: customerData.name,
        mobile: customerData.mobile || null,
        city: customerData.city || null,
        state: customerData.state || null,
        gstin: customerData.gstin || 'URP',
        repId: order.repId,
        status: 'Active'
      }
    });

    const updatedOrder = await prisma.salesOrder.update({
      where: { id: orderId },
      data: { customerId: customer.id, newCustomerData: null },
      include: { customer: true, items: true }
    });

    res.json(updatedOrder);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/sales-orders/:id/status', requireAdmin, async (req, res) => {
  try {
    const { status } = req.body;
    const order = await prisma.salesOrder.update({
      where: { id: parseInt(req.params.id) },
      data: { status }
    });
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

const PORT = process.env.PORT || 5001;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
