import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';
import { useStore } from '../store/useStore';

export default function GodownMaster() {
  const currentType = useStore(state => state.currentType);
  const [godowns, setGodowns] = useState([]);
  const [godownName, setGodownName] = useState('');
  const [message, setMessage] = useState('');

  const fetchGodowns = async () => {
    try {
      const data = await erpApi.getGodowns();
      setGodowns(data);
    } catch (e) {
      console.error(e);
    }
  };

  useEffect(() => {
    fetchGodowns();
  }, []);

  const handleSave = async () => {
    if (!godownName.trim()) {
      alert("Godown name is required");
      return;
    }
    try {
      await erpApi.saveGodown({ name: godownName.trim() });
      setMessage(`Godown saved successfully!`);
      setGodownName('');
      fetchGodowns();
      setTimeout(() => setMessage(''), 3000);
    } catch (error) {
      alert("Error saving godown");
    }
  };

  return (
    <div className="space-y-[14px]">
      <div className="bg-white/90 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Godown Master
        </h2>
        <p className="text-sm font-bold text-slate-500 mb-4">Create and maintain godown / storage location details</p>
        
        <div className="grid grid-cols-1 md:grid-cols-2 gap-[14px]">
          <div>
            <label className="block text-[12px] font-[800] text-slate-600 mb-[3px]">Godown Name *</label>
            <input 
              value={godownName}
              onChange={(e) => setGodownName(e.target.value)}
              placeholder="Eg: Main Godown / Fancy Items Godown" 
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm" 
            />
          </div>
          <div className="flex items-end">
            <button 
              onClick={handleSave}
              className="h-[43px] px-8 bg-active text-white rounded-[14px] font-bold shadow-[0_4px_12px_color-mix(in_srgb,var(--active)_40%,transparent)] hover:-translate-y-[2px] transition-all"
            >
              Save Godown
            </button>
          </div>
        </div>
        {message && <div className="mt-4 text-sm font-bold text-active">{message}</div>}
      </div>

      <div className="bg-white/90 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-slate-500 uppercase tracking-[0.7px] mb-4">Saved Godowns</h2>
        <table className="w-full text-left border-spacing-y-2 border-separate min-w-[300px]">
          <thead>
            <tr>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[80%]">Godown Name</th>
              <th className="text-[11px] font-bold text-slate-500 uppercase px-2 w-[20%]">Action</th>
            </tr>
          </thead>
          <tbody>
            {godowns.map((g) => (
              <tr key={g.id}>
                <td className="px-2 font-bold text-slate-700 bg-slate-50 py-3 rounded-l-[14px] border-y border-l border-slate-200">{g.name}</td>
                <td className="px-2 bg-slate-50 py-3 rounded-r-[14px] border-y border-r border-slate-200">
                  <button 
                    onClick={() => setGodownName(g.name)}
                    className="bg-white text-slate-600 px-3 py-1 rounded-[8px] text-[12px] font-bold border border-slate-200 shadow-sm hover:text-active transition-all"
                  >
                    Edit
                  </button>
                </td>
              </tr>
            ))}
            {godowns.length === 0 && (
              <tr>
                <td colSpan="2" className="px-2 py-4 text-center text-slate-400 font-bold">No godowns added yet.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
