import { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Outlet, Navigate } from 'react-router-dom';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from './api/queryClient';
import Header from './components/Header';
import CustomerMaster from './pages/CustomerMaster';
import SupplierMaster from './pages/SupplierMaster';
import ProductMaster from './pages/ProductMaster';
import TransporterMaster from './pages/TransporterMaster';
import Billing from './pages/Billing';
import GodownMaster from './pages/GodownMaster';
import PurchaseEntry from './pages/PurchaseEntry';
import GodownStock from './pages/GodownStock';
import VehicleMaster from './pages/VehicleMaster';
import StockTransfer from './pages/StockTransfer';
import BillingHistory from './pages/BillingHistory';
import InventoryHistory from './pages/InventoryHistory';
import ProductionEntry from './pages/ProductionEntry';
import MaterialMaster from './pages/MaterialMaster';
import MachineMaster from './pages/MachineMaster';
import UserMaster from './pages/UserMaster';
import Login from './pages/Login';
import EmployeeMaster from './pages/EmployeeMaster';
import PayrollEntry from './pages/PayrollEntry';
import CompanyProfileMaster from './pages/CompanyProfileMaster';
import InvoicePrint from './pages/InvoicePrint';
import CustomerRates from './pages/CustomerRates';
import { useStore } from './store/useStore';
import { useAuth } from './store/useAuth';
import SalesOrderEntry from './pages/SalesOrderEntry';
import PendingOrders from './pages/PendingOrders';
import LegacyDashboard from './pages/legacy/LegacyDashboard';
import EwayBillReport from './pages/EwayBillReport';
import Dashboard from './pages/Dashboard';

const THEMES = {
  // 1. Sales (Blue/Indigo)
  INV: ['#3b82f6', '#1d4ed8', '#eff6ff'],
  EST: ['#3b82f6', '#1d4ed8', '#eff6ff'],
  PRO: ['#3b82f6', '#1d4ed8', '#eff6ff'],
  SALES: ['#3b82f6', '#1d4ed8', '#eff6ff'],
  
  // 2. Purchases (Orange/Red)
  PURCHASES: ['#f97316', '#c2410c', '#fff7ed'],
  
  // 3. Godown (Emerald/Teal)
  GODOWN: ['#10b981', '#047857', '#ecfdf5'],
  
  // 4. Production (Amber/Yellow)
  PRODUCTION: ['#f59e0b', '#b45309', '#fffbeb'],
  
  // 5. HR & Payroll (Indigo/Purple)
  HR: ['#8b5cf6', '#6d28d9', '#f5f3ff'],
  
  // 6. Admin (Slate)
  ADMIN: ['#475569', '#334155', '#f8fafc'],

  // Fallbacks for legacy routes
  MASTER: ['#475569', '#334155', '#f8fafc'],
  INVENTORY: ['#10b981', '#047857', '#ecfdf5'],
  REPORT: ['#475569', '#334155', '#f8fafc'],
  FACTORY: ['#f59e0b', '#b45309', '#fffbeb']
};

function Layout() {
  const currentType = useStore((state) => state.currentType);
  const user = useAuth((state) => state.user);

  if (!user) {
    return <Navigate to="/login" replace />;
  }

  // Sync CSS variables for Tailwind to use dynamically based on the Zustand store
  useEffect(() => {
    const root = document.documentElement;
    const [active, activeDark, activeSoft] = THEMES[currentType] || THEMES.INV;
    root.style.setProperty('--active', active);
    root.style.setProperty('--active-dark', activeDark);
    root.style.setProperty('--active-soft', activeSoft);
  }, [currentType]);

  return (
    <div className="max-w-[1380px] mx-auto pb-[32px] px-2 md:px-4">
      <Header />
      <div className="mt-4">
        {/* Child route components will be injected here */}
        <Outlet />
      </div>
    </div>
  );
}

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/print/invoice/:number" element={<InvoicePrint />} />
          <Route path="/" element={<Layout />}>
            <Route index element={<Dashboard />} />
            <Route path="billing" element={<Billing />} />
            <Route path="customers" element={<CustomerMaster />} />
            <Route path="customer-rates" element={<CustomerRates />} />
            <Route path="suppliers" element={<SupplierMaster />} />
            <Route path="products" element={<ProductMaster />} />
            <Route path="transporters" element={<TransporterMaster />} />
            <Route path="godowns" element={<GodownMaster />} />
            <Route path="users" element={<UserMaster />} />
            <Route path="purchase" element={<PurchaseEntry />} />
            <Route path="stock" element={<GodownStock />} />
            <Route path="vehicles" element={<VehicleMaster />} />
            <Route path="transfers" element={<StockTransfer />} />
            <Route path="pending-orders" element={<PendingOrders />} />
            <Route path="billing-history" element={<BillingHistory />} />
            <Route path="inventory-history" element={<InventoryHistory />} />
            <Route path="sales-order" element={<SalesOrderEntry />} />
            <Route path="production" element={<ProductionEntry />} />
            <Route path="materials" element={<MaterialMaster />} />
            <Route path="machines" element={<MachineMaster />} />
            <Route path="employees" element={<EmployeeMaster />} />
            <Route path="payroll" element={<PayrollEntry />} />
            <Route path="company-profiles" element={<CompanyProfileMaster />} />
            <Route path="legacy" element={<LegacyDashboard />} />
            <Route path="eway-bills" element={<EwayBillReport />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
}
