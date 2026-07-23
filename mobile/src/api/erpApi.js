import axios from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

const API_BASE_URL = 'https://crackers-erp-api.onrender.com/api';

const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 15000,
});

api.interceptors.request.use(
  async (config) => {
    const token = await AsyncStorage.getItem('erp_token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// SWR Cache Helper
const fetchWithCache = async (cacheKey, apiCall, onFreshData = null) => {
  try {
    const cached = await AsyncStorage.getItem(cacheKey);
    let cachedData = null;
    
    if (cached) {
      cachedData = JSON.parse(cached);
    }
    
    apiCall().then(async (freshData) => {
      await AsyncStorage.setItem(cacheKey, JSON.stringify(freshData));
      if (onFreshData) onFreshData(freshData);
    }).catch(err => {
      console.warn(`Background fetch failed for ${cacheKey}:`, err.message);
    });

    if (cachedData) {
      return { data: cachedData, isCached: true };
    } else {
      const freshData = await apiCall();
      await AsyncStorage.setItem(cacheKey, JSON.stringify(freshData));
      return { data: freshData, isCached: false };
    }
  } catch (err) {
    console.error("Cache Error:", err);
    const freshData = await apiCall();
    return { data: freshData, isCached: false };
  }
};

export const erpApi = {
  // Login
  login: async (username, pin) => {
    try {
      const response = await api.post('/login', { username, pin });
      return response.data;
    } catch (error) {
      throw error.response?.data?.error || error.message;
    }
  },

  // Rep Dashboard
  getRepDashboard: async () => {
    try {
      const response = await api.get('/rep-dashboard');
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  // Orders
  saveOrder: async (orderData) => {
    try {
      const response = await api.post('/orders', orderData);
      return response.data;
    } catch (error) {
      throw error;
    }
  },

  // ==========================================
  // MASTERS (With Cache Support)
  // ==========================================
  getProducts: async (onFreshData) => {
    const res = await fetchWithCache('@cache_products', () => api.get('/products').then(r => r.data), onFreshData);
    return res;
  },
  getCustomers: async (onFreshData) => {
    const res = await fetchWithCache('@cache_customers', () => api.get('/customers').then(r => r.data.filter(c => c.status !== 'Inactive')), onFreshData);
    return res;
  },
  getCustomerPrices: async (id) => {
    try {
      const response = await api.get(`/customers/${id}/prices`);
      return response.data;
    } catch (error) {
      throw error;
    }
  },
  
  // ==========================================
  // SALES ORDERS (With Cache Support)
  // ==========================================
  getPendingSalesOrders: async (onFreshData) => {
    const res = await fetchWithCache('@cache_pending_orders', () => api.get('/sales-orders/pending').then(r => r.data), onFreshData);
    return res;
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
  updateSalesOrderStatus: async (id, status) => {
    try {
      const response = await api.post(`/sales-orders/${id}/status`, { status });
      return response.data;
    } catch (error) {
      console.error("Error updating sales order status", error);
      throw error;
    }
  },
  approveSalesOrderCustomer: async (id) => {
    try {
      const response = await api.post(`/sales-orders/${id}/approve-customer`);
      return response.data;
    } catch (error) {
      console.error("Error approving sales order customer", error);
      throw error;
    }
  },

  // ==========================================
  // INVOICES & BILLING
  // ==========================================
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
  generateEwayBill: async (invoiceNo, mode) => {
    try {
      const response = await api.post(`/invoices/eway-bill`, { invoiceNo, mode });
      return response.data;
    } catch (error) {
      console.error("Error generating eway bill", error);
      throw error;
    }
  },

  // ==========================================
  // MORE MASTERS
  // ==========================================
  getCompanyProfiles: async (onFreshData) => {
    const res = await fetchWithCache('@cache_company_profiles', () => api.get('/company-profiles').then(r => r.data), onFreshData);
    return res;
  },
  getTransporters: async (onFreshData) => {
    const res = await fetchWithCache('@cache_transporters', () => api.get('/transporters').then(r => r.data), onFreshData);
    return res;
  },

  // ==========================================
  // GSTIN VERIFICATION
  // ==========================================
  verifyGSTIN: async (gstin) => {
    try {
      const response = await api.get(`/gstin/${gstin}`);
      return response.data;
    } catch (error) {
      throw error.response?.data?.error || "Failed to verify GSTIN";
    }
  }
};
