const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'crackers_erp',
  password: process.env.DB_PASSWORD || '',
  port: process.env.DB_PORT || 5432,
});

async function initializeDatabase() {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS customers (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE,
        mobile VARCHAR(20),
        reference VARCHAR(100),
        address TEXT,
        state VARCHAR(100),
        pincode VARCHAR(20),
        id_number VARCHAR(100),
        gstin VARCHAR(50)
      );

      CREATE TABLE IF NOT EXISTS products (
        id SERIAL PRIMARY KEY,
        code VARCHAR(50) UNIQUE NOT NULL,
        name VARCHAR(255) NOT NULL,
        type VARCHAR(20) DEFAULT 'INV',
        hsn VARCHAR(20) DEFAULT '3604',
        tax DECIMAL(5,2) DEFAULT 18,
        rate DECIMAL(10,2) DEFAULT 0,
        unit_qty INTEGER DEFAULT 1,
        unit VARCHAR(50) DEFAULT 'Case',
        status VARCHAR(20) DEFAULT 'Active'
      );

      CREATE TABLE IF NOT EXISTS godowns (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) UNIQUE NOT NULL
      );

      CREATE TABLE IF NOT EXISTS vehicles (
        id SERIAL PRIMARY KEY,
        no VARCHAR(50) UNIQUE NOT NULL,
        name VARCHAR(255),
        owner_name VARCHAR(255),
        owner_phone VARCHAR(20),
        drivers JSONB DEFAULT '[]'
      );

      CREATE TABLE IF NOT EXISTS invoices (
        id SERIAL PRIMARY KEY,
        series VARCHAR(20),
        number VARCHAR(50) UNIQUE NOT NULL,
        date DATE,
        customer VARCHAR(255),
        state VARCHAR(100),
        subtotal DECIMAL(12,2),
        cgst DECIMAL(12,2),
        sgst DECIMAL(12,2),
        igst DECIMAL(12,2),
        tax DECIMAL(12,2),
        grand_total DECIMAL(12,2),
        saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log("Database initialized properly.");
  } catch (err) {
    console.error("Failed to initialize database:", err);
  } finally {
    client.release();
  }
}

initializeDatabase();

module.exports = pool;
