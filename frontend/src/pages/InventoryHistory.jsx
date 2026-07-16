import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';

export default function InventoryHistory() {
  const [activeTab, setActiveTab] = useState('purchases');
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');

  const loadData = async (tab) => {
    setLoading(true);
    try {
      if (tab === 'purchases') {
        const res = await erpApi.getPurchaseHistory();
        setData(res);
      } else if (tab === 'transfers') {
        const res = await erpApi.getTransferHistory();
        setData(res);
      }
    } catch (e) {
      console.error(e);
      setData([]);
    }
    setLoading(false);
  };

  useEffect(() => {
    loadData(activeTab);
    setSearchTerm('');
  }, [activeTab]);

  const filteredData = data.filter(item => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    if (activeTab === 'purchases') {
      return (item.number?.toLowerCase().includes(term) || item.supplier?.toLowerCase().includes(term));
    }
    if (activeTab === 'transfers') {
      return (item.number?.toLowerCase().includes(term) || item.driverName?.toLowerCase().includes(term));
    }
    return true;
  });

  return (
    <div className="space-y-[14px]">
      {/* HEADER SECTION */}
      <div className="bg-white/90 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-orange-600 uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
          <span className="w-[9px] h-[9px] rounded-full bg-orange-600 shadow-[0_0_0_5px_rgba(234,88,12,0.14)]"></span>
          Inventory History
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-[14px]">
          <div>
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">View Mode</label>
            <div className="flex bg-slate-100 p-1 rounded-[14px]">
              <button 
                onClick={() => setActiveTab('purchases')}
                className={`flex-1 py-2 text-sm font-bold rounded-[10px] transition-all ${activeTab === 'purchases' ? 'bg-white shadow-sm text-orange-600' : 'text-slate-500 hover:text-slate-800'}`}
              >
                Purchases
              </button>
              <button 
                onClick={() => setActiveTab('transfers')}
                className={`flex-1 py-2 text-sm font-bold rounded-[10px] transition-all ${activeTab === 'transfers' ? 'bg-white shadow-sm text-orange-600' : 'text-slate-500 hover:text-slate-800'}`}
              >
                Stock Transfers
              </button>
            </div>
          </div>
          <div>
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Search</label>
            <input 
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder={`Search by ${activeTab === 'purchases' ? 'Purchase No / Supplier' : 'Transfer No / Driver'}...`}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-orange-500 focus:ring-[4px] focus:ring-orange-500/15 shadow-sm"
            />
          </div>
        </div>
      </div>

      {/* DATA TABLE SECTION */}
      <div className="bg-white/90 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        {loading ? (
          <div className="py-12 text-center text-slate-400 font-bold">Loading records...</div>
        ) : (
          <table className="w-full text-left border-spacing-y-2 border-separate min-w-[800px]">
            <thead>
              {activeTab === 'purchases' && (
                <tr>
                  <th className="text-[11px] font-bold text-slate-500 uppercase px-2">Date</th>
                  <th className="text-[11px] font-bold text-slate-500 uppercase px-2">Purchase No</th>
                  <th className="text-[11px] font-bold text-slate-500 uppercase px-2">Supplier</th>
                  <th className="text-[11px] font-bold text-slate-500 uppercase px-2 text-right">Total Qty</th>
                  <th className="text-[11px] font-bold text-slate-500 uppercase px-2 text-right">Value</th>
                </tr>
              )}
              {activeTab === 'transfers' && (
                <tr>
                  <th className="text-[11px] font-bold text-slate-500 uppercase px-2">Date</th>
                  <th className="text-[11px] font-bold text-slate-500 uppercase px-2">Transfer No</th>
                  <th className="text-[11px] font-bold text-slate-500 uppercase px-2">Vehicle / Driver</th>
                  <th className="text-[11px] font-bold text-slate-500 uppercase px-2 text-right">Items</th>
                  <th className="text-[11px] font-bold text-slate-500 uppercase px-2 text-right">Total Qty</th>
                </tr>
              )}
            </thead>
            <tbody>
              {filteredData.map((item) => {
                if (activeTab === 'purchases') {
                  return (
                    <tr key={item.id}>
                      <td className="px-2 text-[13px] font-bold text-slate-500 bg-slate-50 py-3 rounded-l-[14px] border-y border-l border-slate-200">
                        {new Date(item.date).toLocaleDateString()}
                      </td>
                      <td className="px-2 font-black text-slate-800 bg-slate-50 py-3 border-y border-slate-200">{item.number}</td>
                      <td className="px-2 font-bold text-slate-700 bg-slate-50 py-3 border-y border-slate-200">{item.supplier}</td>
                      <td className="px-2 font-bold text-slate-500 bg-slate-50 py-3 border-y border-slate-200 text-right">{item.qty}</td>
                      <td className="px-2 font-black text-orange-600 bg-slate-50 py-3 rounded-r-[14px] border-y border-r border-slate-200 text-right">
                        ₹{parseFloat(item.value).toFixed(2)}
                      </td>
                    </tr>
                  );
                }

                if (activeTab === 'transfers') {
                  return (
                    <tr key={item.id}>
                      <td className="px-2 text-[13px] font-bold text-slate-500 bg-slate-50 py-3 rounded-l-[14px] border-y border-l border-slate-200">
                        {new Date(item.date).toLocaleDateString()}
                      </td>
                      <td className="px-2 font-black text-slate-800 bg-slate-50 py-3 border-y border-slate-200">{item.number}</td>
                      <td className="px-2 font-bold text-slate-700 bg-slate-50 py-3 border-y border-slate-200">
                        {item.vehicle?.no} <span className="text-slate-400 font-normal">({item.driverName})</span>
                      </td>
                      <td className="px-2 font-bold text-slate-500 bg-slate-50 py-3 border-y border-slate-200 text-right">{item.items?.length || 0}</td>
                      <td className="px-2 font-black text-orange-600 bg-slate-50 py-3 rounded-r-[14px] border-y border-r border-slate-200 text-right">
                        {item.qty}
                      </td>
                    </tr>
                  );
                }

                return null;
              })}
              {filteredData.length === 0 && (
                <tr>
                  <td colSpan="5" className="px-2 py-8 text-center text-slate-400 font-bold bg-slate-50 rounded-[14px] border border-slate-200">
                    No {activeTab} found.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
