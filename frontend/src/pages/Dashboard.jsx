import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useStore } from '../store/useStore';
import { useAuth } from '../store/useAuth';
import { erpApi } from '../api/erpApi';

export default function Dashboard() {
  const navigate = useNavigate();
  const setCurrentType = useStore((state) => state.setCurrentType);
  const { user, logout } = useAuth();
  const [repStats, setRepStats] = useState(null);
  
  const handleLogout = () => {
    logout();
    navigate('/login');
  };
  
  // Clear any active specific themes to a neutral/dashboard theme if desired, 
  // or default to INV to keep it consistent with the overall app colors.
  useEffect(() => {
    setCurrentType('INV');
    
    if (user?.role === 'REP') {
      const fetchRepStats = async () => {
        try {
          const stats = await erpApi.getRepDashboard();
          setRepStats(stats);
        } catch (error) {
          console.error("Failed to load rep stats", error);
        }
      };
      fetchRepStats();
    }
  }, [setCurrentType, user?.role]);

  const handleNavigate = (path, type) => {
    if (type) setCurrentType(type);
    navigate(path);
  };

  const isAdmin = user?.role === 'ADMIN';
  const isRep = user?.role === 'REP';
  const canView = (mod) => isAdmin || user?.permissions?.[mod]?.view;

  // Permission checks mapping to the new operational categories
  const showSales = isRep || canView('billing') || canView('customers') || canView('transporters') || canView('reports') || canView('vehicles');
  const showPurchases = !isRep && (canView('purchase') || canView('suppliers') || canView('materials'));
  const showGodown = !isRep && (canView('stock') || canView('transfers') || canView('godowns') || canView('products') || canView('vehicles') || canView('materials'));
  const showProduction = !isRep && (canView('production') || canView('machines'));
  const showHr = !isRep && (isAdmin || ['employees', 'payroll'].some(canView));
  const showAdmin = !isRep && (isAdmin || canView('reports'));

  return (
    <div className="space-y-6 max-w-[1200px] mx-auto pt-4 md:pt-10 relative px-4">
      
      {/* Logout Button */}
      <div className="absolute top-4 right-4 md:top-10 md:right-4 z-10">
        <button 
          onClick={handleLogout}
          className="flex items-center gap-2 bg-white border border-rose-100 text-rose-500 px-4 py-2 rounded-full text-sm font-bold shadow-sm hover:bg-rose-50 hover:text-rose-600 transition-all"
        >
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
          Logout
        </button>
      </div>

      {/* Welcome Section */}
      <div className="text-center space-y-2 mb-8">
        <h1 className="text-3xl md:text-5xl font-black text-slate-800 tracking-tight">
          Welcome back, {user?.username || 'User'}! 👋
        </h1>
        <p className="text-sm md:text-base font-bold text-slate-500 max-w-xl mx-auto">
          {isRep ? "Here is a quick overview of your sales performance." : "Select a module below to begin your work. Your dashboard is customized based on your role access."}
        </p>
      </div>

      {isRep && repStats && (
        <div className="space-y-8 animate-in fade-in slide-in-from-bottom-4 duration-500">
          {/* Rep Stats Row */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white rounded-[24px] p-6 border border-slate-200 shadow-sm flex flex-col justify-center items-center text-center">
              <span className="text-[12px] font-black text-slate-400 uppercase tracking-widest mb-2">Total Approved Sales</span>
              <span className="text-3xl md:text-4xl font-black text-active tracking-tight">₹{(repStats.totalSales || 0).toLocaleString()}</span>
            </div>
            <div className="bg-white rounded-[24px] p-6 border border-slate-200 shadow-sm flex flex-col justify-center items-center text-center">
              <span className="text-[12px] font-black text-slate-400 uppercase tracking-widest mb-2">Pending Orders</span>
              <span className="text-3xl md:text-4xl font-black text-amber-500 tracking-tight">{repStats.pendingOrdersCount}</span>
            </div>
            <div className="bg-white rounded-[24px] p-6 border border-slate-200 shadow-sm flex flex-col justify-center items-center text-center">
              <span className="text-[12px] font-black text-slate-400 uppercase tracking-widest mb-2">Assigned Customers</span>
              <span className="text-3xl md:text-4xl font-black text-emerald-500 tracking-tight">{repStats.totalCustomers}</span>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Quick Actions */}
            <div className="bg-white rounded-[24px] p-6 border border-slate-200 shadow-sm">
              <h2 className="text-[14px] font-black text-slate-700 uppercase tracking-wide mb-4">Quick Actions</h2>
              <div className="space-y-3">
                <button 
                  onClick={() => handleNavigate('/sales-order', 'SALES')}
                  className="w-full flex items-center justify-between p-4 bg-active-soft text-active-dark rounded-[16px] font-bold hover:bg-active hover:text-white transition-all group shadow-sm"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-xl">📝</span>
                    <span>Create New Sales Order</span>
                  </div>
                  <span className="opacity-50 group-hover:opacity-100 group-hover:translate-x-1 transition-all">→</span>
                </button>
                <button 
                  onClick={() => handleNavigate('/customers', 'SALES')}
                  className="w-full flex items-center justify-between p-4 bg-slate-50 text-slate-700 rounded-[16px] font-bold hover:bg-slate-100 transition-all group"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-xl">👥</span>
                    <span>View Customer Directory</span>
                  </div>
                  <span className="opacity-50 group-hover:opacity-100 group-hover:translate-x-1 transition-all">→</span>
                </button>
              </div>
            </div>

            {/* Recent Orders */}
            <div className="bg-white rounded-[24px] p-6 border border-slate-200 shadow-sm">
              <h2 className="text-[14px] font-black text-slate-700 uppercase tracking-wide mb-4">Recent Orders</h2>
              <div className="space-y-3">
                {repStats.recentOrders && repStats.recentOrders.length > 0 ? (
                  repStats.recentOrders.map(order => (
                    <div key={order.id} className="flex justify-between items-center p-3 border-b border-slate-100 last:border-0 hover:bg-slate-50 rounded-lg transition-colors">
                      <div>
                        <div className="text-[13px] font-bold text-slate-800">{order.customerName}</div>
                        <div className="text-[11px] font-semibold text-slate-500">{new Date(order.date).toLocaleDateString()}</div>
                      </div>
                      <div className="text-right">
                        <div className="text-[13px] font-black text-slate-700">₹{parseFloat(order.subtotal).toLocaleString()}</div>
                        <div className={`text-[10px] font-bold uppercase tracking-wider ${
                          order.status === 'APPROVED' ? 'text-emerald-500' : 
                          order.status === 'REJECTED' ? 'text-rose-500' : 'text-amber-500'
                        }`}>
                          {order.status}
                        </div>
                      </div>
                    </div>
                  ))
                ) : (
                  <div className="text-center py-6 text-sm font-bold text-slate-400">No recent orders found.</div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Primary Action Modules - 6 Category Grid (Hidden for Reps) */}
      {!isRep && (
        <>
          {isAdmin && (
            <div className="flex justify-center mb-8">
              <button 
                onClick={() => handleNavigate('/pending-orders', 'SALES')}
                className="flex items-center gap-2 bg-amber-100 border border-amber-200 text-amber-800 px-6 py-3 rounded-full text-sm font-black shadow-sm hover:bg-amber-200 hover:-translate-y-1 transition-all"
              >
                <span className="text-xl">🔔</span> Review Pending Sales Orders
              </button>
            </div>
          )}
          
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        
        {/* Sales */}
        {showSales && (
          <button 
            onClick={() => handleNavigate(isRep ? '/sales-order' : '/billing', 'INV')}
            className="group relative overflow-hidden bg-gradient-to-br from-blue-500 to-indigo-600 rounded-[32px] p-8 text-left transition-all duration-300 hover:-translate-y-2 hover:shadow-[0_32px_64px_rgba(79,70,229,0.25)] border border-white/20 h-[220px] flex flex-col justify-end"
          >
            <div className="absolute top-0 right-0 -mr-8 -mt-8 w-48 h-48 bg-white opacity-10 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700"></div>
            <div className="absolute -top-4 right-6 text-[80px] opacity-20 transform rotate-12 group-hover:rotate-0 transition-transform duration-500">🧾</div>
            
            <div className="relative z-10">
              <div className="w-14 h-14 bg-white/20 backdrop-blur-md rounded-[18px] flex items-center justify-center text-3xl mb-4 border border-white/30 group-hover:scale-110 transition-transform duration-300 shadow-lg">🧾</div>
              <h2 className="text-2xl md:text-3xl font-black text-white mb-1 tracking-tight">{isRep ? 'Sales Order' : 'Sales'}</h2>
              <p className="text-blue-100 font-semibold text-sm">{isRep ? 'Draft a new customer order' : 'Invoices, Estimates & Customers'}</p>
            </div>
          </button>
        )}

        {/* Purchases */}
        {showPurchases && (
          <button 
            onClick={() => handleNavigate('/purchase', 'PURCHASES')}
            className="group relative overflow-hidden bg-gradient-to-br from-orange-400 to-red-500 rounded-[32px] p-8 text-left transition-all duration-300 hover:-translate-y-2 hover:shadow-[0_32px_64px_rgba(239,68,68,0.25)] border border-white/20 h-[220px] flex flex-col justify-end"
          >
            <div className="absolute top-0 right-0 -mr-8 -mt-8 w-48 h-48 bg-white opacity-10 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700"></div>
            <div className="absolute -top-4 right-6 text-[80px] opacity-20 transform rotate-12 group-hover:rotate-0 transition-transform duration-500">🛒</div>
            
            <div className="relative z-10">
              <div className="w-14 h-14 bg-white/20 backdrop-blur-md rounded-[18px] flex items-center justify-center text-3xl mb-4 border border-white/30 group-hover:scale-110 transition-transform duration-300 shadow-lg">🛒</div>
              <h2 className="text-2xl md:text-3xl font-black text-white mb-1 tracking-tight">Purchases</h2>
              <p className="text-orange-100 font-semibold text-sm">Inward Stock & Suppliers</p>
            </div>
          </button>
        )}

        {/* Godown */}
        {showGodown && (
          <button 
            onClick={() => handleNavigate('/stock', 'GODOWN')}
            className="group relative overflow-hidden bg-gradient-to-br from-emerald-400 to-teal-600 rounded-[32px] p-8 text-left transition-all duration-300 hover:-translate-y-2 hover:shadow-[0_32px_64px_rgba(16,185,129,0.25)] border border-white/20 h-[220px] flex flex-col justify-end"
          >
            <div className="absolute top-0 right-0 -mr-8 -mt-8 w-48 h-48 bg-white opacity-10 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700"></div>
            <div className="absolute -top-4 right-6 text-[80px] opacity-20 transform rotate-12 group-hover:rotate-0 transition-transform duration-500">🏭</div>
            
            <div className="relative z-10">
              <div className="w-14 h-14 bg-white/20 backdrop-blur-md rounded-[18px] flex items-center justify-center text-3xl mb-4 border border-white/30 group-hover:scale-110 transition-transform duration-300 shadow-lg">🏭</div>
              <h2 className="text-2xl md:text-3xl font-black text-white mb-1 tracking-tight">Godown</h2>
              <p className="text-emerald-100 font-semibold text-sm">Inventory, Transfers & Items</p>
            </div>
          </button>
        )}

        {/* Production */}
        {showProduction && (
          <button 
            onClick={() => handleNavigate('/production', 'PRODUCTION')}
            className="group relative overflow-hidden bg-gradient-to-br from-amber-400 to-yellow-500 rounded-[32px] p-8 text-left transition-all duration-300 hover:-translate-y-2 hover:shadow-[0_32px_64px_rgba(245,158,11,0.25)] border border-white/20 h-[220px] flex flex-col justify-end"
          >
            <div className="absolute top-0 right-0 -mr-8 -mt-8 w-48 h-48 bg-white opacity-10 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700"></div>
            <div className="absolute -top-4 right-6 text-[80px] opacity-20 transform rotate-12 group-hover:rotate-0 transition-transform duration-500">⚙️</div>
            
            <div className="relative z-10">
              <div className="w-14 h-14 bg-white/20 backdrop-blur-md rounded-[18px] flex items-center justify-center text-3xl mb-4 border border-white/30 group-hover:scale-110 transition-transform duration-300 shadow-lg">⚙️</div>
              <h2 className="text-2xl md:text-3xl font-black text-white mb-1 tracking-tight">Production</h2>
              <p className="text-amber-100 font-semibold text-sm">Factory Output & Processing</p>
            </div>
          </button>
        )}

        {/* HR & Payroll */}
        {showHr && (
          <button 
            onClick={() => handleNavigate('/employees', 'HR')}
            className="group relative overflow-hidden bg-gradient-to-br from-indigo-400 to-purple-600 rounded-[32px] p-8 text-left transition-all duration-300 hover:-translate-y-2 hover:shadow-[0_32px_64px_rgba(139,92,246,0.25)] border border-white/20 h-[220px] flex flex-col justify-end"
          >
            <div className="absolute top-0 right-0 -mr-8 -mt-8 w-48 h-48 bg-white opacity-10 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700"></div>
            <div className="absolute -top-4 right-6 text-[80px] opacity-20 transform rotate-12 group-hover:rotate-0 transition-transform duration-500">👥</div>
            
            <div className="relative z-10">
              <div className="w-14 h-14 bg-white/20 backdrop-blur-md rounded-[18px] flex items-center justify-center text-3xl mb-4 border border-white/30 group-hover:scale-110 transition-transform duration-300 shadow-lg">👥</div>
              <h2 className="text-2xl md:text-3xl font-black text-white mb-1 tracking-tight">HR & Payroll</h2>
              <p className="text-indigo-100 font-semibold text-sm">Staff & Salary Management</p>
            </div>
          </button>
        )}

        {/* Admin & Settings */}
        {showAdmin && (
          <button 
            onClick={() => handleNavigate('/company-profiles', 'ADMIN')}
            className="group relative overflow-hidden bg-gradient-to-br from-slate-600 to-slate-800 rounded-[32px] p-8 text-left transition-all duration-300 hover:-translate-y-2 hover:shadow-[0_32px_64px_rgba(71,85,105,0.25)] border border-white/20 h-[220px] flex flex-col justify-end"
          >
            <div className="absolute top-0 right-0 -mr-8 -mt-8 w-48 h-48 bg-white opacity-10 rounded-full blur-2xl group-hover:scale-150 transition-transform duration-700"></div>
            <div className="absolute -top-4 right-6 text-[80px] opacity-20 transform rotate-12 group-hover:rotate-0 transition-transform duration-500">🛡️</div>
            
            <div className="relative z-10">
              <div className="w-14 h-14 bg-white/20 backdrop-blur-md rounded-[18px] flex items-center justify-center text-3xl mb-4 border border-white/30 group-hover:scale-110 transition-transform duration-300 shadow-lg">🛡️</div>
              <h2 className="text-2xl md:text-3xl font-black text-white mb-1 tracking-tight">Admin</h2>
              <p className="text-slate-200 font-semibold text-sm">Settings & System Tools</p>
            </div>
          </button>
        )}
          </div>
        </>
      )}

    </div>
  );
}
