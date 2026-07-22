import React, { useState } from 'react';
import Select from 'react-select';
import { erpApi } from '../api/erpApi';
import { useProducts, useCustomers } from '../api/queries';

const selectStyles = {
  control: (base, state) => ({
    ...base,
    minHeight: '43px',
    borderRadius: '14px',
    borderColor: state.isFocused ? 'var(--active)' : '#cbd5e1',
    boxShadow: state.isFocused ? '0 0 0 4px color-mix(in srgb, var(--active) 15%, transparent)' : 'none',
    '&:hover': {
      borderColor: state.isFocused ? 'var(--active)' : '#94a3b8'
    },
    fontSize: '14px',
    fontWeight: '800',
    color: '#334155',
    backgroundColor: 'white'
  }),
  option: (base, state) => ({
    ...base,
    fontSize: '14px',
    fontWeight: state.isSelected ? '900' : '600',
    backgroundColor: state.isSelected ? 'var(--active)' : state.isFocused ? 'color-mix(in srgb, var(--active) 10%, transparent)' : 'white',
    color: state.isSelected ? 'white' : '#334155',
    cursor: 'pointer'
  })
};

export default function SalesOrderEntry() {
  const { data: products = [] } = useProducts();
  const { data: customers = [] } = useCustomers();
  
  const [isNewCustomer, setIsNewCustomer] = useState(false);
  const [selectedCustomerId, setSelectedCustomerId] = useState(null);
  const [newCustomerData, setNewCustomerData] = useState({ name: '', mobile: '', city: '', state: '', gstin: '' });
  
  const [customRates, setCustomRates] = useState({}); // { productId: customRate }
  
  const [rows, setRows] = useState([{ id: Date.now(), productId: null, product: '', qty: 1, rate: 0, total: 0 }]);
  const [message, setMessage] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  const addRow = () => setRows([...rows, { id: Date.now(), productId: null, product: '', qty: 1, rate: 0, total: 0 }]);
  const removeRow = (id) => setRows(rows.filter(r => r.id !== id));
  
  const updateRow = (id, field, value) => {
    setRows(rows.map(r => {
      if (r.id === id) {
        const updated = { ...r, [field]: value };
        if (field === 'qty' || field === 'rate' || field === 'productId') {
          updated.total = (parseFloat(updated.qty || 0) * parseFloat(updated.rate || 0));
        }
        return updated;
      }
      return r;
    }));
  };

  // Fetch custom prices when customer changes
  React.useEffect(() => {
    const fetchCustomPrices = async () => {
      if (!selectedCustomerId || isNewCustomer) {
        setCustomRates({});
        // Revert to standard rates for existing rows
        setRows(prevRows => prevRows.map(r => {
          if (!r.productId) return r;
          const p = products.find(prod => prod.id === r.productId);
          const rate = p ? parseFloat(p.rate) : 0;
          return { ...r, rate, total: (parseFloat(r.qty || 0) * rate) };
        }));
        return;
      }

      try {
        const prices = await erpApi.getCustomerPrices(selectedCustomerId);
        const pricesMap = {};
        prices.forEach(cp => pricesMap[cp.productId] = parseFloat(cp.rate));
        setCustomRates(pricesMap);
        
        // Auto-update existing rows with new custom prices
        setRows(prevRows => prevRows.map(r => {
          if (!r.productId) return r;
          const p = products.find(prod => prod.id === r.productId);
          const baseRate = p ? parseFloat(p.rate) : 0;
          const rate = pricesMap[r.productId] !== undefined ? pricesMap[r.productId] : baseRate;
          return { ...r, rate, total: (parseFloat(r.qty || 0) * rate) };
        }));
      } catch (err) {
        console.error("Failed to fetch customer prices");
      }
    };
    fetchCustomPrices();
  }, [selectedCustomerId, isNewCustomer, products]);

  const handleProductSelect = (id, productCode) => {
    const product = products.find(p => p.code === productCode);
    if (product) {
      const standardRate = parseFloat(product.rate);
      const customRate = customRates[product.id];
      const finalRate = customRate !== undefined ? customRate : standardRate;
      
      updateRow(id, 'product', product.name);
      updateRow(id, 'productId', product.id);
      updateRow(id, 'rate', finalRate);
    }
  };

  const subtotal = rows.reduce((sum, r) => sum + (r.total || 0), 0);

  const handleSubmit = async () => {
    if (!isNewCustomer && !selectedCustomerId) {
      alert("Please select a customer or add a new one.");
      return;
    }
    if (isNewCustomer && !newCustomerData.name) {
      alert("New Customer Name is required.");
      return;
    }
    if (rows.length === 0 || rows.every(r => !r.product)) {
      alert("Add at least one product.");
      return;
    }

    const payload = {
      customerId: isNewCustomer ? null : selectedCustomerId,
      newCustomerData: isNewCustomer ? newCustomerData : null,
      subtotal,
      items: rows.filter(r => r.product).map(r => ({
        productId: r.productId,
        product: r.product,
        qty: parseInt(r.qty) || 0,
        rate: parseFloat(r.rate) || 0,
        total: parseFloat(r.total) || 0
      }))
    };

    setIsSubmitting(true);
    try {
      await erpApi.createSalesOrder(payload);
      setMessage('Order submitted successfully for approval!');
      setRows([{ id: Date.now(), productId: null, product: '', qty: 1, rate: 0, total: 0 }]);
      setSelectedCustomerId(null);
      setNewCustomerData({ name: '', mobile: '', city: '', state: '', gstin: '' });
      setIsNewCustomer(false);
      setTimeout(() => setMessage(''), 4000);
    } catch (e) {
      alert("Error submitting order: " + (e.response?.data?.error || e.message));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="max-w-[800px] mx-auto space-y-[18px]">
      
      {/* HEADER SECTION */}
      <div className="bg-white rounded-[24px] p-[20px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200">
        <h2 className="text-[16px] font-black text-active uppercase tracking-[1px] mb-4 flex justify-between items-center">
          <span>Draft Sales Order</span>
          {message && <span className="text-[12px] bg-green-100 text-green-700 px-3 py-1 rounded-full">{message}</span>}
        </h2>

        <div className="mb-4 flex items-center gap-4">
          <button 
            onClick={() => setIsNewCustomer(false)}
            className={`flex-1 py-2 rounded-xl text-[13px] font-bold border-2 transition-all ${!isNewCustomer ? 'border-active bg-active/5 text-active' : 'border-slate-200 text-slate-500 hover:bg-slate-50'}`}
          >
            Select Existing Customer
          </button>
          <button 
            onClick={() => setIsNewCustomer(true)}
            className={`flex-1 py-2 rounded-xl text-[13px] font-bold border-2 transition-all ${isNewCustomer ? 'border-active bg-active/5 text-active' : 'border-slate-200 text-slate-500 hover:bg-slate-50'}`}
          >
            + New Lead / Customer
          </button>
        </div>

        {!isNewCustomer ? (
          <div>
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Select Customer</label>
            <Select
              styles={selectStyles}
              options={customers.map(c => ({ value: c.id, label: c.name }))}
              value={selectedCustomerId ? { value: selectedCustomerId, label: customers.find(c => c.id === selectedCustomerId)?.name } : null}
              onChange={(selected) => setSelectedCustomerId(selected ? selected.value : null)}
              placeholder="Search assigned customers..."
              isClearable
            />
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 bg-slate-50 p-4 rounded-2xl border border-slate-200">
            <div className="sm:col-span-2">
              <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Customer Name *</label>
              <input value={newCustomerData.name} onChange={e => setNewCustomerData({...newCustomerData, name: e.target.value})} className="w-full h-[43px] px-[12px] border border-slate-300 rounded-[14px] text-[14px] font-bold focus:border-active focus:ring-[3px] focus:ring-active/15" placeholder="Business Name" />
            </div>
            <div>
              <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Mobile</label>
              <input value={newCustomerData.mobile} onChange={e => setNewCustomerData({...newCustomerData, mobile: e.target.value})} className="w-full h-[43px] px-[12px] border border-slate-300 rounded-[14px] text-[14px] focus:border-active focus:ring-[3px] focus:ring-active/15" placeholder="10 digits" />
            </div>
            <div>
              <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">GSTIN (Optional)</label>
              <input value={newCustomerData.gstin} onChange={e => setNewCustomerData({...newCustomerData, gstin: e.target.value})} className="w-full h-[43px] px-[12px] border border-slate-300 rounded-[14px] text-[14px] uppercase focus:border-active focus:ring-[3px] focus:ring-active/15" placeholder="15 chars" />
            </div>
            <div>
              <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">City</label>
              <input value={newCustomerData.city} onChange={e => setNewCustomerData({...newCustomerData, city: e.target.value})} className="w-full h-[43px] px-[12px] border border-slate-300 rounded-[14px] text-[14px] focus:border-active focus:ring-[3px] focus:ring-active/15" placeholder="City" />
            </div>
            <div>
              <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">State</label>
              <input value={newCustomerData.state} onChange={e => setNewCustomerData({...newCustomerData, state: e.target.value})} className="w-full h-[43px] px-[12px] border border-slate-300 rounded-[14px] text-[14px] focus:border-active focus:ring-[3px] focus:ring-active/15" placeholder="State" />
            </div>
          </div>
        )}
      </div>

      {/* ITEMS SECTION */}
      <div className="bg-white rounded-[24px] p-[20px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200">
        <h3 className="text-[12px] font-black text-slate-800 uppercase tracking-widest mb-4">Requested Products</h3>
        <datalist id="productCodes">{products.map(p => <option key={p.id} value={p.code}>{p.name}</option>)}</datalist>

        <div className="space-y-4">
          {rows.map((row, index) => (
            <div key={row.id} className="bg-slate-50 border border-slate-200 rounded-[20px] p-4 relative shadow-sm">
              <div className="absolute top-4 right-4 flex gap-1">
                <button onClick={addRow} className="w-[28px] h-[28px] flex items-center justify-center bg-active/20 text-active-dark rounded-[8px] font-bold hover:bg-active hover:text-white transition-colors">+</button>
                <button onClick={() => removeRow(row.id)} className="w-[28px] h-[28px] flex items-center justify-center bg-white border border-slate-200 text-slate-600 rounded-[8px] font-bold hover:bg-rose-50 hover:text-rose-600 transition-colors">-</button>
              </div>
              
              <div className="mb-3 pr-16">
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Item #{index + 1}</span>
                <input list="productCodes" placeholder="Code (e.g. SP01)" className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] uppercase font-bold mb-2 focus:border-active focus:ring-[3px] focus:ring-active/15" onChange={(e) => handleProductSelect(row.id, e.target.value.toUpperCase())} />
                <input value={row.product} onChange={(e) => updateRow(row.id, 'product', e.target.value)} placeholder="Product Name" className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-medium focus:border-active focus:ring-[3px] focus:ring-active/15" />
              </div>

              <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Qty</label>
                  <input type="number" value={row.qty} onChange={(e) => updateRow(row.id, 'qty', parseInt(e.target.value) || 0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-black focus:border-active focus:ring-[3px] focus:ring-active/15" />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Rate</label>
                  <input type="number" value={row.rate} onChange={(e) => updateRow(row.id, 'rate', parseFloat(e.target.value) || 0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-bold focus:border-active focus:ring-[3px] focus:ring-active/15" />
                </div>
                <div className="col-span-2 sm:col-span-1">
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Total</label>
                  <input readOnly value={row.total} className="w-full px-3 py-2 bg-slate-100 border border-slate-200 text-slate-800 rounded-[10px] text-[13px] font-black outline-none shadow-inner" />
                </div>
              </div>
            </div>
          ))}
          <button onClick={addRow} className="w-full py-3 bg-slate-50 text-slate-600 rounded-[14px] font-black text-[12px] border border-dashed border-slate-300 hover:bg-slate-100 transition-colors">+ ADD NEW ITEM</button>
        </div>
      </div>

      {/* FOOTER ACTION */}
      <div className="bg-active-dark rounded-[24px] p-6 text-white shadow-xl flex flex-col sm:flex-row justify-between items-center gap-4">
        <div>
          <span className="block text-[12px] font-bold text-white/70 uppercase tracking-widest">Order Subtotal</span>
          <span className="text-[32px] font-black tracking-tighter">₹{subtotal.toFixed(2)}</span>
        </div>
        <button 
          onClick={handleSubmit} 
          disabled={isSubmitting}
          className="w-full sm:w-auto bg-white text-active-dark px-8 py-4 rounded-2xl font-black text-[15px] shadow-lg hover:scale-105 active:scale-95 transition-all disabled:opacity-50 disabled:hover:scale-100"
        >
          {isSubmitting ? 'SUBMITTING...' : 'SUBMIT ORDER REQUEST'}
        </button>
      </div>

    </div>
  );
}
