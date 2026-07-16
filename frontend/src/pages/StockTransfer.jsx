import React, { useState, useEffect } from 'react';
import { useStore } from '../store/useStore';
import { erpApi } from '../api/erpApi';

export default function StockTransfer() {
  const currentType = useStore(state => state.currentType);
  const [products, setProducts] = useState([]);
  const [godowns, setGodowns] = useState([]);
  const [vehicles, setVehicles] = useState([]);
  const [stockLedger, setStockLedger] = useState([]);
  
  const [header, setHeader] = useState({
    number: `TRF-${Date.now().toString().slice(-4)}`,
    date: new Date().toISOString().split('T')[0],
    vehicleId: '',
    driverName: '',
    remarks: ''
  });

  const [rows, setRows] = useState([
    { id: 1, fromGodownId: '', toGodownId: '', fromGodownName: '', toGodownName: '', productId: '', product: '', qty: 1, rate: 0, value: 0 }
  ]);

  const [message, setMessage] = useState('');

  useEffect(() => {
    erpApi.getProducts().then(setProducts).catch(() => {});
    erpApi.getGodowns().then(setGodowns).catch(() => {});
    erpApi.getVehicles().then(setVehicles).catch(() => {});
    erpApi.getStock().then(setStockLedger).catch(() => {});
  }, []);

  const addRow = () => {
    setRows([...rows, { id: Date.now(), fromGodownId: '', toGodownId: '', fromGodownName: '', toGodownName: '', productId: '', product: '', qty: 1, rate: 0, value: 0 }]);
  };

  const removeRow = (id) => {
    const newRows = rows.filter(r => r.id !== id);
    setRows(newRows.length ? newRows : [{ id: Date.now(), fromGodownId: '', toGodownId: '', fromGodownName: '', toGodownName: '', productId: '', product: '', qty: 1, rate: 0, value: 0 }]);
  };

  const updateRow = (id, field, value) => {
    setRows(rows.map(row => {
      if (row.id === id) {
        const updated = { ...row, [field]: value };
        // Auto-calculate rate and value based on source stock
        if (field === 'fromGodownId' || field === 'product') {
          const sourceStock = stockLedger.find(s => s.godownId === updated.fromGodownId && s.product === updated.product);
          if (sourceStock) {
            updated.rate = parseFloat(sourceStock.avgRate) || 0;
          }
        }
        if (field === 'qty' || field === 'rate' || field === 'fromGodownId' || field === 'product') {
          updated.value = parseFloat((updated.qty * updated.rate).toFixed(2)) || 0;
        }
        return updated;
      }
      return row;
    }));
  };

  const handleProductSelect = (id, productCode) => {
    const product = products.find(p => p.code === productCode);
    if (product) {
      updateRow(id, 'product', product.name);
      updateRow(id, 'productId', product.id);
    }
  };

  const totals = rows.reduce((acc, row) => {
    acc.qty += parseInt(row.qty) || 0;
    acc.value += parseFloat(row.value) || 0;
    return acc;
  }, { qty: 0, value: 0 });

  const handleSave = async () => {
    if (!header.vehicleId) {
      alert("Please select a vehicle.");
      return;
    }
    
    for (const row of rows) {
      if (!row.fromGodownId || !row.toGodownId) {
        alert(`Select From and To Godowns for: ${row.product}`);
        return;
      }
      if (row.fromGodownId === row.toGodownId) {
        alert(`Source and Destination godowns cannot be the same for: ${row.product}`);
        return;
      }
      if (!row.product || row.qty <= 0) {
        alert("Invalid product or quantity.");
        return;
      }
      
      const sourceStock = stockLedger.find(s => s.godownId === row.fromGodownId && s.product === row.product);
      if (!sourceStock || sourceStock.qty < row.qty) {
        alert(`Insufficient stock for ${row.product} in the selected source godown. Available: ${sourceStock ? sourceStock.qty : 0}`);
        return;
      }
    }

    const payload = {
      ...header,
      qty: totals.qty,
      items: rows
    };

    try {
      await erpApi.saveTransfer(payload);
      setMessage(`Transfer ${header.number} saved! Stock updated.`);
      setRows([{ id: Date.now(), fromGodownId: '', toGodownId: '', fromGodownName: '', toGodownName: '', productId: '', product: '', qty: 1, rate: 0, value: 0 }]);
      setHeader({ ...header, number: `TRF-${Date.now().toString().slice(-4)}`, remarks: '' });
      erpApi.getStock().then(setStockLedger).catch(() => {}); // Refresh stock ledger internally
      setTimeout(() => setMessage(''), 4000);
    } catch (error) {
      alert("Error saving transfer: " + (error.response?.data?.error || error.message));
    }
  };

  // Extract selected vehicle's drivers
  const selectedVehicle = vehicles.find(v => v.id === parseInt(header.vehicleId));
  const availableDrivers = selectedVehicle?.drivers || [];

  return (
    <div className="space-y-[14px]">
      
      {/* HEADER SECTION */}
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-orange-500 uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
          <span className="w-[9px] h-[9px] rounded-full bg-orange-500 shadow-[0_0_0_5px_rgba(249,115,22,0.14)]"></span>
          Stock Transfer Entry
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-5 gap-[14px]">
          <div>
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Transfer No</label>
            <input 
              readOnly 
              value={header.number}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-slate-50 border border-slate-200 rounded-[14px] text-[14px] font-bold shadow-sm outline-none" 
            />
          </div>
          
          <div>
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Date</label>
            <input 
              type="date"
              value={header.date}
              onChange={(e) => setHeader({...header, date: e.target.value})}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-orange-400 focus:ring-[4px] focus:ring-orange-400/15 shadow-sm" 
            />
          </div>

          <div>
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Vehicle *</label>
            <select 
              value={header.vehicleId}
              onChange={(e) => setHeader({...header, vehicleId: e.target.value ? parseInt(e.target.value) : '', driverName: ''})}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-orange-400 focus:ring-[4px] focus:ring-orange-400/15 shadow-sm"
            >
              <option value="">Select Vehicle</option>
              {vehicles.map(v => <option key={v.id} value={v.id}>{v.no} {v.name ? `(${v.name})` : ''}</option>)}
            </select>
          </div>

          <div>
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Driver</label>
            <select 
              value={header.driverName}
              onChange={(e) => setHeader({...header, driverName: e.target.value})}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-orange-400 focus:ring-[4px] focus:ring-orange-400/15 shadow-sm"
            >
              <option value="">Select Driver</option>
              {Array.isArray(availableDrivers) && availableDrivers.map((d, i) => <option key={i} value={d.name}>{d.name}</option>)}
            </select>
          </div>

          <div>
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Remarks</label>
            <input 
              value={header.remarks}
              onChange={(e) => setHeader({...header, remarks: e.target.value})}
              placeholder="Optional notes"
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-orange-400 focus:ring-[4px] focus:ring-orange-400/15 shadow-sm" 
            />
          </div>
        </div>
      </div>

      {/* DYNAMIC ROWS SECTION */}
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        <table className="w-full text-left border-spacing-y-2 border-separate min-w-[1000px]">
          <thead>
            <tr>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[5%]">S.No</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[15%]">From Godown</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[15%]">To Godown</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[25%]">Product Name</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%]">Qty</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%]">Rate</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%]">Value</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%]"></th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row, index) => {
              const srcStock = stockLedger.find(s => s.godownId === row.fromGodownId && s.product === row.product);
              const availableQty = srcStock ? srcStock.qty : 0;
              const isError = row.qty > availableQty;

              return (
                <tr key={row.id}>
                  <td className="px-2 font-bold text-slate-400">{index + 1}</td>
                  <td className="px-1">
                    <select
                      value={row.fromGodownId}
                      onChange={(e) => updateRow(row.id, 'fromGodownId', e.target.value ? parseInt(e.target.value) : '')}
                      className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-orange-400 focus:ring-[3px] focus:ring-orange-400/20"
                    >
                      <option value="">Select Source</option>
                      {godowns.map(g => <option key={g.id} value={g.id}>{g.name}</option>)}
                    </select>
                  </td>
                  <td className="px-1">
                    <select
                      value={row.toGodownId}
                      onChange={(e) => updateRow(row.id, 'toGodownId', e.target.value ? parseInt(e.target.value) : '')}
                      className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-orange-400 focus:ring-[3px] focus:ring-orange-400/20"
                    >
                      <option value="">Select Dest</option>
                      {godowns.map(g => <option key={g.id} value={g.id}>{g.name}</option>)}
                    </select>
                  </td>
                  <td className="px-1">
                    <input 
                      list="productCodes"
                      placeholder="Product Code or Name"
                      value={row.product}
                      onChange={(e) => {
                        handleProductSelect(row.id, e.target.value.toUpperCase());
                        updateRow(row.id, 'product', e.target.value);
                      }}
                      className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-orange-400 focus:ring-[3px] focus:ring-orange-400/20"
                    />
                    <datalist id="productCodes">
                      {products.map(p => <option key={p.id} value={p.code}>{p.name}</option>)}
                    </datalist>
                    {row.product && row.fromGodownId && (
                       <div className={`text-[10px] mt-1 ml-1 font-bold ${isError ? 'text-red-500' : 'text-slate-400'}`}>
                         Stock Available: {availableQty}
                       </div>
                    )}
                  </td>
                  <td className="px-1">
                    <input 
                      type="number"
                      value={row.qty}
                      onChange={(e) => updateRow(row.id, 'qty', parseInt(e.target.value) || 0)}
                      className={`w-full px-3 py-2 border ${isError ? 'border-red-400 bg-red-50 text-red-600' : 'border-slate-200'} rounded-[10px] text-[13px] font-bold focus:border-orange-400 focus:ring-[3px] focus:ring-orange-400/20`}
                    />
                  </td>
                  <td className="px-1">
                    <input 
                      type="number"
                      value={row.rate}
                      readOnly
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-[13px] font-bold text-slate-500 outline-none"
                    />
                  </td>
                  <td className="px-1">
                    <input 
                      readOnly
                      value={row.value}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-[13px] font-black text-slate-800 outline-none text-right"
                    />
                  </td>
                  <td className="px-1 flex gap-1 justify-end">
                    <button onClick={addRow} className="bg-orange-50 text-orange-600 px-3 py-2 rounded-[10px] font-bold hover:bg-orange-500 hover:text-white transition-all">+</button>
                    <button onClick={() => removeRow(row.id)} className="bg-slate-100 text-slate-600 px-3 py-2 rounded-[10px] font-bold hover:bg-slate-300 transition-all">-</button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* TOTALS & ACTIONS */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-[14px]">
        <div className="lg:col-span-8 bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
           <h2 className="text-[13px] font-black text-slate-400 uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
            Transfer Summary
          </h2>
          <div className="grid grid-cols-3 gap-4">
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-100">
              <p className="text-xs font-bold text-slate-400 uppercase mb-1">Total Qty To Transfer</p>
              <p className="text-2xl font-black text-slate-700">{totals.qty}</p>
            </div>
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-100">
              <p className="text-xs font-bold text-slate-400 uppercase mb-1">Line Items</p>
              <p className="text-2xl font-black text-slate-700">{rows.length}</p>
            </div>
            <div className="bg-slate-50 p-4 rounded-xl border border-slate-100">
              <p className="text-xs font-bold text-slate-400 uppercase mb-1">Status</p>
              <p className="text-2xl font-black text-orange-500">Draft</p>
            </div>
          </div>
        </div>

        <div className="lg:col-span-4 bg-gradient-to-br from-orange-600 to-orange-500 rounded-[26px] p-[24px] text-white shadow-[0_24px_58px_rgba(249,115,22,0.3)] flex flex-col justify-center">
          <button 
            onClick={handleSave}
            className="w-full bg-white text-orange-600 font-black text-[15px] py-[14px] rounded-[16px] shadow-[0_12px_24px_rgba(0,0,0,0.1)] hover:-translate-y-[2px] transition-all"
          >
            CONFIRM & TRANSFER
          </button>
          
          {message && <div className="mt-4 text-center text-sm font-bold bg-white/20 p-2 rounded-xl">{message}</div>}
        </div>
      </div>
    </div>
  );
}
