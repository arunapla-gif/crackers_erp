import React, { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { erpApi } from '../api/erpApi';

export default function CustomerMaster() {
  const location = useLocation();
  const navigate = useNavigate();
  const verifyLeadState = location.state?.verifyLead;
  const leadData = location.state?.leadData;
  const pendingOrderId = location.state?.orderId;

  const [formData, setFormData] = useState({
    id: null, name: '', mobile: '', reference: '', address: '', city: '', district: '', state: '', pincode: '', id_number: '', gstin: '', status: 'Active', addresses: [], repId: ''
  });
  const [customers, setCustomers] = useState([]);
  const [reps, setReps] = useState([]);
  const [message, setMessage] = useState('');
  const [isSearchingPincode, setIsSearchingPincode] = useState(false);
  const [isSearchingGSTIN, setIsSearchingGSTIN] = useState(false);

  const fetchCustomers = async () => {
    try {
      const data = await erpApi.getCustomers();
      setCustomers(data);
    } catch (e) {
      console.log('Backend not available or customers table empty');
    }
  };

  const fetchReps = async () => {
    try {
      const data = await erpApi.getReps();
      setReps(data);
    } catch (e) {
      console.error(e);
    }
  };

  const verifyGstinData = async (gstin) => {
    setIsSearchingGSTIN(true);
    try {
      // Using the erpApi which calls our backend route
      const data = await erpApi.verifyGSTIN(gstin);
      
      setFormData((prev) => ({
        ...prev,
        name: data.tradeName || data.legalName || prev.name,
        address: data.address || prev.address,
        city: data.city || prev.city,
        state: data.state || prev.state,
        pincode: data.pincode || prev.pincode
      }));
    } catch (err) {
      console.error("Error fetching GSTIN data:", err);
    } finally {
      setIsSearchingGSTIN(false);
    }
  };

  useEffect(() => {
    fetchCustomers();
    fetchReps();
    
    // Intercept Lead Verification from Pending Orders
    if (verifyLeadState && leadData) {
      setMessage("LEAD VERIFICATION MODE: Please verify all details and save to approve the pending order.");
      
      const incomingGstin = (leadData.gstin || leadData.type === 'GST') ? (leadData.gstin || '') : 'URP';
      setFormData(prev => ({
        ...prev,
        name: leadData.name || '',
        city: leadData.city || '',
        mobile: leadData.mobile || '',
        gstin: incomingGstin
      }));
      
      // Auto-trigger full GSTIN verification if GSTIN exists
      if (incomingGstin !== 'URP' && incomingGstin.length === 15) {
        verifyGstinData(incomingGstin);
      }
    }
  }, [verifyLeadState, leadData]);

  const handleChange = async (e) => {
    const { name, value } = e.target;
    // For GSTIN, force uppercase
    const finalValue = name === 'gstin' ? value.toUpperCase() : value;
    setFormData((prev) => ({ ...prev, [name]: finalValue }));

    if (name === 'gstin' && finalValue.length === 15) {
      verifyGstinData(finalValue);
    }

    if (name === 'pincode' && finalValue.length === 6) {
      setIsSearchingPincode(true);
      try {
        const response = await fetch(`https://api.postalpincode.in/pincode/${finalValue}`);
        const data = await response.json();
        if (data && data[0] && data[0].Status === "Success" && data[0].PostOffice && data[0].PostOffice.length > 0) {
          const postOffice = data[0].PostOffice[0];
          setFormData((prev) => ({
            ...prev,
            city: postOffice.Name || postOffice.Block || postOffice.District,
            district: postOffice.District,
            state: postOffice.State
          }));
        }
      } catch (err) {
        console.error("Error fetching pincode data:", err);
      }
      setIsSearchingPincode(false);
    }
  };

  const handleClear = () => {
    setFormData({ id: null, name: '', mobile: '', reference: '', address: '', city: '', district: '', state: '', pincode: '', id_number: '', gstin: '', status: 'Active', addresses: [], repId: '' });
    setMessage('');
  };

  const handleEdit = (customer) => {
    setFormData({
      ...customer,
      repId: customer.repId || ''
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleToggleStatus = async (customer) => {
    const newStatus = customer.status === 'Active' ? 'Inactive' : 'Active';
    try {
      await erpApi.saveCustomer({ ...customer, status: newStatus });
      setMessage(`Customer marked as ${newStatus}!`);
      fetchCustomers();
    } catch (error) {
      alert('Error updating customer status');
    }
  };

  const handleSave = async () => {
    if (!formData.name) {
      alert('Customer Name is required');
      return;
    }
    const payload = {
      ...formData,
      repId: formData.repId || null
    };
    try {
      const savedCustomer = await erpApi.saveCustomer(payload);
      
      // If we are in Lead Verification Mode, link the new customer to the order
      if (verifyLeadState && pendingOrderId && savedCustomer?.id) {
        setMessage('Customer verified! Linking to pending order...');
        await erpApi.linkCustomerToOrder(pendingOrderId, savedCustomer.id);
        setMessage('Order Linked! Returning to Pending Orders...');
        setTimeout(() => {
          navigate('/pending-orders');
        }, 1500);
        return; // Don't clear form yet since we are navigating away
      }

      setMessage('Customer saved successfully!');
      handleClear();
      fetchCustomers();
    } catch (error) {
      alert('Error saving customer. Ensure backend is running.');
    }
  };

  return (
    <div className="space-y-[14px]">
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 hover:-translate-y-[1px] hover:border-[#dbe3ef] transition-all duration-150">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Customer Details Master
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-[14px]">
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">GST Reg. Type</label>
            <select
              value={formData.gstin === 'URP' ? 'Unregistered' : 'Registered'}
              onChange={(e) => {
                if (e.target.value === 'Unregistered') {
                  setFormData({...formData, gstin: 'URP'});
                } else {
                  setFormData({...formData, gstin: ''});
                }
              }}
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all"
            >
              <option value="Registered">Registered</option>
              <option value="Unregistered">Unregistered (URP)</option>
            </select>
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">
              GSTIN Lookup {isSearchingGSTIN && <span className="text-active ml-2 animate-pulse text-[10px]">Searching...</span>}
            </label>
            <input 
               name="gstin" 
               value={formData.gstin === 'URP' ? '' : formData.gstin} 
               onChange={handleChange} 
               disabled={formData.gstin === 'URP'}
               maxLength={15} 
               placeholder={formData.gstin === 'URP' ? 'URP Defaulted' : 'Enter 15 char GSTIN'} 
               className={`w-full min-h-[43px] px-[12px] py-[11px] border rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all font-bold ${formData.gstin === 'URP' ? 'bg-slate-100 border-slate-200 text-slate-400 cursor-not-allowed' : 'bg-white/96 border-slate-300 text-active'}`} 
            />
          </div>
          <div className="col-span-1 md:col-span-6">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Customer / Business Name *</label>
            <input name="name" value={formData.name} onChange={handleChange} placeholder="Customer name" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Mobile</label>
            <input name="mobile" value={formData.mobile} onChange={handleChange} placeholder="10 digit mobile" maxLength={10} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Sales Rep Assignment</label>
            <select name="repId" value={formData.repId || ''} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all">
              <option value="">-- No Rep Assigned --</option>
              {reps.map(r => <option key={r.id} value={r.id}>{r.username}</option>)}
            </select>
          </div>
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Reference / Notes</label>
            <input name="reference" value={formData.reference} onChange={handleChange} placeholder="Other reference" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-12">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Address</label>
            <textarea name="address" value={formData.address} onChange={handleChange} placeholder="Full customer address" className="w-full min-h-[74px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all resize-y"></textarea>
          </div>
          {formData.addresses && formData.addresses.length > 1 && (
            <div className="col-span-1 md:col-span-12 mt-[-6px]">
              <label className="block text-[11px] font-[800] text-slate-500 mb-[4px]">Additional Places of Business (Auto-saved for Billing):</label>
              <div className="flex flex-col gap-[4px] pl-[8px] border-l-[2px] border-slate-300">
                {formData.addresses.filter(a => a.type !== 'Principal Place').map((addr, idx) => (
                  <div key={idx} className="text-[11px] text-slate-500 leading-tight">
                    <span className="font-bold">{addr.type}:</span> {addr.address}, {addr.city}, {addr.state} - {addr.pincode}
                  </div>
                ))}
              </div>
            </div>
          )}
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">State</label>
            <select name="state" value={formData.state} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all">
              <option value="">Select State</option>
              <option value="Andhra Pradesh">Andhra Pradesh</option>
              <option value="Arunachal Pradesh">Arunachal Pradesh</option>
              <option value="Assam">Assam</option>
              <option value="Bihar">Bihar</option>
              <option value="Chhattisgarh">Chhattisgarh</option>
              <option value="Goa">Goa</option>
              <option value="Gujarat">Gujarat</option>
              <option value="Haryana">Haryana</option>
              <option value="Himachal Pradesh">Himachal Pradesh</option>
              <option value="Jharkhand">Jharkhand</option>
              <option value="Karnataka">Karnataka</option>
              <option value="Kerala">Kerala</option>
              <option value="Madhya Pradesh">Madhya Pradesh</option>
              <option value="Maharashtra">Maharashtra</option>
              <option value="Manipur">Manipur</option>
              <option value="Meghalaya">Meghalaya</option>
              <option value="Mizoram">Mizoram</option>
              <option value="Nagaland">Nagaland</option>
              <option value="Odisha">Odisha</option>
              <option value="Punjab">Punjab</option>
              <option value="Rajasthan">Rajasthan</option>
              <option value="Sikkim">Sikkim</option>
              <option value="Tamil Nadu">Tamil Nadu</option>
              <option value="Telangana">Telangana</option>
              <option value="Tripura">Tripura</option>
              <option value="Uttar Pradesh">Uttar Pradesh</option>
              <option value="Uttarakhand">Uttarakhand</option>
              <option value="West Bengal">West Bengal</option>
              <option value="Andaman and Nicobar Islands">Andaman and Nicobar Islands</option>
              <option value="Chandigarh">Chandigarh</option>
              <option value="Dadra and Nagar Haveli and Daman and Diu">Dadra and Nagar Haveli and Daman and Diu</option>
              <option value="Delhi">Delhi</option>
              <option value="Jammu and Kashmir">Jammu and Kashmir</option>
              <option value="Ladakh">Ladakh</option>
              <option value="Lakshadweep">Lakshadweep</option>
              <option value="Puducherry">Puducherry</option>
            </select>
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">
              Pincode {isSearchingPincode && <span className="text-active ml-2 animate-pulse text-[10px]">Searching...</span>}
            </label>
            <input name="pincode" value={formData.pincode} onChange={handleChange} maxLength={6} placeholder="Enter 6 digits" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">City</label>
            <input name="city" value={formData.city} onChange={handleChange} placeholder="City name" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">District</label>
            <input name="district" value={formData.district || ''} onChange={handleChange} placeholder="District name" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Aadhaar / ID</label>
            <input name="id_number" value={formData.id_number} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
        </div>

        <div className="flex justify-end gap-[8px] mt-[18px] bg-slate-50 p-[12px] border border-slate-200 rounded-[18px]">
          <button onClick={handleClear} className="min-h-[40px] px-[16px] py-[10px] bg-slate-200 text-slate-900 border border-slate-300 rounded-[14px] font-[900] hover:-translate-y-[1px] transition-all">Clear</button>
          <button onClick={handleSave} className="min-h-[40px] px-[16px] py-[10px] bg-green-600 text-white rounded-[14px] font-[900] shadow-[0_10px_24px_rgba(15,23,42,0.12)] hover:-translate-y-[1px] transition-all">Save Customer</button>
        </div>
        
        {message && (
          <div className="inline-block mt-[12px] bg-green-50 border border-green-200 text-green-700 p-[10px_12px] rounded-[14px] font-[900] text-[13px]">
            {message}
          </div>
        )}
      </div>

      {/* Saved Customers List */}
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Saved Customers
        </h2>
        <table className="w-full border-separate border-spacing-y-[8px] text-[14px]">
          <thead>
            <tr>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Name</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Mobile</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">City</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">District</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Sales Rep</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">GSTIN</th>
              <th className="text-center font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Status</th>
              <th className="text-right font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Actions</th>
            </tr>
          </thead>
          <tbody>
            {customers.map((c, i) => (
              <tr key={i} className={`hover:bg-slate-50 transition-all ${c.status === 'Inactive' ? 'opacity-60 grayscale' : ''}`}>
                <td className="bg-white border-y border-slate-200 border-l rounded-l-[14px] p-[10px] font-[800] text-slate-800">{c.name}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">{c.mobile || '-'}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">{c.city || '-'}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">{c.district || '-'}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700 font-bold text-active-dark">{c.rep?.username || '-'}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700 uppercase">{c.gstin || '-'}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-center">
                  <span className={`inline-block px-2 py-1 rounded-[6px] text-[10px] font-bold uppercase tracking-wider ${c.status === 'Inactive' ? 'bg-red-100 text-red-600' : 'bg-green-100 text-green-600'}`}>
                    {c.status || 'Active'}
                  </span>
                </td>
                <td className="bg-white border-y border-slate-200 border-r rounded-r-[14px] p-[10px] text-right">
                  <div className="flex justify-end gap-2">
                    <button onClick={() => handleEdit(c)} className="px-3 py-1 bg-blue-50 text-blue-600 hover:bg-blue-100 rounded-[8px] font-bold text-[11px] transition-colors">
                      Edit
                    </button>
                    <button onClick={() => handleToggleStatus(c)} className={`px-3 py-1 rounded-[8px] font-bold text-[11px] transition-colors ${c.status === 'Inactive' ? 'bg-emerald-50 text-emerald-600 hover:bg-emerald-100' : 'bg-rose-50 text-rose-600 hover:bg-rose-100'}`}>
                      {c.status === 'Inactive' ? 'Enable' : 'Disable'}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {customers.length === 0 && (
              <tr>
                <td colSpan={7} className="bg-white border border-slate-200 rounded-[14px] p-[10px] text-center text-slate-500">No customers found in Postgres DB</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
