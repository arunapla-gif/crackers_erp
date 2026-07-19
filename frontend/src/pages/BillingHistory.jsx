import React, { useState, useEffect } from 'react';
import { FiSearch, FiRefreshCw } from 'react-icons/fi';
import { useNavigate } from 'react-router-dom';
import { erpApi } from '../api/erpApi';
import InvoicePrint from './InvoicePrint';

export default function BillingHistory() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [printConfirmId, setPrintConfirmId] = useState(null);
  const [printIframeUrl, setPrintIframeUrl] = useState(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await erpApi.getInvoiceHistory();
      setData(res);
    } catch (e) {
      console.error(e);
      setData([]);
    }
    setLoading(false);
  };

  useEffect(() => {
    loadData();
  }, []);

  const filteredData = data.filter(item => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    return (item.number?.toLowerCase().includes(term) || item.customer?.toLowerCase().includes(term));
  });

  return (
    <div className="space-y-[14px]">
      <div className="print:hidden space-y-[14px]">
      {/* HEADER SECTION */}
      <div className="bg-white/90 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-purple-600 uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
          <span className="w-[9px] h-[9px] rounded-full bg-purple-600 shadow-[0_0_0_5px_rgba(147,51,234,0.14)]"></span>
          Billing History
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-[14px]">
          <div>
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Search</label>
            <input 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search by Invoice No / Customer..."
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-purple-500 focus:ring-[4px] focus:ring-purple-500/15 shadow-sm"
            />
          </div>
        </div>
      </div>

      {/* DATA TABLE SECTION */}
      <div className="bg-white/90 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        {loading ? (
          <div className="py-12 text-center text-slate-400 font-bold">Loading records...</div>
        ) : (
          <div className="w-full min-w-[800px] flex flex-col h-[600px]">
            {/* Table Header */}
            <div className="flex px-2 mb-2 shrink-0">
              <div className="w-[120px] text-[11px] font-bold text-slate-500 uppercase px-2">Date</div>
              <div className="w-[100px] text-[11px] font-bold text-slate-500 uppercase px-2">Type</div>
              <div className="w-[140px] text-[11px] font-bold text-slate-500 uppercase px-2">Number</div>
              <div className="flex-1 text-[11px] font-bold text-slate-500 uppercase px-2">Customer</div>
              <div className="w-[80px] text-[11px] font-bold text-slate-500 uppercase px-2 text-right">Items</div>
              <div className="w-[150px] text-[11px] font-bold text-slate-500 uppercase px-2 text-right">Amount</div>
            </div>
            
            {/* Standard Body */}
            <div className="flex-1 overflow-y-auto pr-2 pb-2">
              {filteredData.map((item) => {
                const isEst = item.number.startsWith('EST');
                const isPro = item.number.startsWith('PRO');
                const typeLabel = isEst ? 'ESTIMATE' : isPro ? 'PERFORMA' : (item.series || 'INVOICE');
                const typeColor = isEst ? 'text-red-600 bg-red-50' : isPro ? 'text-purple-600 bg-purple-50' : 'text-blue-600 bg-blue-50';

                return (
                  <div className="pb-2" key={item.id}>
                    <div className="flex items-center h-[52px] w-full rounded-[14px] border border-slate-200 bg-slate-50 group hover:border-purple-200 hover:shadow-sm transition-all">
                      <div className="w-[120px] px-4 text-[13px] font-bold text-slate-500 truncate">
                        {new Date(item.date).toLocaleDateString()}
                      </div>
                      <div className="w-[100px] px-2">
                        <span className={`px-2 py-1 rounded-[6px] text-[10px] font-black ${typeColor}`}>{typeLabel}</span>
                      </div>
                      <div className="w-[140px] px-2 font-black text-slate-800 truncate">{item.number}</div>
                      <div className="flex-1 px-2 font-bold text-slate-700 truncate">{item.customer}</div>
                      <div className="w-[80px] px-2 font-bold text-slate-500 text-right">{item.items?.length || 0}</div>
                      <div className="w-[150px] px-4 font-black text-purple-600 text-right">
                        <div className="flex justify-end items-center gap-4">
                          <span>₹{parseFloat(item.grand_total).toFixed(2)}</span>
                          <button onClick={() => setPrintConfirmId(item.number)} className="px-3 py-1 bg-purple-100 text-purple-700 rounded-[8px] text-[11px] font-bold hover:bg-purple-200 transition-colors border border-purple-200">
                            Print
                          </button>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
            
            {filteredData.length === 0 && (
              <div className="px-2 py-8 text-center text-slate-400 font-bold bg-slate-50 rounded-[14px] border border-slate-200 mt-2">
                No billing documents found.
              </div>
            )}
          </div>
        )}
      </div>
      </div>
      {/* Print Confirmation Modal */}
      {printConfirmId && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-[24px] shadow-2xl p-6 w-full max-w-sm border border-slate-200">
            <h3 className="text-[18px] font-black text-slate-800 mb-2">Print Invoice</h3>
            <p className="text-[13px] font-bold text-slate-500 mb-6">Are you sure you want to generate and print invoice <span className="text-purple-600 font-black">{printConfirmId}</span>?</p>
            <div className="flex gap-3 justify-end">
              <button onClick={() => setPrintConfirmId(null)} className="px-4 py-2 text-slate-500 hover:bg-slate-100 rounded-xl text-[13px] font-bold transition-colors">
                Cancel
              </button>
              <button 
                onClick={() => {
                  setPrintIframeUrl(printConfirmId); // Here printIframeUrl actually stores the invoice number now
                  setPrintConfirmId(null);
                }} 
                className="px-6 py-2 bg-purple-600 text-white rounded-xl text-[13px] font-black hover:bg-purple-700 shadow-md transition-all"
              >
                Confirm Print
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Native DOM Injection for Printing */}
      {printIframeUrl && (
        <div className="hidden print:block absolute top-0 left-0 w-full bg-white z-[9999]">
           <InvoicePrint propNumber={printIframeUrl} isInline={true} onPrintComplete={() => setPrintIframeUrl(null)} />
        </div>
      )}
    </div>
  );
}
