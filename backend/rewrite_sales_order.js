const fs = require('fs');

const path = '/Users/arun_ap/Desktop/crackers erp/frontend/src/pages/SalesOrderEntry.jsx';
let content = fs.readFileSync(path, 'utf8');

// Replace rows state
content = content.replace(
  "const [rows, setRows] = useState([{ id: Date.now(), productId: null, productSearch: '', product: '', qty: 1, rate: 0, total: 0 }]);",
  "const [cart, setCart] = useState({});"
);

// Remove addRow, removeRow, updateRow, handleProductSelect
content = content.replace(/const addRow = \(\) => {[\s\S]*?};/, "");
content = content.replace(/const removeRow = \(id\) => {[\s\S]*?};/, "");
content = content.replace(/const updateRow = \(id, field, value\) => {[\s\S]*?};/, "");
content = content.replace(/const handleProductSelect = \(id, searchValue\) => {[\s\S]*?};/g, "");

// Add cart helpers and grouping logic
const cartHelpers = `
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

  const getProductRate = (productId) => {
    const product = products.find(p => p.id === productId);
    if (!product) return 0;
    const standardRate = parseFloat(product.rate);
    const customRate = customRates[productId];
    return customRate !== undefined ? customRate : standardRate;
  };

  const cartItems = Object.keys(cart).map(idStr => {
    const productId = parseInt(idStr);
    const qty = cart[productId];
    const product = products.find(p => p.id === productId);
    const rate = getProductRate(productId);
    return {
      productId,
      product: product?.name || '',
      qty,
      rate,
      total: rate * qty
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
`;

// Wait, subtotal is defined below handleProductSelect in original.
content = content.replace(/const subtotal = rows\.reduce.*?0\);/, cartHelpers);

// Update handleSubmit
const newHandleSubmit = `
  const handleSubmit = async () => {
    if (!isNewCustomer && !selectedCustomerId) {
      alert("Please select a customer or add a new one.");
      return;
    }
    if (isNewCustomer && !newCustomerData.name) {
      alert("New Customer Name is required.");
      return;
    }
    if (cartItems.length === 0) {
      alert("Add at least one product.");
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
      alert("Error submitting order: " + (e.response?.data?.error || e.message));
    } finally {
      setIsSubmitting(false);
    }
  };
`;
content = content.replace(/const handleSubmit = async \(\) => {[\s\S]*?};/, newHandleSubmit);

// Replace the entire ITEMS SECTION HTML
const newItemsSection = `
      {/* MENU SECTION */}
      <div className="bg-white rounded-[24px] p-[24px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200">
        <h3 className="text-[14px] font-black text-slate-800 uppercase tracking-widest mb-6 flex items-center gap-2">
          <span className="w-2 h-2 rounded-full bg-active"></span> Product Menu
        </h3>

        {Object.entries(groupedProducts).map(([category, subCategories]) => (
          <div key={category} className="mb-10 last:mb-0">
            {/* Main Category Header */}
            <div className="sticky top-0 bg-white/95 backdrop-blur-md z-10 py-3 mb-4 border-b-2 border-slate-100">
              <h4 className="text-[18px] font-black text-active uppercase tracking-wider">{category}</h4>
            </div>

            <div className="space-y-8">
              {Object.entries(subCategories).map(([subCategory, items]) => (
                <div key={subCategory} className="bg-slate-50/50 rounded-[20px] p-5 border border-slate-100">
                  {/* Sub Category Header */}
                  <h5 className="text-[12px] font-black text-slate-500 uppercase tracking-[1.5px] mb-4 flex items-center gap-2">
                    <div className="h-[1px] flex-1 bg-slate-200"></div>
                    {subCategory}
                    <div className="h-[1px] flex-1 bg-slate-200"></div>
                  </h5>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {items.map(product => {
                      const qty = cart[product.id] || 0;
                      const rate = getProductRate(product.id);
                      return (
                        <div key={product.id} className={\`flex items-center justify-between p-3 rounded-[14px] border transition-all \${qty > 0 ? 'bg-active/5 border-active/30' : 'bg-white border-slate-200 hover:border-slate-300'}\`}>
                          <div className="flex-1 pr-3">
                            <div className="text-[10px] font-black text-slate-400 mb-0.5">{product.code}</div>
                            <div className="text-[13px] font-bold text-slate-800 leading-tight">{product.name}</div>
                            <div className="text-[12px] font-black text-active mt-1">₹{rate.toLocaleString()}</div>
                          </div>
                          
                          <div className="flex items-center gap-3 bg-slate-50 p-1.5 rounded-[12px] border border-slate-200">
                            <button 
                              onClick={() => updateCart(product.id, -1)}
                              className={\`w-[28px] h-[28px] flex items-center justify-center rounded-[8px] font-black text-[16px] transition-colors \${qty > 0 ? 'bg-white text-rose-500 shadow-sm border border-slate-200 hover:bg-rose-50' : 'text-slate-300'}\`}
                              disabled={qty === 0}
                            >
                              -
                            </button>
                            <span className="w-[20px] text-center text-[14px] font-black text-slate-700">{qty}</span>
                            <button 
                              onClick={() => updateCart(product.id, 1)}
                              className="w-[28px] h-[28px] flex items-center justify-center rounded-[8px] bg-active text-white font-black text-[16px] shadow-sm hover:bg-active-dark transition-colors"
                            >
                              +
                            </button>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
        {epProducts.length === 0 && (
          <div className="text-center py-10 text-slate-500 font-bold">No products found for your assigned categories.</div>
        )}
      </div>
`;

// Need to match exactly the ITEMS SECTION in the file
content = content.replace(/{\/\* ITEMS SECTION \*\/}[\s\S]*?{\/\* FOOTER ACTION \*\/}/, newItemsSection + "\n\n      {/* FOOTER ACTION */}");

// Remove Auto-update existing rows with new custom prices block in useEffect since we dynamically calculate it now!
const useEffectBody = `
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
        console.error("Failed to fetch customer prices");
      }
    };
    fetchCustomPrices();
  }, [selectedCustomerId, isNewCustomer]);
`;
content = content.replace(/useEffect\(\(\) => {[\s\S]*?\}, \[selectedCustomerId, isNewCustomer, products\]\);/, useEffectBody);


fs.writeFileSync(path, content, 'utf8');
console.log('SalesOrderEntry replaced');
