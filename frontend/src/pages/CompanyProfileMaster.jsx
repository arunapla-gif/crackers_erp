import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';
import { FaEdit, FaPowerOff, FaCheckCircle, FaBuilding, FaEye, FaTimes, FaPlus, FaTrash } from 'react-icons/fa';

export default function CompanyProfileMaster() {
  const [profiles, setProfiles] = useState([]);
  const [formData, setFormData] = useState({ name: '', gstin: '', address: '', city: '', district: '', state: 'Tamil Nadu', pincode: '', addresses: [], status: 'Active' });
  const [editingId, setEditingId] = useState(null);
  const [message, setMessage] = useState('');
  const [isSearchingGSTIN, setIsSearchingGSTIN] = useState(false);
  const [selectedProfile, setSelectedProfile] = useState(null);
  const [seriesData, setSeriesData] = useState({ prefix: '', name: '', lastNumber: 0 });
  const [systemCredentials, setSystemCredentials] = useState(null);

  const loadProfiles = () => {
    erpApi.getCompanyProfiles().then(setProfiles).catch(console.error);
    erpApi.getSystemCredentials().then(setSystemCredentials).catch(console.error);
  };

  useEffect(() => {
    loadProfiles();
  }, []);

  const handleSave = async (e) => {
    e.preventDefault();
    if (!formData.name || !formData.gstin) {
      alert("Name and GSTIN are required!");
      return;
    }
    try {
      await erpApi.saveCompanyProfile({ ...formData, id: editingId });
      setMessage(editingId ? 'Profile Updated!' : 'Profile Saved!');
      setFormData({ name: '', gstin: '', address: '', city: '', district: '', state: 'Tamil Nadu', pincode: '', addresses: [], status: 'Active' });
      setEditingId(null);
      loadProfiles();
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      alert(`Error saving profile: ${error.response?.data?.error || error.message}`);
    }
  };

  const handleEdit = (profile) => {
    setEditingId(profile.id);
    setFormData({
      name: profile.name,
      gstin: profile.gstin,
      address: profile.address || '',
      city: profile.city || '',
      district: profile.district || '',
      state: profile.state || 'Tamil Nadu',
      pincode: profile.pincode || '',
      addresses: profile.addresses || [],
      status: profile.status
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleToggleStatus = async (profile) => {
    try {
      const newStatus = profile.status === 'Active' ? 'Inactive' : 'Active';
      await erpApi.saveCompanyProfile({ ...profile, status: newStatus });
      loadProfiles();
    } catch (error) {
      alert(`Error updating status: ${error.message}`);
    }
  };

  const handleViewProfile = (profile) => {
    setSelectedProfile(profile);
  };

  const handleSaveSeries = async (e) => {
    e.preventDefault();
    try {
      await erpApi.saveBillingSeries({ ...seriesData, companyProfileId: selectedProfile.id });
      setSeriesData({ prefix: '', name: '', lastNumber: 0 });
      const updatedProfiles = await erpApi.getCompanyProfiles();
      setProfiles(updatedProfiles);
      setSelectedProfile(updatedProfiles.find(p => p.id === selectedProfile.id));
    } catch (err) {
      alert("Error saving series: " + err.message);
    }
  };

  const handleDeleteSeries = async (seriesId) => {
    if (!window.confirm("Delete this billing series?")) return;
    try {
      await erpApi.deleteBillingSeries(seriesId);
      const updatedProfiles = await erpApi.getCompanyProfiles();
      setProfiles(updatedProfiles);
      setSelectedProfile(updatedProfiles.find(p => p.id === selectedProfile.id));
    } catch (err) {
      alert("Error deleting series: " + err.message);
    }
  };

  const handleChange = async (e) => {
    const { name, value } = e.target;
    const finalValue = name === 'gstin' ? value.toUpperCase() : value;
    setFormData(prev => ({ ...prev, [name]: finalValue }));

    if (name === 'gstin' && finalValue.length === 15) {
      setIsSearchingGSTIN(true);
      try {
        const response = await fetch(`https://appyflow.in/api/verifyGST?gstNo=${finalValue}&key_secret=7eWP3WelRNexYGJ172L3Hb8JNrY2`);
        const data = await response.json();
        
        if (!data.error && data.taxpayerInfo) {
          const info = data.taxpayerInfo;
          let newAddress = '';
          let newCity = '';
          let newDistrict = '';
          let newPincode = '';
          let newAddresses = [];
          let newState = info.pradr?.addr?.stcd || formData.state;
          let businessName = info.tradeNam || info.lgnm || formData.name;

          if (info.pradr && info.pradr.addr) {
            const addrInfo = info.pradr.addr;
            const addrParts = [addrInfo.bno, addrInfo.bnm, addrInfo.st, addrInfo.flno].filter(Boolean);
            newAddress = addrParts.join(', ');
            newCity = addrInfo.loc || addrInfo.city || '';
            newDistrict = addrInfo.dst || '';
            newPincode = addrInfo.pncd || '';
          }

          if (info.adadr && Array.isArray(info.adadr)) {
            info.adadr.forEach((ad, idx) => {
              if (ad.addr) {
                const addrInfo = ad.addr;
                const addrParts = [addrInfo.bno, addrInfo.bnm, addrInfo.st, addrInfo.flno].filter(Boolean);
                newAddresses.push({
                  type: `Additional Place ${idx + 1}`,
                  address: addrParts.join(', '),
                  city: addrInfo.loc || addrInfo.city || '',
                  district: addrInfo.dst || '',
                  state: addrInfo.stcd || newState,
                  pincode: addrInfo.pncd || ''
                });
              }
            });
          }

          setFormData(prev => ({
            ...prev,
            name: businessName,
            address: newAddress,
            city: newCity,
            district: newDistrict,
            state: newState,
            pincode: newPincode,
            addresses: newAddresses
          }));
        }
      } catch (err) {
        console.error("Error fetching GSTIN data:", err);
      }
      setIsSearchingGSTIN(false);
    }
  };

  return (
    <div className="space-y-[24px]">
      <div className="bg-white/80 backdrop-blur-xl rounded-[32px] p-[24px] shadow-[0_24px_64px_rgba(15,23,42,0.06)] border border-white/80 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-[400px] h-[400px] bg-indigo-500/10 rounded-full blur-3xl -z-10 pointer-events-none translate-x-1/2 -translate-y-1/2"></div>
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between mb-8 gap-4">
          <h2 className="text-[18px] font-black text-slate-800 tracking-[-0.5px] flex items-center gap-[12px]">
            <span className="w-[38px] h-[38px] rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shadow-inner">
              <FaBuilding size={16} />
            </span>
            Company Profiles (Multi-GSTIN)
          </h2>
          <div className="flex items-center gap-2">
            {systemCredentials && (
              <div className="group relative">
                <div className="flex items-center gap-2 bg-slate-100 text-slate-500 px-3 py-1.5 rounded-lg text-[11px] font-bold cursor-pointer hover:bg-slate-200 transition-colors">
                  <FaEye /> View Global API Credentials
                </div>
                <div className="absolute top-full right-0 mt-2 w-72 bg-slate-800 text-white p-4 rounded-xl shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all z-50">
                  <h4 className="text-[10px] font-black uppercase text-slate-400 mb-2 border-b border-slate-600 pb-1">System Environment Variables</h4>
                  <div className="space-y-1 text-[11px] font-mono break-all">
                    <p><span className="text-indigo-400">USERNAME:</span> {systemCredentials.WHITEBOOKS_USERNAME}</p>
                    <p><span className="text-emerald-400">PASSWORD:</span> {systemCredentials.WHITEBOOKS_PASSWORD}</p>
                    <p><span className="text-rose-400">GSTIN:</span> {systemCredentials.WHITEBOOKS_GSTIN}</p>
                    <p><span className="text-amber-400">EMAIL:</span> {systemCredentials.WHITEBOOKS_EMAIL}</p>
                  </div>
                </div>
              </div>
            )}
            {editingId && (
              <button 
                onClick={() => { setEditingId(null); setFormData({ name: '', gstin: '', address: '', city: '', district: '', state: 'Tamil Nadu', pincode: '', addresses: [], status: 'Active' }); }}
                className="text-[11px] font-black text-slate-400 bg-slate-100 hover:bg-slate-200 px-4 py-2 rounded-xl transition-colors uppercase tracking-wider"
              >
                Cancel Edit
              </button>
            )}
          </div>
        </div>

        <form onSubmit={handleSave} className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-[16px]">
          <div>
            <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-[6px] ml-1">Branch Name</label>
            <input required name="name" value={formData.name} onChange={handleChange} placeholder="Main Branch / Factory 1" className="w-full px-[16px] py-[14px] bg-slate-50 border border-slate-200 rounded-[16px] text-[14px] font-bold text-slate-700 focus:outline-none focus:border-indigo-400 focus:ring-[4px] focus:ring-indigo-400/20 transition-all placeholder:font-medium placeholder:text-slate-300" />
          </div>
          <div>
            <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-[6px] ml-1">
              GSTIN {isSearchingGSTIN && <span className="text-indigo-500 ml-2 animate-pulse text-[10px]">Searching...</span>}
            </label>
            <input required name="gstin" value={formData.gstin} onChange={handleChange} maxLength={15} placeholder="e.g. 33AABCU9603R1ZX" className="w-full px-[16px] py-[14px] bg-slate-50 border border-slate-200 rounded-[16px] text-[14px] font-black text-indigo-700 uppercase focus:outline-none focus:border-indigo-400 focus:ring-[4px] focus:ring-indigo-400/20 transition-all placeholder:font-medium placeholder:text-slate-300" />
          </div>
          <div>
            <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-[6px] ml-1">State</label>
            <select name="state" value={formData.state} onChange={handleChange} className="w-full px-[16px] py-[14px] bg-slate-50 border border-slate-200 rounded-[16px] text-[14px] font-bold text-slate-700 focus:outline-none focus:border-indigo-400 focus:ring-[4px] focus:ring-indigo-400/20 transition-all appearance-none bg-[url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%2224%22%20height%3D%2224%22%20viewBox%3D%220%200%2024%2024%22%20fill%3D%22none%22%20stroke%3D%22%2364748b%22%20stroke-width%3D%222%22%20stroke-linecap%3D%22round%22%20stroke-linejoin%3D%22round%22%3E%3Cpolyline%20points%3D%226%209%2012%2015%2018%209%22%3E%3C%2Fpolyline%3E%3C%2Fsvg%3E')] bg-[length:16px_16px] bg-[position:right_16px_center] bg-no-repeat pr-[40px]">
              <option>Tamil Nadu</option>
              <option>Karnataka</option>
              <option>Kerala</option>
              <option>Andhra Pradesh</option>
              <option>Maharashtra</option>
              <option>Delhi</option>
            </select>
          </div>
          <div className="lg:col-span-3">
            <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-[6px] ml-1">Street Address</label>
            <input name="address" value={formData.address} onChange={handleChange} placeholder="Street, Area" className="w-full px-[16px] py-[14px] bg-slate-50 border border-slate-200 rounded-[16px] text-[14px] font-bold text-slate-700 focus:outline-none focus:border-indigo-400 focus:ring-[4px] focus:ring-indigo-400/20 transition-all placeholder:font-medium placeholder:text-slate-300" />
          </div>
          <div>
            <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-[6px] ml-1">City</label>
            <input name="city" value={formData.city} onChange={handleChange} placeholder="City" className="w-full px-[16px] py-[14px] bg-slate-50 border border-slate-200 rounded-[16px] text-[14px] font-bold text-slate-700 focus:outline-none focus:border-indigo-400 focus:ring-[4px] focus:ring-indigo-400/20 transition-all placeholder:font-medium placeholder:text-slate-300" />
          </div>
          <div>
            <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-[6px] ml-1">District</label>
            <input name="district" value={formData.district} onChange={handleChange} placeholder="District" className="w-full px-[16px] py-[14px] bg-slate-50 border border-slate-200 rounded-[16px] text-[14px] font-bold text-slate-700 focus:outline-none focus:border-indigo-400 focus:ring-[4px] focus:ring-indigo-400/20 transition-all placeholder:font-medium placeholder:text-slate-300" />
          </div>
          <div>
            <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-[6px] ml-1">Pincode</label>
            <input name="pincode" value={formData.pincode} onChange={handleChange} maxLength={6} placeholder="600001" className="w-full px-[16px] py-[14px] bg-slate-50 border border-slate-200 rounded-[16px] text-[14px] font-bold text-slate-700 focus:outline-none focus:border-indigo-400 focus:ring-[4px] focus:ring-indigo-400/20 transition-all placeholder:font-medium placeholder:text-slate-300" />
          </div>

          {formData.addresses && formData.addresses.length > 0 && (
            <div className="lg:col-span-3 mt-2">
              <label className="block text-[11px] font-black text-slate-400 uppercase tracking-wider mb-[6px] ml-1">Additional Places of Business (Auto-saved)</label>
              <div className="flex flex-col gap-[6px] pl-[12px] border-l-[3px] border-indigo-200">
                {formData.addresses.map((addr, idx) => (
                  <div key={idx} className="text-[12px] font-medium text-slate-600 bg-slate-50 p-2 rounded-lg border border-slate-100">
                    <span className="font-bold text-indigo-600">{addr.type}:</span> {addr.address}, {addr.city}, {addr.district}, {addr.state} - {addr.pincode}
                  </div>
                ))}
              </div>
            </div>
          )}
          
          <div className="md:col-span-2 lg:col-span-3 flex items-center justify-between pt-4">
            <div className="text-[13px] font-bold text-emerald-500">{message}</div>
            <button type="submit" className="bg-indigo-600 text-white px-[32px] py-[14px] rounded-[16px] text-[13px] font-black uppercase tracking-wider hover:bg-indigo-700 hover:-translate-y-[2px] hover:shadow-[0_8px_24px_rgba(79,70,229,0.25)] transition-all active:translate-y-0 active:shadow-none">
              {editingId ? 'Update Profile' : 'Save Profile'}
            </button>
          </div>
        </form>
      </div>

      {/* Profiles List */}
      <div className="bg-white/80 backdrop-blur-xl rounded-[32px] p-[24px] shadow-[0_24px_64px_rgba(15,23,42,0.06)] border border-white/80">
        <h2 className="text-[13px] font-black text-slate-400 uppercase tracking-wider mb-6">Saved Profiles</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-[16px]">
          {profiles.map((p) => {
            const isActive = p.status === 'Active';
            return (
              <div key={p.id} onClick={() => handleViewProfile(p)} className="bg-white border border-slate-200 rounded-[24px] p-5 relative shadow-[0_4px_20px_rgba(15,23,42,0.03)] hover:border-indigo-200 hover:shadow-[0_8px_32px_rgba(79,70,229,0.08)] transition-all group cursor-pointer">
                <div className="absolute top-5 right-5 flex gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                  <button onClick={(e) => { e.stopPropagation(); handleEdit(p); }} className="w-[32px] h-[32px] rounded-[10px] bg-slate-50 text-slate-400 flex items-center justify-center hover:bg-indigo-50 hover:text-indigo-600 transition-colors"><FaEdit size={14} /></button>
                  <button onClick={(e) => { e.stopPropagation(); handleToggleStatus(p); }} className={`w-[32px] h-[32px] rounded-[10px] flex items-center justify-center transition-colors ${isActive ? 'bg-rose-50 text-rose-400 hover:bg-rose-100 hover:text-rose-600' : 'bg-emerald-50 text-emerald-400 hover:bg-emerald-100 hover:text-emerald-600'}`}>
                    {isActive ? <FaPowerOff size={13} /> : <FaCheckCircle size={14} />}
                  </button>
                </div>
                
                <div className={`w-[48px] h-[48px] rounded-[14px] flex items-center justify-center mb-4 ${isActive ? 'bg-indigo-50 text-indigo-600' : 'bg-slate-100 text-slate-400'}`}>
                  <FaBuilding size={20} />
                </div>
                
                <h3 className="text-[16px] font-black text-slate-800 mb-1">{p.name}</h3>
                <div className="inline-block px-2 py-1 bg-slate-100 rounded-md text-[11px] font-black tracking-widest text-indigo-500 uppercase mb-3">{p.gstin}</div>
                
                <div className="space-y-1">
                  <p className="text-[12px] font-bold text-slate-500">{p.state}</p>
                  <p className="text-[12px] font-medium text-slate-400 line-clamp-2">
                    {p.address} {p.city && `, ${p.city}`} {p.district && `, ${p.district}`} {p.pincode && `- ${p.pincode}`}
                  </p>
                  {p.addresses && p.addresses.length > 0 && (
                    <p className="text-[10px] font-bold text-indigo-500 mt-2 bg-indigo-50 inline-block px-2 py-1 rounded">
                      +{p.addresses.length} Additional Places
                    </p>
                  )}
                </div>

                {!isActive && (
                  <div className="absolute inset-0 bg-slate-50/60 backdrop-blur-[2px] rounded-[24px] flex items-center justify-center z-10">
                    <span className="px-3 py-1.5 bg-white text-rose-500 text-[11px] font-black uppercase tracking-wider rounded-lg shadow-sm border border-rose-100">Inactive</span>
                  </div>
                )}
                {/* Ensure buttons stay above blur if inactive */}
                {!isActive && (
                   <div className="absolute top-5 right-5 flex gap-2 z-20">
                     <button onClick={() => handleEdit(p)} className="w-[32px] h-[32px] rounded-[10px] bg-white shadow-sm text-slate-400 flex items-center justify-center hover:bg-indigo-50 hover:text-indigo-600 transition-colors"><FaEdit size={14} /></button>
                     <button onClick={() => handleToggleStatus(p)} className="w-[32px] h-[32px] rounded-[10px] bg-white shadow-sm text-emerald-400 flex items-center justify-center hover:bg-emerald-50 hover:text-emerald-600"><FaCheckCircle size={14} /></button>
                   </div>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {/* Modal Profile View */}
      {selectedProfile && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-[32px] w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl">
            {/* Header */}
            <div className="p-6 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
              <div className="flex items-center gap-4">
                <div className="w-[48px] h-[48px] rounded-[14px] bg-indigo-100 text-indigo-600 flex items-center justify-center">
                  <FaBuilding size={20} />
                </div>
                <div>
                  <h2 className="text-[18px] font-black text-slate-800">{selectedProfile.name}</h2>
                  <p className="text-[12px] font-bold text-indigo-500 uppercase tracking-widest mt-1">{selectedProfile.gstin}</p>
                </div>
              </div>
              <button onClick={() => setSelectedProfile(null)} className="w-8 h-8 rounded-full bg-slate-100 text-slate-400 flex items-center justify-center hover:bg-slate-200 hover:text-slate-600 transition-colors"><FaTimes /></button>
            </div>
            {/* Body */}
            <div className="p-6 overflow-y-auto flex-1">
              {/* Profile Details */}
              <div className="mb-8 p-4 bg-slate-50 rounded-2xl border border-slate-100">
                <h3 className="text-[11px] font-black text-slate-400 uppercase tracking-wider mb-2">Registered Address</h3>
                <p className="text-[13px] font-bold text-slate-700">
                  {selectedProfile.address} {selectedProfile.city && `, ${selectedProfile.city}`} {selectedProfile.district && `, ${selectedProfile.district}`} {selectedProfile.state} {selectedProfile.pincode && `- ${selectedProfile.pincode}`}
                </p>
                {selectedProfile.addresses && selectedProfile.addresses.length > 0 && (
                  <div className="mt-4">
                    <h3 className="text-[11px] font-black text-slate-400 uppercase tracking-wider mb-2">Additional Places of Business</h3>
                    <div className="space-y-2">
                      {selectedProfile.addresses.map((addr, idx) => (
                        <div key={idx} className="text-[12px] font-medium text-slate-600">
                          <span className="font-bold text-indigo-600">{addr.type}:</span> {addr.address}, {addr.city}, {addr.state}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Billing Series Management */}
              <h3 className="text-[13px] font-black text-slate-800 uppercase tracking-wider mb-4 flex items-center gap-2">
                <div className="w-2 h-2 rounded-full bg-indigo-500"></div>
                Billing Series Management
              </h3>
              
              <form onSubmit={handleSaveSeries} className="flex gap-2 mb-6">
                <input required placeholder="Prefix (e.g. RET-)" value={seriesData.prefix} onChange={e => setSeriesData({...seriesData, prefix: e.target.value.toUpperCase()})} className="flex-1 px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-[13px] font-bold focus:outline-none focus:border-indigo-400 uppercase placeholder:normal-case" />
                <input required placeholder="Series Name (e.g. Retail)" value={seriesData.name} onChange={e => setSeriesData({...seriesData, name: e.target.value})} className="flex-[1.5] px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-[13px] font-bold focus:outline-none focus:border-indigo-400" />
                <input type="number" placeholder="Last No." value={seriesData.lastNumber} onChange={e => setSeriesData({...seriesData, lastNumber: e.target.value})} className="w-24 px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl text-[13px] font-bold focus:outline-none focus:border-indigo-400" />
                <button type="submit" className="px-5 py-3 bg-indigo-600 text-white rounded-xl hover:bg-indigo-700 flex items-center gap-2 text-[13px] font-black uppercase tracking-wider transition-all hover:shadow-[0_4px_12px_rgba(79,70,229,0.3)]"><FaPlus /> Add</button>
              </form>
              
              <div className="space-y-2">
                {selectedProfile.billingSeries && selectedProfile.billingSeries.length > 0 ? (
                  selectedProfile.billingSeries.map(s => (
                    <div key={s.id} className="flex items-center justify-between p-4 bg-white border border-slate-200 rounded-2xl shadow-sm">
                      <div className="flex items-center gap-4">
                        <div className="px-3 py-1.5 bg-indigo-50 text-indigo-600 rounded-lg text-[13px] font-black uppercase tracking-widest">{s.prefix}</div>
                        <div>
                          <div className="text-[14px] font-bold text-slate-800">{s.name}</div>
                          <div className="text-[11px] font-bold text-slate-400 mt-0.5">Current Bill No: <span className="text-emerald-500">{s.lastNumber}</span></div>
                        </div>
                      </div>
                      <button onClick={() => handleDeleteSeries(s.id)} className="w-8 h-8 rounded-lg bg-rose-50 text-rose-400 flex items-center justify-center hover:bg-rose-100 hover:text-rose-600 transition-colors"><FaTrash size={12}/></button>
                    </div>
                  ))
                ) : (
                  <div className="text-center py-8 bg-slate-50 rounded-2xl border border-slate-100 border-dashed">
                    <p className="text-slate-400 text-[13px] font-bold">No billing series added yet.</p>
                    <p className="text-slate-400 text-[11px] mt-1">Add prefixes like "RET-2425/" or "WHS-" to auto-generate invoice numbers.</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
