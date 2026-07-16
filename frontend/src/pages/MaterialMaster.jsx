import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';

export default function MaterialMaster() {
  const [formData, setFormData] = useState({
    code: '', name: '', type: 'RM', category: '', hsn: '', tax: '18.00', rate: '0.00', unit_qty: '1', unit: 'Kg', pack_unit: 'Bag', status: 'Active'
  });
  const [materials, setMaterials] = useState([]);
  const [message, setMessage] = useState('');

  const fetchMaterials = async () => {
    try {
      const data = await erpApi.getProducts();
      setMaterials(data.filter(p => p.type === 'RM'));
    } catch (e) {
      console.log('Backend not available or products table empty');
    }
  };

  const loadNextCode = async () => {
    const code = await erpApi.getNextProductCode('RM');
    setFormData({
      code,
      name: '',
      type: 'RM',
      category: '',
      hsn: '',
      tax: '18.00',
      rate: '0.00',
      unit_qty: '1',
      unit: 'Kg',
      pack_unit: 'Bag',
      status: 'Active'
    });
  };

  useEffect(() => {
    fetchMaterials();
    loadNextCode();
  }, []);

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleClear = () => {
    setMessage('');
    fetchMaterials();
    loadNextCode();
  };

  const handleEdit = (material) => {
    setFormData({
      ...material,
      category: material.category || '',
      tax: String(material.tax),
      rate: String(material.rate),
      unit_qty: String(material.unit_qty)
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleToggleStatus = async (material) => {
    const newStatus = material.status === 'Active' ? 'Inactive' : 'Active';
    try {
      await erpApi.saveProduct({
        ...material,
        tax: parseFloat(material.tax),
        rate: parseFloat(material.rate),
        unit_qty: parseInt(material.unit_qty),
        status: newStatus
      });
      setMessage(`Material status set to ${newStatus}!`);
      fetchMaterials();
    } catch (error) {
      alert('Error updating material status');
    }
  };

  const handleSave = async () => {
    if (!formData.code || !formData.name) {
      alert('Material Code and Name are required');
      return;
    }
    try {
      await erpApi.saveProduct({
        ...formData,
        tax: parseFloat(formData.tax),
        rate: parseFloat(formData.rate),
        unit_qty: parseInt(formData.unit_qty)
      });
      setMessage(`Material ${formData.code} saved successfully!`);
      handleClear();
    } catch (error) {
      const errorMsg = error.response?.data?.error || error.message;
      alert(`Error saving material: ${errorMsg}`);
    }
  };

  const renderMaterialTable = () => (
    <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
      <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
        <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
        Raw Materials ({materials.length})
      </h2>
      <table className="w-full border-separate border-spacing-y-[8px] text-[14px]">
        <thead>
          <tr>
            <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Code</th>
            <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Name</th>
            <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Category</th>
            <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Pricing Unit</th>
            <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Pack Info</th>
            <th className="text-center font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Status</th>
            <th className="text-right font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Actions</th>
          </tr>
        </thead>
        <tbody>
          {materials.map((p, i) => (
            <tr key={i} className={`hover:bg-slate-50 transition-all ${p.status === 'Inactive' ? 'opacity-60 grayscale' : ''}`}>
              <td className="bg-white border-y border-slate-200 border-l rounded-l-[14px] p-[10px] font-[800] text-slate-800">{p.code}</td>
              <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">{p.name}</td>
              <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700 font-bold text-active">{p.category || '-'}</td>
              <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700 font-[800]">{p.unit}</td>
              <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">
                <span className="font-bold">{p.unit_qty} {p.unit}</span> / {p.pack_unit || 'Pack'}
              </td>
              <td className="bg-white border-y border-slate-200 p-[10px] text-center">
                <span className={`inline-block px-2 py-1 rounded-[6px] text-[10px] font-bold uppercase tracking-wider ${p.status === 'Inactive' ? 'bg-red-100 text-red-600' : 'bg-green-100 text-green-600'}`}>
                  {p.status || 'Active'}
                </span>
              </td>
              <td className="bg-white border-y border-slate-200 border-r rounded-r-[14px] p-[10px] text-right">
                <div className="flex justify-end gap-2">
                  <button onClick={() => handleEdit(p)} className="px-3 py-1 bg-blue-50 text-blue-600 hover:bg-blue-100 rounded-[8px] font-bold text-[11px] transition-colors">
                    Edit
                  </button>
                  <button onClick={() => handleToggleStatus(p)} className={`px-3 py-1 rounded-[8px] font-bold text-[11px] transition-colors ${p.status === 'Inactive' ? 'bg-emerald-50 text-emerald-600 hover:bg-emerald-100' : 'bg-rose-50 text-rose-600 hover:bg-rose-100'}`}>
                    {p.status === 'Inactive' ? 'Enable' : 'Disable'}
                  </button>
                </div>
              </td>
            </tr>
          ))}
          {materials.length === 0 && (
            <tr>
              <td colSpan={7} className="bg-white border border-slate-200 rounded-[14px] p-[10px] text-center text-slate-500">No raw materials found</td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );

  return (
    <div className="space-y-[14px]">
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 hover:-translate-y-[1px] hover:border-[#dbe3ef] transition-all duration-150">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Material Master
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-[14px]">
          <div className="col-span-1 md:col-span-2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Material Code
              <span className="ml-2 px-[6px] py-[2px] text-[9px] font-black bg-active/10 text-active rounded-[5px] uppercase tracking-wider">Auto</span>
            </label>
            <input name="code" value={formData.code} onChange={handleChange} placeholder="e.g. RM001" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-active/30 rounded-[14px] text-[14px] font-black text-active focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all uppercase" />
          </div>
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Material Name *</label>
            <input name="name" value={formData.name} onChange={handleChange} placeholder="e.g. Gun Powder" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Category</label>
            <input name="category" value={formData.category} onChange={handleChange} placeholder="e.g. Chemicals, Paper" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">HSN Code</label>
            <input name="hsn" value={formData.hsn} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Tax (%)</label>
            <select name="tax" value={formData.tax} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all">
              <option value="0.00">0% (Exempt)</option>
              <option value="5.00">5%</option>
              <option value="12.00">12%</option>
              <option value="18.00">18%</option>
              <option value="28.00">28%</option>
            </select>
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Pricing Unit</label>
            <select name="unit" value={formData.unit} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all">
              <option>Kg</option>
              <option>Ton</option>
              <option>Litre</option>
              <option>Meters</option>
              <option>Pcs</option>
            </select>
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Packing Unit</label>
            <select name="pack_unit" value={formData.pack_unit} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all">
              <option>Bag</option>
              <option>Box</option>
              <option>Drum</option>
              <option>Roll</option>
              <option>Bundle</option>
              <option>Pkt</option>
              <option>Pcs</option>
            </select>
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Qty per Pack</label>
            <input name="unit_qty" type="number" value={formData.unit_qty} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
        </div>

        <div className="flex justify-end gap-[8px] mt-[18px] bg-slate-50 p-[12px] border border-slate-200 rounded-[18px]">
          <button onClick={handleClear} className="min-h-[40px] px-[16px] py-[10px] bg-slate-200 text-slate-900 border border-slate-300 rounded-[14px] font-[900] hover:-translate-y-[1px] transition-all">Clear</button>
          <button onClick={handleSave} className="min-h-[40px] px-[16px] py-[10px] bg-yellow-500 text-white rounded-[14px] font-[900] shadow-[0_10px_24px_rgba(234,179,8,0.2)] hover:-translate-y-[1px] transition-all">Save Material</button>
        </div>
        
        {message && (
          <div className="inline-block mt-[12px] bg-yellow-50 border border-yellow-200 text-yellow-700 p-[10px_12px] rounded-[14px] font-[900] text-[13px]">
            {message}
          </div>
        )}
      </div>

      {renderMaterialTable()}
    </div>
  );
}
