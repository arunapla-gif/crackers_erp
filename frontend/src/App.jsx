import { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Outlet, Navigate } from 'react-router-dom';
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
import { useStore } from './store/useStore';
import { useAuth } from './store/useAuth';
import LegacyDashboard from './pages/legacy/LegacyDashboard';
import EwayBillReport from './pages/EwayBillReport';
import Dashboard from './pages/Dashboard';

const THEMES = {
  INV: ['#ff6b6b', '#c24141', '#fff1f2'],
  EST: ['#4f8cff', '#1e40af', '#eff6ff'],
  PRO: ['#9b6dff', '#5b21b6', '#f5f3ff'],
  MASTER: ['#22c55e', '#166534', '#f0fdf4'],
  INVENTORY: ['#f97316', '#c2410c', '#fff7ed'],
  REPORT: ['#a855f7', '#7e22ce', '#faf5ff'],
  FACTORY: ['#eab308', '#a16207', '#fefce8']
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
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/print/invoice/:number" element={<InvoicePrint />} />
        <Route path="/" element={<Layout />}>
          <Route index element={<Dashboard />} />
          <Route path="billing" element={<Billing />} />
          <Route path="customers" element={<CustomerMaster />} />
          <Route path="suppliers" element={<SupplierMaster />} />
          <Route path="products" element={<ProductMaster />} />
          <Route path="transporters" element={<TransporterMaster />} />
          <Route path="godowns" element={<GodownMaster />} />
          <Route path="users" element={<UserMaster />} />
          <Route path="purchase" element={<PurchaseEntry />} />
          <Route path="stock" element={<GodownStock />} />
          <Route path="vehicles" element={<VehicleMaster />} />
          <Route path="transfers" element={<StockTransfer />} />
          <Route path="billing-history" element={<BillingHistory />} />
          <Route path="inventory-history" element={<InventoryHistory />} />
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
  );
}
