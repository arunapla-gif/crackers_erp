import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';

export default function EmployeeMaster() {
  const [formData, setFormData] = useState({
    id: null, name: '', mobile: '', role: '', salary: '', paymentType: 'Monthly', unit: '', status: 'Active'
  });
  const [employees, setEmployees] = useState([]);
  const [message, setMessage] = useState('');

  // Advances Modal State
  const [advanceModal, setAdvanceModal] = useState({ isOpen: false, employee: null });
  const [advanceList, setAdvanceList] = useState([]);
  const [newAdvance, setNewAdvance] = useState({ date: new Date().toISOString().split('T')[0], amount: '', description: '' });

  const fetchEmployees = async () => {
    try {
      const data = await erpApi.getEmployees();
      setEmployees(data);
    } catch (e) {
      console.log('Backend not available or employees table empty');
    }
  };

  useEffect(() => {
    fetchEmployees();
  }, []);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleClear = () => {
    setFormData({ id: null, name: '', mobile: '', role: '', salary: '', paymentType: 'Monthly', unit: '', status: 'Active' });
    setMessage('');
  };

  const handleEdit = (employee) => {
    setFormData(employee);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleToggleStatus = async (employee) => {
    const newStatus = employee.status === 'Active' ? 'Inactive' : 'Active';
    try {
      await erpApi.saveEmployee({ ...employee, status: newStatus });
      setMessage(`Employee marked as ${newStatus}!`);
      fetchEmployees();
    } catch (error) {
      alert('Error updating employee status');
    }
  };

  const handleSave = async () => {
    if (!formData.name) {
      alert('Employee Name is required');
      return;
    }
    try {
      await erpApi.saveEmployee(formData);
      setMessage('Employee saved successfully!');
      handleClear();
      fetchEmployees();
    } catch (error) {
      alert('Error saving to Postgres DB.');
    }
  };

  const handleOpenAdvance = async (emp) => {
    setAdvanceModal({ isOpen: true, employee: emp });
    try {
      const data = await erpApi.getAdvances(emp.id);
      setAdvanceList(data);
    } catch (e) {
      console.error('Error fetching advances');
    }
  };

  const handleCloseAdvance = () => {
    setAdvanceModal({ isOpen: false, employee: null });
    setAdvanceList([]);
    setNewAdvance({ date: new Date().toISOString().split('T')[0], amount: '', description: '' });
  };

  const handleSaveAdvance = async () => {
    if (!newAdvance.amount || parseFloat(newAdvance.amount) <= 0) {
      alert('Please enter a valid amount');
      return;
    }
    try {
      await erpApi.saveAdvance({
        employeeId: advanceModal.employee.id,
        ...newAdvance
      });
      setNewAdvance({ date: new Date().toISOString().split('T')[0], amount: '', description: '' });
      // Refresh list
      const data = await erpApi.getAdvances(advanceModal.employee.id);
      setAdvanceList(data);
      fetchEmployees(); // Refresh balance in main list
    } catch (e) {
      alert('Error saving advance');
    }
  };

  return (
    <div className="space-y-[14px]">
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 hover:-translate-y-[1px] hover:border-[#dbe3ef] transition-all duration-150">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Employee Master
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-[14px]">
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Employee Name *</label>
            <input name="name" value={formData.name} onChange={handleChange} placeholder="Full Name" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all font-bold" />
          </div>
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Mobile Number</label>
            <input name="mobile" value={formData.mobile} onChange={handleChange} placeholder="10-digit number" maxLength={10} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Role</label>
            <input name="role" value={formData.role} onChange={handleChange} placeholder="e.g. Manager, Worker" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Payment Type</label>
            <select name="paymentType" value={formData.paymentType} onChange={handleChange} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all font-bold">
              <option value="Monthly">Monthly Salary</option>
              <option value="Contractual">Contractual / Piece Rate</option>
            </select>
          </div>
          <div className="col-span-1 md:col-span-4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">
              {formData.paymentType === 'Contractual' ? 'Piece Rate (₹)' : 'Basic Salary (₹)'}
            </label>
            <input type="number" name="salary" value={formData.salary} onChange={handleChange} placeholder="0.00" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
          </div>
          {formData.paymentType === 'Contractual' && (
            <div className="col-span-1 md:col-span-4">
              <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Unit (Optional)</label>
              <input name="unit" value={formData.unit || ''} onChange={handleChange} placeholder="e.g. per 1000 pcs, per gross" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-[inset_0_1px_0_rgba(255,255,255,0.7)] transition-all" />
            </div>
          )}
        </div>

        <div className="flex justify-end gap-[8px] mt-[18px] bg-slate-50 p-[12px] border border-slate-200 rounded-[18px]">
          <button onClick={handleClear} className="min-h-[40px] px-[16px] py-[10px] bg-slate-200 text-slate-900 border border-slate-300 rounded-[14px] font-[900] hover:-translate-y-[1px] transition-all">Clear</button>
          <button onClick={handleSave} className="min-h-[40px] px-[16px] py-[10px] bg-active text-white rounded-[14px] font-[900] shadow-[0_10px_24px_rgba(15,23,42,0.12)] hover:-translate-y-[1px] transition-all">Save Employee</button>
        </div>
        
        {message && (
          <div className="inline-block mt-[12px] bg-green-50 border border-green-200 text-green-700 p-[10px_12px] rounded-[14px] font-[900] text-[13px]">
            {message}
          </div>
        )}
      </div>

      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Employee List
        </h2>
        <table className="w-full border-separate border-spacing-y-[8px] text-[14px]">
          <thead>
            <tr>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Name</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Mobile</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Role</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Type</th>
              <th className="text-right font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Rate/Salary (₹)</th>
              <th className="text-right font-bold text-rose-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Advance Bal.</th>
              <th className="text-center font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Status</th>
              <th className="text-right font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Actions</th>
            </tr>
          </thead>
          <tbody>
            {employees.map((e, i) => (
              <tr key={i} className={`hover:bg-slate-50 transition-all ${e.status === 'Inactive' ? 'opacity-60 grayscale' : ''}`}>
                <td className="bg-white border-y border-slate-200 border-l rounded-l-[14px] p-[10px] font-[800] text-slate-800">{e.name}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">{e.mobile || '-'}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">{e.role || '-'}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700">
                  <span className={`px-2 py-1 rounded-[6px] text-[10px] font-bold ${e.paymentType === 'Contractual' ? 'bg-indigo-100 text-indigo-700' : 'bg-slate-100 text-slate-700'}`}>
                    {e.paymentType}
                  </span>
                </td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-800 font-bold text-right">
                  {e.salary || '0.00'} <span className="text-[10px] text-slate-400 font-normal">{e.paymentType === 'Contractual' && e.unit ? ` / ${e.unit}` : ''}</span>
                </td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-rose-600 font-black text-right">
                  {parseFloat(e.advanceBalance) > 0 ? `₹${parseFloat(e.advanceBalance).toFixed(2)}` : '-'}
                </td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-center">
                  <span className={`inline-block px-2 py-1 rounded-[6px] text-[10px] font-bold uppercase tracking-wider ${e.status === 'Inactive' ? 'bg-red-100 text-red-600' : 'bg-green-100 text-green-600'}`}>
                    {e.status || 'Active'}
                  </span>
                </td>
                <td className="bg-white border-y border-slate-200 border-r rounded-r-[14px] p-[10px] text-right">
                  <div className="flex justify-end gap-2">
                    <button onClick={() => handleOpenAdvance(e)} className="px-3 py-1 bg-amber-50 text-amber-600 hover:bg-amber-100 rounded-[8px] font-bold text-[11px] transition-colors">
                      Advances
                    </button>
                    <button onClick={() => handleEdit(e)} className="px-3 py-1 bg-blue-50 text-blue-600 hover:bg-blue-100 rounded-[8px] font-bold text-[11px] transition-colors">
                      Edit
                    </button>
                    <button onClick={() => handleToggleStatus(e)} className={`px-3 py-1 rounded-[8px] font-bold text-[11px] transition-colors ${e.status === 'Inactive' ? 'bg-emerald-50 text-emerald-600 hover:bg-emerald-100' : 'bg-rose-50 text-rose-600 hover:bg-rose-100'}`}>
                      {e.status === 'Inactive' ? 'Enable' : 'Disable'}
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {employees.length === 0 && (
              <tr>
                <td colSpan={6} className="bg-white border border-slate-200 rounded-[14px] p-[10px] text-center text-slate-500">No employees found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Advance Modal */}
      {advanceModal.isOpen && advanceModal.employee && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm">
          <div className="bg-white rounded-[24px] shadow-2xl w-full max-w-2xl overflow-hidden flex flex-col max-h-[90vh]">
            <div className="p-[20px_24px] border-b border-slate-200 flex justify-between items-center bg-slate-50">
              <div>
                <h3 className="text-[16px] font-black text-slate-800 uppercase tracking-wide">Advance Ledger</h3>
                <p className="text-[13px] font-bold text-slate-500">{advanceModal.employee.name} — Current Balance: <span className="text-rose-600">₹{parseFloat(advanceModal.employee.advanceBalance).toFixed(2)}</span></p>
              </div>
              <button onClick={handleCloseAdvance} className="text-slate-400 hover:text-slate-700 text-2xl font-bold transition-colors">&times;</button>
            </div>
            
            <div className="p-[24px] border-b border-slate-200 bg-white">
              <h4 className="text-[12px] font-bold text-slate-500 uppercase tracking-wider mb-3">Issue New Advance</h4>
              <div className="flex gap-3 items-end">
                <div className="flex-1">
                  <label className="block text-[11px] font-[800] text-[#334155] mb-[2px]">Date</label>
                  <input type="date" value={newAdvance.date} onChange={e => setNewAdvance({...newAdvance, date: e.target.value})} className="w-full h-[40px] px-[12px] border border-slate-300 rounded-[10px] text-[13px] font-bold focus:outline-none focus:border-indigo-500" />
                </div>
                <div className="flex-1">
                  <label className="block text-[11px] font-[800] text-[#334155] mb-[2px]">Amount (₹)</label>
                  <input type="number" placeholder="0.00" value={newAdvance.amount} onChange={e => setNewAdvance({...newAdvance, amount: e.target.value})} className="w-full h-[40px] px-[12px] border border-slate-300 rounded-[10px] text-[13px] font-bold focus:outline-none focus:border-indigo-500 text-rose-600" />
                </div>
                <div className="flex-[2]">
                  <label className="block text-[11px] font-[800] text-[#334155] mb-[2px]">Description</label>
                  <input type="text" placeholder="e.g. Festival Loan" value={newAdvance.description} onChange={e => setNewAdvance({...newAdvance, description: e.target.value})} className="w-full h-[40px] px-[12px] border border-slate-300 rounded-[10px] text-[13px] font-bold focus:outline-none focus:border-indigo-500" />
                </div>
                <button onClick={handleSaveAdvance} className="h-[40px] px-[16px] bg-amber-500 hover:bg-amber-600 text-white font-bold text-[13px] rounded-[10px] shadow-sm transition-colors whitespace-nowrap">Give Advance</button>
              </div>
            </div>

            <div className="flex-1 overflow-y-auto p-[24px] bg-slate-50">
              <h4 className="text-[12px] font-bold text-slate-500 uppercase tracking-wider mb-3">Advance History</h4>
              <div className="bg-white border border-slate-200 rounded-[16px] overflow-hidden">
                <table className="w-full text-left border-collapse text-[13px]">
                  <thead className="bg-slate-100">
                    <tr>
                      <th className="p-[10px_16px] font-black text-slate-600 border-b border-slate-200 text-[11px] uppercase">Date</th>
                      <th className="p-[10px_16px] font-black text-slate-600 border-b border-slate-200 text-[11px] uppercase">Type</th>
                      <th className="p-[10px_16px] font-black text-slate-600 border-b border-slate-200 text-[11px] uppercase">Description</th>
                      <th className="p-[10px_16px] font-black text-slate-600 border-b border-slate-200 text-[11px] uppercase text-right">Amount (₹)</th>
                    </tr>
                  </thead>
                  <tbody>
                    {advanceList.map((log, idx) => (
                      <tr key={idx} className="border-b border-slate-100 last:border-0 hover:bg-slate-50">
                        <td className="p-[10px_16px] font-bold text-slate-600">{new Date(log.date).toLocaleDateString()}</td>
                        <td className="p-[10px_16px]">
                          <span className={`px-2 py-1 rounded-[6px] text-[10px] font-bold ${log.type === 'GIVEN' ? 'bg-rose-100 text-rose-700' : 'bg-green-100 text-green-700'}`}>
                            {log.type}
                          </span>
                        </td>
                        <td className="p-[10px_16px] text-slate-500">{log.description || '-'}</td>
                        <td className={`p-[10px_16px] font-black text-right ${log.type === 'GIVEN' ? 'text-rose-600' : 'text-green-600'}`}>
                          {parseFloat(log.amount).toFixed(2)}
                        </td>
                      </tr>
                    ))}
                    {advanceList.length === 0 && (
                      <tr><td colSpan={4} className="p-[16px] text-center text-slate-400 italic">No advances found for this employee.</td></tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
