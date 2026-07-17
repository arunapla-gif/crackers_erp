import React, { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useStore } from '../store/useStore';
import { useAuth } from '../store/useAuth';

export default function Dashboard() {
  const navigate = useNavigate();
  const setCurrentType = useStore((state) => state.setCurrentType);
  const { user, logout } = useAuth();
  
  const handleLogout = () => {
    logout();
    navigate('/login');
  };
  
  // Clear any active specific themes to a neutral/dashboard theme if desired, 
  // or default to INV to keep it consistent with the overall app colors.
  useEffect(() => {
    setCurrentType('INV');
  }, [setCurrentType]);

  const handleNavigate = (path, type) => {
    if (type) setCurrentType(type);
    navigate(path);
  };

  const isAdmin = user?.role === 'ADMIN';
  const canView = (mod) => isAdmin || user?.permissions?.[mod]?.view;

  return (
    <div className="space-y-6 max-w-[1000px] mx-auto pt-4 md:pt-10 relative">
      
      {/* Logout Button */}
      <div className="absolute top-4 right-4 md:top-10 md:right-0">
        <button 
          onClick={handleLogout}
          className="flex items-center gap-2 bg-white border border-rose-100 text-rose-500 px-4 py-2 rounded-full text-sm font-bold shadow-sm hover:bg-rose-50 hover:text-rose-600 transition-all"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
          Logout
        </button>
      </div>

      {/* Welcome Section */}
      <div className="text-center space-y-2 mb-10">
        <h1 className="text-3xl md:text-5xl font-black text-slate-800 tracking-tight">
          Welcome back, {user?.username || 'User'}! 👋
        </h1>
        <p className="text-sm md:text-base font-bold text-slate-500 max-w-xl mx-auto">
          Select a module below to begin your work. Your dashboard is customized based on your role access.
        </p>
      </div>

      {/* Primary Action Modules */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        
        {/* Billing & Sales */}
        <button 
          onClick={() => handleNavigate('/billing', 'INV')}
          className="group relative overflow-hidden bg-gradient-to-br from-blue-500 to-indigo-600 rounded-[32px] p-8 text-left transition-all duration-300 hover:-translate-y-2 hover:shadow-[0_32px_64px_rgba(79,70,229,0.25)] border border-white/20 h-[220px] flex flex-col justify-end"
        >
          {/* Background Decoration */}
          <div className="absolute top-0 right-0 -mr-8 -mt-8 w-48 h-48 bg-white opacity-10 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700"></div>
          <div className="absolute -top-4 right-6 text-[80px] opacity-20 transform rotate-12 group-hover:rotate-0 transition-transform duration-500">
            🧾
          </div>
          
          <div className="relative z-10">
            <div className="w-14 h-14 bg-white/20 backdrop-blur-md rounded-[18px] flex items-center justify-center text-3xl mb-4 border border-white/30 group-hover:scale-110 transition-transform duration-300 shadow-lg">
              🛒
            </div>
            <h2 className="text-2xl md:text-3xl font-black text-white mb-1 tracking-tight">Billing & Sales</h2>
            <p className="text-blue-100 font-semibold text-sm">Create Invoices, Estimates & Performas</p>
          </div>
        </button>

        {/* Factory & Production */}
        { (isAdmin || ['production','materials','machines','purchase','stock','vehicles','transfers'].some(canView)) && (
          <button 
            onClick={() => handleNavigate('/production', 'FACTORY')}
            className="group relative overflow-hidden bg-gradient-to-br from-amber-400 to-orange-500 rounded-[32px] p-8 text-left transition-all duration-300 hover:-translate-y-2 hover:shadow-[0_32px_64px_rgba(245,158,11,0.25)] border border-white/20 h-[220px] flex flex-col justify-end"
          >
            {/* Background Decoration */}
            <div className="absolute top-0 right-0 -mr-8 -mt-8 w-48 h-48 bg-white opacity-10 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700"></div>
            <div className="absolute -top-4 right-6 text-[80px] opacity-20 transform rotate-12 group-hover:rotate-0 transition-transform duration-500">
              🏭
            </div>
            
            <div className="relative z-10">
              <div className="w-14 h-14 bg-white/20 backdrop-blur-md rounded-[18px] flex items-center justify-center text-3xl mb-4 border border-white/30 group-hover:scale-110 transition-transform duration-300 shadow-lg">
                ⚙️
              </div>
              <h2 className="text-2xl md:text-3xl font-black text-white mb-1 tracking-tight">Factory Core</h2>
              <p className="text-orange-100 font-semibold text-sm">Manage Production, Stock & Materials</p>
            </div>
          </button>
        )}
      </div>

      {/* Secondary Modules */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-6">
        
        {/* Master Data */}
        { (isAdmin || ['customers','suppliers','products','transporters','godowns'].some(canView)) && (
          <button 
            onClick={() => handleNavigate('/customers', 'MASTER')}
            className="group bg-white rounded-[24px] p-6 text-left border border-slate-200 shadow-[0_8px_24px_rgba(15,23,42,0.04)] hover:shadow-[0_16px_40px_rgba(15,23,42,0.08)] hover:-translate-y-1 transition-all duration-300 flex items-center gap-4"
          >
            <div className="w-12 h-12 bg-emerald-50 rounded-[14px] flex items-center justify-center text-2xl border border-emerald-100 group-hover:scale-110 transition-transform duration-300">
              👥
            </div>
            <div>
              <h3 className="text-base font-black text-slate-800">Master Data</h3>
              <p className="text-xs font-bold text-slate-400 mt-0.5">Customers, Suppliers & Items</p>
            </div>
          </button>
        )}

        {/* HR & Payroll */}
        { (isAdmin || ['employees', 'payroll'].some(canView)) && (
          <button 
            onClick={() => handleNavigate('/employees', 'REPORT')}
            className="group bg-white rounded-[24px] p-6 text-left border border-slate-200 shadow-[0_8px_24px_rgba(15,23,42,0.04)] hover:shadow-[0_16px_40px_rgba(15,23,42,0.08)] hover:-translate-y-1 transition-all duration-300 flex items-center gap-4"
          >
            <div className="w-12 h-12 bg-indigo-50 rounded-[14px] flex items-center justify-center text-2xl border border-indigo-100 group-hover:scale-110 transition-transform duration-300">
              💼
            </div>
            <div>
              <h3 className="text-base font-black text-slate-800">HR & Payroll</h3>
              <p className="text-xs font-bold text-slate-400 mt-0.5">Staff & Salary Management</p>
            </div>
          </button>
        )}

        {/* Reports & Analytics */}
        { (canView('reports')) && (
          <button 
            onClick={() => handleNavigate('/billing-history', 'REPORT')}
            className="group bg-white rounded-[24px] p-6 text-left border border-slate-200 shadow-[0_8px_24px_rgba(15,23,42,0.04)] hover:shadow-[0_16px_40px_rgba(15,23,42,0.08)] hover:-translate-y-1 transition-all duration-300 flex items-center gap-4"
          >
            <div className="w-12 h-12 bg-purple-50 rounded-[14px] flex items-center justify-center text-2xl border border-purple-100 group-hover:scale-110 transition-transform duration-300">
              📈
            </div>
            <div>
              <h3 className="text-base font-black text-slate-800">Reports</h3>
              <p className="text-xs font-bold text-slate-400 mt-0.5">History, Analytics & E-Way Bills</p>
            </div>
          </button>
        )}
      </div>

    </div>
  );
}
