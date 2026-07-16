import React, { useState, useEffect, useMemo } from 'react';
import { erpApi } from '../../api/erpApi';

export default function LegacyDashboard() {
  const [activeTab, setActiveTab] = useState('MENU');
  
  // Search, Filter, Sort, Pagination State
  const [searchTerm, setSearchTerm] = useState('');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [sortBy, setSortBy] = useState('date_desc');
  const [currentPage, setCurrentPage] = useState(1);
  const ITEMS_PER_PAGE = 50;
  
  // Accounts Data
  const [customers, setCustomers] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [purchases, setPurchases] = useState([]);
  const [payments, setPayments] = useState([]);
  const [estimates, setEstimates] = useState([]);
  
  // Payroll Data
  const [employees, setEmployees] = useState([]);
  const [workentries, setWorkentries] = useState([]);
  const [payrollProducts, setPayrollProducts] = useState([]);

  const [loading, setLoading] = useState(false);

  // Expanding row state
  const [expandedPurchase, setExpandedPurchase] = useState(null);
  const [purchaseItems, setPurchaseItems] = useState({});
  const [purchaseCharges, setPurchaseCharges] = useState({});
  
  const [expandedEstimate, setExpandedEstimate] = useState(null);
  const [estimateDetails, setEstimateDetails] = useState({});

  const [expandedWork, setExpandedWork] = useState(null);
  const [workItems, setWorkItems] = useState({});
  const [analytics, setAnalytics] = useState(null);
  const [trendProducts, setTrendProducts] = useState([]);
  const [selectedProduct, setSelectedProduct] = useState('');
  const [priceTrends, setPriceTrends] = useState([]);
  const [trendsLoading, setTrendsLoading] = useState(false);

  // Reset filters & page on tab change
  useEffect(() => {
    if (activeTab === 'MENU') {
      if (!analytics) erpApi.getLegacyAnalytics().then(data => setAnalytics(data)).catch(console.error);
      if (trendProducts.length === 0) erpApi.getLegacyAnalyticsProducts().then(data => setTrendProducts(data)).catch(console.error);
    }
    setSearchTerm('');
    setDateFrom('');
    setDateTo('');
    setSortBy('date_desc');
    setCurrentPage(1);
    setExpandedPurchase(null);
    setExpandedWork(null);
    setExpandedEstimate(null);
  }, [activeTab]);

  // Reset page to 1 when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, dateFrom, dateTo, sortBy]);

  useEffect(() => {
    if (selectedProduct) {
      setTrendsLoading(true);
      erpApi.getLegacyAnalyticsPriceTrends(selectedProduct).then(data => {
        setPriceTrends(data);
        setTrendsLoading(false);
      }).catch(console.error);
    } else {
      setPriceTrends([]);
    }
  }, [selectedProduct]);

  useEffect(() => {
    if (activeTab === 'CUSTOMERS' && customers.length === 0) {
      setLoading(true);
      erpApi.getLegacyCustomers().then(data => { setCustomers(data); setLoading(false); }).catch(() => setLoading(false));
    }
    if (activeTab === 'SUPPLIERS' && suppliers.length === 0) {
      setLoading(true);
      erpApi.getLegacySuppliers().then(data => { setSuppliers(data); setLoading(false); }).catch(() => setLoading(false));
    }
    if (activeTab === 'EMPLOYEES' && employees.length === 0) {
      setLoading(true);
      erpApi.getLegacyEmployees().then(data => { setEmployees(data); setLoading(false); }).catch(() => setLoading(false));
    }
    if (activeTab === 'PAYMENTS' && payments.length === 0) {
      setLoading(true);
      Promise.all([
        erpApi.getLegacyPayments(),
        suppliers.length === 0 ? erpApi.getLegacySuppliers() : Promise.resolve(suppliers)
      ]).then(([payData, supData]) => {
        if (suppliers.length === 0) setSuppliers(supData);
        const enriched = payData.map(p => {
          const sup = supData.find(s => s.SupplierID === p.Suppliername);
          return { ...p, SupplierNameStr: sup ? sup.Suppliername : `ID: ${p.Suppliername}` };
        });
        setPayments(enriched);
        setLoading(false);
      }).catch(() => setLoading(false));
    }
    if (activeTab === 'ESTIMATES' && estimates.length === 0) {
      setLoading(true);
      Promise.all([
        erpApi.getLegacyEstimates(),
        customers.length === 0 ? erpApi.getLegacyCustomers() : Promise.resolve(customers)
      ]).then(([estData, custData]) => {
        if (customers.length === 0) setCustomers(custData);
        const enriched = estData.map(e => {
          const cust = custData.find(c => c.CustomerID === e.Customeraccountnumber);
          return { ...e, CustomerName: cust ? cust.Customername : `ID: ${e.Customeraccountnumber}` };
        });
        setEstimates(enriched);
        setLoading(false);
      }).catch(() => setLoading(false));
    }
    if (activeTab === 'PURCHASES' && purchases.length === 0) {
      setLoading(true);
      Promise.all([
        erpApi.getLegacyPurchases(),
        suppliers.length === 0 ? erpApi.getLegacySuppliers() : Promise.resolve(suppliers)
      ]).then(([purchasesData, suppliersData]) => {
        if (suppliers.length === 0) setSuppliers(suppliersData);
        const enriched = purchasesData.map(p => {
          const sup = suppliersData.find(s => s.SupplierID === p.Supplieraccountnumber);
          return { ...p, Suppliername: sup ? sup.Suppliername : `ID: ${p.Supplieraccountnumber}` };
        });
        setPurchases(enriched);
        setLoading(false);
      }).catch(() => setLoading(false));
    }
    if (activeTab === 'WORKENTRIES' && workentries.length === 0) {
      setLoading(true);
      Promise.all([
        erpApi.getLegacyWorkentries(),
        employees.length === 0 ? erpApi.getLegacyEmployees() : Promise.resolve(employees),
        erpApi.getLegacyPayrollProducts()
      ]).then(([workData, empData, prodData]) => {
        if (employees.length === 0) setEmployees(empData);
        setPayrollProducts(prodData);
        const enriched = workData.map(w => {
          const emp = empData.find(e => e.EmployeeID === w.EmployeeId);
          return { ...w, EmployeeName: emp ? emp.EmployeeName : `ID: ${w.EmployeeId}` };
        });
        setWorkentries(enriched);
        setLoading(false);
      }).catch(() => setLoading(false));
    }
  }, [activeTab]);

  const handlePurchaseClick = async (purchaseId) => {
    if (expandedPurchase === purchaseId) { setExpandedPurchase(null); return; }
    setExpandedPurchase(purchaseId);
    if (!purchaseItems[purchaseId]) {
      setItemsLoading(true);
      try {
        const [items, charges] = await Promise.all([erpApi.getLegacyPurchaseParticulars(purchaseId), erpApi.getLegacyPurchaseCharges(purchaseId)]);
        setPurchaseItems(prev => ({ ...prev, [purchaseId]: items }));
        setPurchaseCharges(prev => ({ ...prev, [purchaseId]: charges }));
      } catch (err) { console.error(err); }
      setItemsLoading(false);
    }
  };

  const handleEstimateClick = async (salesId) => {
    if (expandedEstimate === salesId) { setExpandedEstimate(null); return; }
    setExpandedEstimate(salesId);
    if (!estimateDetails[salesId]) {
      setItemsLoading(true);
      try {
        const details = await erpApi.getLegacyEstimateDetails(salesId);
        setEstimateDetails(prev => ({ ...prev, [salesId]: details }));
      } catch (err) { console.error(err); }
      setItemsLoading(false);
    }
  };

  const handleWorkClick = async (workId) => {
    if (expandedWork === workId) { setExpandedWork(null); return; }
    setExpandedWork(workId);
    if (!workItems[workId]) {
      setItemsLoading(true);
      try {
        const items = await erpApi.getLegacyWorkentryParticulars(workId);
        const enrichedItems = items.map(i => {
          const prod = payrollProducts.find(p => p.ParticularID === String(i.ProductID));
          return { ...i, ProductName: prod ? prod.Particularname : `Prod ID: ${i.ProductID}` };
        });
        setWorkItems(prev => ({ ...prev, [workId]: enrichedItems }));
      } catch (err) { console.error(err); }
      setItemsLoading(false);
    }
  };

  const getInitials = (name) => {
    if (!name) return '?';
    return name.substring(0, 2).toUpperCase();
  };

  // Helper to parse "DD-MM-YYYY" to Date object
  const parseDateString = (dateStr) => {
    if (!dateStr) return new Date(0);
    const parts = dateStr.split('-');
    if (parts.length === 3) return new Date(`${parts[2]}-${parts[1]}-${parts[0]}`);
    return new Date(dateStr); // Fallback
  };

  // Data Pipeline: Search -> Date Filter -> Sort
  const getProcessedData = (data, tab) => {
    let result = [...data];

    // 1. Search Filter
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      result = result.filter(item => {
        if (tab === 'CUSTOMERS' || tab === 'SUPPLIERS') return String(item.Customername || item.Suppliername || '').toLowerCase().includes(term) || String(item.CustomerID || item.SupplierID || '').toLowerCase().includes(term);
        if (tab === 'PURCHASES') return String(item.Suppliername || '').toLowerCase().includes(term) || String(item.Invoiceno || '').toLowerCase().includes(term);
        if (tab === 'PAYMENTS') return String(item.SupplierNameStr || '').toLowerCase().includes(term) || String(item.Invoiceno || '').toLowerCase().includes(term);
        if (tab === 'ESTIMATES') return String(item.CustomerName || '').toLowerCase().includes(term);
        if (tab === 'EMPLOYEES') return String(item.EmployeeName || '').toLowerCase().includes(term) || String(item.City || '').toLowerCase().includes(term);
        if (tab === 'WORKENTRIES') return String(item.EmployeeName || '').toLowerCase().includes(term);
        return true;
      });
    }

    // 2. Date Filter
    if ((tab === 'PURCHASES' || tab === 'PAYMENTS' || tab === 'ESTIMATES' || tab === 'WORKENTRIES') && (dateFrom || dateTo)) {
      const from = dateFrom ? new Date(dateFrom) : new Date(0);
      const to = dateTo ? new Date(dateTo) : new Date('2100-01-01');
      to.setHours(23, 59, 59, 999);
      
      result = result.filter(item => {
        let itemDateStr = '';
        if (tab === 'PURCHASES') itemDateStr = item.Purchasedate;
        if (tab === 'PAYMENTS') itemDateStr = item.Paymentdate;
        if (tab === 'ESTIMATES') itemDateStr = item.Salesdate;
        if (tab === 'WORKENTRIES') itemDateStr = item.Workerdate;
        const itemDate = parseDateString(itemDateStr);
        return itemDate >= from && itemDate <= to;
      });
    }

    // 3. Sorting
    result.sort((a, b) => {
      if (sortBy === 'date_desc' || sortBy === 'date_asc') {
        let dateA = 0, dateB = 0;
        if (tab === 'PURCHASES') { dateA = parseDateString(a.Purchasedate); dateB = parseDateString(b.Purchasedate); }
        else if (tab === 'PAYMENTS') { dateA = parseDateString(a.Paymentdate); dateB = parseDateString(b.Paymentdate); }
        else if (tab === 'ESTIMATES') { dateA = parseDateString(a.Salesdate); dateB = parseDateString(b.Salesdate); }
        else if (tab === 'WORKENTRIES') { dateA = parseDateString(a.Workerdate); dateB = parseDateString(b.Workerdate); }
        else { dateA = a.id || 0; dateB = b.id || 0; }
        return sortBy === 'date_desc' ? dateB - dateA : dateA - dateB;
      }
      if (sortBy === 'amt_desc' || sortBy === 'amt_asc') {
        let amtA = 0, amtB = 0;
        if (tab === 'PURCHASES' || tab === 'ESTIMATES' || tab === 'WORKENTRIES') { amtA = parseFloat(a.Netamount) || 0; amtB = parseFloat(b.Netamount) || 0; }
        else if (tab === 'PAYMENTS') { amtA = parseFloat(a.Paymentamount) || 0; amtB = parseFloat(b.Paymentamount) || 0; }
        else if (tab === 'CUSTOMERS' || tab === 'SUPPLIERS') { amtA = parseFloat(a.Openingbalance) || 0; amtB = parseFloat(b.Openingbalance) || 0; }
        return sortBy === 'amt_desc' ? amtB - amtA : amtA - amtB;
      }
      if (sortBy === 'name_asc' || sortBy === 'name_desc') {
        let nameA = '', nameB = '';
        if (tab === 'CUSTOMERS') { nameA = a.Customername || ''; nameB = b.Customername || ''; }
        else if (tab === 'SUPPLIERS') { nameA = a.Suppliername || ''; nameB = b.Suppliername || ''; }
        else if (tab === 'EMPLOYEES') { nameA = a.EmployeeName || ''; nameB = b.EmployeeName || ''; }
        else if (tab === 'PURCHASES') { nameA = a.Suppliername || ''; nameB = b.Suppliername || ''; }
        else if (tab === 'PAYMENTS') { nameA = a.SupplierNameStr || ''; nameB = b.SupplierNameStr || ''; }
        else if (tab === 'ESTIMATES') { nameA = a.CustomerName || ''; nameB = b.CustomerName || ''; }
        else if (tab === 'WORKENTRIES') { nameA = a.EmployeeName || ''; nameB = b.EmployeeName || ''; }
        return sortBy === 'name_asc' ? nameA.localeCompare(nameB) : nameB.localeCompare(nameA);
      }
      return 0;
    });

    return result;
  };

  // Select source data based on tab
  const getSourceData = () => {
    if (activeTab === 'CUSTOMERS') return customers;
    if (activeTab === 'SUPPLIERS') return suppliers;
    if (activeTab === 'PURCHASES') return purchases;
    if (activeTab === 'PAYMENTS') return payments;
    if (activeTab === 'ESTIMATES') return estimates;
    if (activeTab === 'EMPLOYEES') return employees;
    if (activeTab === 'WORKENTRIES') return workentries;
    return [];
  };

  // Compute final paginated data
  const processedData = useMemo(() => getProcessedData(getSourceData(), activeTab), [activeTab, customers, suppliers, purchases, payments, estimates, employees, workentries, searchTerm, dateFrom, dateTo, sortBy]);
  const totalPages = Math.max(1, Math.ceil(processedData.length / ITEMS_PER_PAGE));
  const currentData = processedData.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

  // CSV Export (Exports all processed data, ignoring pagination)
  const handleExportCSV = () => {
    if (!processedData || processedData.length === 0) { alert("No data available to export."); return; }
    const headers = Object.keys(processedData[0]).join(',');
    const rows = processedData.map(obj => Object.values(obj).map(val => `"${String(val !== null && val !== undefined ? val : '').replace(/"/g, '""')}"`).join(','));
    const csvContent = [headers, ...rows].join('\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.setAttribute('href', URL.createObjectURL(blob));
    link.setAttribute('download', `Legacy_${activeTab}_Export.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const hasDateSupport = ['PURCHASES', 'PAYMENTS', 'ESTIMATES', 'WORKENTRIES'].includes(activeTab);

  return (
    <div className="p-4 md:p-8 bg-[#F4F7F9] min-h-[90vh] rounded-[32px] border border-slate-200 shadow-sm mt-4 font-sans">
      
      {/* HEADER SECTION */}
      <div className="flex flex-col xl:flex-row xl:items-end justify-between mb-8 gap-4 pb-6 border-b border-slate-200/60">
        <div>
          <div className="flex items-center gap-4">
            {activeTab !== 'MENU' && (
              <button onClick={() => setActiveTab('MENU')} className="w-12 h-12 shrink-0 bg-white hover:bg-slate-100 rounded-2xl flex items-center justify-center transition-all shadow-sm border border-slate-100 hover:scale-105">
                <svg className="w-5 h-5 text-slate-700" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2.5" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path></svg>
              </button>
            )}
            <div>
               <div className="flex items-center gap-3 mb-1">
                  <div className="px-3 py-1 bg-gradient-to-r from-slate-800 to-slate-700 text-white font-bold rounded-lg text-[10px] tracking-widest shadow-sm">LEGACY ARCHIVE</div>
                  <span className="text-slate-400 font-bold text-[13px] tracking-wide uppercase">Read-Only</span>
               </div>
               <h1 className="text-[32px] md:text-[40px] font-black text-slate-800 tracking-tight leading-none">
                  {activeTab === 'MENU' ? 'Old ERP Portal' : activeTab}
               </h1>
            </div>
          </div>
        </div>
        
        {/* ADVANCED ACTION BAR (SEARCH, FILTERS, EXPORT) */}
        {activeTab !== 'MENU' && (
          <div className="flex flex-wrap items-center gap-3 mt-4 xl:mt-0">
             
             {/* Global Search */}
             <div className="relative">
                <svg className="w-5 h-5 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>
                <input type="text" placeholder="Search..." value={searchTerm} onChange={(e) => setSearchTerm(e.target.value)} className="pl-10 pr-4 py-2.5 rounded-xl border border-slate-200 bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 text-[13px] font-bold text-slate-700 w-full md:w-48 transition-all" />
             </div>

             {/* Date Filters (Only for transaction tabs) */}
             {hasDateSupport && (
               <div className="flex items-center gap-2 bg-white rounded-xl border border-slate-200 shadow-sm px-2">
                 <input type="date" value={dateFrom} onChange={(e) => setDateFrom(e.target.value)} className="py-2.5 outline-none text-[12px] font-bold text-slate-600 bg-transparent" />
                 <span className="text-slate-300 font-black">→</span>
                 <input type="date" value={dateTo} onChange={(e) => setDateTo(e.target.value)} className="py-2.5 outline-none text-[12px] font-bold text-slate-600 bg-transparent" />
               </div>
             )}

             {/* Sort Dropdown */}
             <div className="relative">
               <select value={sortBy} onChange={(e) => setSortBy(e.target.value)} className="appearance-none pl-4 pr-10 py-2.5 rounded-xl border border-slate-200 bg-white shadow-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 text-[13px] font-bold text-slate-700 w-full md:w-auto cursor-pointer">
                 {hasDateSupport && <option value="date_desc">Newest First</option>}
                 {hasDateSupport && <option value="date_asc">Oldest First</option>}
                 <option value="name_asc">Name (A-Z)</option>
                 <option value="name_desc">Name (Z-A)</option>
                 <option value="amt_desc">Highest Amount/Balance</option>
                 <option value="amt_asc">Lowest Amount/Balance</option>
               </select>
               <svg className="w-4 h-4 absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 9l-7 7-7-7"></path></svg>
             </div>

             <button onClick={handleExportCSV} className="flex items-center gap-2 bg-emerald-50 text-emerald-700 border border-emerald-200 hover:bg-emerald-600 hover:text-white px-4 py-2.5 rounded-xl text-[13px] font-bold transition-all shadow-sm">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4"></path></svg>
                Export
             </button>
          </div>
        )}
      </div>

      {/* DASHBOARD MENU */}
      {activeTab === 'MENU' && (
        <div className="space-y-12 animate-in fade-in duration-500">
          
          {/* HISTORICAL ANALYTICS */}
          {analytics && (
            <section>
               <h2 className="text-[14px] font-black text-slate-400 uppercase tracking-[0.2em] mb-6 flex items-center gap-3"><span className="w-8 h-[2px] bg-indigo-300 rounded-full"></span>Historical Financial Overview</h2>
               <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                  <div className="bg-gradient-to-br from-indigo-500 to-indigo-700 p-6 rounded-[24px] shadow-lg shadow-indigo-500/20 text-white transform hover:scale-105 transition-transform">
                     <h3 className="text-indigo-200 text-[12px] font-bold uppercase tracking-widest mb-1">Total Sales (Estimates)</h3>
                     <p className="text-[28px] font-black tracking-tight">₹{(analytics.financials.totalEstimates).toLocaleString('en-IN')}</p>
                     <p className="text-indigo-200 text-[12px] font-semibold mt-3 flex items-center gap-2"><span className="w-2 h-2 rounded-full bg-indigo-400"></span>{analytics.counts.estimates.toLocaleString()} historical bills</p>
                  </div>
                  <div className="bg-gradient-to-br from-emerald-500 to-emerald-700 p-6 rounded-[24px] shadow-lg shadow-emerald-500/20 text-white transform hover:scale-105 transition-transform">
                     <h3 className="text-emerald-200 text-[12px] font-bold uppercase tracking-widest mb-1">Total Purchases</h3>
                     <p className="text-[28px] font-black tracking-tight">₹{(analytics.financials.totalPurchases).toLocaleString('en-IN')}</p>
                     <p className="text-emerald-200 text-[12px] font-semibold mt-3 flex items-center gap-2"><span className="w-2 h-2 rounded-full bg-emerald-400"></span>{analytics.counts.purchases.toLocaleString()} inward bills</p>
                  </div>
                  <div className="bg-gradient-to-br from-amber-500 to-amber-700 p-6 rounded-[24px] shadow-lg shadow-amber-500/20 text-white transform hover:scale-105 transition-transform">
                     <h3 className="text-amber-200 text-[12px] font-bold uppercase tracking-widest mb-1">Total Factory Wages</h3>
                     <p className="text-[28px] font-black tracking-tight">₹{(analytics.financials.totalWages).toLocaleString('en-IN')}</p>
                     <p className="text-amber-200 text-[12px] font-semibold mt-3 flex items-center gap-2"><span className="w-2 h-2 rounded-full bg-amber-400"></span>{analytics.counts.workentries.toLocaleString()} production logs</p>
                  </div>
                  <div className="bg-gradient-to-br from-cyan-500 to-cyan-700 p-6 rounded-[24px] shadow-lg shadow-cyan-500/20 text-white transform hover:scale-105 transition-transform">
                     <h3 className="text-cyan-200 text-[12px] font-bold uppercase tracking-widest mb-1">Total Payments Sent</h3>
                     <p className="text-[28px] font-black tracking-tight">₹{(analytics.financials.totalPayments).toLocaleString('en-IN')}</p>
                     <p className="text-cyan-200 text-[12px] font-semibold mt-3 flex items-center gap-2"><span className="w-2 h-2 rounded-full bg-cyan-400"></span>{analytics.counts.suppliers.toLocaleString()} total suppliers</p>
                  </div>
               </div>
            </section>
          )}

          {trendProducts.length > 0 && (
             <div className="mt-8 bg-white p-6 md:p-8 rounded-[24px] shadow-sm border border-slate-200 relative overflow-hidden">
                <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-50 rounded-full blur-3xl -z-10 opacity-50 transform translate-x-1/2 -translate-y-1/2"></div>
                <div className="flex flex-col md:flex-row md:items-center justify-between mb-6 gap-4">
                   <div>
                      <h3 className="text-[18px] font-black text-slate-800">Raw Material Price Trends</h3>
                      <p className="text-[13px] font-medium text-slate-500 mt-1">Track historical purchase price inflation for any item</p>
                   </div>
                   <select value={selectedProduct} onChange={(e) => setSelectedProduct(e.target.value)} className="px-4 py-2.5 rounded-xl border border-slate-200 bg-slate-50 font-bold text-slate-700 text-[14px] outline-none focus:ring-2 focus:ring-indigo-500 w-full md:w-64">
                      <option value="">-- Select Material to Analyze --</option>
                      {trendProducts.map((p, i) => <option key={i} value={p}>{p}</option>)}
                   </select>
                </div>
                
                {selectedProduct && trendsLoading && <div className="py-12 text-center text-slate-400 font-bold animate-pulse">Analyzing historical ledgers...</div>}
                
                {selectedProduct && !trendsLoading && priceTrends.length > 0 && (
                   <div className="overflow-x-auto rounded-xl border border-slate-100 shadow-sm">
                      <table className="w-full text-left">
                         <thead className="bg-slate-50 border-b border-slate-100">
                            <tr>
                               <th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider">Purchase Date</th>
                               <th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Quantity Bought</th>
                               <th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Purchase Rate</th>
                               <th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Price Movement</th>
                            </tr>
                         </thead>
                         <tbody className="divide-y divide-slate-50">
                            {priceTrends.map((t, idx) => {
                               const pct = parseFloat(t.pctChange);
                               let movementClass = "text-slate-400";
                               let arrow = "-";
                               if (pct > 0) { movementClass = "text-rose-500"; arrow = "↑"; }
                               if (pct < 0) { movementClass = "text-emerald-500"; arrow = "↓"; }
                               
                               return (
                                  <tr key={idx} className="hover:bg-slate-50">
                                     <td className="py-3 px-4 text-[13px] font-bold text-slate-700">{t.date}</td>
                                     <td className="py-3 px-4 text-[13px] font-bold text-slate-600 text-right">{t.qty}</td>
                                     <td className="py-3 px-4 text-[14px] font-black text-slate-800 text-right">₹{t.rate}</td>
                                     <td className={`py-3 px-4 text-[13px] font-black text-right flex items-center justify-end gap-1 ${movementClass}`}>
                                        {pct !== 0 ? <>{arrow} {Math.abs(pct)}%</> : <span className="text-slate-300">-</span>}
                                     </td>
                                  </tr>
                               );
                            })}
                         </tbody>
                      </table>
                   </div>
                )}
                {selectedProduct && !trendsLoading && priceTrends.length === 0 && (
                   <div className="py-12 text-center text-slate-400 font-bold">No purchase history found for this item.</div>
                )}
             </div>
          )}

          <section>
            <h2 className="text-[14px] font-black text-slate-400 uppercase tracking-[0.2em] mb-6 flex items-center gap-3"><span className="w-8 h-[2px] bg-slate-300 rounded-full"></span>Billing & Accounts</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <div onClick={() => setActiveTab('ESTIMATES')} className="group bg-white p-6 rounded-[24px] shadow-sm border border-slate-100 hover:shadow-lg transition-all cursor-pointer hover:-translate-y-2">
                <div className="w-14 h-14 bg-indigo-50 text-indigo-600 rounded-2xl flex items-center justify-center mb-5 group-hover:scale-110 group-hover:bg-indigo-600 group-hover:text-white transition-all"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg></div>
                <h3 className="font-black text-slate-800 text-[22px]">Estimates</h3><p className="text-slate-500 text-[14px] mt-1 font-medium">Historical sales & quotes</p>
              </div>
              <div onClick={() => setActiveTab('PURCHASES')} className="group bg-white p-6 rounded-[24px] shadow-sm border border-slate-100 hover:shadow-lg transition-all cursor-pointer hover:-translate-y-2">
                <div className="w-14 h-14 bg-emerald-50 text-emerald-600 rounded-2xl flex items-center justify-center mb-5 group-hover:scale-110 group-hover:bg-emerald-600 group-hover:text-white transition-all"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4"></path></svg></div>
                <h3 className="font-black text-slate-800 text-[22px]">Purchases</h3><p className="text-slate-500 text-[14px] mt-1 font-medium">Historical inward bills</p>
              </div>
              <div onClick={() => setActiveTab('PAYMENTS')} className="group bg-white p-6 rounded-[24px] shadow-sm border border-slate-100 hover:shadow-lg transition-all cursor-pointer hover:-translate-y-2">
                <div className="w-14 h-14 bg-cyan-50 text-cyan-600 rounded-2xl flex items-center justify-center mb-5 group-hover:scale-110 group-hover:bg-cyan-600 group-hover:text-white transition-all"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"></path></svg></div>
                <h3 className="font-black text-slate-800 text-[22px]">Payments</h3><p className="text-slate-500 text-[14px] mt-1 font-medium">Vouchers & Ledgers</p>
              </div>
              <div onClick={() => setActiveTab('CUSTOMERS')} className="group bg-white p-6 rounded-[24px] shadow-sm border border-slate-100 hover:shadow-lg transition-all cursor-pointer hover:-translate-y-2">
                <div className="w-14 h-14 bg-blue-50 text-blue-600 rounded-2xl flex items-center justify-center mb-5 group-hover:scale-110 group-hover:bg-blue-600 group-hover:text-white transition-all"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"></path></svg></div>
                <h3 className="font-black text-slate-800 text-[22px]">Profiles</h3><p className="text-slate-500 text-[14px] mt-1 font-medium">Customers & Suppliers</p>
              </div>
            </div>
          </section>
          <section>
            <h2 className="text-[14px] font-black text-slate-400 uppercase tracking-[0.2em] mb-6 flex items-center gap-3"><span className="w-8 h-[2px] bg-slate-300 rounded-full"></span>Payroll & Factory</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
              <div onClick={() => setActiveTab('EMPLOYEES')} className="group bg-white p-6 rounded-[24px] shadow-sm border border-slate-100 hover:shadow-lg transition-all cursor-pointer hover:-translate-y-2">
                <div className="w-14 h-14 bg-rose-50 text-rose-600 rounded-2xl flex items-center justify-center mb-5 group-hover:scale-110 group-hover:bg-rose-600 group-hover:text-white transition-all"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"></path></svg></div>
                <h3 className="font-black text-slate-800 text-[22px]">Employees</h3><p className="text-slate-500 text-[14px] mt-1 font-medium">Historical staff directory</p>
              </div>
              <div onClick={() => setActiveTab('WORKENTRIES')} className="group bg-white p-6 rounded-[24px] shadow-sm border border-slate-100 hover:shadow-lg transition-all cursor-pointer hover:-translate-y-2">
                <div className="w-14 h-14 bg-amber-50 text-amber-600 rounded-2xl flex items-center justify-center mb-5 group-hover:scale-110 group-hover:bg-amber-600 group-hover:text-white transition-all"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"></path></svg></div>
                <h3 className="font-black text-slate-800 text-[22px]">Work Logs</h3><p className="text-slate-500 text-[14px] mt-1 font-medium">Daily production & wages</p>
              </div>
            </div>
          </section>
        </div>
      )}

      {loading && <div className="flex justify-center py-32"><div className="w-12 h-12 border-4 border-slate-200 border-t-slate-800 rounded-full animate-spin"></div></div>}

      {/* RESULTS COUNT & PAGINATION HEADER */}
      {activeTab !== 'MENU' && !loading && (
        <div className="flex justify-between items-center mb-4">
           <div className="text-[13px] font-bold text-slate-500">
              Showing {(currentPage - 1) * ITEMS_PER_PAGE + 1} - {Math.min(currentPage * ITEMS_PER_PAGE, processedData.length)} of {processedData.length} records
           </div>
           
           {totalPages > 1 && (
             <div className="flex gap-2">
                <button onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))} disabled={currentPage === 1} className="px-3 py-1.5 rounded-lg bg-white border border-slate-200 text-slate-600 disabled:opacity-50 text-[12px] font-bold shadow-sm hover:bg-slate-50">Prev</button>
                <span className="px-4 py-1.5 rounded-lg bg-slate-100 text-slate-700 text-[12px] font-black">{currentPage} / {totalPages}</span>
                <button onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))} disabled={currentPage === totalPages} className="px-3 py-1.5 rounded-lg bg-white border border-slate-200 text-slate-600 disabled:opacity-50 text-[12px] font-bold shadow-sm hover:bg-slate-50">Next</button>
             </div>
           )}
        </div>
      )}

      {/* CUSTOMERS & SUPPLIERS - CARD GRID VIEW */}
      {!loading && (activeTab === 'CUSTOMERS' || activeTab === 'SUPPLIERS') && (
        <div className="animate-in fade-in duration-500">
           <div className="flex gap-4 mb-6">
              <button onClick={() => setActiveTab('CUSTOMERS')} className={`px-6 py-2.5 rounded-full font-bold text-[14px] transition-all ${activeTab === 'CUSTOMERS' ? 'bg-blue-600 text-white shadow-md' : 'bg-white text-slate-500 border border-slate-200'}`}>Customers</button>
              <button onClick={() => setActiveTab('SUPPLIERS')} className={`px-6 py-2.5 rounded-full font-bold text-[14px] transition-all ${activeTab === 'SUPPLIERS' ? 'bg-purple-600 text-white shadow-md' : 'bg-white text-slate-500 border border-slate-200'}`}>Suppliers</button>
           </div>
           <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
             {currentData.map(p => {
                const name = activeTab === 'CUSTOMERS' ? p.Customername : p.Suppliername;
                const idStr = activeTab === 'CUSTOMERS' ? p.CustomerID : p.SupplierID;
                const typeColor = activeTab === 'CUSTOMERS' ? 'blue' : 'purple';
                const fullAddress = [p.Address1, p.Address2, p.Address3].filter(Boolean).join(', ');
                return (
                  <div key={p.id} className="bg-white rounded-[24px] p-6 shadow-sm border border-slate-200/60 hover:shadow-lg hover:border-slate-300 transition-all group flex flex-col">
                     <div className="flex items-start justify-between mb-4">
                        <div className="flex items-center gap-4">
                           <div className={`w-14 h-14 rounded-2xl bg-${typeColor}-50 text-${typeColor}-600 font-black text-[18px] flex items-center justify-center group-hover:scale-105 transition-transform`}>{getInitials(name)}</div>
                           <div>
                              <h3 className="font-black text-slate-800 text-[18px] line-clamp-1">{name}</h3>
                              <div className="flex gap-2 items-center mt-1">
                                <span className="bg-slate-100 text-slate-600 px-2.5 py-0.5 rounded-md text-[11px] font-bold tracking-wider">ID: {idStr}</span>
                                {p.Status === 'Active' && <span className="w-2 h-2 rounded-full bg-emerald-500"></span>}
                              </div>
                           </div>
                        </div>
                     </div>
                     <div className="space-y-3 mt-2 flex-grow">
                        <div className="flex items-start gap-3"><svg className="w-5 h-5 text-slate-400 mt-0.5 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 11a3 3 0 11-6 0 3 3 0 016 0z"></path></svg><p className="text-[13px] font-semibold text-slate-600 leading-snug">{fullAddress || 'No address provided'}</p></div>
                        <div className="flex items-center gap-3"><svg className="w-5 h-5 text-slate-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z"></path></svg><p className="text-[13px] font-bold text-slate-700">{[p.Contactnumber, p.Contactnumber2].filter(Boolean).join(' / ') || '-'}</p></div>
                        {(p.Email || p.Whatsapp) && (<div className="flex items-center gap-3"><svg className="w-5 h-5 text-slate-400 shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"></path></svg><p className="text-[13px] font-bold text-slate-700">{p.Email || p.Whatsapp}</p></div>)}
                     </div>
                     <div className="mt-6 pt-4 border-t border-slate-100 flex justify-between items-center"><span className="text-[11px] font-black uppercase text-slate-400 tracking-wider">Opening Bal</span><span className="text-[15px] font-black text-slate-800">₹{p.Openingbalance || '0.00'}</span></div>
                  </div>
                );
             })}
             {currentData.length === 0 && <div className="col-span-full py-12 text-center text-slate-400 font-bold text-[14px]">No records found.</div>}
           </div>
        </div>
      )}

      {/* EMPLOYEES - CARD GRID VIEW */}
      {!loading && activeTab === 'EMPLOYEES' && (
        <div className="animate-in fade-in duration-500">
           <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
             {currentData.map(e => (
                <div key={e.id} className="bg-white rounded-[24px] p-6 shadow-sm border border-slate-200/60 hover:shadow-md transition-all flex flex-col items-center text-center">
                   <div className="w-20 h-20 rounded-full bg-rose-50 border-[4px] border-white shadow-sm text-rose-600 font-black text-[24px] flex items-center justify-center mb-4 relative">{getInitials(e.EmployeeName)}<span className={`absolute bottom-0 right-1 w-4 h-4 rounded-full border-2 border-white ${e.Status === 'Active' ? 'bg-emerald-500' : 'bg-slate-300'}`}></span></div>
                   <h3 className="font-black text-slate-800 text-[18px] mb-1">{e.EmployeeName}</h3><span className="bg-slate-100 text-slate-600 px-3 py-1 rounded-full text-[11px] font-bold tracking-wider mb-4">EMP ID: {e.EmployeeID}</span>
                   <div className="w-full pt-4 border-t border-slate-100 flex justify-between items-center text-[13px]"><span className="font-semibold text-slate-400">City</span><span className="font-bold text-slate-700">{e.City || 'N/A'}</span></div>
                </div>
             ))}
             {currentData.length === 0 && <div className="col-span-full py-12 text-center text-slate-400 font-bold text-[14px]">No employees found.</div>}
           </div>
        </div>
      )}

      {/* PAYMENTS - PREMIUM LIST VIEW */}
      {!loading && activeTab === 'PAYMENTS' && (
        <div className="animate-in fade-in duration-500 bg-white rounded-[24px] shadow-sm border border-slate-200 overflow-hidden">
            <table className="w-full text-left min-w-[800px]">
              <thead className="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Transaction</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Supplier</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Method</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest text-right">Amount</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {currentData.map(p => (
                  <tr key={p.id} className="hover:bg-cyan-50/30 transition-colors">
                    <td className="py-4 px-6"><div className="flex flex-col"><span className="text-[14px] font-black text-slate-800">{p.Paymentdate}</span><span className="text-[12px] font-semibold text-slate-400">Ref: {p.Invoiceno || 'N/A'}</span></div></td>
                    <td className="py-4 px-6"><div className="flex items-center gap-3"><div className="w-8 h-8 rounded-full bg-slate-100 flex items-center justify-center text-[11px] font-bold text-slate-600">{getInitials(p.SupplierNameStr)}</div><span className="text-[14px] font-bold text-slate-700">{p.SupplierNameStr}</span></div></td>
                    <td className="py-4 px-6"><span className="bg-cyan-50 text-cyan-700 px-3 py-1 rounded-full text-[12px] font-bold border border-cyan-100">{p.Paymenttype || 'Cash'}</span></td>
                    <td className="py-4 px-6 text-right"><span className="text-[16px] font-black text-cyan-600">₹{p.Paymentamount}</span></td>
                  </tr>
                ))}
                {currentData.length === 0 && <tr><td colSpan="4" className="py-12 text-center text-slate-400 font-bold text-[14px]">No records found.</td></tr>}
              </tbody>
            </table>
        </div>
      )}

      {/* ESTIMATES - EXPANDABLE PREMIUM LIST */}
      {!loading && activeTab === 'ESTIMATES' && (
        <div className="animate-in fade-in duration-500 bg-white rounded-[24px] shadow-sm border border-slate-200 overflow-hidden">
            <table className="w-full text-left min-w-[800px]">
               <thead className="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Date & ID</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Customer</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Type</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest text-right">Net Amount</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {currentData.map(e => (
                  <React.Fragment key={e.id}>
                    <tr onClick={() => handleEstimateClick(e.SalesID)} className={`cursor-pointer transition-colors ${expandedEstimate === e.SalesID ? 'bg-indigo-50 border-l-4 border-l-indigo-500' : 'hover:bg-slate-50 border-l-4 border-l-transparent'}`}>
                      <td className="py-4 px-6"><div className="flex flex-col"><span className="text-[14px] font-black text-slate-800">{e.Salesdate}</span><span className="text-[12px] font-semibold text-slate-400">Est #{e.SalesID}</span></div></td>
                      <td className="py-4 px-6 text-[14px] font-bold text-slate-700">{e.CustomerName}</td>
                      <td className="py-4 px-6"><span className="bg-slate-100 text-slate-600 px-3 py-1 rounded-full text-[12px] font-bold tracking-wide">{e.Salestype}</span></td>
                      <td className="py-4 px-6 text-right"><span className="text-[16px] font-black text-indigo-600">₹{e.Netamount}</span></td>
                    </tr>
                    {expandedEstimate === e.SalesID && (
                      <tr>
                        <td colSpan="4" className="p-0 border-b border-slate-200 bg-[#F8FAFC]">
                          <div className="p-6 md:p-8 grid grid-cols-1 lg:grid-cols-3 gap-8 relative overflow-hidden">
                            <div className="absolute top-0 right-0 w-64 h-64 bg-indigo-50 rounded-full blur-3xl -z-10 opacity-50 transform translate-x-1/2 -translate-y-1/2"></div>
                            <div className="lg:col-span-2">
                              <h4 className="text-[13px] font-black text-slate-800 uppercase tracking-widest mb-4">Line Items</h4>
                              {itemsLoading && !estimateDetails[e.SalesID] ? (
                                <div className="text-[13px] font-bold text-slate-400 p-4 animate-pulse">Loading items...</div>
                              ) : (
                                <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
                                  <table className="w-full">
                                    <thead className="bg-slate-50 border-b border-slate-100"><tr><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider">Product</th><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Rate</th><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Qty</th><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Total</th></tr></thead>
                                    <tbody className="divide-y divide-slate-50">{((estimateDetails[e.SalesID] && estimateDetails[e.SalesID].particulars) || []).map((item, idx) => (<tr key={idx} className="hover:bg-slate-50"><td className="py-3 px-4 text-[13px] font-bold text-slate-800">{item.Productname}</td><td className="py-3 px-4 text-[13px] font-bold text-slate-600 text-right">₹{item.Salesrate}</td><td className="py-3 px-4 text-[13px] font-black text-slate-700 text-right">{item.Quantity}</td><td className="py-3 px-4 text-[13px] font-black text-indigo-600 text-right">₹{item.Totalamount}</td></tr>))}</tbody>
                                  </table>
                                </div>
                              )}
                            </div>
                            <div>
                               <h4 className="text-[13px] font-black text-slate-800 uppercase tracking-widest mb-4">Charges & Summary</h4>
                               {itemsLoading && !estimateDetails[e.SalesID] ? (<div className="text-[13px] font-bold text-slate-400 p-4 animate-pulse">Loading...</div>) : (
                                <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-5 space-y-4">
                                  {((estimateDetails[e.SalesID] && estimateDetails[e.SalesID].charges) || []).map((c, i) => (<div key={i} className="flex justify-between items-center"><span className="text-[13px] font-bold text-slate-500">{c.ChargeName}</span><span className="text-[14px] font-black text-slate-700">₹{c.ChargeAmount2}</span></div>))}
                                  <div className="pt-4 border-t border-slate-200 border-dashed flex justify-between items-center"><span className="text-[14px] font-black text-slate-800 uppercase">Total Estimate</span><span className="text-[20px] font-black text-indigo-600">₹{e.Netamount}</span></div>
                                </div>
                              )}
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))}
                {currentData.length === 0 && <tr><td colSpan="4" className="py-12 text-center text-slate-400 font-bold text-[14px]">No records found.</td></tr>}
              </tbody>
            </table>
        </div>
      )}

      {/* PURCHASES - EXPANDABLE PREMIUM LIST */}
      {!loading && activeTab === 'PURCHASES' && (
        <div className="animate-in fade-in duration-500 bg-white rounded-[24px] shadow-sm border border-slate-200 overflow-hidden">
            <table className="w-full text-left min-w-[800px]">
               <thead className="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Date & Inv</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Supplier</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Type</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest text-right">Net Amount</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {currentData.map(p => (
                  <React.Fragment key={p.id}>
                    <tr onClick={() => handlePurchaseClick(p.PurchaseID)} className={`cursor-pointer transition-colors ${expandedPurchase === p.PurchaseID ? 'bg-emerald-50 border-l-4 border-l-emerald-500' : 'hover:bg-slate-50 border-l-4 border-l-transparent'}`}>
                      <td className="py-4 px-6"><div className="flex flex-col"><span className="text-[14px] font-black text-slate-800">{p.Purchasedate}</span><span className="text-[12px] font-semibold text-slate-400">Inv: {p.Invoiceno || 'N/A'}</span></div></td>
                      <td className="py-4 px-6 text-[14px] font-bold text-slate-700">{p.Suppliername}</td>
                      <td className="py-4 px-6"><span className="bg-slate-100 text-slate-600 px-3 py-1 rounded-full text-[12px] font-bold tracking-wide">{p.Purchasetype}</span></td>
                      <td className="py-4 px-6 text-right"><span className="text-[16px] font-black text-emerald-600">₹{p.Netamount}</span></td>
                    </tr>
                    {expandedPurchase === p.PurchaseID && (
                      <tr>
                        <td colSpan="4" className="p-0 border-b border-slate-200 bg-[#F8FAFC]">
                          <div className="p-6 md:p-8 grid grid-cols-1 xl:grid-cols-4 gap-8 relative overflow-hidden">
                            <div className="absolute top-0 left-0 w-64 h-64 bg-emerald-50 rounded-full blur-3xl -z-10 opacity-50 transform -translate-x-1/2 -translate-y-1/2"></div>
                            <div className="xl:col-span-3">
                              <h4 className="text-[13px] font-black text-slate-800 uppercase tracking-widest mb-4">Purchased Items</h4>
                              {itemsLoading && !purchaseItems[p.PurchaseID] ? (<div className="text-[13px] font-bold text-slate-400 p-4 animate-pulse">Loading...</div>) : (
                                <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
                                  <table className="w-full">
                                    <thead className="bg-slate-50 border-b border-slate-100"><tr><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider">Product</th><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Qty</th><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Rate</th><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Total</th></tr></thead>
                                    <tbody className="divide-y divide-slate-50">{(purchaseItems[p.PurchaseID] || []).map((item, idx) => (<tr key={idx} className="hover:bg-slate-50"><td className="py-3 px-4 text-[13px] font-bold text-slate-800">{item.Productname}{item.HSNCode && <div className="text-[10px] text-slate-400 mt-0.5">HSN: {item.HSNCode}</div>}</td><td className="py-3 px-4 text-[13px] font-black text-slate-700 text-right">{item.Qty} <span className="text-[10px] text-slate-400 font-semibold">{item.UOM}</span></td><td className="py-3 px-4 text-[13px] font-bold text-slate-600 text-right">₹{item.Purchaserate}</td><td className="py-3 px-4 text-[13px] font-black text-emerald-600 text-right">₹{item.TotalAmount}</td></tr>))}</tbody>
                                  </table>
                                </div>
                              )}
                            </div>
                            <div className="xl:col-span-1">
                               <h4 className="text-[13px] font-black text-slate-800 uppercase tracking-widest mb-4">Charges & Summary</h4>
                               {itemsLoading && !purchaseCharges[p.PurchaseID] ? (<div className="text-[13px] font-bold text-slate-400 p-4 animate-pulse">Loading...</div>) : (
                                 <div className="bg-white rounded-2xl shadow-sm border border-slate-200 p-5 space-y-4">
                                   {(purchaseCharges[p.PurchaseID] || []).map((c, i) => (<div key={i} className="flex justify-between items-center"><span className="text-[13px] font-bold text-slate-500">{c.ChargeName}</span><span className="text-[14px] font-black text-slate-700">₹{c.ChargeAmount2}</span></div>))}
                                   <div className="pt-4 border-t border-slate-200 border-dashed flex justify-between items-center"><span className="text-[14px] font-black text-slate-800 uppercase">Net Bill</span><span className="text-[20px] font-black text-emerald-600">₹{p.Netamount}</span></div>
                                 </div>
                               )}
                            </div>
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))}
                {currentData.length === 0 && <tr><td colSpan="4" className="py-12 text-center text-slate-400 font-bold text-[14px]">No records found.</td></tr>}
              </tbody>
            </table>
        </div>
      )}

      {/* WORK ENTRIES - PREMIUM LIST */}
      {!loading && activeTab === 'WORKENTRIES' && (
        <div className="animate-in fade-in duration-500 bg-white rounded-[24px] shadow-sm border border-slate-200 overflow-hidden">
            <table className="w-full text-left min-w-[800px]">
               <thead className="bg-slate-50 border-b border-slate-200">
                <tr>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Date</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest">Employee</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest text-right">Adv Given</th>
                  <th className="py-5 px-6 text-[12px] font-black text-slate-400 uppercase tracking-widest text-right">Net Wage</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {currentData.map(w => (
                  <React.Fragment key={w.id}>
                    <tr onClick={() => handleWorkClick(w.ID)} className={`cursor-pointer transition-colors ${expandedWork === w.ID ? 'bg-amber-50 border-l-4 border-l-amber-500' : 'hover:bg-slate-50 border-l-4 border-l-transparent'}`}>
                      <td className="py-4 px-6 text-[14px] font-black text-slate-800">{w.Workerdate}</td>
                      <td className="py-4 px-6 text-[14px] font-bold text-slate-700">{w.EmployeeName}</td>
                      <td className="py-4 px-6 text-right">
                         {parseFloat(w.AdvanceReceive) > 0 ? (
                            <span className="bg-rose-50 text-rose-600 px-2.5 py-1 rounded-md text-[12px] font-black tracking-wide border border-rose-100">₹{w.AdvanceReceive}</span>
                         ) : (<span className="text-[13px] font-bold text-slate-300">-</span>)}
                      </td>
                      <td className="py-4 px-6 text-right"><span className="text-[16px] font-black text-amber-600">₹{w.Netamount}</span></td>
                    </tr>
                    {expandedWork === w.ID && (
                      <tr>
                        <td colSpan="4" className="p-0 border-b border-slate-200 bg-[#F8FAFC]">
                          <div className="p-6 md:p-8 max-w-3xl mx-auto">
                            <h4 className="text-[13px] font-black text-slate-800 uppercase tracking-widest mb-4 text-center">Detailed Production Log</h4>
                            {itemsLoading && !workItems[w.ID] ? (<div className="text-[13px] font-bold text-slate-400 p-4 text-center animate-pulse">Loading piece rates...</div>) : (
                              <div className="bg-white rounded-2xl shadow-[0_8px_30px_rgb(0,0,0,0.04)] border border-slate-200 overflow-hidden">
                                <table className="w-full">
                                  <thead className="bg-slate-50 border-b border-slate-100"><tr><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider">Produced Item</th><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Qty</th><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Rate</th><th className="py-3 px-4 text-[11px] font-black text-slate-500 uppercase tracking-wider text-right">Wages</th></tr></thead>
                                  <tbody className="divide-y divide-slate-50">{(workItems[w.ID] || []).map((item, idx) => (<tr key={idx} className="hover:bg-slate-50"><td className="py-3 px-4 text-[13px] font-bold text-slate-800">{item.ProductName}</td><td className="py-3 px-4 text-[13px] font-black text-slate-700 text-right">{item.Qty}</td><td className="py-3 px-4 text-[13px] font-bold text-slate-600 text-right">₹{item.Rate}</td><td className="py-3 px-4 text-[13px] font-black text-amber-600 text-right">₹{item.Netamount}</td></tr>))}</tbody>
                                  <tfoot className="bg-amber-50/30 border-t border-slate-100"><tr><td colSpan="3" className="py-4 px-4 text-[13px] font-black text-slate-500 uppercase tracking-wider text-right">Total Daily Wage</td><td className="py-4 px-4 text-[16px] font-black text-amber-700 text-right">₹{w.Netamount}</td></tr></tfoot>
                                </table>
                              </div>
                            )}
                          </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))}
                {currentData.length === 0 && <tr><td colSpan="4" className="py-12 text-center text-slate-400 font-bold text-[14px]">No records found.</td></tr>}
              </tbody>
            </table>
        </div>
      )}
      
      {/* PAGINATION FOOTER */}
      {activeTab !== 'MENU' && !loading && totalPages > 1 && (
        <div className="flex justify-center mt-8">
           <div className="flex items-center gap-2 bg-white px-4 py-2 rounded-2xl shadow-sm border border-slate-200">
              <button onClick={() => setCurrentPage(1)} disabled={currentPage === 1} className="w-8 h-8 rounded-lg hover:bg-slate-100 disabled:opacity-30 flex items-center justify-center text-slate-600 font-black">«</button>
              <button onClick={() => setCurrentPage(prev => Math.max(1, prev - 1))} disabled={currentPage === 1} className="w-8 h-8 rounded-lg hover:bg-slate-100 disabled:opacity-30 flex items-center justify-center text-slate-600 font-black">‹</button>
              <span className="px-4 text-[13px] font-black text-slate-700">Page {currentPage} of {totalPages}</span>
              <button onClick={() => setCurrentPage(prev => Math.min(totalPages, prev + 1))} disabled={currentPage === totalPages} className="w-8 h-8 rounded-lg hover:bg-slate-100 disabled:opacity-30 flex items-center justify-center text-slate-600 font-black">›</button>
              <button onClick={() => setCurrentPage(totalPages)} disabled={currentPage === totalPages} className="w-8 h-8 rounded-lg hover:bg-slate-100 disabled:opacity-30 flex items-center justify-center text-slate-600 font-black">»</button>
           </div>
        </div>
      )}

    </div>
  );
}
