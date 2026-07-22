import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';

export default function ProductMaster() {
  const [formData, setFormData] = useState({
    code: '', name: '', type: 'INV', category: '', subCategory: '', hsn: '3604', tax: '18.00', rate: '0.00', unit_qty: '1', unit: 'Case', status: 'Active', factoryAliasId: ''
  });
  const [products, setProducts] = useState([]);
  const [message, setMessage] = useState('');

  const fetchProducts = async () => {
    try {
      const data = await erpApi.getProducts();
      setProducts(data);
    } catch (e) {
      console.log('Backend not available or products table empty');
    }
  };

  const loadNextCode = async (newType) => {
    const targetType = newType || formData.type || 'INV';
    const code = await erpApi.getNextProductCode(targetType);
    if (newType) {
      setFormData(prev => ({ ...prev, code, type: targetType }));
    } else {
      setFormData({
        code,
        name: '',
        type: 'INV',
        category: '',
        subCategory: '',
        hsn: '3604',
        tax: '18.00',
        rate: '0.00',
        unit_qty: '1',
        unit: 'Case',
        status: 'Active',
        factoryAliasId: ''
      });
    }
  };

  useEffect(() => {
    fetchProducts();
    loadNextCode();
  }, []);

  const handleChange = (e) => {
    if (e.target.name === 'type') {
      loadNextCode(e.target.value);
    } else {
      setFormData({ ...formData, [e.target.name]: e.target.value });
    }
  };

  const handleClear = () => {
    setMessage('');
    fetchProducts();
    loadNextCode();
  };

  const handleEdit = (product) => {
    setFormData({
      ...product,
      category: product.category || '',
      subCategory: product.subCategory || '',
      tax: String(product.tax),
      rate: String(product.rate),
      unit_qty: String(product.unit_qty),
      factoryAliasId: product.factoryAliasId ? String(product.factoryAliasId) : ''
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleToggleStatus = async (product) => {
    const newStatus = product.status === 'Active' ? 'Inactive' : 'Active';
    try {
      await erpApi.saveProduct({
        ...product,
        tax: parseFloat(product.tax),
        rate: parseFloat(product.rate),
        unit_qty: parseInt(product.unit_qty),
        status: newStatus
      });
      setMessage(`Product status set to ${newStatus}!`);
      fetchProducts();
    } catch (error) {
      alert('Error updating product status');
    }
  };

  const handleSave = async () => {
    if (!formData.code || !formData.name) {
      alert('Product Code and Name are required');
      return;
    }
    try {
      await erpApi.saveProduct({
        ...formData,
        tax: parseFloat(formData.tax),
        rate: parseFloat(formData.rate),
        unit_qty: parseInt(formData.unit_qty),
        factoryAliasId: formData.factoryAliasId ? parseInt(formData.factoryAliasId) : null
      });
      setMessage(`Product ${formData.code} saved successfully!`);
      handleClear();
    } catch (error) {
      const errorMsg = error.response?.data?.error || error.message;
      alert(`Error saving product: ${errorMsg}`);
    }
  };

  const renderProductTable = (title, items) => {
    const groups = {};
    items.forEach(p => {
      const groupKey = p.subCategory || p.category || 'UNCATEGORIZED';
      if (!groups[groupKey]) groups[groupKey] = [];
      groups[groupKey].push(p);
    });

    const customOrder = [
      '400 COUNT',
      '400 COUNT (CORE & CELLOPHANE)',
      '600 COUNT',
      '700 COUNT',
      '800 COUNT'
    ];
    
    const sortedGroupKeys = Object.keys(groups).sort((a, b) => {
      const indexA = customOrder.indexOf(a.toUpperCase());
      const indexB = customOrder.indexOf(b.toUpperCase());
      if (indexA !== -1 && indexB !== -1) return indexA - indexB;
      if (indexA !== -1) return -1;
      if (indexB !== -1) return 1;
      return a.localeCompare(b);
    });

    return (
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          {title} ({items.length})
        </h2>
        <table className="w-full border-separate border-spacing-y-[8px] text-[14px]">
          <thead>
            <tr>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Code</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Name</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Category</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">HSN</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Rate</th>
              <th className="text-center font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Status</th>
              <th className="text-right font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Actions</th>
            </tr>
          </thead>
          <tbody>
            {items.length === 0 ? (
              <tr>
                <td colSpan={7} className="bg-white border border-slate-200 rounded-[14px] p-[10px] text-center text-slate-500">No products found in this category</td>
              </tr>
            ) : (
              sortedGroupKeys.map(groupKey => (
                <React.Fragment key={groupKey}>
                  <tr>
                    <td colSpan={7} className="bg-[#b4d2a5] text-center font-bold text-slate-900 py-[6px] border-y border-[#9bb88d] text-[12px] uppercase tracking-[1px] shadow-sm">
                      {groupKey}
                    </td>
                  </tr>
                  {groups[groupKey].map((p, i) => (
                    <tr key={p.id || i} className={`hover:bg-slate-50 transition-all ${p.status === 'Inactive' ? 'opacity-60 grayscale' : ''}`}>
                      <td className="bg-white border-y border-slate-200 border-l rounded-l-[14px] p-[10px] font-[800] text-slate-800">{p.code}</td>
                      <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">{p.name}</td>
                      <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700 font-bold text-active">{p.category || '-'}</td>
                      <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">{p.hsn}</td>
                      <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">₹{p.rate}</td>
                      <td className="bg-white border-y border-slate-200 p-[10px] text-center">
                        <span className={`inline-block px-2 py-1 rounded-[6px] text-[10px] font-bold uppercase tracking-wider ${p.status === 'Inactive' ? 'bg-red-100 text-red-600' : 'bg-green-100 text-green-600'}`}>
                          {p.status || 'Active'}
                        </span>
                      </td>
                      <td className="bg-white border-y border-slate-200 border-r rounded-r-[14px] p-[10px] text-right">
                        <div className="flex justify-end gap-2">
                          <button onClick={() => handleEdit(p)} className="px-3 py-1 bg-blue-50 text-blue-600 hover:bg-blue-100 rounded-[8px] font-bold text-[11px] transition-colors">
                            Edit
                          </button>
                          <button onClick={() => handleToggleStatus(p)} className={`px-3 py-1 rounded-[8px] font-bold text-[11px] transition-colors ${p.status === 'Inactive' ? 'bg-emerald-50 text-emerald-600 hover:bg-emerald-100' : 'bg-rose-50 text-rose-600 hover:bg-rose-100'}`}>
                            {p.status === 'Inactive' ? 'Enable' : 'Disable'}
                          </button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </React.Fragment>
              ))
            )}
          </tbody>
        </table>
      </div>
    );
  };

  return (
    <div className="space-y-[14px]">
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 hover:-translate-y-[1px] hover:border-[#dbe3ef] transition-all duration-150">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Product Details Master
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-[14px]">
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Product Code
              <span className="ml-2 px-[6px] py-[2px] text-[9px] font-black bg-active/10 text-active rounded-[5px] uppercase tracking-wider">Auto</span>
            </label>
            <input name="code" value={formData.code} onChange={handleChange} placeholder="e.g. SP001" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-active/30 rounded-[14px] text-[14px] font-black text-active focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all uppercase" />
          </div>
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Product Name *</label>
            <input name="name" value={formData.name} onChange={handleChange} placeholder="e.g. 1000 Wala" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Product Category</label>
            <input name="category" value={formData.category} onChange={handleChange} placeholder="e.g. STANDARD WALAS" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all uppercase" />
          </div>
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Sub-Category</label>
            <input name="subCategory" value={formData.subCategory} onChange={handleChange} placeholder="e.g. 400 COUNT" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all uppercase" />
          </div>
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Type</label>
            <select name="type" value={formData.type} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all">
              <option value="INV">Invoice Item (INV)</option>
              <option value="EP">Estimate Only (EP)</option>
              <option value="WIP">Factory Processing (WIP)</option>
            </select>
          </div>
          
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">HSN Code</label>
            <input name="hsn" value={formData.hsn} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Tax (%)</label>
            <input name="tax" type="number" step="0.01" value={formData.tax} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Rate (₹)</label>
            <input name="rate" type="number" step="0.01" value={formData.rate} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Unit Qty</label>
            <input name="unit_qty" type="number" value={formData.unit_qty} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Unit Type</label>
            <select name="unit" value={formData.unit} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all">
              <option>Case</option>
              <option>Box</option>
              <option>Pkt</option>
              <option>Pcs</option>
            </select>
          </div>
          <div className="col-span-1 md:col-span-12 mt-2 pt-2 border-t border-slate-100">
            <label className="block text-[12px] font-[800] text-amber-600 mb-[3px]">Factory Dispatch Mapping (Optional)</label>
            <p className="text-[10px] text-slate-500 mb-2">If selected, selling this product will internally generate a factory order for the mapped product instead.</p>
            <select name="factoryAliasId" value={formData.factoryAliasId} onChange={handleChange} className="w-full md:w-1/2 min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-amber-300 rounded-[14px] text-[14px] focus:outline-none focus:border-amber-500 focus:ring-[4px] focus:ring-amber-500/15 transition-all">
              <option value="">-- No Mapping (Deduct Own Stock) --</option>
              {products.filter(p => p.id !== formData.id).map(p => (
                <option key={p.id} value={p.id}>{p.name} ({p.code})</option>
              ))}
            </select>
          </div>
        </div>

        <div className="flex justify-end gap-[8px] mt-[18px] bg-slate-50 p-[12px] border border-slate-200 rounded-[18px]">
          <button onClick={handleClear} className="min-h-[40px] px-[16px] py-[10px] bg-slate-200 text-slate-900 border border-slate-300 rounded-[14px] font-[900] hover:-translate-y-[1px] transition-all">Clear</button>
          <button onClick={handleSave} className="min-h-[40px] px-[16px] py-[10px] bg-green-600 text-white rounded-[14px] font-[900] shadow-[0_10px_24px_rgba(15,23,42,0.12)] hover:-translate-y-[1px] transition-all">Save Product</button>
        </div>
        
        {message && (
          <div className="inline-block mt-[12px] bg-green-50 border border-green-200 text-green-700 p-[10px_12px] rounded-[14px] font-[900] text-[13px]">
            {message}
          </div>
        )}
      </div>

      {renderProductTable("Invoice Items (INV)", products.filter(p => p.type === 'INV'))}
      {renderProductTable("Estimate Items (EP)", products.filter(p => p.type === 'EP'))}
      {renderProductTable("Factory Processing (WIP)", products.filter(p => p.type === 'WIP'))}
    </div>
  );
}
