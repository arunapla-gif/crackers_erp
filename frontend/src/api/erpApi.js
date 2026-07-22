import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://crackers-erp-api.onrender.com/api';

// Create a configured axios instance
const api = axios.create({
  baseURL: API_BASE_URL
});

// Add a request interceptor to attach the JWT token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('erp_token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

export const erpApi = {
  // User APIs
  getUsers: async () => {
    try {
      const response = await api.get(`/users`);
      return response.data;
    } catch (error) {
      console.error("Error fetching users", error);
      throw error;
    }
  },
  
  saveUser: async (userData) => {
    try {
      const response = await api.post(`/users`, userData);
      return response.data;
    } catch (error) {
      console.error("Error saving user", error);
      throw error;
    }
  },

  getReps: async () => {
    try {
      const response = await api.get(`/reps`);
      return response.data;
    } catch (error) {
      console.error("Error fetching reps", error);
      throw error;
    }
  },

  deleteUser: async (id) => {
    try {
      const response = await api.delete(`/users/${id}`);
      return response.data;
    } catch (error) {
      console.error("Error deleting user", error);
      throw error;
    }
  },

  // Customer APIs
  getCustomers: async () => {
    try {
      const response = await api.get(`/customers`);
      return response.data;
    } catch (error) {
      console.error("Error fetching customers", error);
      throw error;
    }
  },
  
  saveCustomer: async (customerData) => {
    try {
      const response = await api.post(`/customers`, customerData);
      return response.data;
    } catch (error) {
      console.error("Error saving customer", error);
      throw error;
    }
  },
  
  getCustomerPrices: async (id) => {
    try {
      const response = await api.get(`/customers/${id}/prices`);
      return response.data;
    } catch (error) {
      console.error("Error fetching customer prices", error);
      throw error;
    }
  },
  
  saveCustomerPrices: async (id, prices) => {
    try {
      const response = await api.post(`/customers/${id}/prices`, { prices });
      return response.data;
    } catch (error) {
      console.error("Error saving customer prices", error);
      throw error;
    }
  },

  // Supplier APIs
  getSuppliers: async () => {
    try {
      const response = await api.get(`/suppliers`);
      return response.data;
    } catch (error) {
      console.error("Error fetching suppliers", error);
      throw error;
    }
  },
  
  saveSupplier: async (supplierData) => {
    try {
      const response = await api.post(`/suppliers`, supplierData);
      return response.data;
    } catch (error) {
      console.error("Error saving supplier", error);
      throw error;
    }
  },
  
  // Product APIs
  getProducts: async () => {
    try {
      const response = await api.get(`/products`);
      return response.data;
    } catch (error) {
      console.error("Error fetching products", error);
      throw error;
    }
  },
  
  saveProduct: async (productData) => {
    try {
      const response = await api.post(`/products`, productData);
      return response.data;
    } catch (error) {
      console.error("Error saving product", error);
      throw error;
    }
  },
  getNextProductCode: async (type = 'INV') => {
    try {
      const response = await api.get(`/products/next-code?type=${type}`);
      return response.data.code;
    } catch (error) {
      console.error("Error fetching next product code", error);
      return `${type}001`;
    }
  },

  // Invoice APIs
  saveInvoice: async (invoiceData) => {
    try {
      const response = await api.post(`/invoices`, invoiceData);
      return response.data;
    } catch (error) {
      console.error("Error saving invoice", error);
      throw error;
    }
  },
  
  getInvoice: async (number) => {
    try {
      const response = await api.get(`/invoices/${number}`);
      return response.data;
    } catch (error) {
      console.error("Error fetching invoice", error);
      throw error;
    }
  },

  generateEwayBill: async (number, mode) => {
    try {
      const response = await api.post(`/invoices/${number}/ewaybill`, { mode });
      return response.data;
    } catch (error) {
      console.error("Error generating e-way bill", error);
      throw error;
    }
  },

  // Transporter APIs
  getTransporters: async () => {
    try {
      const response = await api.get(`/transporters`);
      return response.data;
    } catch (error) {
      console.error("Error fetching transporters", error);
      throw error;
    }
  },
  saveTransporter: async (transporterData) => {
    try {
      const response = await api.post(`/transporters`, transporterData);
      return response.data;
    } catch (error) {
      console.error("Error saving transporter", error);
      throw error;
    }
  },

  // Sales Orders (Representative / Approval Workflow)
  getPendingSalesOrders: async () => {
    try {
      const response = await api.get('/sales-orders/pending');
      return response.data;
    } catch (error) {
      console.error("Error fetching pending sales orders", error);
      throw error;
    }
  },
  getApprovedSalesOrders: async () => {
    try {
      const response = await api.get('/sales-orders/approved');
      return response.data;
    } catch (error) {
      console.error("Error fetching approved sales orders", error);
      throw error;
    }
  },
  getFactoryView: async (id) => {
    try {
      const response = await api.get(`/sales-orders/${id}/factory-view`);
      return response.data;
    } catch (error) {
      console.error("Error fetching factory view", error);
      throw error;
    }
  },
  createSalesOrder: async (data) => {
    try {
      const response = await api.post('/sales-orders', data);
      return response.data;
    } catch (error) {
      console.error("Error creating sales order", error);
      throw error;
    }
  },
  approveSalesOrderCustomer: async (id) => {
    try {
      const response = await api.post(`/sales-orders/${id}/approve-customer`);
      return response.data;
    } catch (error) {
      console.error("Error approving customer from sales order", error);
      throw error;
    }
  },
  updateSalesOrderStatus: async (id, status) => {
    try {
      const response = await api.post(`/sales-orders/${id}/status`, { status });
      return response.data;
    } catch (error) {
      console.error("Error updating sales order status", error);
      throw error;
    }
  },

  // Godown & Stock APIs
  getGodowns: async () => {
    try {
      const response = await api.get(`/godowns`);
      return response.data;
    } catch (error) {
      console.error("Error fetching godowns", error);
      throw error;
    }
  },
  saveGodown: async (godownData) => {
    try {
      const response = await api.post(`/godowns`, godownData);
      return response.data;
    } catch (error) {
      console.error("Error saving godown", error);
      throw error;
    }
  },
  savePurchase: async (purchaseData) => {
    try {
      const response = await api.post(`/purchases`, purchaseData);
      return response.data;
    } catch (error) {
      console.error("Error saving purchase", error);
      throw error;
    }
  },
  getPurchases: async () => {
    try {
      const response = await api.get(`/history/purchases`);
      return response.data;
    } catch (error) {
      console.error("Error fetching purchases", error);
      throw error;
    }
  },
  togglePurchaseStatus: async (id, status) => {
    try {
      const response = await api.post(`/purchases/${id}/status`, { status });
      return response.data;
    } catch (error) {
      console.error("Error toggling purchase status", error);
      throw error;
    }
  },
  getStock: async () => {
    try {
      const response = await api.get(`/stock`);
      return response.data;
    } catch (error) {
      console.error("Error fetching stock", error);
      throw error;
    }
  },

  // Vehicle & Transfer APIs
  getVehicles: async () => {
    try {
      const response = await api.get(`/vehicles`);
      return response.data;
    } catch (error) {
      console.error("Error fetching vehicles", error);
      throw error;
    }
  },
  saveVehicle: async (vehicleData) => {
    try {
      const response = await api.post(`/vehicles`, vehicleData);
      return response.data;
    } catch (error) {
      console.error("Error saving vehicle", error);
      throw error;
    }
  },
  saveTransfer: async (transferData) => {
    try {
      const response = await api.post(`/transfers`, transferData);
      return response.data;
    } catch (error) {
      console.error("Error saving transfer", error);
      throw error;
    }
  },

  // History APIs
  getInvoiceHistory: async () => {
    try {
      const response = await api.get(`/history/invoices`);
      return response.data;
    } catch (error) {
      console.error("Error fetching invoice history", error);
      throw error;
    }
  },
  getPurchaseHistory: async () => {
    try {
      const response = await api.get(`/history/purchases`);
      return response.data;
    } catch (error) {
      console.error("Error fetching purchase history", error);
      throw error;
    }
  },
  getTransferHistory: async () => {
    try {
      const response = await api.get(`/history/transfers`);
      return response.data;
    } catch (error) {
      console.error("Error fetching transfer history", error);
      throw error;
    }
  },

  // Employee APIs
  getEmployees: async () => {
    try {
      const response = await api.get(`/employees`);
      return response.data;
    } catch (error) {
      console.error("Error fetching employees", error);
      throw error;
    }
  },
  saveEmployee: async (employeeData) => {
    try {
      const response = await api.post(`/employees`, employeeData);
      return response.data;
    } catch (error) {
      console.error("Error saving employee", error);
      throw error;
    }
  },
  deleteEmployee: async (id) => {
    try {
      const response = await api.delete(`/employees/${id}`);
      return response.data;
    } catch (error) {
      console.error("Error deleting employee", error);
      throw error;
    }
  },

  // Employee Advances APIs
  getAdvances: async (employeeId) => {
    try {
      const response = await api.get(`/advances/${employeeId}`);
      return response.data;
    } catch (error) {
      console.error("Error fetching advances", error);
      throw error;
    }
  },
  saveAdvance: async (advanceData) => {
    try {
      const response = await api.post(`/advances`, advanceData);
      return response.data;
    } catch (error) {
      console.error("Error saving advance", error);
      throw error;
    }
  },

  // Payroll APIs
  getPayrolls: async () => {
    try {
      const response = await api.get(`/payrolls`);
      return response.data;
    } catch (error) {
      console.error("Error fetching payrolls", error);
      throw error;
    }
  },
  savePayroll: async (payrollData) => {
    try {
      const response = await api.post(`/payrolls`, payrollData);
      return response.data;
    } catch (error) {
      console.error("Error saving payroll", error);
      throw error;
    }
  },

  // Daily Production APIs
  getDailyProductions: async () => {
    try {
      const response = await api.get(`/production/daily`);
      return response.data;
    } catch (error) {
      console.error("Error fetching daily productions", error);
      throw error;
    }
  },
  saveDailyProduction: async (productionData) => {
    try {
      const response = await api.post(`/production/daily`, productionData);
      return response.data;
    } catch (error) {
      console.error("Error saving daily production", error);
      throw error;
    }
  },
  deleteDailyProduction: async (id) => {
    try {
      const response = await api.delete(`/production/daily/${id}`);
      return response.data;
    } catch (error) {
      console.error("Error deleting daily production", error);
      throw error;
    }
  },
  getAggregateProduction: async (employeeId, startDate, endDate) => {
    try {
      const response = await api.get(`/production/aggregate`, { params: { employeeId, startDate, endDate } });
      return response.data;
    } catch (error) {
      console.error("Error fetching aggregate production", error);
      throw error;
    }
  },

  // Company Profiles API
  getCompanyProfiles: async () => {
    try {
      const response = await api.get(`/company-profiles`);
      return response.data;
    } catch (error) {
      console.error("Error fetching company profiles", error);
      throw error;
    }
  },
  saveCompanyProfile: async (profileData) => {
    try {
      const response = await api.post(`/company-profiles`, profileData);
      return response.data;
    } catch (error) {
      console.error("Error saving company profile", error);
      throw error;
    }
  },
  deleteCompanyProfile: async (id) => {
    try {
      const response = await api.delete(`/company-profiles/${id}`);
      return response.data;
    } catch (error) {
      console.error("Error deleting company profile", error);
      throw error;
    }
  },

  // Billing Series APIs
  saveBillingSeries: async (seriesData) => {
    try {
      const response = await api.post(`/billing-series`, seriesData);
      return response.data;
    } catch (error) {
      console.error("Error saving billing series", error);
      throw error;
    }
  },
  deleteBillingSeries: async (id) => {
    try {
      const response = await api.delete(`/billing-series/${id}`);
      return response.data;
    } catch (error) {
      console.error("Error deleting billing series", error);
      throw error;
    }
  },
  getSystemCredentials: async () => {
    try {
      const response = await api.get(`/system-credentials`);
      return response.data;
    } catch (error) {
      console.error("Error fetching system credentials", error);
      throw error;
    }
  },

  // Legacy ERP APIs
  getLegacyCustomers: async () => {
    try {
      const response = await api.get(`/legacy/customers`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy customers", error);
      throw error;
    }
  },
  getLegacySuppliers: async () => {
    try {
      const response = await api.get(`/legacy/suppliers`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy suppliers", error);
      throw error;
    }
  },
  getLegacyPurchases: async () => {
    try {
      const response = await api.get(`/legacy/purchases`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy purchases", error);
      throw error;
    }
  },
  getLegacyPurchaseParticulars: async (purchaseId) => {
    try {
      const response = await api.get(`/legacy/purchases/${purchaseId}/particulars`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy purchase particulars", error);
      throw error;
    }
  },
  
  // Legacy Payroll APIs
  getLegacyEmployees: async () => {
    try {
      const response = await api.get(`/legacy/employees`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy employees", error);
      throw error;
    }
  },
  getLegacyWorkentries: async () => {
    try {
      const response = await api.get(`/legacy/workentries`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy workentries", error);
      throw error;
    }
  },
  getLegacyWorkentryParticulars: async (workId) => {
    try {
      const response = await api.get(`/legacy/workentries/${workId}/particulars`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy workentry particulars", error);
      throw error;
    }
  },
  getLegacyPayrollProducts: async () => {
    try {
      const response = await api.get(`/legacy/payroll-products`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy payroll products", error);
      throw error;
    }
  },
  
  // Extra Legacy APIs
  getLegacyPayments: async () => {
    try {
      const response = await api.get(`/legacy/payments`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy payments", error);
      throw error;
    }
  },
  getLegacyEstimates: async () => {
    try {
      const response = await api.get(`/legacy/estimates`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy estimates", error);
      throw error;
    }
  },
  getLegacyEstimateDetails: async (salesId) => {
    try {
      const response = await api.get(`/legacy/estimates/${salesId}/details`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy estimate details", error);
      throw error;
    }
  },
  getLegacyPurchaseCharges: async (purchaseId) => {
    try {
      const response = await api.get(`/legacy/purchases/${purchaseId}/charges`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy purchase charges", error);
      throw error;
    }
  },

  getLegacyAnalytics: async () => {
    try {
      const response = await api.get(`/legacy/analytics`);
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy analytics:", error);
      throw error;
    }
  },

  getLegacyAnalyticsProducts: async () => {
    try {
      const response = await api.get('/legacy/analytics/products');
      return response.data;
    } catch (error) {
      console.error("Error fetching legacy products:", error);
      throw error;
    }
  },

  getLegacyAnalyticsPriceTrends: async (product) => {
    try {
      const response = await api.get(`/legacy/analytics/price-trends?product=${encodeURIComponent(product)}`);
      return response.data;
    } catch (error) {
      console.error("Error fetching price trends:", error);
      throw error;
    }
  }
};
