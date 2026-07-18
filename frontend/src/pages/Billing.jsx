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
  
  const [invoiceHeader, setInvoiceHeader] = useState(() => {
    const saved = localStorage.getItem('crackers-erp-billing-header');
    if (saved) {
      try { return JSON.parse(saved); } catch (e) {}
    }
    return {
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
    };
  });

  const [message, setMessage] = useState('');
  const [isGatewayOpen, setIsGatewayOpen] = useState(false);

  // Persist header to localStorage on change
  useEffect(() => {
    localStorage.setItem('crackers-erp-billing-header', JSON.stringify(invoiceHeader));
  }, [invoiceHeader]);

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
      // Instead of auto-selecting, open the gateway if no company is selected
      if (activeProfiles.length > 0 && !invoiceHeader.companyProfileId) {
        setIsGatewayOpen(true);
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
      localStorage.removeItem('crackers-erp-billing-header');
      
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

  const clearDraft = () => {
    if (window.confirm("Are you sure you want to clear this draft? All progress will be lost.")) {
      clearCart();
      localStorage.removeItem('crackers-erp-billing-header');
      setInvoiceHeader({
        series: '', number: '', date: new Date().toISOString().split('T')[0],
        customer: '', customerAddress: '', vehicleNo: '', distance: '', transporterId: '',
        ewayBillNo: '', companyProfileId: '', companyProfileName: '', dispatchAddress: ''
      });
      // Show gateway again for the next bill
      setIsGatewayOpen(true);
    }
  };

  const handleGatewaySelect = (profile) => {
    let newDispatchAddress = `${profile.address}, ${profile.city}, ${profile.district}, ${profile.state} - ${profile.pincode}`;
    let defaultSeries = profile.billingSeries && profile.billingSeries.length > 0 ? profile.billingSeries[0].prefix : '';
    let nextNo = getNextNumber(profile.id, defaultSeries, profiles);
    setOriginState(profile.state);
    setInvoiceHeader({ 
      ...invoiceHeader, 
      companyProfileName: `${profile.name} - ${profile.gstin}`, 
      companyProfileId: profile.id, 
      dispatchAddress: newDispatchAddress, 
      series: defaultSeries, 
      number: nextNo 
    });
    setIsGatewayOpen(false);
  };

  if (isGatewayOpen) {
    return (
      <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-900/40 backdrop-blur-md p-4">
        <div className="bg-white rounded-[32px] p-8 md:p-12 shadow-[0_32px_80px_rgba(15,23,42,0.2)] max-w-[800px] w-full border border-white/50 animate-in fade-in zoom-in duration-300">
          <div className="text-center mb-10">
            <div className="w-16 h-16 bg-active/10 text-active rounded-full flex items-center justify-center text-3xl mx-auto mb-4 border border-active/20">
              🏢
            </div>
            <h1 className="text-3xl md:text-4xl font-black text-slate-800 tracking-tight">Select Billing Company</h1>
            <p className="text-sm font-bold text-slate-500 mt-2">Which company profile are you generating this {currentType === 'INV' ? 'Invoice' : currentType === 'EST' ? 'Estimate' : 'Performa'} from?</p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {profiles.map(profile => (
              <button
                key={profile.id}
                onClick={() => handleGatewaySelect(profile)}
                className="group relative overflow-hidden bg-white border-2 border-slate-200 rounded-[24px] p-6 text-left hover:border-active hover:shadow-[0_16px_40px_color-mix(in_srgb,var(--active)_15%,transparent)] transition-all duration-300 hover:-translate-y-1"
              >
                <div className="absolute top-0 right-0 w-24 h-24 bg-active opacity-0 group-hover:opacity-5 rounded-full blur-2xl transition-opacity duration-500 -mr-8 -mt-8"></div>
                
                <h3 className="text-lg font-black text-slate-800 group-hover:text-active transition-colors">{profile.name}</h3>
                <div className="inline-block mt-2 px-3 py-1 bg-slate-100 text-slate-600 rounded-lg text-xs font-black tracking-wider border border-slate-200">
                  GSTIN: {profile.gstin}
                </div>
                <p className="text-xs font-bold text-slate-400 mt-3 line-clamp-2 leading-relaxed">
                  {profile.address}, {profile.city}, {profile.state}
                </p>
                
                {/* Default Series Badge */}
                {profile.billingSeries && profile.billingSeries.length > 0 && (
                  <div className="mt-4 flex items-center gap-2 text-[10px] font-black text-active uppercase tracking-widest">
                    <span>Default Series: {profile.billingSeries[0].prefix}</span>
                  </div>
                )}
              </button>
            ))}
          </div>

          {/* Quick actions row */}
          <div className="mt-8 flex justify-center">
            {invoiceHeader.companyProfileId && (
              <button 
                onClick={() => setIsGatewayOpen(false)}
                className="text-sm font-bold text-slate-400 hover:text-slate-600 transition-colors underline underline-offset-4"
              >
                Cancel & return to draft
              </button>
            )}
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="grid grid-cols-1 xl:grid-cols-12 gap-[18px] items-start">
      
      {/* LEFT COLUMN: Header, Items, Charges */}
      <div className="xl:col-span-8 space-y-[18px]">
        
        {/* GROUPED HEADER CARDS */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-[14px]">
          
          {/* Card 1: Party Details */}
          <div className="bg-white rounded-[20px] p-[16px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200">
            <h3 className="text-[11px] font-black text-slate-400 uppercase tracking-widest mb-3 border-b border-slate-100 pb-2">Party Details</h3>
            
            <div className="space-y-[12px]">
              <div>
                <label className="block text-[11px] font-[800] text-[#334155] mb-[3px]">Billing Branch</label>
                <Select
                  styles={selectStyles}
                  options={profiles.map(p => ({ value: p.id, label: `${p.name} - ${p.gstin}`, profile: p }))}
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
                  placeholder="Select Branch..."
                  isClearable
                />
              </div>

              <div>
                <label className="block text-[11px] font-[800] text-[#334155] mb-[3px]">Customer</label>
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
                    if (custObj?.state) setBillState(custObj.state);
                  }}
                  placeholder="Search Customer..."
                  isClearable
                />
              </div>

              <div>
                <label className="block text-[11px] font-[800] text-[#334155] mb-[3px]">State of Supply</label>
                <select 
                  value={billState} 
                  onChange={(e) => setBillState(e.target.value)}
                  className="w-full h-[43px] px-[12px] bg-white border border-slate-300 rounded-[14px] text-[14px] font-bold text-slate-700 focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm appearance-none bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2224%22%20height%3D%2224%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%23334155%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%3E%3Cpolyline%20points%3D%226%209%2012%2015%2018%209%22%3E%3C%2Fpolyline%3E%3C%2Fsvg%3E')] bg-[length:16px_16px] bg-[position:right_12px_center] bg-no-repeat pr-[36px]"
                >
                  <option>Tamil Nadu</option>
                  <option>Karnataka</option>
                  <option>Kerala</option>
                  <option>Maharashtra</option>
                </select>
              </div>
            </div>
          </div>

          {/* Card 2: Document Details */}
          <div className="bg-white rounded-[20px] p-[16px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200">
            <h3 className="text-[11px] font-black text-slate-400 uppercase tracking-widest mb-3 border-b border-slate-100 pb-2">Document Info</h3>
            
            <div className="space-y-[12px]">
              <div>
                <label className="block text-[11px] font-[800] text-[#334155] mb-[3px]">Date</label>
                <input 
                  type="date"
                  value={invoiceHeader.date}
                  onChange={(e) => setInvoiceHeader({...invoiceHeader, date: e.target.value})}
                  className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] font-bold text-slate-700 focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
                />
              </div>

              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-[800] text-[#334155] mb-[3px]">Series</label>
                  <select 
                    value={invoiceHeader.series}
                    onChange={(e) => {
                      const newSeries = e.target.value;
                      const nextNo = getNextNumber(invoiceHeader.companyProfileId, newSeries, profiles);
                      setInvoiceHeader({...invoiceHeader, series: newSeries, number: nextNo});
                    }}
                    className="w-full h-[43px] px-[12px] bg-white border border-slate-300 rounded-[14px] text-[14px] font-bold text-slate-700 focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm appearance-none bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2224%22%20height%3D%2224%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%23334155%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%3E%3Cpolyline%20points%3D%226%209%2012%2015%2018%209%22%3E%3C%2Fpolyline%3E%3C%2Fsvg%3E')] bg-[length:16px_16px] bg-[position:right_12px_center] bg-no-repeat pr-[28px]"
                  >
                    <option value="">-</option>
                    {(() => {
                      const activeProfile = profiles.find(p => p.id.toString() === String(invoiceHeader.companyProfileId));
                      if (activeProfile && activeProfile.billingSeries) {
                        return activeProfile.billingSeries.map(s => <option key={s.id} value={s.prefix}>{s.prefix}</option>);
                      }
                      return null;
                    })()}
                  </select>
                </div>
                <div>
                  <label className="block text-[11px] font-[800] text-[#334155] mb-[3px]">Doc No</label>
                  <input 
                    value={invoiceHeader.number}
                    onChange={(e) => setInvoiceHeader({...invoiceHeader, number: e.target.value})}
                    className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] font-black text-slate-800 focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
                  />
                </div>
              </div>

              <div className="flex justify-end pt-2">
                <button onClick={clearDraft} className="text-[10px] font-bold text-rose-500 hover:text-rose-600 bg-rose-50 hover:bg-rose-100 px-3 py-1.5 rounded-lg transition-colors">
                  🗑️ Clear Draft
                </button>
              </div>
            </div>
          </div>

          {/* Card 3: Logistics */}
          <div className="bg-white rounded-[20px] p-[16px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200">
            <h3 className="text-[11px] font-black text-slate-400 uppercase tracking-widest mb-3 border-b border-slate-100 pb-2">Logistics & E-Way Bill</h3>
            
            <div className="space-y-[12px]">
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <label className="block text-[11px] font-[800] text-[#334155] mb-[3px]">Vehicle No</label>
                  <input 
                    value={invoiceHeader.vehicleNo}
                    onChange={(e) => setInvoiceHeader({...invoiceHeader, vehicleNo: e.target.value})}
                    placeholder="TN-00-XX-0000"
                    className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[13px] font-bold text-slate-700 focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
                  />
                </div>
                <div>
                  <label className="block text-[11px] font-[800] text-[#334155] mb-[3px]">Distance (Km)</label>
                  <input 
                    type="number"
                    value={invoiceHeader.distance}
                    onChange={(e) => setInvoiceHeader({...invoiceHeader, distance: e.target.value})}
                    placeholder="0"
                    className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[13px] font-bold text-slate-700 focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
                  />
                </div>
              </div>

              <div>
                <label className="block text-[11px] font-[800] text-[#334155] mb-[3px]">Transporter</label>
                <Select
                  styles={selectStyles}
                  options={transporters.map(t => ({ value: t.gstin, label: `${t.name} (${t.gstin})` }))}
                  value={invoiceHeader.transporterId ? { value: invoiceHeader.transporterId, label: transporters.find(t => t.gstin === invoiceHeader.transporterId)?.name ? `${transporters.find(t => t.gstin === invoiceHeader.transporterId).name} (${invoiceHeader.transporterId})` : invoiceHeader.transporterId } : null}
                  onChange={(selected) => setInvoiceHeader({...invoiceHeader, transporterId: selected ? selected.value : ''})}
                  placeholder="Select Transporter..."
                  isClearable
                />
              </div>

              <div>
                <label className="block text-[11px] font-[800] text-[#334155] mb-[3px]">E-Way Bill No</label>
                <div className="flex flex-col sm:flex-row gap-1">
                  <input 
                    value={invoiceHeader.ewayBillNo}
                    onChange={(e) => setInvoiceHeader({...invoiceHeader, ewayBillNo: e.target.value})}
                    placeholder="12 digit EWB No"
                    maxLength={12}
                    className="w-full min-h-[38px] px-[10px] bg-slate-50 border border-slate-300 rounded-[10px] text-[12px] focus:outline-none focus:border-active focus:ring-[3px] focus:ring-active/15 shadow-inner font-black text-slate-800" 
                  />
                  <div className="flex gap-1">
                    <button onClick={() => handleGenerateEwayBill('PART_A')} title="Generate Part A" className="bg-slate-700 text-white min-h-[38px] px-2 rounded-[10px] text-[10px] font-bold shadow-sm hover:bg-slate-800 transition-all whitespace-nowrap">
                      Part A
                    </button>
                    <button onClick={() => handleGenerateEwayBill('FULL')} title="Generate Full E-Way Bill" className="bg-active text-white min-h-[38px] px-2 rounded-[10px] text-[10px] font-bold shadow-sm hover:bg-active-dark transition-all whitespace-nowrap">
                      Full EWB
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ITEMS TABLE */}
        <div className="bg-white rounded-[24px] p-[16px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200">
          <h2 className="text-[13px] font-black text-slate-800 uppercase tracking-widest flex items-center gap-[10px] mb-4">
            Products / Items
          </h2>

          <datalist id="productCodes">{products.map(p => <option key={p.id} value={p.code}>{p.name}</option>)}</datalist>
          
          <div className="hidden md:block overflow-x-auto">
            <table className="w-full text-left border-spacing-y-[6px] border-separate min-w-[800px]">
              <thead>
                <tr>
                  <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-3 w-[5%] pb-1">S.No</th>
                  <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[15%] pb-1">Code</th>
                  <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[30%] pb-1">Product Name</th>
                  <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[10%] pb-1">HSN</th>
                  <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[10%] pb-1">Qty</th>
                  <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[10%] pb-1">Rate</th>
                  <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[10%] pb-1">Amount</th>
                  <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[10%] pb-1"></th>
                </tr>
              </thead>
              <tbody>
                {rows.map((row, index) => (
                  <tr key={row.id} className="group hover:bg-slate-50 transition-colors rounded-[12px]">
                    <td className="px-3 py-2 font-bold text-slate-400 text-sm rounded-l-[12px]">{index + 1}</td>
                    <td className="px-1 py-1">
                      <input list="productCodes" placeholder="SP01" className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-[10px] text-[13px] uppercase font-bold text-slate-700 focus:border-active focus:ring-[3px] focus:ring-active/20 transition-all shadow-sm group-hover:border-slate-300" onChange={(e) => handleProductSelect(row.id, e.target.value.toUpperCase())} />
                    </td>
                    <td className="px-1 py-1">
                      <input value={row.product} onChange={(e) => updateRow(row.id, 'product', e.target.value)} placeholder="Product description" className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-[10px] text-[13px] font-medium text-slate-700 focus:border-active focus:ring-[3px] focus:ring-active/20 transition-all shadow-sm group-hover:border-slate-300" />
                    </td>
                    <td className="px-1 py-1">
                      <input value={row.hsn} onChange={(e) => updateRow(row.id, 'hsn', e.target.value)} className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-[10px] text-[13px] font-medium text-slate-700 focus:border-active focus:ring-[3px] focus:ring-active/20 transition-all shadow-sm group-hover:border-slate-300" />
                    </td>
                    <td className="px-1 py-1">
                      <input type="number" value={row.qty} onChange={(e) => updateRow(row.id, 'qty', parseInt(e.target.value) || 0)} className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-[10px] text-[13px] font-black text-slate-700 focus:border-active focus:ring-[3px] focus:ring-active/20 transition-all shadow-sm group-hover:border-slate-300" />
                    </td>
                    <td className="px-1 py-1">
                      <input type="number" value={row.rate} onChange={(e) => updateRow(row.id, 'rate', parseFloat(e.target.value) || 0)} className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-[10px] text-[13px] font-bold text-slate-700 focus:border-active focus:ring-[3px] focus:ring-active/20 transition-all shadow-sm group-hover:border-slate-300" />
                    </td>
                    <td className="px-1 py-1">
                      <input readOnly value={row.amount} className="w-full px-3 py-2.5 bg-slate-100 border border-slate-200 rounded-[10px] text-[13px] font-black text-slate-800 outline-none shadow-inner" />
                    </td>
                    <td className="px-1 py-1 flex gap-1 rounded-r-[12px]">
                      <button onClick={addRow} className="bg-active-soft text-active-dark px-3 py-2.5 rounded-[10px] font-black hover:bg-active hover:text-white transition-all shadow-sm">+</button>
                      <button onClick={() => removeRow(row.id)} className="bg-white border border-slate-200 text-slate-600 px-3 py-2.5 rounded-[10px] font-black hover:bg-rose-50 hover:text-rose-600 hover:border-rose-200 transition-all shadow-sm">-</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="block md:hidden space-y-4">
            {rows.map((row, index) => (
              <div key={row.id} className="bg-slate-50 border border-slate-200 rounded-[20px] p-4 relative shadow-sm">
                <div className="absolute top-4 right-4 flex gap-1">
                  <button onClick={addRow} className="w-[28px] h-[28px] flex items-center justify-center bg-active-soft text-active-dark rounded-[8px] font-bold">+</button>
                  <button onClick={() => removeRow(row.id)} className="w-[28px] h-[28px] flex items-center justify-center bg-white border border-slate-200 text-slate-600 rounded-[8px] font-bold">-</button>
                </div>
                
                <div className="mb-3 pr-16">
                  <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Item #{index + 1}</span>
                  <input list="productCodes" placeholder="Code (SP01)" className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] uppercase focus:border-active mb-2 font-bold" onChange={(e) => handleProductSelect(row.id, e.target.value.toUpperCase())} />
                  <input value={row.product} onChange={(e) => updateRow(row.id, 'product', e.target.value)} placeholder="Product description" className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-active font-medium" />
                </div>

                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Qty</label>
                    <input type="number" value={row.qty} onChange={(e) => updateRow(row.id, 'qty', parseInt(e.target.value) || 0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-black" />
                  </div>
                  <div>
                    <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Rate</label>
                    <input type="number" value={row.rate} onChange={(e) => updateRow(row.id, 'rate', parseFloat(e.target.value) || 0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-bold" />
                  </div>
                  <div>
                    <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">HSN</label>
                    <input value={row.hsn} onChange={(e) => updateRow(row.id, 'hsn', e.target.value)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-medium" />
                  </div>
                  <div>
                    <label className="text-[10px] font-bold text-slate-500 uppercase ml-1">Amount</label>
                    <input readOnly value={row.amount} className="w-full px-3 py-2 bg-slate-100 border border-slate-200 text-slate-800 rounded-[10px] text-[13px] font-black outline-none shadow-inner" />
                  </div>
                </div>
              </div>
            ))}
            <button onClick={addRow} className="w-full py-3 bg-slate-50 text-slate-600 rounded-[14px] font-black text-[12px] border border-dashed border-slate-300 hover:bg-slate-100 transition-colors">+ ADD NEW ITEM</button>
          </div>
        </div>

        {/* ADDITIONAL CHARGES */}
        <div className="bg-white rounded-[24px] p-[16px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200">
          {currentType === 'INV' ? (
            <div className="flex flex-col items-center justify-center py-6 text-center">
              <div className="w-[40px] h-[40px] rounded-full bg-slate-50 border border-slate-100 grid place-items-center mb-3">
                <span className="text-[16px] opacity-40">🔒</span>
              </div>
              <h3 className="font-black text-slate-400 text-[11px] uppercase tracking-widest">Tax Document Locked</h3>
              <p className="text-[12px] font-bold text-slate-500 mt-1 max-w-[250px]">Estimates support custom charges.</p>
            </div>
          ) : (
            <div>
              <h2 className="text-[13px] font-black text-blue-500 uppercase tracking-widest flex items-center gap-[10px] mb-4">
                Additional Charges
              </h2>
              
              <div className="hidden md:block overflow-x-auto">
                <table className="w-full text-left border-spacing-y-[6px] border-separate min-w-[700px]">
                  <thead>
                    <tr>
                      <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 pb-1">Name</th>
                      <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[120px] pb-1">Type</th>
                      <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[100px] pb-1">Value</th>
                      <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[160px] pb-1">Fetch Past Tax</th>
                      <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[100px] pb-1">Amount</th>
                      <th className="text-[10px] font-black text-slate-400 uppercase tracking-wider px-2 w-[80px] pb-1"></th>
                    </tr>
                  </thead>
                  <tbody>
                    {chargeRows.map((row, i) => (
                      <tr key={row.id} className="group hover:bg-slate-50 transition-colors rounded-[12px]">
                        <td className="px-1 py-1 rounded-l-[12px]"><input value={row.name} onChange={e => updateChargeRow(row.id, 'name', e.target.value)} placeholder="Packing / Loading..." className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-[10px] text-[13px] font-medium focus:border-blue-400 focus:ring-[3px] focus:ring-blue-400/20 shadow-sm" /></td>
                        <td className="px-1 py-1 flex gap-1">
                          <select value={row.mode} onChange={e => updateChargeRow(row.id, 'mode', e.target.value)} className="w-1/2 px-2 py-2.5 border border-slate-200 rounded-[10px] text-[12px] font-bold bg-white text-slate-700 focus:border-blue-400"><option value="ADD">+</option><option value="DEDUCT">-</option></select>
                          <select value={row.type} onChange={e => updateChargeRow(row.id, 'type', e.target.value)} className="w-1/2 px-2 py-2.5 border border-slate-200 rounded-[10px] text-[12px] font-bold bg-white text-slate-700 focus:border-blue-400"><option value="AMOUNT">₹</option><option value="PERCENT">%</option></select>
                        </td>
                        <td className="px-1 py-1"><input type="number" value={row.value} onChange={e => updateChargeRow(row.id, 'value', parseFloat(e.target.value)||0)} className="w-full px-3 py-2.5 bg-white border border-slate-200 rounded-[10px] text-[13px] font-bold focus:border-blue-400 shadow-sm" /></td>
                        <td className="px-1 py-1">
                          <div className="flex bg-white p-1 rounded-[10px] border border-slate-200 shadow-sm">
                            <select value={row.series} onChange={e => updateChargeRow(row.id, 'series', e.target.value)} className="w-[50px] bg-transparent text-[11px] font-bold outline-none border-r border-slate-200 pr-1 text-slate-700">
                              <option value="">-</option>
                              {(() => {
                                const activeProfile = profiles.find(p => p.id.toString() === String(invoiceHeader.companyProfileId));
                                if (activeProfile && activeProfile.billingSeries) {
                                  return activeProfile.billingSeries.map(s => <option key={s.id} value={s.prefix}>{s.prefix}</option>);
                                }
                                return null;
                              })()}
                            </select>
                            <input value={row.number} onChange={e => updateChargeRow(row.id, 'number', e.target.value)} placeholder="No." className="w-[45px] bg-transparent text-[12px] px-1 outline-none font-bold text-slate-700" />
                            <button onClick={() => fetchInvoiceTaxForRow(row.id, row.series, row.number)} className="bg-blue-100 text-blue-700 hover:bg-blue-600 hover:text-white px-2 py-1 rounded-[6px] text-[10px] font-black transition-colors">GET</button>
                          </div>
                        </td>
                        <td className="px-1 py-1"><input readOnly value={row.amount} className="w-full px-3 py-2.5 bg-slate-100 border border-slate-200 rounded-[10px] text-[13px] font-black text-slate-800 outline-none text-right shadow-inner" /></td>
                        <td className="px-1 py-1 flex gap-1 justify-end rounded-r-[12px]">
                          <button onClick={addChargeRow} className="bg-blue-50 text-blue-600 px-3 py-2.5 rounded-[10px] font-black hover:bg-blue-500 hover:text-white transition-all shadow-sm">+</button>
                          <button onClick={() => removeChargeRow(row.id)} className="bg-white border border-slate-200 text-slate-600 px-3 py-2.5 rounded-[10px] font-black hover:bg-rose-50 hover:text-rose-600 hover:border-rose-200 transition-all shadow-sm">-</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="block md:hidden space-y-4">
                {chargeRows.map((row, i) => (
                  <div key={row.id} className="bg-slate-50 border border-slate-200 rounded-[20px] p-4 relative shadow-sm">
                    <div className="absolute top-4 right-4 flex gap-1">
                      <button onClick={() => removeChargeRow(row.id)} className="w-[28px] h-[28px] flex items-center justify-center bg-white border border-slate-200 text-slate-600 rounded-[8px] font-bold">-</button>
                    </div>
                    
                    <div className="mb-3 pr-10">
                      <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest block mb-1">Charge #{i + 1}</span>
                      <input value={row.name} onChange={e => updateChargeRow(row.id, 'name', e.target.value)} placeholder="Packing / Loading..." className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] focus:border-blue-400 font-medium" />
                    </div>

                    <div className="grid grid-cols-2 gap-2 mb-2">
                      <div className="flex gap-1">
                        <select value={row.mode} onChange={e => updateChargeRow(row.id, 'mode', e.target.value)} className="w-1/2 px-2 py-2 border border-slate-200 rounded-[10px] text-[12px] bg-white text-slate-700 font-bold"><option value="ADD">+</option><option value="DEDUCT">-</option></select>
                        <select value={row.type} onChange={e => updateChargeRow(row.id, 'type', e.target.value)} className="w-1/2 px-2 py-2 border border-slate-200 rounded-[10px] text-[12px] bg-white text-slate-700 font-bold"><option value="AMOUNT">₹</option><option value="PERCENT">%</option></select>
                      </div>
                      <div>
                        <input type="number" value={row.value} onChange={e => updateChargeRow(row.id, 'value', parseFloat(e.target.value)||0)} className="w-full px-3 py-2 border border-slate-200 rounded-[10px] text-[13px] font-bold" placeholder="Value" />
                      </div>
                    </div>
                    
                    <div className="flex bg-white p-1 rounded-[10px] border border-slate-200 mb-2">
                      <select value={row.series} onChange={e => updateChargeRow(row.id, 'series', e.target.value)} className="w-[60px] bg-transparent text-[11px] font-bold outline-none border-r border-slate-200 pr-1 text-slate-700">
                        <option value="">-</option>
                        {(() => {
                          const activeProfile = profiles.find(p => p.id.toString() === String(invoiceHeader.companyProfileId));
                          if (activeProfile && activeProfile.billingSeries) {
                            return activeProfile.billingSeries.map(s => <option key={s.id} value={s.prefix}>{s.prefix}</option>);
                          }
                          return null;
                        })()}
                      </select>
                      <input value={row.number} onChange={e => updateChargeRow(row.id, 'number', e.target.value)} placeholder="Inv No." className="flex-1 bg-transparent text-[12px] px-2 outline-none font-bold text-slate-700" />
                      <button onClick={() => fetchInvoiceTaxForRow(row.id, row.series, row.number)} className="bg-blue-100 text-blue-700 px-3 py-1 rounded-[8px] text-[10px] font-black">GET TAX</button>
                    </div>

                    <div>
                      <input readOnly value={row.amount} className="w-full px-3 py-2 bg-slate-100 border border-slate-200 text-slate-800 rounded-[10px] text-[13px] font-black outline-none shadow-inner" />
                    </div>
                  </div>
                ))}
                <button onClick={addChargeRow} className="w-full py-3 bg-slate-50 text-slate-600 rounded-[14px] font-black text-[12px] border border-dashed border-slate-300 hover:bg-slate-100 transition-colors">+ ADD NEW CHARGE</button>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* RIGHT COLUMN: Sticky Totals */}
      <div className="xl:col-span-4 sticky top-[100px]">
        <div className="bg-gradient-to-br from-active-dark to-active rounded-[24px] p-6 md:p-[24px] text-white shadow-[0_24px_58px_rgba(15,23,42,0.16)] flex flex-col justify-center">
          
          <div className="flex justify-between items-center mb-3 pb-3 border-b border-white/20">
            <span className="font-bold text-active-50 text-sm">Subtotal</span>
            <span className="font-black text-xl">₹{totals.subtotal.toFixed(2)}</span>
          </div>
          
          {currentType === 'INV' && (
            <>
              {totals.igst > 0 ? (
                <div className="flex justify-between items-center mb-3 pb-3 border-b border-white/20">
                  <span className="font-bold text-active-50 text-sm">IGST</span>
                  <span className="font-black text-xl">₹{totals.igst.toFixed(2)}</span>
                </div>
              ) : (
                <>
                  <div className="flex justify-between items-center mb-2 pb-2 border-b border-white/20">
                    <span className="font-bold text-active-50 text-sm">CGST</span>
                    <span className="font-black text-lg">₹{totals.cgst.toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between items-center mb-3 pb-3 border-b border-white/20">
                    <span className="font-bold text-active-50 text-sm">SGST</span>
                    <span className="font-black text-lg">₹{totals.sgst.toFixed(2)}</span>
                  </div>
                </>
              )}
            </>
          )}

          {currentType !== 'INV' && (
            <div className="flex justify-between items-center mb-3 pb-3 border-b border-white/20">
              <span className="font-bold text-active-50 text-sm">Addl. Charges</span>
              <span className="font-black text-xl">₹{(totals.charges || 0).toFixed(2)}</span>
            </div>
          )}

          <div className="flex justify-between items-center mt-4">
            <span className="font-black text-xl md:text-2xl tracking-wide">TOTAL</span>
            <span className="font-black text-[32px] md:text-[38px] tracking-[-1px]">₹{totals.grandTotal.toFixed(2)}</span>
          </div>

          <button 
            onClick={handleSaveInvoice}
            className="w-full mt-6 bg-white text-active-dark font-black text-[15px] py-[16px] rounded-[16px] shadow-[0_12px_24px_rgba(0,0,0,0.15)] hover:-translate-y-[2px] transition-transform active:scale-[0.98]"
          >
            SAVE DOCUMENT
          </button>
          
          {message && <div className="mt-4 text-center text-sm font-bold bg-white/20 p-2 rounded-xl backdrop-blur-sm">{message}</div>}
        </div>
      </div>

    </div>
  );
}
