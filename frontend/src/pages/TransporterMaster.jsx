import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';

export default function TransporterMaster() {
  const [formData, setFormData] = useState({
    id: null, name: '', address: '', city: '', district: '', state: '', pincode: '', gstin: '', status: 'Active'
  });
  const [transporters, setTransporters] = useState([]);
  const [message, setMessage] = useState('');
  const [isSearchingPincode, setIsSearchingPincode] = useState(false);
  const [isSearchingGSTIN, setIsSearchingGSTIN] = useState(false);

  const fetchTransporters = async () => {
    try {
      const data = await erpApi.getTransporters();
      setTransporters(data);
    } catch (e) {
      console.log('Backend not available or transporters table empty');
    }
  };

  useEffect(() => {
    fetchTransporters();
  }, []);

  const handleChange = async (e) => {
    const { name, value } = e.target;
    const finalValue = name === 'gstin' ? value.toUpperCase() : value;
    setFormData((prev) => ({ ...prev, [name]: finalValue }));

    if (name === 'gstin' && finalValue.length === 15) {
      setIsSearchingGSTIN(true);
      try {
        const response = await fetch(`https://appyflow.in/api/verifyGST?gstNo=${finalValue}&key_secret=7eWP3WelRNexYGJ172L3Hb8JNrY2`);
        const data = await response.json();
        
        if (!data.error && data.taxpayerInfo) {
          const info = data.taxpayerInfo;
          let address = '';
          let city = '';
          let district = '';
          let state = '';
          let pincode = '';
          
          if (info.pradr && info.pradr.addr) {
            const addrInfo = info.pradr.addr;
            const addrParts = [addrInfo.bno, addrInfo.bnm, addrInfo.st, addrInfo.flno].filter(Boolean);
            address = addrParts.join(', ');
            city = addrInfo.loc || addrInfo.city || '';
            district = addrInfo.dst || '';
            state = addrInfo.stcd || '';
            pincode = addrInfo.pncd || '';
          }

          const businessName = info.tradeNam || info.lgnm || '';
          
          setFormData((prev) => ({
            ...prev,
            name: businessName,
            address: address,
            city: city,
            district: district,
            state: state,
            pincode: pincode
          }));
        }
      } catch (err) {
        console.error("Error fetching GSTIN data:", err);
      }
      setIsSearchingGSTIN(false);
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
    setFormData({ id: null, name: '', address: '', city: '', district: '', state: '', pincode: '', gstin: '', status: 'Active' });
    setMessage('');
  };

  const handleEdit = (transporter) => {
    setFormData(transporter);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleToggleStatus = async (transporter) => {
    const newStatus = transporter.status === 'Active' ? 'Inactive' : 'Active';
    try {
      await erpApi.saveTransporter({ ...transporter, status: newStatus });
      setMessage(`Transporter marked as ${newStatus}!`);
      fetchTransporters();
    } catch (error) {
      alert('Error updating transporter status');
    }
  };

  const handleSave = async () => {
    if (!formData.gstin) {
      alert('GSTIN is required for Transporter');
      return;
    }
    if (!formData.name) {
      alert('Transporter Name is required');
      return;
    }
    try {
      await erpApi.saveTransporter(formData);
      setMessage('Transporter saved successfully!');
      handleClear();
      fetchTransporters();
    } catch (error) {
      alert('Error saving to PostgreSQL. Ensure backend is running.');
    }
  };

  return (
    <div className="space-y-[14px]">
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 hover:-translate-y-[1px] hover:border-[#dbe3ef] transition-all duration-150">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Transporter Details Master
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-[14px]">
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">
              GSTIN Lookup {isSearchingGSTIN && <span className="text-active ml-2 animate-pulse text-[10px]">Searching...</span>}
            </label>
            <input name="gstin" value={formData.gstin} onChange={handleChange} maxLength={15} placeholder="Enter 15 char GSTIN" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all font-bold text-active" />
          </div>
          <div className="col-span-1 md:col-span-8">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Transporter Name *</label>
            <input name="name" value={formData.name} onChange={handleChange} placeholder="Transporter name" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-12">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Full Address</label>
            <textarea name="address" value={formData.address} onChange={handleChange} placeholder="Transporter full address" className="w-full min-h-[74px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all resize-y"></textarea>
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">State</label>
            <select name="state" value={formData.state || ''} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all">
              <option value="">Select State</option>
              <option value="Tamil Nadu">Tamil Nadu</option>
              <option value="Kerala">Kerala</option>
              <option value="Karnataka">Karnataka</option>
              <option value="Andhra Pradesh">Andhra Pradesh</option>
              <option value="Telangana">Telangana</option>
              <option value="Maharashtra">Maharashtra</option>
            </select>
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">
              Pincode {isSearchingPincode && <span className="text-active ml-2 animate-pulse text-[10px]">Searching...</span>}
            </label>
            <input name="pincode" value={formData.pincode || ''} onChange={handleChange} maxLength={6} placeholder="Enter 6 digits" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">City</label>
            <input name="city" value={formData.city || ''} onChange={handleChange} placeholder="City name" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">District</label>
            <input name="district" value={formData.district || ''} onChange={handleChange} placeholder="District name" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
        </div>

        <div className="flex justify-end gap-[8px] mt-[18px] bg-slate-50 p-[12px] border border-slate-200 rounded-[18px]">
          <button onClick={handleClear} className="min-h-[40px] px-[16px] py-[10px] bg-slate-200 text-slate-900 border border-slate-300 rounded-[14px] font-[900] hover:-translate-y-[1px] transition-all">Clear</button>
          <button onClick={handleSave} className="min-h-[40px] px-[16px] py-[10px] bg-active text-white rounded-[14px] font-[900] shadow-[0_10px_24px_rgba(15,23,42,0.12)] hover:-translate-y-[1px] transition-all">Save Transporter</button>
        </div>
        
        {message && (
          <div className="inline-block mt-[12px] bg-green-50 border border-green-200 text-green-700 p-[10px_12px] rounded-[14px] font-[900] text-[13px]">
            {message}
          </div>
        )}
      </div>

      {/* Saved Transporters List */}
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Saved Transporters
        </h2>
        <table className="w-full border-separate border-spacing-y-[8px] text-[14px]">
          <thead>
            <tr>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">GSTIN</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Name</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">City</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">District</th>
              <th className="text-center font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Status</th>
              <th className="text-right font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Actions</th>
            </tr>
          </thead>
          <tbody>
            {transporters.map((c, i) => (
              <tr key={i} className={`hover:bg-slate-50 transition-all ${c.status === 'Inactive' ? 'opacity-60 grayscale' : ''}`}>
                <td className="bg-white border-y border-slate-200 border-l rounded-l-[14px] p-[10px] font-[800] text-slate-800">{c.gstin}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] font-bold text-slate-800">{c.name}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">{c.city || '-'}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">{c.district || '-'}</td>
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
            {transporters.length === 0 && (
              <tr>
                <td colSpan={5} className="bg-white border border-slate-200 rounded-[14px] p-[10px] text-center text-slate-500">No transporters found in Postgres DB</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
