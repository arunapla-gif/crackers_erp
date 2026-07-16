import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';
import { useStore } from '../store/useStore';

export default function VehicleMaster() {
  const currentType = useStore(state => state.currentType);
  const [vehicles, setVehicles] = useState([]);
  
  const [form, setForm] = useState({
    no: '',
    name: '',
    owner_name: '',
    owner_phone: ''
  });
  
  const [drivers, setDrivers] = useState([]);
  const [driverDraft, setDriverDraft] = useState({ name: '', phone: '' });
  const [message, setMessage] = useState('');

  const fetchVehicles = async () => {
    try {
      const data = await erpApi.getVehicles();
      setVehicles(data);
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    fetchVehicles();
  }, []);

  const addDriver = () => {
    if (!driverDraft.name) {
      alert("Driver name is required");
      return;
    }
    setDrivers([...drivers, { ...driverDraft }]);
    setDriverDraft({ name: '', phone: '' });
  };

  const removeDriver = (index) => {
    setDrivers(drivers.filter((_, i) => i !== index));
  };

  const handleSave = async () => {
    if (!form.no) {
      alert("Vehicle Number is required");
      return;
    }
    try {
      await erpApi.saveVehicle({ ...form, drivers });
      setMessage(`Vehicle ${form.no} saved successfully!`);
      setForm({ no: '', name: '', owner_name: '', owner_phone: '' });
      setDrivers([]);
      fetchVehicles();
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      alert("Error saving vehicle");
    }
  };

  const editVehicle = (v) => {
    setForm({ no: v.no, name: v.name || '', owner_name: v.owner_name || '', owner_phone: v.owner_phone || '' });
    setDrivers(Array.isArray(v.drivers) ? v.drivers : []);
  };

  return (
    <div className="space-y-[14px]">
      <div className="bg-white/90 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Vehicle Master
        </h2>
        <p className="text-sm font-bold text-slate-500 mb-4">Create vehicles used for stock transfer between godowns.</p>
        
        <div className="grid grid-cols-1 md:grid-cols-4 gap-[14px]">
          <div>
            <label className="block text-[12px] font-[800] text-slate-600 mb-[3px]">Vehicle Number *</label>
            <input 
              value={form.no}
              onChange={(e) => setForm({...form, no: e.target.value.toUpperCase()})}
              placeholder="TN67AB1234" 
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] font-bold uppercase focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
            />
          </div>
          <div>
            <label className="block text-[12px] font-[800] text-slate-600 mb-[3px]">Vehicle Name</label>
            <input 
              value={form.name}
              onChange={(e) => setForm({...form, name: e.target.value})}
              placeholder="Mini Truck / Van" 
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
            />
          </div>
          <div>
            <label className="block text-[12px] font-[800] text-slate-600 mb-[3px]">Owner Name</label>
            <input 
              value={form.owner_name}
              onChange={(e) => setForm({...form, owner_name: e.target.value})}
              placeholder="Owner name" 
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
            />
          </div>
          <div>
            <label className="block text-[12px] font-[800] text-slate-600 mb-[3px]">Owner Phone</label>
            <input 
              value={form.owner_phone}
              onChange={(e) => setForm({...form, owner_phone: e.target.value})}
              maxLength={10}
              placeholder="10 digit phone" 
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
            />
          </div>
        </div>

        <div className="mt-6 border-t border-slate-200 pt-6">
          <h3 className="text-[12px] font-[800] text-slate-500 mb-3">Attach Drivers to this Vehicle</h3>
          <div className="flex gap-3 items-end">
            <div className="flex-1">
              <input 
                value={driverDraft.name}
                onChange={(e) => setDriverDraft({...driverDraft, name: e.target.value})}
                placeholder="Driver Name" 
                className="w-full min-h-[43px] px-[12px] py-[11px] bg-slate-50 border border-slate-200 rounded-[14px] text-[13px] focus:border-active focus:ring-[3px] focus:ring-active/20"
              />
            </div>
            <div className="flex-1">
              <input 
                value={driverDraft.phone}
                onChange={(e) => setDriverDraft({...driverDraft, phone: e.target.value})}
                maxLength={10}
                placeholder="Driver Phone" 
                className="w-full min-h-[43px] px-[12px] py-[11px] bg-slate-50 border border-slate-200 rounded-[14px] text-[13px] focus:border-active focus:ring-[3px] focus:ring-active/20"
              />
            </div>
            <button onClick={addDriver} className="h-[43px] px-6 bg-slate-800 text-white rounded-[14px] font-bold hover:bg-black transition-all">+ Add Driver</button>
          </div>
          
          {drivers.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-4">
              {drivers.map((d, i) => (
                <div key={i} className="bg-slate-100 border border-slate-200 text-slate-700 px-3 py-1 rounded-[10px] text-xs font-bold flex items-center gap-2">
                  {d.name} ({d.phone})
                  <button onClick={() => removeDriver(i)} className="text-red-500 hover:text-red-700">✕</button>
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="mt-6">
          <button 
            onClick={handleSave}
            className="w-full h-[48px] bg-active text-white rounded-[16px] font-black text-[15px] shadow-[0_4px_12px_color-mix(in_srgb,var(--active)_40%,transparent)] hover:-translate-y-[2px] transition-all"
          >
            SAVE VEHICLE
          </button>
        </div>
        {message && <div className="mt-4 text-center text-sm font-bold text-active">{message}</div>}
      </div>

      {/* SAVED VEHICLES LIST */}
      <div className="bg-white/90 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        <h2 className="text-[13px] font-black text-slate-500 uppercase tracking-[0.7px] mb-4">Saved Vehicles</h2>
        <table className="w-full text-left border-spacing-y-2 border-separate min-w-[700px]">
          <thead>
            <tr>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[15%]">Vehicle No</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[20%]">Name</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[20%]">Owner</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[35%]">Drivers</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[10%] text-center">Action</th>
            </tr>
          </thead>
          <tbody>
            {vehicles.map((v) => (
              <tr key={v.id}>
                <td className="px-2 font-black text-active bg-slate-50 py-3 rounded-l-[14px] border-y border-l border-slate-200">{v.no}</td>
                <td className="px-2 font-bold text-slate-700 bg-slate-50 py-3 border-y border-slate-200">{v.name || '-'}</td>
                <td className="px-2 text-sm text-slate-600 bg-slate-50 py-3 border-y border-slate-200">
                  <div className="font-bold">{v.owner_name}</div>
                  <div className="text-xs text-slate-400">{v.owner_phone}</div>
                </td>
                <td className="px-2 text-xs font-bold text-slate-500 bg-slate-50 py-3 border-y border-slate-200">
                  {Array.isArray(v.drivers) ? v.drivers.map(d => `${d.name} (${d.phone})`).join(', ') : '-'}
                </td>
                <td className="px-2 bg-slate-50 py-3 rounded-r-[14px] border-y border-r border-slate-200 text-center">
                  <button 
                    onClick={() => editVehicle(v)}
                    className="bg-white text-slate-600 px-3 py-1 rounded-[8px] text-[12px] font-bold border border-slate-200 shadow-sm hover:text-active transition-all"
                  >
                    Edit
                  </button>
                </td>
              </tr>
            ))}
            {vehicles.length === 0 && (
              <tr>
                <td colSpan="5" className="px-2 py-4 text-center text-slate-400 font-bold">No vehicles added yet.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
