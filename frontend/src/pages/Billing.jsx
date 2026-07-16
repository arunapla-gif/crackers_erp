import React, { useState, useEffect } from 'react';
import Select from 'react-select';
import { useStore } from '../store/useStore';
import { erpApi } from '../api/erpApi';

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
    cursor: 'pointer',
    '&:active': {
      backgroundColor: 'var(--active)'
    }
  }),
  singleValue: (base) => ({
    ...base,
    color: '#334155',
    fontWeight: '800'
  }),
  input: (base) => ({
    ...base,
    color: '#334155',
    fontWeight: '800'
  })
};

export default function Billing() {
  const currentType = useStore(state => state.currentType);
  const rows = useStore(state => state.rows);
  const chargeRows = useStore(state => state.chargeRows) || [];
  const totals = useStore(state => state.totals);
  const billState = useStore(state => state.billState);
  const originState = useStore(state => state.originState);
  const setOriginState = useStore(state => state.setOriginState);
  
  const addRow = useStore(state => state.addRow);
  const removeRow = useStore(state => state.removeRow);
  const updateRow = useStore(state => state.updateRow);
  const addChargeRow = useStore(state => state.addChargeRow);
  const removeChargeRow = useStore(state => state.removeChargeRow);
  const updateChargeRow = useStore(state => state.updateChargeRow);
  const setBillState = useStore(state => state.setBillState);
  const calculateTotals = useStore(state => state.calculateTotals);
  const clearCart = useStore(state => state.clearCart);

  const [products, setProducts] = useState([]);
  const [customers, setCustomers] = useState([]);
  const [transporters, setTransporters] = useState([]);
  const [profiles, setProfiles] = useState([]);
  
  const [invoiceHeader, setInvoiceHeader] = useState({
    series: '',
    number: '',
    date: new Date().toISOString().split('T')[0],
    customer: '',
    customerAddress: '',
    vehicleNo: '',
    distance: '',
    transporterId: '',
    ewayBillNo: '',
    companyProfileId: '',
    companyProfileName: '',
    dispatchAddress: ''
  });

  const [message, setMessage] = useState('');

  const getNextNumber = (profileId, seriesPrefix, profileList) => {
    if (!profileId || !seriesPrefix) return '';
    const prof = (profileList || profiles).find(p => p.id.toString() === String(profileId));
    if (prof && prof.billingSeries) {
      const s = prof.billingSeries.find(bs => bs.prefix === seriesPrefix);
      if (s) return String(s.lastNumber + 1).padStart(4, '0');
    }
    return '';
  };

  // Fetch dropdown data on mount
  useEffect(() => {
    erpApi.getProducts().then(setProducts).catch(() => {});
    erpApi.getCustomers().then(data => setCustomers(data.filter(c => c.status !== 'Inactive'))).catch(() => {});
    erpApi.getTransporters().then(data => setTransporters(data.filter(t => t.status !== 'Inactive'))).catch(() => {});
    erpApi.getCompanyProfiles().then(data => {
      const activeProfiles = data.filter(p => p.status !== 'Inactive');
      setProfiles(activeProfiles);
      if (activeProfiles.length > 0) {
        const p = activeProfiles[0];
        let initialAddress = `${p.address}, ${p.city}, ${p.district}, ${p.state} - ${p.pincode}`;
        let defaultSeries = p.billingSeries && p.billingSeries.length > 0 ? p.billingSeries[0].prefix : '';
        let nextNo = getNextNumber(p.id, defaultSeries, activeProfiles);
        setInvoiceHeader(prev => ({ ...prev, companyProfileId: p.id, companyProfileName: p.name, dispatchAddress: initialAddress, series: defaultSeries, number: nextNo }));
        setOriginState(p.state);
      }
    }).catch(() => {});
  }, [setOriginState]);

  // Recalculate totals if currentType changes
  useEffect(() => {
    calculateTotals();
  }, [currentType, calculateTotals]);

  const handleProductSelect = (id, productCode) => {
    const product = products.find(p => p.code === productCode);
    if (product) {
      updateRow(id, 'product', product.name);
      updateRow(id, 'productId', product.id);
      updateRow(id, 'hsn', product.hsn);
      updateRow(id, 'tax', parseFloat(product.tax));
      updateRow(id, 'rate', parseFloat(product.rate));
    }
  };

  const fetchInvoiceTaxForRow = async (id, series, number) => {
    if (!number) {
      alert("Enter invoice number first.");
      return;
    }
    // Search exactly for what the user typed (e.g., "0001" or "SGFI-0001")
    const invNo = number.trim();
    try {
      const record = await erpApi.getInvoice(invNo);
      if (record) {
        updateChargeRow(id, 'name', `Invoice Tax ${record.number}`);
        updateChargeRow(id, 'source', 'INVOICE_TAX');
        updateChargeRow(id, 'mode', 'ADD');
        updateChargeRow(id, 'type', 'AMOUNT');
        updateChargeRow(id, 'value', parseFloat(record.tax));
      }
    } catch (e) {
      alert("Invoice tax record not found. Save the invoice first.");
    }
  };

  const handleSaveInvoice = async () => {
    if (!invoiceHeader.number) {
      alert("Invoice Number is required!");
      return;
    }
    
    const fullNumber = invoiceHeader.series + invoiceHeader.number;

    const payload = {
      series: invoiceHeader.series,
      number: fullNumber,
      date: invoiceHeader.date,
      customer: invoiceHeader.customer,
      customerAddress: invoiceHeader.customerAddress,
      vehicleNo: invoiceHeader.vehicleNo,
      distance: invoiceHeader.distance,
      transporterId: invoiceHeader.transporterId,
      ewayBillNo: invoiceHeader.ewayBillNo,
      companyProfileId: invoiceHeader.companyProfileId || null,
      dispatchAddress: invoiceHeader.dispatchAddress || '',
      state: billState,
      subtotal: totals.subtotal,
      cgst: totals.cgst,
      sgst: totals.sgst,
      igst: totals.igst,
      tax: totals.tax,
      grand_total: totals.grandTotal,
      items: rows.map(r => ({
        productId: r.productId || null,
        product: r.product,
        hsn: r.hsn,
        qty: parseInt(r.qty),
        rate: parseFloat(r.rate),
        tax: parseFloat(r.tax),
        total: parseFloat(r.amount)
      })),
      charges: currentType !== 'INV' ? chargeRows.map(c => ({
        name: c.name,
        source: c.source,
        mode: c.mode,
        type: c.type,
        value: parseFloat(c.value),
        amount: parseFloat(c.amount)
      })).filter(c => c.name || c.amount !== 0) : []
    };

    try {
      await erpApi.saveInvoice(payload);
      setMessage(`Document ${fullNumber} saved successfully!`);
      clearCart();
      
      const updatedProfiles = await erpApi.getCompanyProfiles();
      setProfiles(updatedProfiles);
      const nextNo = getNextNumber(invoiceHeader.companyProfileId, invoiceHeader.series, updatedProfiles);
      
      setInvoiceHeader(prev => ({
        ...prev,
        customer: '',
        customerAddress: '',
        vehicleNo: '',
        distance: '',
        transporterId: '',
        ewayBillNo: '',
        dispatchAddress: '',
        number: nextNo
      }));

      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      alert(`Error saving document: ${error.response?.data?.error || error.message}`);
    }
  };

  const handleGenerateEwayBill = async (mode) => {
    if (!invoiceHeader.number) {
      alert("Please save the invoice with a number first!");
      return;
    }
    
    // Auto-save invoice first to ensure database has latest data
    await handleSaveInvoice();
    
    setMessage(`Generating ${mode === 'PART_A' ? 'Part-A ' : 'Full '}E-Way Bill via GSTZen...`);
    try {
      const result = await erpApi.generateEwayBill(invoiceHeader.number, mode);
      if (result.ewayBillNo) {
        setInvoiceHeader({...invoiceHeader, ewayBillNo: result.ewayBillNo});
        setMessage(`Success! E-Way Bill Generated: ${result.ewayBillNo}`);
      }
    } catch (error) {
      alert(`Error generating E-Way Bill: ${error.response?.data?.error || error.message}`);
      setMessage("");
    }
  };

  return (
    <div className="space-y-[14px]">
      
      {/* HEADER SECTION */}
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Billing Details
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-12 gap-[14px]">
          <div className="col-span-1 md:col-span-12">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Billing From (Branch / GSTIN)</label>
            <Select
              styles={selectStyles}
              options={profiles.map(p => ({ value: p.id, label: `${p.name} - ${p.gstin} (${p.state})`, profile: p }))}
              value={invoiceHeader.companyProfileId ? { value: invoiceHeader.companyProfileId, label: invoiceHeader.companyProfileName } : null}
              onChange={(selected) => {
                if (!selected) {
                  setInvoiceHeader({ ...invoiceHeader, companyProfileName: '', companyProfileId: '', dispatchAddress: '', series: '', number: '' });
                  return;
                }
                const profile = selected.profile;
                let newDispatchAddress = `${profile.address}, ${profile.city}, ${profile.district}, ${profile.state} - ${profile.pincode}`;
                let defaultSeries = profile.billingSeries && profile.billingSeries.length > 0 ? profile.billingSeries[0].prefix : '';
                let nextNo = getNextNumber(profile.id, defaultSeries, profiles);
                setOriginState(profile.state);
                setInvoiceHeader({ ...invoiceHeader, companyProfileName: selected.label, companyProfileId: profile.id, dispatchAddress: newDispatchAddress, series: defaultSeries, number: nextNo });
              }}
              placeholder="Search Branch..."
              isClearable
            />
            
            {(() => {
              const activeProfile = profiles.find(p => p.id.toString() === String(invoiceHeader.companyProfileId));
              if (activeProfile && activeProfile.addresses && activeProfile.addresses.length > 0) {
                return (
                  <div className="mt-3">
                    <label className="block text-[11px] font-[800] text-indigo-700 mb-[3px]">Select Dispatch Address (Multiple Places Found)</label>
                    <select
                      value={invoiceHeader.dispatchAddress}
                      onChange={(e) => setInvoiceHeader({...invoiceHeader, dispatchAddress: e.target.value})}
                      className="w-full h-[43px] px-[12px] bg-white border border-indigo-200 rounded-[14px] text-[13px] font-bold text-slate-700 focus:outline-none focus:border-indigo-400 focus:ring-[4px] focus:ring-indigo-400/20 shadow-sm appearance-none bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2224%22%20height%3D%2224%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%234f46e5%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%3E%3Cpolyline%20points%3D%226%209%2012%2015%2018%209%22%3E%3C%2Fpolyline%3E%3C%2Fsvg%3E')] bg-[length:16px_16px] bg-[position:right_12px_center] bg-no-repeat pr-[36px]"
                    >
                      <option value={`${activeProfile.address}, ${activeProfile.city}, ${activeProfile.district}, ${activeProfile.state} - ${activeProfile.pincode}`}>
                        Principal Place - {activeProfile.address}, {activeProfile.city}
                      </option>
                      {activeProfile.addresses.map((addr, idx) => (
                        <option key={idx} value={`${addr.address}, ${addr.city}, ${addr.district}, ${addr.state} - ${addr.pincode}`}>
                          {addr.type} - {addr.address}, {addr.city}
                        </option>
                      ))}
                    </select>
                  </div>
                );
              }
              return null;
            })()}
          </div>

          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Customer</label>
            <Select
              styles={selectStyles}
              options={customers.map(c => ({ value: c.id, label: c.name, customerObj: c }))}
              value={invoiceHeader.customer ? { label: invoiceHeader.customer, value: invoiceHeader.customer } : null}
              onChange={(selected) => {
                if (!selected) {
                  setInvoiceHeader({ ...invoiceHeader, customer: '', customerAddress: '' });
                  return;
                }
                const custObj = selected.customerObj;
                setInvoiceHeader({
                  ...invoiceHeader, 
                  customer: selected.label,
                  customerAddress: custObj && custObj.addresses && custObj.addresses.length > 0 ? custObj.addresses[0].address : (custObj?.address || '')
                });
                if (custObj?.state) {
                  setBillState(custObj.state);
                }
              }}
              placeholder="Search Customer..."
              isClearable
            />

            {(() => {
              const custObj = customers.find(c => c.name === invoiceHeader.customer);
              if (custObj && custObj.addresses && custObj.addresses.length > 1) {
                return (
                  <div className="mt-2">
                    <label className="block text-[11px] font-[800] text-active mb-[3px]">Select Billing Address</label>
                    <select
                      value={invoiceHeader.customerAddress}
                      onChange={(e) => setInvoiceHeader({...invoiceHeader, customerAddress: e.target.value})}
                      className="w-full h-[43px] px-[12px] bg-white border border-active/40 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm appearance-none bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2224%22%20height%3D%2224%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%23334155%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%3E%3Cpolyline%20points%3D%226%209%2012%2015%2018%209%22%3E%3C%2Fpolyline%3E%3C%2Fsvg%3E')] bg-[length:16px_16px] bg-[position:right_12px_center] bg-no-repeat pr-[36px]"
                    >
                      {custObj.addresses.map((addr, idx) => (
                        <option key={idx} value={addr.address}>{addr.type} - {addr.address}</option>
                      ))}
                    </select>
                  </div>
                );
              }
              return null;
            })()}
          </div>
          
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">State of Supply</label>
            <select 
              value={billState} 
              onChange={(e) => setBillState(e.target.value)}
              className="w-full h-[43px] px-[12px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm appearance-none bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2224%22%20height%3D%2224%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%23334155%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%3E%3Cpolyline%20points%3D%226%209%2012%2015%2018%209%22%3E%3C%2Fpolyline%3E%3C%2Fsvg%3E')] bg-[length:16px_16px] bg-[position:right_12px_center] bg-no-repeat pr-[36px]"
            >
              <option>Tamil Nadu</option>
              <option>Karnataka</option>
              <option>Kerala</option>
              <option>Maharashtra</option>
            </select>
          </div>

          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Date</label>
            <input 
              type="date"
              value={invoiceHeader.date}
              onChange={(e) => setInvoiceHeader({...invoiceHeader, date: e.target.value})}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
            />
          </div>

          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Series</label>
            <select 
              value={invoiceHeader.series}
              onChange={(e) => {
                const newSeries = e.target.value;
                const nextNo = getNextNumber(invoiceHeader.companyProfileId, newSeries, profiles);
                setInvoiceHeader({...invoiceHeader, series: newSeries, number: nextNo});
              }}
              className="w-full h-[43px] px-[12px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm appearance-none bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2224%22%20height%3D%2224%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%23334155%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%3E%3Cpolyline%20points%3D%226%209%2012%2015%2018%209%22%3E%3C%2Fpolyline%3E%3C%2Fsvg%3E')] bg-[length:16px_16px] bg-[position:right_12px_center] bg-no-repeat pr-[36px]"
            >
              <option value="">Select Series</option>
              {(() => {
                const activeProfile = profiles.find(p => p.id.toString() === String(invoiceHeader.companyProfileId));
                if (activeProfile && activeProfile.billingSeries) {
                  return activeProfile.billingSeries.map(s => (
                    <option key={s.id} value={s.prefix}>{s.prefix} ({s.name})</option>
                  ));
                }
                return null;
              })()}
            </select>
          </div>

          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Doc Number</label>
            <input 
              value={invoiceHeader.number}
              onChange={(e) => setInvoiceHeader({...invoiceHeader, number: e.target.value})}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm font-bold" 
            />
          </div>

          <div className="col-span-1 md:col-span-12 mt-2">
            <h3 className="text-[11px] font-bold text-slate-400 uppercase tracking-wider border-b border-slate-200 pb-1">Transporter & E-Way Bill</h3>
          </div>
          
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Vehicle No</label>
            <input 
              value={invoiceHeader.vehicleNo}
              onChange={(e) => setInvoiceHeader({...invoiceHeader, vehicleNo: e.target.value})}
              placeholder="TN-00-XX-0000"
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm font-bold text-slate-700" 
            />
          </div>
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Distance (Km)</label>
            <input 
              type="number"
              value={invoiceHeader.distance}
              onChange={(e) => setInvoiceHeader({...invoiceHeader, distance: e.target.value})}
              placeholder="0"
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm font-bold text-slate-700" 
            />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Transporter ID / GSTIN</label>
            <Select
              styles={selectStyles}
              options={transporters.map(t => ({ value: t.gstin, label: `${t.name} (${t.gstin})` }))}
              value={invoiceHeader.transporterId ? { value: invoiceHeader.transporterId, label: transporters.find(t => t.gstin === invoiceHeader.transporterId)?.name ? `${transporters.find(t => t.gstin === invoiceHeader.transporterId).name} (${invoiceHeader.transporterId})` : invoiceHeader.transporterId } : null}
              onChange={(selected) => setInvoiceHeader({...invoiceHeader, transporterId: selected ? selected.value : ''})}
              placeholder="Search Transporter..."
              isClearable
            />
          </div>
          <div className="col-span-1 md:col-span-4 flex flex-col justify-end gap-1">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">E-Way Bill Number</label>
            <div className="flex flex-col sm:flex-row gap-2">
              <input 
                value={invoiceHeader.ewayBillNo}
                onChange={(e) => setInvoiceHeader({...invoiceHeader, ewayBillNo: e.target.value})}
                placeholder="12 digit EWB No"
                maxLength={12}
                className="w-full min-h-[43px] px-[12px] py-[11px] bg-[#f8fafc] border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-inner font-black text-slate-800" 
              />
              <div className="flex gap-1 w-full sm:w-auto">
                <button 
                  onClick={() => handleGenerateEwayBill('PART_A')}
                  title="Generate Part A Only (No Vehicle Needed)"
                  className="flex-1 sm:flex-none bg-slate-700 text-white min-h-[43px] px-3 rounded-[14px] text-[11px] font-bold shadow-md hover:bg-slate-800 hover:shadow-lg transition-all whitespace-nowrap border-b-2 border-slate-900 active:border-b-0 active:translate-y-[2px]"
                >
                  Part A 📄
                </button>
                <button 
                  onClick={() => handleGenerateEwayBill('FULL')}
                  title="Generate Full E-Way Bill (Vehicle Required)"
                  className="flex-1 sm:flex-none bg-active text-white min-h-[43px] px-3 rounded-[14px] text-[11px] font-bold shadow-md hover:bg-active-dark hover:shadow-lg transition-all whitespace-nowrap border-b-2 border-active-dark active:border-b-0 active:translate-y-[2px]"
                >
                  Full 🚀
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* DYNAMIC ROWS SECTION (Responsive Cards on Mobile) */}
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-4 md:p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-slate-800 uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4 md:hidden">
          Products / Items
        </h2>

        <datalist id="productCodes">{products.map(p => <option key={p.id} value={p.code}>{p.name}</option>)}</datalist>
        
        {/* Desktop Table View */}
        <div className="hidden md:block overflow-x-auto">
          <table className="w-full text-left border-spacing-y-2 border-separate min-w-[800px]">
            <thead>
              <tr>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[5%]">S.No</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[15%]">Code</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[30%]">Product Name</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%]">HSN</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%]">Qty</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%]">Rate</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%]">Amount</th>
                <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%]"></th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row, index) => (
                <tr key={row.id}>
                  <td className="px-2 font-bold text-slate-400">{index + 1}</td>
                  <td className="px-1">
                    <input list="productCodes" placeholder="SP01" className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] uppercase focus:border-active focus:ring-[3px] focus:ring-active/20" onChange={(e) => handleProductSelect(row.id, e.target.value.toUpperCase())} />
                  </td>
                  <td className="px-1">
                    <input value={row.product} onChange={(e) => updateRow(row.id, 'product', e.target.value)} placeholder="Product description" className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-active focus:ring-[3px] focus:ring-active/20" />
                  </td>
                  <td className="px-1">
                    <input value={row.hsn} onChange={(e) => updateRow(row.id, 'hsn', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-active focus:ring-[3px] focus:ring-active/20" />
                  </td>
                  <td className="px-1">
                    <input type="number" value={row.qty} onChange={(e) => updateRow(row.id, 'qty', parseInt(e.target.value) || 0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-bold focus:border-active focus:ring-[3px] focus:ring-active/20" />
                  </td>
                  <td className="px-1">
                    <input type="number" value={row.rate} onChange={(e) => updateRow(row.id, 'rate', parseFloat(e.target.value) || 0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-active focus:ring-[3px] focus:ring-active/20" />
                  </td>
                  <td className="px-1">
                    <input readOnly value={row.amount} className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-[13px] font-black text-slate-800 outline-none" />
                  </td>
                  <td className="px-1 flex gap-1">
                    <button onClick={addRow} className="bg-active-soft text-active-dark px-3 py-2 rounded-[10px] font-bold hover:bg-active hover:text-white transition-all">+</button>
                    <button onClick={() => removeRow(row.id)} className="bg-slate-100 text-slate-600 px-3 py-2 rounded-[10px] font-bold hover:bg-slate-300 transition-all">-</button>
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
                  list="productCodes" 
                  placeholder="Code (SP01)" 
                  className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] uppercase focus:border-active mb-2" 
                  onChange={(e) => handleProductSelect(row.id, e.target.value.toUpperCase())} 
                />
                
                <input 
                  value={row.product} 
                  onChange={(e) => updateRow(row.id, 'product', e.target.value)} 
                  placeholder="Product description" 
                  className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-active" 
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Qty</label>
                  <input type="number" value={row.qty} onChange={(e) => updateRow(row.id, 'qty', parseInt(e.target.value) || 0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-bold" />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Rate</label>
                  <input type="number" value={row.rate} onChange={(e) => updateRow(row.id, 'rate', parseFloat(e.target.value) || 0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px]" />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">HSN</label>
                  <input value={row.hsn} onChange={(e) => updateRow(row.id, 'hsn', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px]" />
                </div>
                <div>
                  <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Amount</label>
                  <input readOnly value={row.amount} className="w-full px-3 py-2 bg-emerald-50 border border-emerald-100 text-emerald-700 rounded-[10px] text-[13px] font-black outline-none" />
                </div>
              </div>
            </div>
          ))}
          <button onClick={addRow} className="w-full py-3 bg-slate-100 text-slate-600 rounded-[14px] font-black text-[12px] border border-dashed border-slate-300 hover:bg-slate-200">+ ADD NEW ITEM</button>
        </div>
      </div>

      {/* TOTALS & ACTIONS */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-[14px]">
        
        {/* Additional Charges / Left Panel */}
        <div className="lg:col-span-8 bg-white/88 backdrop-blur-[14px] rounded-[26px] p-4 md:p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 md:min-h-[300px]">
          {currentType === 'INV' ? (
            <div className="flex flex-col items-center justify-center h-full text-center py-8 md:p-6">
              <div className="w-[48px] h-[48px] rounded-full bg-slate-100 grid place-items-center mb-3">
                <span className="text-[20px] opacity-40">🔒</span>
              </div>
              <h3 className="font-black text-slate-400 text-sm uppercase tracking-wider">Tax Document Locked</h3>
              <p className="text-sm font-bold text-slate-500 mt-2 max-w-[250px]">Estimates and Performas support custom additional charges. Switch module to unlock.</p>
            </div>
          ) : (
            <div>
              <h2 className="text-[13px] font-black text-blue-500 uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
                <span className="w-[9px] h-[9px] rounded-full bg-blue-500 shadow-[0_0_0_5px_rgba(59,130,246,0.14)]"></span>
                Additional Charges
              </h2>
              
              {/* Desktop Charges Table */}
              <div className="hidden md:block overflow-x-auto">
                <table className="w-full text-left border-spacing-y-2 border-separate min-w-[700px]">
                  <thead>
                    <tr>
                      <th className="text-[11px] font-bold text-slate-500 uppercase px-2">Name</th>
                      <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[120px]">Type</th>
                      <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[100px]">Value</th>
                      <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[160px]">Fetch Past Tax</th>
                      <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[100px]">Amount</th>
                      <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[80px]"></th>
                    </tr>
                  </thead>
                  <tbody>
                    {chargeRows.map((row, i) => (
                      <tr key={row.id}>
                        <td className="px-1"><input value={row.name} onChange={e => updateChargeRow(row.id, 'name', e.target.value)} placeholder="Packing / Loading..." className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-blue-400" /></td>
                        <td className="px-1 flex gap-1">
                          <select value={row.mode} onChange={e => updateChargeRow(row.id, 'mode', e.target.value)} className="w-1/2 px-2 py-2 border border-slate-200 rounded-[10px] text-[12px] bg-white text-slate-600 focus:border-blue-400"><option value="ADD">+</option><option value="DEDUCT">-</option></select>
                          <select value={row.type} onChange={e => updateChargeRow(row.id, 'type', e.target.value)} className="w-1/2 px-2 py-2 border border-slate-200 rounded-[10px] text-[12px] bg-white text-slate-600 focus:border-blue-400"><option value="AMOUNT">₹</option><option value="PERCENT">%</option></select>
                        </td>
                        <td className="px-1"><input type="number" value={row.value} onChange={e => updateChargeRow(row.id, 'value', parseFloat(e.target.value)||0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-bold focus:border-blue-400" /></td>
                        <td className="px-1">
                          <div className="flex bg-slate-50 p-1 rounded-[10px] border border-slate-200">
                            <select value={row.series} onChange={e => updateChargeRow(row.id, 'series', e.target.value)} className="w-[50px] bg-transparent text-[11px] font-bold outline-none border-r border-slate-200 pr-1">
                              <option value="">-</option>
                              {(() => {
                                const activeProfile = profiles.find(p => p.id.toString() === String(invoiceHeader.companyProfileId));
                                if (activeProfile && activeProfile.billingSeries) {
                                  return activeProfile.billingSeries.map(s => <option key={s.id} value={s.prefix}>{s.prefix}</option>);
                                }
                                return null;
                              })()}
                            </select>
                            <input value={row.number} onChange={e => updateChargeRow(row.id, 'number', e.target.value)} placeholder="No." className="w-[45px] bg-transparent text-[12px] px-1 outline-none" />
                            <button onClick={() => fetchInvoiceTaxForRow(row.id, row.series, row.number)} className="bg-blue-600 text-white px-2 py-1 rounded-[6px] text-[10px] font-bold">GET</button>
                          </div>
                        </td>
                        <td className="px-1"><input readOnly value={row.amount} className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-[10px] text-[13px] font-black text-slate-800 outline-none text-right" /></td>
                        <td className="px-1 flex gap-1 justify-end">
                          <button onClick={addChargeRow} className="bg-blue-50 text-blue-600 px-3 py-2 rounded-[10px] font-bold hover:bg-blue-500 hover:text-white transition-all">+</button>
                          <button onClick={() => removeChargeRow(row.id)} className="bg-slate-100 text-slate-600 px-3 py-2 rounded-[10px] font-bold hover:bg-slate-300 transition-all">-</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* Mobile Charges Card View */}
              <div className="block md:hidden space-y-4">
                {chargeRows.map((row, i) => (
                  <div key={row.id} className="bg-slate-50 border border-slate-200 rounded-[20px] p-4 relative shadow-sm">
                    <div className="absolute top-4 right-4 flex gap-1">
                      <button onClick={() => removeChargeRow(row.id)} className="w-[28px] h-[28px] flex items-center justify-center bg-white border border-slate-200 text-slate-600 rounded-[8px] font-bold">-</button>
                    </div>
                    
                    <div className="mb-3 pr-10">
                      <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Charge #{i + 1}</span>
                      <input value={row.name} onChange={e => updateChargeRow(row.id, 'name', e.target.value)} placeholder="Packing / Loading..." className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-blue-400" />
                    </div>

                    <div className="grid grid-cols-2 gap-2 mb-2">
                      <div className="flex gap-1">
                        <select value={row.mode} onChange={e => updateChargeRow(row.id, 'mode', e.target.value)} className="w-1/2 px-2 py-2 border border-slate-200 rounded-[10px] text-[12px] bg-white text-slate-600"><option value="ADD">+</option><option value="DEDUCT">-</option></select>
                        <select value={row.type} onChange={e => updateChargeRow(row.id, 'type', e.target.value)} className="w-1/2 px-2 py-2 border border-slate-200 rounded-[10px] text-[12px] bg-white text-slate-600"><option value="AMOUNT">₹</option><option value="PERCENT">%</option></select>
                      </div>
                      <div>
                        <input type="number" value={row.value} onChange={e => updateChargeRow(row.id, 'value', parseFloat(e.target.value)||0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-bold" placeholder="Value" />
                      </div>
                    </div>
                    
                    <div className="flex bg-white p-1 rounded-[10px] border border-slate-200 mb-2">
                      <select value={row.series} onChange={e => updateChargeRow(row.id, 'series', e.target.value)} className="w-[60px] bg-transparent text-[11px] font-bold outline-none border-r border-slate-200 pr-1">
                        <option value="">-</option>
                        {(() => {
                          const activeProfile = profiles.find(p => p.id.toString() === String(invoiceHeader.companyProfileId));
                          if (activeProfile && activeProfile.billingSeries) {
                            return activeProfile.billingSeries.map(s => <option key={s.id} value={s.prefix}>{s.prefix}</option>);
                          }
                          return null;
                        })()}
                      </select>
                      <input value={row.number} onChange={e => updateChargeRow(row.id, 'number', e.target.value)} placeholder="Inv No." className="flex-1 bg-transparent text-[12px] px-2 outline-none" />
                      <button onClick={() => fetchInvoiceTaxForRow(row.id, row.series, row.number)} className="bg-blue-600 text-white px-3 py-1 rounded-[8px] text-[10px] font-bold">GET TAX</button>
                    </div>

                    <div>
                      <input readOnly value={row.amount} className="w-full px-3 py-2 bg-blue-50 border border-blue-100 text-blue-700 rounded-[10px] text-[13px] font-black outline-none" />
                    </div>
                  </div>
                ))}
                <button onClick={addChargeRow} className="w-full py-3 bg-blue-50 text-blue-600 rounded-[14px] font-black text-[12px] border border-dashed border-blue-200 hover:bg-blue-100">+ ADD NEW CHARGE</button>
              </div>

            </div>
          )}
        </div>

        {/* Totals Panel */}
        <div className="lg:col-span-4 bg-gradient-to-br from-active-dark to-active rounded-[26px] p-6 md:p-[24px] text-white shadow-[0_24px_58px_rgba(15,23,42,0.16)] flex flex-col justify-center md:min-h-[300px]">
          
          <div className="flex justify-between items-center mb-3 pb-3 border-b border-white/20">
            <span className="font-bold opacity-90 text-sm">Subtotal</span>
            <span className="font-black text-xl">₹{totals.subtotal.toFixed(2)}</span>
          </div>
          
          {currentType === 'INV' && (
            <>
              {totals.igst > 0 ? (
                <div className="flex justify-between items-center mb-3 pb-3 border-b border-white/20">
                  <span className="font-bold opacity-90 text-sm">IGST</span>
                  <span className="font-black text-xl">₹{totals.igst.toFixed(2)}</span>
                </div>
              ) : (
                <>
                  <div className="flex justify-between items-center mb-2 pb-2 border-b border-white/20">
                    <span className="font-bold opacity-90 text-sm">CGST</span>
                    <span className="font-black text-lg">₹{totals.cgst.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between items-center mb-3 pb-3 border-b border-white/20">
                    <span className="font-bold opacity-90 text-sm">SGST</span>
                    <span className="font-black text-lg">₹{totals.sgst.toFixed(2)}</span>
                  </div>
                </>
              )}
            </>
          )}

          {currentType !== 'INV' && (
            <div className="flex justify-between items-center mb-3 pb-3 border-b border-white/20">
              <span className="font-bold opacity-90 text-sm">Addl. Charges</span>
              <span className="font-black text-xl">₹{(totals.charges || 0).toFixed(2)}</span>
            </div>
          )}

          <div className="flex justify-between items-center mt-4">
            <span className="font-black text-xl md:text-2xl tracking-wide">TOTAL</span>
            <span className="font-black text-[32px] md:text-[38px] tracking-[-1px]">₹{totals.grandTotal.toFixed(2)}</span>
          </div>

          <button 
            onClick={handleSaveInvoice}
            className="w-full mt-6 bg-white text-active-dark font-black text-[15px] py-[16px] rounded-[16px] shadow-[0_12px_24px_rgba(0,0,0,0.15)] hover:-translate-y-[2px] transition-all"
          >
            SAVE DOCUMENT
          </button>
          
          {message && <div className="mt-4 text-center text-sm font-bold bg-white/20 p-2 rounded-xl">{message}</div>}
        </div>
      </div>
    </div>
  );
}
