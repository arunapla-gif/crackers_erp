import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';
import { useStore } from '../store/useStore';

export default function GodownStock() {
  const currentType = useStore(state => state.currentType);
  const [stock, setStock] = useState([]);
  const [godowns, setGodowns] = useState([]);
  const [filterGodown, setFilterGodown] = useState('');
  const [searchProduct, setSearchProduct] = useState('');

  useEffect(() => {
    erpApi.getStock().then(setStock).catch(() => {});
    erpApi.getGodowns().then(setGodowns).catch(() => {});
  }, []);

  const filteredStock = stock.filter(item => {
    if (filterGodown && item.godownId !== parseInt(filterGodown)) return false;
    if (searchProduct && !item.product.toLowerCase().includes(searchProduct.toLowerCase())) return false;
    return true;
  });

  const totalStockValue = filteredStock.reduce((acc, item) => acc + parseFloat(item.value), 0);

  return (
    <div className="space-y-[14px]">
      
      {/* FILTER SECTION */}
      <div className="bg-white/90 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Godown Stock Ledger
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-[14px]">
          <div>
            <label className="block text-[12px] font-[800] text-slate-600 mb-[3px]">Filter Godown</label>
            <select 
              value={filterGodown}
              onChange={(e) => setFilterGodown(e.target.value)}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm"
            >
              <option value="">All Godowns</option>
              {godowns.map(g => <option key={g.id} value={g.id}>{g.name}</option>)}
            </select>
          </div>
          
          <div>
            <label className="block text-[12px] font-[800] text-slate-600 mb-[3px]">Search Product</label>
            <input 
              value={searchProduct}
              onChange={(e) => setSearchProduct(e.target.value)}
              placeholder="Type product name" 
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
            />
          </div>

          <div>
            <label className="block text-[12px] font-[800] text-slate-600 mb-[3px]">Total Stock Value</label>
            <input 
              readOnly 
              value={`₹${totalStockValue.toFixed(2)}`}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-slate-50 border border-slate-200 rounded-[14px] text-[16px] font-black text-active shadow-sm outline-none" 
            />
          </div>
        </div>
      </div>

      {/* TABLE SECTION */}
      <div className="bg-white/90 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        <table className="w-full text-left border-spacing-y-2 border-separate min-w-[700px]">
          <thead>
            <tr>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[20%]">Godown</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[40%]">Product</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%] text-right">Qty</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[15%] text-right">Avg Rate</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[15%] text-right">Value</th>
            </tr>
          </thead>
          <tbody>
            {filteredStock.map((item) => (
              <tr key={item.id}>
                <td className="px-2 font-bold text-slate-700 bg-slate-50 py-3 rounded-l-[14px] border-y border-l border-slate-200">{item.godown.name}</td>
                <td className="px-2 font-bold text-slate-700 bg-slate-50 py-3 border-y border-slate-200">{item.product}</td>
                <td className="px-2 font-black text-active bg-slate-50 py-3 border-y border-slate-200 text-right">{item.qty}</td>
                <td className="px-2 font-bold text-slate-500 bg-slate-50 py-3 border-y border-slate-200 text-right">₹{parseFloat(item.avgRate).toFixed(2)}</td>
                <td className="px-2 font-black text-slate-800 bg-slate-50 py-3 rounded-r-[14px] border-y border-r border-slate-200 text-right">₹{parseFloat(item.value).toFixed(2)}</td>
              </tr>
            ))}
            {filteredStock.length === 0 && (
              <tr>
                <td colSpan="5" className="px-2 py-4 text-center text-slate-400 font-bold">No stock available.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
