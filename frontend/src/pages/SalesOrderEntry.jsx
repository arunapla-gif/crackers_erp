import React, { useState, useEffect } from 'react';
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
  
  const [customRates, setCustomRates] = useState({});
  const [cart, setCart] = useState({}); // { [productId]: qty }
  const [message, setMessage] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Fetch custom prices when customer changes
  useEffect(() => {
    const fetchCustomPrices = async () => {
      if (!selectedCustomerId || isNewCustomer) {
        setCustomRates({});
        return;
      }
      try {
        const prices = await erpApi.getCustomerPrices(selectedCustomerId);
        const pricesMap = {};
        prices.forEach(p => pricesMap[p.productId] = parseFloat(p.rate));
        setCustomRates(pricesMap);
      } catch (err) {
        console.error('Failed to fetch customer prices');
      }
    };
    fetchCustomPrices();
  }, [selectedCustomerId, isNewCustomer]);

  const updateCart = (productId, delta) => {
    setCart(prev => {
      const currentQty = prev[productId] || 0;
      const newQty = Math.max(0, currentQty + delta);
      const newCart = { ...prev };
      if (newQty === 0) delete newCart[productId];
      else newCart[productId] = newQty;
      return newCart;
    });
  };

  const setCartQty = (productId, qty) => {
    setCart(prev => {
      const newCart = { ...prev };
      if (qty <= 0) delete newCart[productId];
      else newCart[productId] = qty;
      return newCart;
    });
  };

  const getProductRate = (productId) => {
    const product = products.find(p => p.id === productId);
    if (!product) return 0;
    const standardRate = parseFloat(product.rate);
    const customRate = customRates[productId];
    return customRate !== undefined ? customRate : standardRate;
  };

  const cartItems = Object.keys(cart).map(idStr => {
    const productId = parseInt(idStr);
    const qty = cart[productId]; // This is Cases
    const product = products.find(p => p.id === productId);
    const rate = getProductRate(productId); // Rate per Box
    const boxesPerCase = product?.boxesPerCase || 1;
    return {
      productId,
      product: product?.name || '',
      qty,
      rate,
      total: rate * boxesPerCase * qty
    };
  });

  const subtotal = cartItems.reduce((sum, item) => sum + item.total, 0);

  const epProducts = products.filter(p => p.type === 'EP');
  
  const groupedProducts = epProducts.reduce((groups, p) => {
    const cat = p.category || 'UNCATEGORIZED';
    const subCat = p.subCategory || 'STANDARD';
    if (!groups[cat]) groups[cat] = {};
    if (!groups[cat][subCat]) groups[cat][subCat] = [];
    groups[cat][subCat].push(p);
    return groups;
  }, {});

  const handleSubmit = async () => {
    if (!isNewCustomer && !selectedCustomerId) {
      alert('Please select a customer or add a new one.');
      return;
    }
    if (isNewCustomer && !newCustomerData.name) {
      alert('New Customer Name is required.');
      return;
    }
    if (cartItems.length === 0) {
      alert('Add at least one product.');
      return;
    }

    const payload = {
      customerId: isNewCustomer ? null : selectedCustomerId,
      newCustomerData: isNewCustomer ? newCustomerData : null,
      subtotal,
      items: cartItems
    };

    setIsSubmitting(true);
    try {
      await erpApi.createSalesOrder(payload);
      setMessage('Order submitted successfully for approval!');
      setCart({});
      setSelectedCustomerId(null);
      setNewCustomerData({ name: '', mobile: '', city: '', state: '', gstin: '' });
      setIsNewCustomer(false);
      setTimeout(() => setMessage(''), 4000);
    } catch (e) {
      alert('Error submitting order: ' + (e.response?.data?.error || e.message));
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="max-w-[800px] mx-auto space-y-[18px]">
      
      {/* HEADER SECTION */}
      <div className="bg-white rounded-[24px] p-[20px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200">
        <h2 className="text-[16px] font-black text-active uppercase tracking-[1px] mb-4 flex justify-between items-center">
          <span>Create New Sales Order</span>
        </h2>
        
        {message && (
          <div className="mb-4 bg-green-50 text-green-700 p-4 rounded-[16px] font-black border border-green-200 text-[14px]">
            {message}
          </div>
        )}

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* Customer Selection */}
          <div className="col-span-1 md:col-span-2">
            <div className="flex justify-between items-center mb-[3px]">
              <label className="block text-[12px] font-[800] text-[#334155]">Select Customer</label>
              <button 
                onClick={() => { setIsNewCustomer(!isNewCustomer); setSelectedCustomerId(null); }}
                className="text-[11px] font-black text-active hover:text-active-dark transition-colors"
              >
                {isNewCustomer ? "Select Existing" : "+ Add New Customer"}
              </button>
            </div>
            
            {!isNewCustomer ? (
              <Select
                styles={selectStyles}
                value={customers.map(c => ({ value: c.id, label: `${c.name} - ${c.city || 'N/A'}` })).find(opt => opt.value === selectedCustomerId) || null}
                onChange={(opt) => setSelectedCustomerId(opt ? opt.value : null)}
                options={customers.map(c => ({ value: c.id, label: `${c.name} - ${c.city || 'N/A'}` }))}
                isClearable
                placeholder="Search Customer..."
              />
            ) : (
              <div className="bg-active/5 p-4 rounded-[16px] border border-active/20 grid grid-cols-1 md:grid-cols-2 gap-4 animate-in fade-in zoom-in duration-300">
                <div className="col-span-1 md:col-span-2">
                  <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">New Customer Name *</label>
                  <input value={newCustomerData.name} onChange={e => setNewCustomerData({...newCustomerData, name: e.target.value})} className="w-full h-[43px] px-[12px] border border-active/30 rounded-[14px] text-[14px] focus:border-active focus:ring-[3px] focus:ring-active/15 bg-white" placeholder="Name" />
                </div>
                <div>
                  <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Mobile</label>
                  <input value={newCustomerData.mobile} onChange={e => setNewCustomerData({...newCustomerData, mobile: e.target.value})} className="w-full h-[43px] px-[12px] border border-slate-300 rounded-[14px] text-[14px] focus:border-active focus:ring-[3px] focus:ring-active/15 bg-white" placeholder="Mobile" />
                </div>
                <div>
                  <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">City</label>
                  <input value={newCustomerData.city} onChange={e => setNewCustomerData({...newCustomerData, city: e.target.value})} className="w-full h-[43px] px-[12px] border border-slate-300 rounded-[14px] text-[14px] focus:border-active focus:ring-[3px] focus:ring-active/15 bg-white" placeholder="City" />
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* MENU SECTION */}
      <div className="bg-white rounded-[24px] p-[24px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200">
        <h3 className="text-[14px] font-black text-slate-800 uppercase tracking-widest mb-6 flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-active"></span> Product Menu
        </h3>

        {Object.entries(groupedProducts).map(([category, subCategories]) => (
          <div key={category} className="mb-6">
            {/* Main Category Header */}
            <div className="sticky top-0 bg-white/95 backdrop-blur-md z-10 py-2 mb-2 border-b-2 border-active">
              <h4 className="text-[15px] font-black text-slate-800 uppercase tracking-widest">{category}</h4>
            </div>

            <div className="flex flex-col">
              {Object.keys(subCategories).sort((a, b) => {
                const customOrder = ['400 COUNT', '400 COUNT (CORE & CELLOPHANE)', '600 COUNT', '700 COUNT', '800 COUNT'];
                const indexA = customOrder.indexOf(a.toUpperCase());
                const indexB = customOrder.indexOf(b.toUpperCase());
                if (indexA !== -1 && indexB !== -1) return indexA - indexB;
                if (indexA !== -1) return -1;
                if (indexB !== -1) return 1;
                return a.localeCompare(b);
              }).map(subCategory => {
                const items = subCategories[subCategory];
                return (
                <div key={subCategory} className="mb-4">
                  {/* Sub Category Header */}
                  <div className="py-1 mb-1 border-b border-slate-200">
                    <h5 className="text-[11px] font-bold text-slate-500 uppercase tracking-[2px]">
                      {subCategory}
                    </h5>
                  </div>

                  <div className="flex flex-col">
                    {items.sort((a, b) => {
                      const numA = parseInt(a.name.match(/\d+/)?.[0] || 0);
                      const numB = parseInt(b.name.match(/\d+/)?.[0] || 0);
                      return numA - numB;
                    }).map(product => {
                      const qty = cart[product.id] || 0;
                      const rate = getProductRate(product.id);
                      return (
                        <div key={product.id} className={`flex items-center justify-between py-2.5 border-b border-slate-100 transition-colors ${qty > 0 ? 'bg-active/5' : ''}`}>
                          <div className="flex-1 pr-2">
                            <div className="text-[14px] font-bold text-slate-800 leading-tight">{product.name}</div>
                            <div className="text-[12px] font-bold text-slate-500 mt-0.5">
                              ₹{rate.toLocaleString()}
                            </div>
                          </div>
                          
                          <div className="shrink-0 flex flex-col items-end">
                            <input 
                              type="number" 
                              inputMode="numeric"
                              pattern="[0-9]*"
                              value={qty || ''} 
                              onChange={(e) => setCartQty(product.id, parseInt(e.target.value) || 0)}
                              className="w-[50px] h-[32px] text-center text-[16px] font-black text-slate-800 bg-slate-100 border-none rounded-[6px] focus:outline-none focus:ring-2 focus:ring-active p-0 m-0 hide-arrows"
                              placeholder="0"
                            />
                            {qty > 0 && <span className="text-[9px] font-bold text-slate-400 mt-1 uppercase tracking-wider">{qty * (product.boxesPerCase || 1)} BXS</span>}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
                );
              })}
            </div>
          </div>
        ))}
        {epProducts.length === 0 && (
          <div className="text-center py-10 text-slate-500 font-bold">No products found for your assigned categories.</div>
        )}
      </div>

      {/* FOOTER ACTION */}
      <div className="bg-active-dark rounded-[24px] p-6 text-white shadow-xl flex flex-col sm:flex-row justify-between items-center gap-4 sticky bottom-6 z-20 mb-[env(safe-area-inset-bottom)]">
        <div>
          <span className="block text-[12px] font-bold text-white/70 uppercase tracking-widest">Order Subtotal</span>
          <span className="block text-3xl font-black tracking-tight">₹{subtotal.toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}</span>
        </div>
        
        <button 
          onClick={handleSubmit}
          disabled={isSubmitting || cartItems.length === 0}
          className="w-full sm:w-auto px-8 py-4 bg-white text-active-dark rounded-[16px] font-black text-[14px] tracking-wide shadow-[0_4px_14px_rgba(0,0,0,0.2)] hover:-translate-y-[2px] active:translate-y-[1px] transition-all disabled:opacity-50 disabled:hover:translate-y-0"
        >
          {isSubmitting ? 'SUBMITTING...' : `SUBMIT ORDER (${cartItems.length} ITEMS)`}
        </button>
      </div>
      
    </div>
  );
}
