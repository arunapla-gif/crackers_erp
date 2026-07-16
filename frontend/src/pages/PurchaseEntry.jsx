import React, { useState, useEffect } from 'react';
import { useStore } from '../store/useStore';
import { erpApi } from '../api/erpApi';
import { FaEdit, FaPowerOff, FaCheckCircle } from 'react-icons/fa';

const COMPANY_STATE = "Tamil Nadu"; // Default Company State for GST Calculations

export default function PurchaseEntry() {
  const currentType = useStore(state => state.currentType);
  const [products, setProducts] = useState([]);
  const [godowns, setGodowns] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [history, setHistory] = useState([]);
  const [editingId, setEditingId] = useState(null);
  const [supplierState, setSupplierState] = useState('');
  
  const defaultHeader = {
    number: `PUR-${Date.now().toString().slice(-4)}`,
    date: new Date().toISOString().split('T')[0],
    supplier: '',
    billNo: ''
  };

  const [header, setHeader] = useState({ ...defaultHeader });

  const defaultRow = { 
    id: 1, godownId: '', godownName: '', productId: '', product: '', productCode: '',
    packs: 1, qtyPerPack: 1, packUnit: 'Pack', 
    qty: 1, pricingUnit: 'Kg', 
    rate: 0, amount: 0, 
    discount: 0, taxRate: 18, taxAmt: 0, netAmt: 0 
  };

  const [rows, setRows] = useState([{ ...defaultRow }]);
  const [message, setMessage] = useState('');

  const loadData = () => {
    erpApi.getProducts().then(data => setProducts(data.filter(p => p.type === 'RM'))).catch(() => {});
    erpApi.getGodowns().then(setGodowns).catch(() => {});
    erpApi.getSuppliers().then(setSuppliers).catch(() => {});
    erpApi.getPurchases().then(setHistory).catch(() => {});
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleSupplierSelect = (supplierName) => {
    setHeader({ ...header, supplier: supplierName });
    const supplier = suppliers.find(s => s.name === supplierName);
    if (supplier && supplier.state) {
      setSupplierState(supplier.state);
    } else {
      setSupplierState('Tamil Nadu'); // Default intra-state if undefined
    }
  };

  const addRow = () => {
    setRows([...rows, { ...defaultRow, id: Date.now() }]);
  };

  const removeRow = (id) => {
    const newRows = rows.filter(r => r.id !== id);
    setRows(newRows.length ? newRows : [{ ...defaultRow, id: Date.now() }]);
  };

  const updateRow = (id, field, value) => {
    setRows(rows.map(row => {
      if (row.id === id) {
        const updated = { ...row, [field]: value };
        
        // Recalculate everything
        updated.qty = (parseInt(updated.packs) || 0) * (parseInt(updated.qtyPerPack) || 1);
        updated.amount = parseFloat((updated.qty * parseFloat(updated.rate || 0)).toFixed(2));
        const taxable = updated.amount - (parseFloat(updated.discount) || 0);
        updated.taxAmt = parseFloat((taxable * parseFloat(updated.taxRate || 0) / 100).toFixed(2));
        updated.netAmt = parseFloat((taxable + updated.taxAmt).toFixed(2));
        
        return updated;
      }
      return row;
    }));
  };

  const handleProductSelect = (id, productName) => {
    const product = products.find(p => p.name === productName);
    if (product) {
      setRows(rows.map(row => {
        if (row.id === id) {
          const qtyPerPack = product.unit_qty || 1;
          const qty = (parseInt(row.packs) || 0) * qtyPerPack;
          const rate = parseFloat(product.rate) || 0;
          const amount = parseFloat((qty * rate).toFixed(2));
          const discount = parseFloat(row.discount) || 0;
          const taxRate = parseFloat(product.tax) || 18;
          const taxable = amount - discount;
          const taxAmt = parseFloat((taxable * taxRate / 100).toFixed(2));
          const netAmt = parseFloat((taxable + taxAmt).toFixed(2));
          
          return {
            ...row,
            productCode: product.code,
            productId: product.id,
            product: product.name,
            qtyPerPack,
            packUnit: product.pack_unit || 'Pack',
            pricingUnit: product.unit || 'Kg',
            qty,
            rate,
            amount,
            taxRate,
            taxAmt,
            netAmt
          };
        }
        return row;
      }));
    } else {
      updateRow(id, 'product', productName);
    }
  };

  const handleGodownSelect = (id, godownName) => {
    const godown = godowns.find(g => g.name === godownName);
    if (godown) {
      updateRow(id, 'godownName', godown.name);
      updateRow(id, 'godownId', godown.id);
    } else {
      updateRow(id, 'godownName', godownName);
      updateRow(id, 'godownId', null);
    }
  };

  const totals = rows.reduce((acc, row) => {
    acc.qty += parseInt(row.qty) || 0;
    acc.subtotal += parseFloat(row.amount) || 0;
    acc.discount += parseFloat(row.discount) || 0;
    acc.tax += parseFloat(row.taxAmt) || 0;
    acc.value += parseFloat(row.netAmt) || 0;
    return acc;
  }, { qty: 0, subtotal: 0, discount: 0, tax: 0, value: 0 });

  // Calculate GST Split
  const isIntraState = !supplierState || supplierState.toUpperCase() === COMPANY_STATE.toUpperCase();
  const cgst = isIntraState ? totals.tax / 2 : 0;
  const sgst = isIntraState ? totals.tax / 2 : 0;
  const igst = isIntraState ? 0 : totals.tax;

  const handleSave = async () => {
    if (!header.supplier) {
      alert("Supplier name is required");
      return;
    }
    
    // Validate rows
    for (const row of rows) {
      if (!row.godownId) {
        alert(`Please select a valid Godown for product: ${row.product}`);
        return;
      }
      if (!row.product) {
        alert("Product name is required for all rows");
        return;
      }
    }

    const payload = {
      ...header,
      id: editingId,
      qty: totals.qty,
      subtotal: totals.subtotal,
      discount: totals.discount,
      tax: totals.tax,
      cgst,
      sgst,
      igst,
      value: totals.value,
      items: rows.map(r => ({
        ...r,
        pack_unit: r.packUnit,
        pricing_unit: r.pricingUnit,
        tax_rate: r.taxRate,
        tax_amt: r.taxAmt,
        net_amount: r.netAmt
      }))
    };

    try {
      await erpApi.savePurchase(payload);
      setMessage(`Purchase ${header.number} ${editingId ? 'updated' : 'saved'}! Stock balances updated.`);
      setRows([{ ...defaultRow, id: Date.now() }]);
      setHeader({ ...defaultHeader, number: `PUR-${Date.now().toString().slice(-4)}` });
      setEditingId(null);
      setSupplierState('');
      loadData();
      setTimeout(() => setMessage(''), 4000);
    } catch (error) {
      alert("Error saving purchase: " + (error.response?.data?.error || error.message));
    }
  };

  const handleEdit = (purchase) => {
    setEditingId(purchase.id);
    setHeader({
      number: purchase.number,
      date: new Date(purchase.date).toISOString().split('T')[0],
      supplier: purchase.supplier,
      billNo: purchase.billNo
    });
    
    // Re-fetch supplier state
    const supplier = suppliers.find(s => s.name === purchase.supplier);
    setSupplierState(supplier?.state || 'Tamil Nadu');
    
    if (purchase.items && purchase.items.length > 0) {
      const editRows = purchase.items.map(item => ({
        id: item.id,
        godownId: item.godownId,
        godownName: item.godown?.name || '',
        productId: item.productId,
        product: item.product,
        productCode: '', 
        packs: item.packs || 0,
        qtyPerPack: item.qty / (item.packs || 1), 
        packUnit: item.pack_unit || 'Pack',
        qty: item.qty,
        pricingUnit: item.pricing_unit || 'Kg',
        rate: parseFloat(item.rate),
        amount: parseFloat(item.amount),
        discount: parseFloat(item.discount || 0),
        taxRate: parseFloat(item.tax_rate || 18),
        taxAmt: parseFloat(item.tax_amt || 0),
        netAmt: parseFloat(item.net_amount || item.amount)
      }));
      setRows(editRows);
    } else {
      setRows([{ ...defaultRow, id: Date.now() }]);
    }
    
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleToggleStatus = async (purchase) => {
    if (!window.confirm(`Are you sure you want to ${purchase.status === 'Active' ? 'disable' : 'enable'} this purchase? This will ${purchase.status === 'Active' ? 'decrease' : 'increase'} godown stock.`)) {
      return;
    }
    try {
      const newStatus = purchase.status === 'Active' ? 'Inactive' : 'Active';
      await erpApi.togglePurchaseStatus(purchase.id, newStatus);
      loadData();
    } catch (error) {
      alert("Error toggling status: " + (error.response?.data?.error || error.message));
    }
  };

  return (
    <div className="space-y-[14px]">
      
      {/* HEADER SECTION */}
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center justify-between mb-4">
          <div className="flex items-center gap-[10px]">
            <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
            {editingId ? 'Edit Purchase Entry' : 'Purchase Entry (Inward Stock)'}
          </div>
          {editingId && (
            <button 
              onClick={() => {
                setEditingId(null);
                setHeader({ ...defaultHeader, number: `PUR-${Date.now().toString().slice(-4)}` });
                setRows([{ ...defaultRow, id: Date.now() }]);
              }}
              className="text-[11px] font-bold text-slate-400 hover:text-slate-600 bg-slate-100 px-3 py-1 rounded-[8px]"
            >
              Cancel Edit
            </button>
          )}
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-12 gap-[14px]">
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Purchase No</label>
            <input 
              readOnly 
              value={header.number}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-slate-50 border border-slate-200 rounded-[14px] text-[14px] font-bold shadow-sm outline-none" 
            />
          </div>
          
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Date</label>
            <input 
              type="date"
              value={header.date}
              onChange={(e) => setHeader({...header, date: e.target.value})}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
            />
          </div>

          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Supplier Name</label>
            <input 
              list="suppliersList"
              value={header.supplier}
              onChange={(e) => handleSupplierSelect(e.target.value)}
              placeholder="Supplier / Manufacturer"
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm"
            />
            <datalist id="suppliersList">
              {suppliers.map(s => <option key={s.id} value={s.name} />)}
            </datalist>
          </div>

          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Supplier Bill No</label>
            <input 
              value={header.billNo}
              onChange={(e) => setHeader({...header, billNo: e.target.value})}
              placeholder="Bill No"
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
            />
          </div>
        </div>
      </div>

      {/* DYNAMIC ROWS SECTION */}
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-4 md:p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-slate-800 uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4 md:hidden">
          Products / Items
        </h2>

        {/* Desktop Table View */}
        <div className="hidden md:block overflow-x-auto">
          <table className="w-full text-left border-spacing-y-2 border-separate min-w-[1100px]">
            <thead>
              <tr>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[4%]">S.No</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[12%]">Dest Godown</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[20%]">Product Name</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[8%]">Packs</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[9%]">Total Qty</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[9%]">Rate</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[9%]">Amount</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[8%]">Disc</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[7%]">Tax %</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[10%]">Net Amt</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-1 w-[4%]"></th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row, index) => (
                <tr key={row.id}>
                  <td className="px-1 font-bold text-slate-400 text-center">{index + 1}</td>
                  <td className="px-1">
                    <input list="godownList" placeholder="Godown" value={row.godownName} onChange={(e) => handleGodownSelect(row.id, e.target.value)} className="w-full px-2 py-[7px] border border-slate-200 rounded-[8px] text-[12px] focus:border-active focus:ring-[3px] focus:ring-active/20" />
                    <datalist id="godownList">{godowns.map(g => <option key={g.id} value={g.name} />)}</datalist>
                  </td>
                  <td className="px-1 flex gap-1">
                    <input list="productNames" placeholder="Search Material Name..." value={row.product} className="w-full px-2 py-[7px] border border-slate-200 rounded-[8px] text-[12px] font-bold text-active focus:border-active focus:ring-[3px] focus:ring-active/20" onChange={(e) => handleProductSelect(row.id, e.target.value)} />
                    <datalist id="productNames">{products.map(p => <option key={p.id} value={p.name} />)}</datalist>
                  </td>
                  <td className="px-1 relative">
                    <input type="number" value={row.packs || ''} onChange={(e) => updateRow(row.id, 'packs', parseInt(e.target.value) || 0)} className="w-full px-2 py-[7px] border border-slate-200 rounded-[8px] text-[12px] font-bold focus:border-active focus:ring-[3px] focus:ring-active/20" />
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[9px] font-black text-slate-400 uppercase pointer-events-none">{row.packUnit}</span>
                  </td>
                  <td className="px-1 relative">
                    <input readOnly value={row.qty} className="w-full px-2 py-[7px] bg-slate-50 border border-slate-200 rounded-[8px] text-[12px] font-bold text-slate-600 outline-none" />
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-[9px] font-black text-slate-400 uppercase pointer-events-none">{row.pricingUnit}</span>
                  </td>
                  <td className="px-1">
                    <input type="number" value={row.rate || ''} onChange={(e) => updateRow(row.id, 'rate', parseFloat(e.target.value) || 0)} className="w-full px-2 py-[7px] border border-slate-200 rounded-[8px] text-[12px] focus:border-active focus:ring-[3px] focus:ring-active/20" />
                  </td>
                  <td className="px-1">
                    <input readOnly value={row.amount} className="w-full px-2 py-[7px] bg-slate-50 border border-slate-200 rounded-[8px] text-[12px] font-black text-slate-700 outline-none" />
                  </td>
                  <td className="px-1">
                    <input type="number" value={row.discount || ''} onChange={(e) => updateRow(row.id, 'discount', parseFloat(e.target.value) || 0)} className="w-full px-2 py-[7px] border border-slate-200 rounded-[8px] text-[12px] focus:border-active focus:ring-[3px] focus:ring-active/20" />
                  </td>
                  <td className="px-1">
                    <input type="number" value={row.taxRate || ''} onChange={(e) => updateRow(row.id, 'taxRate', parseFloat(e.target.value) || 0)} className="w-full px-2 py-[7px] border border-slate-200 rounded-[8px] text-[12px] focus:border-active focus:ring-[3px] focus:ring-active/20" />
                  </td>
                  <td className="px-1">
                    <input readOnly value={row.netAmt} className="w-full px-2 py-[7px] bg-emerald-50 border border-emerald-200 text-emerald-700 rounded-[8px] text-[12px] font-black outline-none" />
                  </td>
                  <td className="px-1 flex gap-1 justify-end">
                    <button onClick={addRow} className="bg-active-soft text-active-dark w-[28px] h-[28px] flex items-center justify-center rounded-[8px] font-bold hover:bg-active hover:text-white transition-all">+</button>
                    <button onClick={() => removeRow(row.id)} className="bg-slate-100 text-slate-600 w-[28px] h-[28px] flex items-center justify-center rounded-[8px] font-bold hover:bg-slate-300 transition-all">-</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>

        {/* Mobile Card View */}
        <div className="block md:hidden space-y-4">
          {rows.map((row, index) => (
            <div key={row.id} className="bg-slate-50 border border-slate-200 rounded-[20px] p-4 relative shadow-sm">
              <div className="absolute top-4 right-4 flex gap-1">
                <button onClick={addRow} className="w-[28px] h-[28px] flex items-center justify-center bg-active-soft text-active-dark rounded-[8px] font-bold">+</button>
                <button onClick={() => removeRow(row.id)} className="w-[28px] h-[28px] flex items-center justify-center bg-white border border-slate-200 text-slate-600 rounded-[8px] font-bold">-</button>
              </div>
              
              <div className="mb-3 pr-16">
                <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Item #{index + 1}</span>
                <input 
                  list="productNamesMobile" 
                  placeholder="Search Material Name..." 
                  className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-bold text-active focus:border-active mb-2" 
                  value={row.product}
                  onChange={(e) => handleProductSelect(row.id, e.target.value)} 
                />
                <datalist id="productNamesMobile">{products.map(p => <option key={p.id} value={p.name} />)}</datalist>

                <input 
                  list="godownListMobile" 
                  placeholder="Dest Godown" 
                  value={row.godownName} 
                  onChange={(e) => handleGodownSelect(row.id, e.target.value)} 
                  className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-active" 
                />
                <datalist id="godownListMobile">{godowns.map(g => <option key={g.id} value={g.name} />)}</datalist>
              </div>

              <div className="grid grid-cols-2 gap-2 mb-2">
                <div className="relative">
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Packs</label>
                  <input type="number" value={row.packs || ''} onChange={(e) => updateRow(row.id, 'packs', parseInt(e.target.value) || 0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-bold" />
                  <span className="absolute right-3 top-[28px] text-[9px] font-black text-slate-400 uppercase pointer-events-none">{row.packUnit}</span>
                </div>
                <div className="relative">
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Total Qty</label>
                  <input readOnly value={row.qty} className="w-full px-3 py-2 bg-slate-100 border border-slate-200 rounded-[10px] text-[13px] font-bold text-slate-600 outline-none" />
                  <span className="absolute right-3 top-[28px] text-[9px] font-black text-slate-400 uppercase pointer-events-none">{row.pricingUnit}</span>
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Rate</label>
                  <input type="number" value={row.rate || ''} onChange={(e) => updateRow(row.id, 'rate', parseFloat(e.target.value) || 0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px]" />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Disc / Tax %</label>
                  <div className="flex gap-1">
                    <input type="number" placeholder="Disc" value={row.discount || ''} onChange={(e) => updateRow(row.id, 'discount', parseFloat(e.target.value) || 0)} className="w-1/2 px-2 py-2 border border-slate-200 rounded-[10px] text-[12px]" />
                    <input type="number" placeholder="Tax%" value={row.taxRate || ''} onChange={(e) => updateRow(row.id, 'taxRate', parseFloat(e.target.value) || 0)} className="w-1/2 px-2 py-2 border border-slate-200 rounded-[10px] text-[12px]" />
                  </div>
                </div>
              </div>

              <div>
                <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Net Amount</label>
                <input readOnly value={row.netAmt} className="w-full px-3 py-2 bg-emerald-50 border border-emerald-100 text-emerald-700 rounded-[10px] text-[13px] font-black outline-none" />
              </div>
            </div>
          ))}
          <button onClick={addRow} className="w-full py-3 bg-slate-100 text-slate-600 rounded-[14px] font-black text-[12px] border border-dashed border-slate-300 hover:bg-slate-200">+ ADD NEW ITEM</button>
        </div>
      </div>

      {/* TOTALS & ACTIONS */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-[14px]">
        
        <div className="lg:col-span-8 bg-white/88 backdrop-blur-[14px] rounded-[26px] p-6 md:p-[24px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
           <div className="flex justify-between items-center mb-4">
             <h2 className="text-[13px] font-black text-slate-400 uppercase tracking-[0.7px] flex items-center gap-[10px]">
              Purchase Summary
            </h2>
            <div className="text-[11px] font-black px-3 py-1 bg-slate-100 text-slate-500 rounded-full border border-slate-200 uppercase">
              {isIntraState ? `Intra-State (${COMPANY_STATE})` : `Inter-State (${supplierState})`}
            </div>
           </div>
          <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-5 gap-4">
            <div className="flex flex-col">
              <span className="text-[11px] font-bold text-slate-400 uppercase mb-1">Subtotal</span>
              <span className="text-[18px] font-black text-slate-700">₹{totals.subtotal.toFixed(2)}</span>
            </div>
            <div className="flex flex-col">
              <span className="text-[11px] font-bold text-slate-400 uppercase mb-1">Discount</span>
              <span className="text-[18px] font-black text-rose-500">-₹{totals.discount.toFixed(2)}</span>
            </div>
            {isIntraState ? (
              <>
                <div className="flex flex-col">
                  <span className="text-[11px] font-bold text-slate-400 uppercase mb-1">CGST</span>
                  <span className="text-[18px] font-black text-slate-700">₹{cgst.toFixed(2)}</span>
                </div>
                <div className="flex flex-col">
                  <span className="text-[11px] font-bold text-slate-400 uppercase mb-1">SGST</span>
                  <span className="text-[18px] font-black text-slate-700">₹{sgst.toFixed(2)}</span>
                </div>
              </>
            ) : (
              <div className="flex flex-col col-span-2 md:col-span-1">
                <span className="text-[11px] font-bold text-slate-400 uppercase mb-1">IGST</span>
                <span className="text-[18px] font-black text-slate-700">₹{igst.toFixed(2)}</span>
              </div>
            )}
            <div className="flex flex-col hidden md:flex">
              <span className="text-[11px] font-bold text-slate-400 uppercase mb-1">Total Qty</span>
              <span className="text-[18px] font-black text-slate-700">{totals.qty}</span>
            </div>
          </div>
        </div>

        <div className="lg:col-span-4 bg-gradient-to-br from-active-dark to-active rounded-[26px] p-6 md:p-[24px] text-white shadow-[0_24px_58px_rgba(15,23,42,0.16)] flex flex-col justify-center">
          <div className="flex justify-between items-center mt-2">
            <span className="font-black text-[15px] tracking-wide">GRAND TOTAL</span>
            <span className="font-black text-[32px] md:text-[38px] tracking-[-1px]">₹{totals.value.toFixed(2)}</span>
          </div>

          <button 
            onClick={handleSave}
            className="w-full mt-6 bg-white text-active-dark font-black text-[15px] py-[16px] rounded-[16px] shadow-[0_12px_24px_rgba(0,0,0,0.15)] hover:-translate-y-[2px] transition-all"
          >
            {editingId ? 'UPDATE PURCHASE' : 'SAVE & ADD STOCK'}
          </button>
          
          {message && <div className="mt-4 text-center text-[12px] font-bold bg-white/20 p-2 rounded-[10px]">{message}</div>}
        </div>
      </div>

      {/* HISTORY TABLE */}
      <div className="bg-white/60 backdrop-blur-xl rounded-[32px] p-[24px] shadow-[0_24px_64px_rgba(15,23,42,0.06)] border border-white/80 mt-8 overflow-hidden relative">
        <div className="absolute top-0 right-0 w-[400px] h-[400px] bg-active/5 rounded-full blur-3xl -z-10 pointer-events-none translate-x-1/2 -translate-y-1/2"></div>
        <div className="absolute bottom-0 left-0 w-[300px] h-[300px] bg-emerald-500/5 rounded-full blur-3xl -z-10 pointer-events-none -translate-x-1/2 translate-y-1/2"></div>

        <div className="flex items-center justify-between mb-6">
          <h2 className="text-[16px] font-black text-slate-800 tracking-[-0.5px] flex items-center gap-[12px]">
            <span className="w-[32px] h-[32px] rounded-xl bg-active/10 text-active flex items-center justify-center shadow-inner">
              <FaCheckCircle size={14} />
            </span>
            Recent Purchases Log
          </h2>
        </div>
        
        <div className="overflow-x-auto pb-4">
          <table className="w-full text-left border-spacing-y-[8px] border-separate min-w-[900px]">
            <thead>
              <tr>
                <th className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-5 pb-2 w-[12%]">Date</th>
                <th className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-5 pb-2 w-[16%]">Purchase No</th>
                <th className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-5 pb-2 w-[22%]">Supplier</th>
                <th className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-5 pb-2 w-[15%] text-right">Tax (C+S/I)</th>
                <th className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-5 pb-2 w-[15%] text-right">Value</th>
                <th className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-5 pb-2 w-[10%] text-center">Status</th>
                <th className="text-[10px] font-black text-slate-400 uppercase tracking-widest px-5 pb-2 w-[10%] text-center">Actions</th>
              </tr>
            </thead>
            <tbody>
              {history.map(p => {
                const pTaxLabel = parseFloat(p.igst) > 0 ? `IGST: ₹${p.igst}` : `C+S: ₹${(parseFloat(p.cgst) + parseFloat(p.sgst)).toFixed(2)}`;
                const isActive = p.status === 'Active';
                return (
                  <tr key={p.id} className="group transition-all duration-300">
                    <td className="px-5 py-[16px] text-[13px] font-bold text-slate-600 bg-white group-hover:bg-slate-50/80 rounded-l-[16px] shadow-[0_2px_10px_rgba(15,23,42,0.02)] border-y border-l border-white group-hover:border-slate-100 transition-colors">
                      {new Date(p.date).toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
                    </td>
                    <td className="px-5 py-[16px] text-[13px] font-black text-active bg-white group-hover:bg-slate-50/80 shadow-[0_2px_10px_rgba(15,23,42,0.02)] border-y border-white group-hover:border-slate-100 transition-colors">
                      {p.number}
                    </td>
                    <td className="px-5 py-[16px] text-[14px] font-bold text-slate-700 bg-white group-hover:bg-slate-50/80 shadow-[0_2px_10px_rgba(15,23,42,0.02)] border-y border-white group-hover:border-slate-100 transition-colors">
                      {p.supplier}
                    </td>
                    <td className="px-5 py-[16px] text-[12px] font-bold text-slate-500 text-right bg-white group-hover:bg-slate-50/80 shadow-[0_2px_10px_rgba(15,23,42,0.02)] border-y border-white group-hover:border-slate-100 transition-colors">
                      {pTaxLabel}
                    </td>
                    <td className="px-5 py-[16px] text-[15px] font-black text-slate-800 text-right bg-white group-hover:bg-slate-50/80 shadow-[0_2px_10px_rgba(15,23,42,0.02)] border-y border-white group-hover:border-slate-100 transition-colors">
                      ₹{parseFloat(p.value).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                    </td>
                    <td className="px-5 py-[16px] text-center bg-white group-hover:bg-slate-50/80 shadow-[0_2px_10px_rgba(15,23,42,0.02)] border-y border-white group-hover:border-slate-100 transition-colors">
                      <span className={`px-[10px] py-[4px] rounded-full text-[10px] font-black uppercase tracking-wider shadow-sm border ${
                        isActive 
                        ? 'bg-emerald-50 text-emerald-600 border-emerald-100' 
                        : 'bg-rose-50 text-rose-500 border-rose-100'
                      }`}>
                        {p.status || 'Active'}
                      </span>
                    </td>
                    <td className="px-5 py-[16px] bg-white group-hover:bg-slate-50/80 rounded-r-[16px] shadow-[0_2px_10px_rgba(15,23,42,0.02)] border-y border-r border-white group-hover:border-slate-100 transition-colors">
                      <div className="flex items-center justify-center gap-[8px]">
                        <button 
                          onClick={() => handleEdit(p)}
                          className="w-[32px] h-[32px] rounded-xl bg-slate-50 text-slate-400 flex items-center justify-center hover:bg-active hover:text-white hover:shadow-[0_4px_12px_rgba(var(--active-rgb),0.3)] hover:-translate-y-[2px] transition-all"
                          title="Edit Purchase"
                        >
                          <FaEdit size={14} />
                        </button>
                        <button 
                          onClick={() => handleToggleStatus(p)}
                          className={`w-[32px] h-[32px] rounded-xl flex items-center justify-center hover:-translate-y-[2px] transition-all ${
                            isActive 
                            ? 'bg-rose-50 text-rose-400 hover:bg-rose-500 hover:text-white hover:shadow-[0_4px_12px_rgba(244,63,94,0.3)]' 
                            : 'bg-emerald-50 text-emerald-500 hover:bg-emerald-500 hover:text-white hover:shadow-[0_4px_12px_rgba(16,185,129,0.3)]'
                          }`}
                          title={isActive ? "Disable Purchase" : "Enable Purchase"}
                        >
                          {isActive ? <FaPowerOff size={13} /> : <FaCheckCircle size={14} />}
                        </button>
                      </div>
                    </td>
                  </tr>
                );
              })}
              {history.length === 0 && (
                <tr>
                  <td colSpan="7" className="text-center py-[48px]">
                    <div className="inline-flex flex-col items-center justify-center opacity-50">
                      <span className="w-[48px] h-[48px] rounded-2xl bg-slate-100 text-slate-300 flex items-center justify-center mb-3">
                        <FaEdit size={20} />
                      </span>
                      <p className="text-[13px] font-bold text-slate-400">No purchase history found.</p>
                    </div>
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
