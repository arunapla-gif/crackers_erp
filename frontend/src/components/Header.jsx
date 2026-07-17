import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { useStore } from '../store/useStore';
import { useAuth } from '../store/useAuth';

const MenuItem = ({ icon, title, desc, onClick, themeClass = '', textHoverClass = '' }) => (
  <button 
    onClick={onClick} 
    className={`flex items-start gap-[12px] w-full text-left p-[10px] rounded-[14px] transition-all duration-200 group hover:bg-white hover:shadow-[0_4px_12px_rgba(0,0,0,0.05)] ${themeClass}`}
  >
    <div className={`w-[34px] h-[34px] shrink-0 rounded-[10px] bg-white shadow-sm flex items-center justify-center text-[16px] transition-transform duration-300 group-hover:scale-110 group-hover:-rotate-6 border border-slate-100`}>
      {icon}
    </div>
    <div>
      <div className={`text-[13px] font-[900] text-slate-700 transition-colors ${textHoverClass}`}>{title}</div>
      <div className="text-[11px] font-[600] text-slate-500 leading-[1.2] mt-[2px] opacity-80 group-hover:opacity-100 transition-opacity">{desc}</div>
    </div>
  </button>
);

export default function Header() {
  const [billingMenuOpen, setBillingMenuOpen] = useState(false);
  const [factoryMenuOpen, setFactoryMenuOpen] = useState(false);
  const [mastersMenuOpen, setMastersMenuOpen] = useState(false);
  const [reportsMenuOpen, setReportsMenuOpen] = useState(false);
  const [hrMenuOpen, setHrMenuOpen] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();
  
  // Zustand store usage
  const currentType = useStore((state) => state.currentType);
  const setCurrentType = useStore((state) => state.setCurrentType);
  const { user, logout } = useAuth();

  const getBadgeText = () => {
    if (location.pathname === '/customers') return 'CUSTOMER MASTER';
    if (location.pathname === '/suppliers') return 'SUPPLIER MASTER';
    if (currentType === 'INV') return 'INVOICE • SGFI-0001';
    if (currentType === 'EST') return 'ESTIMATE • SGFI-0001';
    if (currentType === 'PRO') return 'PERFORMA • SGFI-0001';
    return 'MASTER';
  };

  const handleNavigate = (path, type) => {
    setCurrentType(type);
    navigate(path);
    setBillingMenuOpen(false);
    setFactoryMenuOpen(false);
    setMastersMenuOpen(false);
    setReportsMenuOpen(false);
    setHrMenuOpen(false);
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const isAdmin = user?.role === 'ADMIN';
  const canView = (mod) => isAdmin || user?.permissions?.[mod]?.view;

  // Check if any item in a section is visible
  const showBillingSection = canView('billing');
  const showMastersSection = isAdmin || ['customers','suppliers','products','transporters','godowns'].some(canView);
  const showFactorySection = isAdmin || ['production','materials','machines','purchase','stock','vehicles','transfers'].some(canView);
  const showReportsSection = canView('reports');
  const showHrSection = isAdmin || ['employees', 'payroll'].some(canView);

  // Remove top headers on dashboard
  if (location.pathname === '/') {
    return null;
  }

  return (
    <header className="sticky top-0 md:top-[12px] z-[60] bg-white border-b border-slate-200 shadow-[0_4px_24px_rgba(0,0,0,0.04)] text-slate-800 p-[10px_16px] md:p-[12px_24px] rounded-b-[24px] md:rounded-[24px]">
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
        
        <div className="flex items-center gap-[12px]">
          <div className="hidden md:grid place-items-center w-[44px] h-[44px] rounded-[16px] bg-active text-white shadow-lg text-[13px] font-black">
            ERP
          </div>
          <div>
            <h1 className="text-[22px] md:text-[32px] font-black leading-[1.05] tracking-[-0.7px] m-0">Crackers Billing ERP</h1>
            <p className="text-[11px] md:text-[13px] font-bold opacity-90 m-[3px_0_0_0] md:hidden">Crackers ERP Solution</p>
          </div>
          <div className="hidden md:inline-block mt-[8px] md:mt-0 px-[11px] py-[6px] md:px-[14px] md:py-[8px] bg-white text-active-dark rounded-full font-black text-[12px] md:text-[13px] ml-2">
            {getBadgeText()}
          </div>
        </div>

        <div className="flex items-center gap-[8px] flex-wrap">
          
          {/* Home Button */}
          <button 
            onClick={() => handleNavigate('/', 'INV')}
            className="bg-slate-100 text-slate-700 border border-slate-200 px-[12px] py-[8px] rounded-full text-[13px] font-black hover:bg-slate-200 transition-all shadow-sm flex items-center justify-center"
            title="Return to Dashboard"
          >
            🏠
          </button>

          {/* Billing Section */}
          <div className="relative">
            <button 
              onClick={() => { setBillingMenuOpen(!billingMenuOpen); setFactoryMenuOpen(false); setMastersMenuOpen(false); setReportsMenuOpen(false); setHrMenuOpen(false); }}
              className="bg-active-soft text-active-dark border border-active/20 px-[12px] py-[8px] rounded-full text-[13px] font-black hover:bg-active hover:text-white transition-all shadow-sm flex-1 md:flex-none"
            >
              Billing ▾
            </button>
            {billingMenuOpen && (
              <div className="absolute top-[100%] mt-3 left-0 w-[calc(100vw-32px)] md:w-[280px] bg-slate-50/90 backdrop-blur-[24px] border border-white/60 rounded-[24px] shadow-[0_32px_80px_rgba(15,23,42,0.12)] p-[8px] z-[90]">
                <div className="px-[12px] pt-[12px] pb-[8px]">
                  <h3 className="text-[10px] text-slate-400 font-[1000] uppercase tracking-[1px]">Billing Tools</h3>
                </div>
                <div className="flex flex-col gap-[2px]">
                  {canView('billing') && <MenuItem icon="🧾" title="Invoice" desc="Create a new invoice" onClick={() => handleNavigate('/billing', 'INV')} textHoverClass="group-hover:text-active" />}
                  {canView('billing') && <MenuItem icon="📝" title="Estimate" desc="Draft an estimate" onClick={() => handleNavigate('/billing', 'EST')} textHoverClass="group-hover:text-active" />}
                  {canView('billing') && <MenuItem icon="📋" title="Performa" desc="Generate performa" onClick={() => handleNavigate('/billing', 'PRO')} textHoverClass="group-hover:text-active" />}
                </div>
              </div>
            )}
          </div>

          {/* Masters Section */}
          {showMastersSection && (
            <div className="relative">
              <button 
                onClick={() => { setMastersMenuOpen(!mastersMenuOpen); setBillingMenuOpen(false); setFactoryMenuOpen(false); setReportsMenuOpen(false); setHrMenuOpen(false); }}
              className="bg-green-50 text-green-700 border border-green-500/20 px-[12px] py-[8px] rounded-full text-[13px] font-black hover:bg-green-500 hover:text-white transition-all shadow-sm flex-1 md:flex-none"
            >
              Masters ▾
            </button>
            {mastersMenuOpen && (
              <div className="absolute top-[100%] mt-3 left-0 md:left-1/2 md:-translate-x-1/2 w-[calc(100vw-32px)] md:w-[280px] bg-slate-50/90 backdrop-blur-[24px] border border-white/60 rounded-[24px] shadow-[0_32px_80px_rgba(15,23,42,0.12)] p-[8px] z-[90]">
                <div className="px-[12px] pt-[12px] pb-[8px]">
                  <h3 className="text-[10px] text-slate-400 font-[1000] uppercase tracking-[1px]">Master Entries</h3>
                </div>
                <div className="flex flex-col gap-[2px]">
                  {canView('customers') && <MenuItem icon="👥" title="Customer Master" desc="Manage customers" onClick={() => handleNavigate('/customers', 'MASTER')} textHoverClass="group-hover:text-green-600" />}
                  {canView('suppliers') && <MenuItem icon="🏢" title="Supplier Master" desc="Manage suppliers" onClick={() => handleNavigate('/suppliers', 'MASTER')} textHoverClass="group-hover:text-green-600" />}
                  {canView('products') && <MenuItem icon="📦" title="Product Master" desc="Items and pricing" onClick={() => handleNavigate('/products', 'MASTER')} textHoverClass="group-hover:text-green-600" />}
                  {canView('transporters') && <MenuItem icon="🚚" title="Transporter Master" desc="Logistics & shipping" onClick={() => handleNavigate('/transporters', 'MASTER')} textHoverClass="group-hover:text-green-600" />}
                  {canView('godowns') && <MenuItem icon="🏭" title="Godown Master" desc="Locations and warehouses" onClick={() => handleNavigate('/godowns', 'MASTER')} textHoverClass="group-hover:text-green-600" />}
                  {isAdmin && <MenuItem icon="🏢" title="Company Profiles" desc="Multi-GSTIN Branches" onClick={() => handleNavigate('/company-profiles', 'MASTER')} textHoverClass="group-hover:text-green-600" />}
                  {isAdmin && <div className="h-px bg-slate-200 my-1"></div>}
                  {isAdmin && <MenuItem icon="🔐" title="User Management" desc="Manage staff access" onClick={() => handleNavigate('/users', 'MASTER')} textHoverClass="group-hover:text-rose-600" />}
                </div>
              </div>
            )}
            </div>
          )}

          {/* Factory Section */}
          {showFactorySection && (
          <div className="relative">
            <button 
              onClick={() => { setFactoryMenuOpen(!factoryMenuOpen); setBillingMenuOpen(false); setMastersMenuOpen(false); setReportsMenuOpen(false); setHrMenuOpen(false); }}
              className="bg-yellow-50 text-yellow-700 border border-yellow-500/20 px-[12px] py-[8px] rounded-full text-[13px] font-black hover:bg-yellow-500 hover:text-white transition-all shadow-sm flex-1 md:flex-none"
            >
              Factory ▾
            </button>
            {factoryMenuOpen && (
              <div className="absolute top-[100%] mt-3 left-0 md:left-1/2 md:-translate-x-1/2 w-[calc(100vw-32px)] md:w-[540px] bg-slate-50/90 backdrop-blur-[24px] border border-white/60 rounded-[24px] shadow-[0_32px_80px_rgba(15,23,42,0.12)] p-[8px] z-[90] grid grid-cols-1 md:grid-cols-2 gap-[8px]">
                <div>
                  <div className="px-[12px] pt-[12px] pb-[8px]">
                    <h3 className="text-[10px] text-slate-400 font-[1000] uppercase tracking-[1px]">Factory Core</h3>
                  </div>
                  <div className="flex flex-col gap-[2px]">
                    {canView('production') && <MenuItem icon="🏭" title="Production Entry" desc="Log daily production" onClick={() => handleNavigate('/production', 'FACTORY')} textHoverClass="group-hover:text-yellow-600" />}
                    {canView('materials') && <MenuItem icon="📦" title="Material Master" desc="Manage raw materials" onClick={() => handleNavigate('/materials', 'FACTORY')} textHoverClass="group-hover:text-yellow-600" />}
                    {canView('machines') && <MenuItem icon="⚙️" title="Machine Master" desc="Manage machines" onClick={() => handleNavigate('/machines', 'FACTORY')} textHoverClass="group-hover:text-yellow-600" />}
                  </div>
                </div>

                <div>
                  <div className="px-[12px] pt-[12px] pb-[8px]">
                    <h3 className="text-[10px] text-slate-400 font-[1000] uppercase tracking-[1px]">Inventory & Stock</h3>
                  </div>
                  <div className="flex flex-col gap-[2px]">
                    {canView('purchase') && <MenuItem icon="🛒" title="Purchase Entry" desc="Record purchases" onClick={() => handleNavigate('/purchase', 'FACTORY')} textHoverClass="group-hover:text-orange-600" />}
                    {canView('stock') && <MenuItem icon="📊" title="Stock Ledger" desc="View inventory" onClick={() => handleNavigate('/stock', 'FACTORY')} textHoverClass="group-hover:text-orange-600" />}
                    {canView('vehicles') && <MenuItem icon="🚛" title="Vehicle Master" desc="Fleet management" onClick={() => handleNavigate('/vehicles', 'FACTORY')} textHoverClass="group-hover:text-orange-600" />}
                    {canView('transfers') && <MenuItem icon="🔄" title="Stock Transfer" desc="Move items" onClick={() => handleNavigate('/transfers', 'FACTORY')} textHoverClass="group-hover:text-orange-600" />}
                  </div>
                </div>
              </div>
            )}
          </div>
          )}

          {/* Reports Section */}
          {showReportsSection && (
            <div className="relative">
            <button 
              onClick={() => { setReportsMenuOpen(!reportsMenuOpen); setBillingMenuOpen(false); setMastersMenuOpen(false); setFactoryMenuOpen(false); setHrMenuOpen(false); }}
              className="bg-purple-50 text-purple-700 border border-purple-500/20 px-[12px] py-[8px] rounded-full text-[13px] font-black hover:bg-purple-500 hover:text-white transition-all shadow-sm flex-1 md:flex-none"
            >
              Reports ▾
            </button>
            {reportsMenuOpen && (
              <div className="absolute top-[100%] mt-3 right-0 w-[calc(100vw-32px)] md:w-[280px] bg-slate-50/90 backdrop-blur-[24px] border border-white/60 rounded-[24px] shadow-[0_32px_80px_rgba(15,23,42,0.12)] p-[8px] z-[90]">
                <div className="px-[12px] pt-[12px] pb-[8px]">
                  <h3 className="text-[10px] text-slate-400 font-[1000] uppercase tracking-[1px]">History & Analytics</h3>
                </div>
                <div className="flex flex-col gap-[2px]">
                  {canView('reports') && <MenuItem icon="📈" title="Billing History" desc="View past invoices" onClick={() => handleNavigate('/billing-history', 'REPORT')} textHoverClass="group-hover:text-purple-600" />}
                  {canView('reports') && <MenuItem icon="📉" title="Inventory History" desc="View stock changes" onClick={() => handleNavigate('/inventory-history', 'REPORT')} textHoverClass="group-hover:text-purple-600" />}
                  {canView('reports') && <div className="h-px bg-slate-200 my-1"></div>}
                  {canView('reports') && <MenuItem icon="🏛️" title="Old ERP Portal" desc="Historical data access" onClick={() => handleNavigate('/legacy', 'REPORT')} textHoverClass="group-hover:text-purple-600" />}
                  {canView('reports') && <MenuItem icon="🌐" title="E-Way Bill Fetcher" desc="Gov portal sync" onClick={() => handleNavigate('/eway-bills', 'REPORT')} textHoverClass="group-hover:text-purple-600" />}
                </div>
              </div>
            )}
            </div>
          )}

          {/* HR & Payroll Section */}
          {showHrSection && (
            <div className="relative">
            <button 
              onClick={() => { setHrMenuOpen(!hrMenuOpen); setReportsMenuOpen(false); setBillingMenuOpen(false); setMastersMenuOpen(false); setFactoryMenuOpen(false); }}
              className="bg-indigo-50 text-indigo-700 border border-indigo-500/20 px-[12px] py-[8px] rounded-full text-[13px] font-black hover:bg-indigo-500 hover:text-white transition-all shadow-sm flex-1 md:flex-none"
            >
              HR ▾
            </button>
            {hrMenuOpen && (
              <div className="absolute top-[100%] mt-3 right-0 w-[calc(100vw-32px)] md:w-[280px] bg-slate-50/90 backdrop-blur-[24px] border border-white/60 rounded-[24px] shadow-[0_32px_80px_rgba(15,23,42,0.12)] p-[8px] z-[90]">
                <div className="px-[12px] pt-[12px] pb-[8px]">
                  <h3 className="text-[10px] text-slate-400 font-[1000] uppercase tracking-[1px]">Staff Management</h3>
                </div>
                <div className="flex flex-col gap-[2px]">
                  {canView('employees') && <MenuItem icon="👥" title="Employee Master" desc="Manage staff details" onClick={() => handleNavigate('/employees', 'REPORT')} textHoverClass="group-hover:text-indigo-600" />}
                  {canView('payroll') && <MenuItem icon="💸" title="Payroll Entry" desc="Manage salary payouts" onClick={() => handleNavigate('/payroll', 'REPORT')} textHoverClass="group-hover:text-indigo-600" />}
                </div>
              </div>
            )}
            </div>
          )}

          {/* User Profile & Logout */}
          <div className="hidden md:flex items-center gap-3 ml-2 pl-4 border-l border-slate-200">
            <div className="text-right">
              <div className="text-[11px] font-black text-slate-800 uppercase tracking-wider">{user?.username || 'User'}</div>
              <div className="text-[9px] font-bold text-slate-400 uppercase">{user?.role || 'Staff'}</div>
            </div>
            <button 
              onClick={handleLogout}
              className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-slate-500 hover:bg-rose-50 hover:text-rose-600 transition-colors"
              title="Logout"
            >
              <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
            </button>
          </div>

        </div>
      </div>
    </header>
  );
}
