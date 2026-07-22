import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';

export default function CustomerRates() {
  const [customers, setCustomers] = useState([]);
  const [products, setProducts] = useState([]);
  const [selectedCustomerId, setSelectedCustomerId] = useState('');
  const [prices, setPrices] = useState({}); // { productId: customRate }
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    fetchInitialData();
  }, []);

  const fetchInitialData = async () => {
    try {
      const [custData, prodData] = await Promise.all([
        erpApi.getCustomers(),
        erpApi.getProducts()
      ]);
      setCustomers(custData);
      setProducts(prodData.filter(p => p.type !== 'WIP')); // Only invoiceable/estimate products
    } catch (err) {
      console.error(err);
      setMessage('Error loading initial data');
    }
  };

  const handleCustomerChange = async (e) => {
    const customerId = e.target.value;
    setSelectedCustomerId(customerId);
    setPrices({});
    setMessage('');
    
    if (customerId) {
      setLoading(true);
      try {
        const customPrices = await erpApi.getCustomerPrices(customerId);
        const pricesMap = {};
        customPrices.forEach(cp => {
          pricesMap[cp.productId] = cp.rate;
        });
        setPrices(pricesMap);
      } catch (err) {
        setMessage('Error fetching customer prices');
      } finally {
        setLoading(false);
      }
    }
  };

  const handlePriceChange = (productId, val) => {
    setPrices(prev => ({ ...prev, [productId]: val }));
  };

  const handleSave = async () => {
    if (!selectedCustomerId) return;
    setSaving(true);
    setMessage('');
    try {
      const pricesToSave = Object.keys(prices).map(pid => ({
        productId: pid,
        rate: prices[pid]
      }));
      await erpApi.saveCustomerPrices(selectedCustomerId, pricesToSave);
      setMessage('Custom rates saved successfully!');
    } catch (err) {
      setMessage('Error saving custom rates');
    } finally {
      setSaving(false);
    }
  };

  const filteredProducts = products.filter(p => 
    p.name.toLowerCase().includes(searchTerm.toLowerCase()) || 
    p.code.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (p.category && p.category.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  return (
    <div className="max-w-[1000px] mx-auto space-y-6 pt-4">
      <div>
        <h1 className="text-3xl font-black text-slate-800 tracking-tight">Customer Rates</h1>
        <p className="text-sm font-bold text-slate-500 mt-1">Manage negotiated product rates for specific customers.</p>
      </div>

      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-[14px] mb-[18px]">
          <div>
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Select Customer</label>
            <select 
              value={selectedCustomerId} 
              onChange={handleCustomerChange} 
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] font-bold text-slate-800 focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all"
            >
              <option value="">-- Choose a customer --</option>
              {customers.map(c => (
                <option key={c.id} value={c.id}>{c.name}</option>
              ))}
            </select>
          </div>
          {selectedCustomerId && (
            <div>
              <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Search Products</label>
              <input 
                type="text" 
                placeholder="Search by name, code or category..." 
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all"
              />
            </div>
          )}
        </div>

        {selectedCustomerId && (
          <>
            {loading ? (
              <div className="text-center py-10 font-bold text-slate-500 animate-pulse">Loading rates...</div>
            ) : (
              <div className="overflow-x-auto border border-slate-200 rounded-[14px] mb-[18px]">
                <table className="w-full text-left border-collapse text-[13px]">
                  <thead>
                    <tr className="bg-slate-100">
                      <th className="py-3 px-4 font-black text-slate-500 uppercase tracking-wider text-[11px] border-b border-slate-200">Category</th>
                      <th className="py-3 px-4 font-black text-slate-500 uppercase tracking-wider text-[11px] border-b border-slate-200">Code</th>
                      <th className="py-3 px-4 font-black text-slate-500 uppercase tracking-wider text-[11px] border-b border-slate-200">Product Name</th>
                      <th className="py-3 px-4 font-black text-slate-500 uppercase tracking-wider text-[11px] border-b border-slate-200 text-right">Standard Rate</th>
                      <th className="py-3 px-4 font-black text-slate-500 uppercase tracking-wider text-[11px] border-b border-slate-200 text-right w-[150px]">Custom Rate (₹)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredProducts.map(p => (
                      <tr key={p.id} className="border-b border-slate-100 last:border-0 hover:bg-slate-50/50">
                        <td className="py-3 px-4 text-slate-500 font-bold text-xs">{p.category || '-'}</td>
                        <td className="py-3 px-4 text-slate-700 font-bold">{p.code}</td>
                        <td className="py-3 px-4 text-slate-800 font-bold">{p.name}</td>
                        <td className="py-3 px-4 text-slate-500 text-right font-medium">₹{parseFloat(p.rate).toFixed(2)}</td>
                        <td className="py-2 px-4">
                          <input 
                            type="number" 
                            step="0.01" 
                            placeholder="Standard"
                            value={prices[p.id] !== undefined ? prices[p.id] : ''}
                            onChange={(e) => handlePriceChange(p.id, e.target.value)}
                            className="w-full px-3 py-2 bg-white border border-slate-300 rounded-[8px] text-[13px] font-bold text-active text-right focus:outline-none focus:border-active focus:ring-[3px] focus:ring-active/20"
                          />
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
            
            <div className="flex justify-between items-center bg-slate-50 p-4 border border-slate-200 rounded-[18px]">
              <div>
                {message && (
                  <span className={`text-[13px] font-bold px-3 py-1.5 rounded-lg ${message.includes('Error') ? 'bg-red-100 text-red-600' : 'bg-emerald-100 text-emerald-700'}`}>
                    {message}
                  </span>
                )}
              </div>
              <button 
                onClick={handleSave} 
                disabled={saving}
                className="min-h-[44px] px-8 bg-active-dark text-white rounded-[14px] font-black shadow-[0_8px_20px_rgba(0,0,0,0.15)] hover:-translate-y-0.5 hover:shadow-[0_12px_24px_rgba(0,0,0,0.2)] active:scale-[0.98] transition-all disabled:opacity-50"
              >
                {saving ? 'Saving...' : 'Save Customer Rates'}
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
