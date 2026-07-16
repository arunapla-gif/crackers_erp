import React, { useState, useEffect } from 'react';

export default function EwayBillReport() {
  const [reportData, setReportData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [days, setDays] = useState(7);

  const fetchReport = async () => {
    setLoading(true);
    setError(null);
    try {
      const token = localStorage.getItem('token');
      const response = await fetch(`/api/ewaybill/reports/recent?days=${days}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.error || "Failed to fetch from government portal");
      }
      
      setReportData(data);
    } catch (err) {
      setError(err.message);
    }
    setLoading(false);
  };

  useEffect(() => {
    fetchReport();
  }, [days]);

  return (
    <div className="max-w-7xl mx-auto py-8 px-4 sm:px-6 lg:px-8 font-sans">
      <div className="flex flex-col md:flex-row md:items-end justify-between mb-8 gap-4">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <span className="px-3 py-1 bg-emerald-100 text-emerald-800 text-[11px] font-black tracking-widest uppercase rounded-md border border-emerald-200 shadow-sm">GOV.IN PORTAL</span>
          </div>
          <h1 className="text-[32px] font-black text-slate-800 tracking-tight leading-none mb-2">E-Way Bill Auto-Fetcher</h1>
          <p className="text-[14px] font-medium text-slate-500">Automatically sync past E-way bills directly from the government servers.</p>
        </div>
        <div className="flex items-center gap-3 bg-white p-2 rounded-xl shadow-sm border border-slate-200">
          <span className="text-[13px] font-bold text-slate-600 pl-2">Timeframe:</span>
          <select value={days} onChange={(e) => setDays(Number(e.target.value))} className="px-4 py-2 bg-slate-50 border border-slate-200 rounded-lg text-[13px] font-black text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500 cursor-pointer">
            <option value={3}>Last 3 Days</option>
            <option value={5}>Last 5 Days</option>
            <option value={7}>Last 7 Days</option>
            <option value={15}>Last 15 Days</option>
          </select>
          <button onClick={fetchReport} disabled={loading} className="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 disabled:bg-indigo-300 text-white text-[13px] font-bold rounded-lg transition-all shadow-sm flex items-center gap-2">
            {loading ? (
              <><div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></div> Syncing...</>
            ) : (
              <><svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg> Refresh</>
            )}
          </button>
        </div>
      </div>

      {error && (
        <div className="mb-8 p-6 bg-rose-50 border border-rose-200 rounded-[20px] text-rose-700 flex items-start gap-4 shadow-sm animate-in fade-in">
          <div className="w-10 h-10 bg-white rounded-full flex items-center justify-center shrink-0 shadow-sm"><svg className="w-5 h-5 text-rose-500" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z"></path></svg></div>
          <div>
            <h3 className="text-[15px] font-black mb-1">API Connection Error</h3>
            <p className="text-[13px] font-medium opacity-90">{error}</p>
            <p className="text-[12px] font-bold mt-3 opacity-70 bg-rose-100/50 inline-block px-3 py-1 rounded-md">The Whitebooks / NIC servers may be experiencing downtime or rate limits. Try again in a few minutes.</p>
          </div>
        </div>
      )}

      {loading && !reportData && (
        <div className="py-24 flex flex-col items-center justify-center bg-white rounded-[24px] border border-slate-200 shadow-sm">
          <div className="w-16 h-16 border-4 border-slate-100 border-t-indigo-600 rounded-full animate-spin mb-6"></div>
          <p className="text-[15px] font-black text-slate-700 mb-1">Contacting Government Servers</p>
          <p className="text-[13px] font-medium text-slate-400">Authenticating via Whitebooks and retrieving multi-day ledgers...</p>
        </div>
      )}

      {reportData && !loading && (
        <div className="space-y-6 animate-in slide-in-from-bottom-4 duration-500">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="bg-white p-6 rounded-[20px] shadow-sm border border-slate-200 flex items-center justify-between">
              <div><p className="text-[12px] font-bold text-slate-400 uppercase tracking-wider mb-1">Total Days Scanned</p><p className="text-[28px] font-black text-slate-800 leading-none">{days}</p></div>
              <div className="w-12 h-12 bg-slate-50 text-slate-400 rounded-full flex items-center justify-center"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z"></path></svg></div>
            </div>
            <div className="bg-white p-6 rounded-[20px] shadow-sm border border-emerald-200 flex items-center justify-between">
              <div><p className="text-[12px] font-bold text-emerald-600 uppercase tracking-wider mb-1">Successful Pulls</p><p className="text-[28px] font-black text-emerald-700 leading-none">{reportData.totalDaysSuccess}</p></div>
              <div className="w-12 h-12 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg></div>
            </div>
            <div className="bg-white p-6 rounded-[20px] shadow-sm border border-rose-200 flex items-center justify-between">
              <div><p className="text-[12px] font-bold text-rose-600 uppercase tracking-wider mb-1">Failed Pulls</p><p className="text-[28px] font-black text-rose-700 leading-none">{reportData.totalDaysFailed}</p></div>
              <div className="w-12 h-12 bg-rose-50 text-rose-600 rounded-full flex items-center justify-center"><svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg></div>
            </div>
          </div>

          <div className="bg-white rounded-[24px] shadow-sm border border-slate-200 overflow-hidden">
             <div className="p-6 border-b border-slate-100">
               <h3 className="text-[16px] font-black text-slate-800">Raw Data Feeds by Date</h3>
               <p className="text-[13px] text-slate-500 mt-1">If standard NIC encryption is required by the API, data objects may appear encrypted or throw errors below.</p>
             </div>
             
             <div className="divide-y divide-slate-100">
                {reportData.data.map((dayObj, idx) => (
                  <div key={idx} className="p-6 hover:bg-slate-50 transition-colors">
                     <div className="flex items-center justify-between mb-4">
                        <span className="bg-indigo-50 text-indigo-700 px-3 py-1 rounded-md text-[13px] font-black border border-indigo-100">Date: {dayObj.date}</span>
                        <span className="text-[12px] font-bold text-emerald-600 flex items-center gap-1"><svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M5 13l4 4L19 7"></path></svg> Successful Connection</span>
                     </div>
                     <pre className="bg-slate-900 text-emerald-400 p-4 rounded-xl text-[11px] font-mono overflow-x-auto">
                       {JSON.stringify(dayObj.data, null, 2)}
                     </pre>
                  </div>
                ))}
                
                {reportData.errors.map((errObj, idx) => (
                  <div key={`err-${idx}`} className="p-6 bg-rose-50/30">
                     <div className="flex items-center justify-between mb-4">
                        <span className="bg-slate-100 text-slate-600 px-3 py-1 rounded-md text-[13px] font-black border border-slate-200">Date: {errObj.date}</span>
                        <span className="text-[12px] font-bold text-rose-600 flex items-center gap-1"><svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg> Fetch Failed</span>
                     </div>
                     <pre className="bg-rose-900 text-rose-200 p-4 rounded-xl text-[11px] font-mono overflow-x-auto border border-rose-800">
                       {typeof errObj.error === 'object' ? JSON.stringify(errObj.error, null, 2) : errObj.error}
                     </pre>
                  </div>
                ))}

                {reportData.data.length === 0 && reportData.errors.length === 0 && (
                   <div className="p-12 text-center text-slate-400 font-bold">No data processed.</div>
                )}
             </div>
          </div>
        </div>
      )}
    </div>
  );
}
