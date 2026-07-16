import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';

export default function ProductionEntry() {
  const [date, setDate] = useState(new Date().toISOString().split('T')[0]);
  
  // Data Master
  const [employeesByRole, setEmployeesByRole] = useState({});
  const [products, setProducts] = useState([]);
  const [records, setRecords] = useState([]);

  // Matrix State
  // columns = [{ id: uniqueId, productName: 'Chakkars', rate: 10 }]
  const [columns, setColumns] = useState([]);
  // matrix = { employeeId_1: { colId_1: qty, colId_2: qty }, employeeId_2: { ... } }
  const [matrix, setMatrix] = useState({});

  const [message, setMessage] = useState('');
  const [selectedProductId, setSelectedProductId] = useState('');

  const fetchInitialData = async () => {
    try {
      const [emps, prods, prodRecords] = await Promise.all([
        erpApi.getEmployees(),
        erpApi.getProducts(),
        erpApi.getDailyProductions()
      ]);
      
      const contractualEmps = emps.filter(e => e.status === 'Active' && e.paymentType === 'Contractual');
      
      // Group employees by role
      const grouped = {};
      contractualEmps.forEach(emp => {
        const role = emp.role || 'Unassigned';
        if (!grouped[role]) grouped[role] = [];
        grouped[role].push(emp);
      });
      setEmployeesByRole(grouped);
      
      setProducts(prods.filter(p => p.type === 'WIP')); // Only Factory Processing Items
      setRecords(prodRecords);
    } catch (e) {
      console.log('Error fetching initial data', e);
    }
  };

  useEffect(() => {
    fetchInitialData();
  }, []);

  const handleAddColumn = () => {
    if (!selectedProductId) return;
    const prod = products.find(p => p.id.toString() === selectedProductId);
    if (prod) {
      const newColId = Date.now().toString(); // unique ID for column instance
      setColumns([...columns, { id: newColId, productId: prod.id, productName: prod.name, rate: prod.rate || 0 }]);
      setSelectedProductId('');
    }
  };

  const handleRemoveColumn = (colId) => {
    setColumns(columns.filter(c => c.id !== colId));
    
    // Clean up matrix
    const newMatrix = { ...matrix };
    Object.keys(newMatrix).forEach(empId => {
      delete newMatrix[empId][colId];
    });
    setMatrix(newMatrix);
  };

  const handleRateChange = (colId, newRate) => {
    setColumns(columns.map(c => c.id === colId ? { ...c, rate: newRate } : c));
  };

  const handleCellChange = (empId, colId, value) => {
    setMatrix(prev => ({
      ...prev,
      [empId]: {
        ...(prev[empId] || {}),
        [colId]: value
      }
    }));
  };

  const handleClear = () => {
    setDate(new Date().toISOString().split('T')[0]);
    setColumns([]);
    setMatrix({});
    setMessage('');
  };

  const handleSave = async () => {
    if (!date) {
      alert('Date is required');
      return;
    }
    if (columns.length === 0) {
      alert('Please add at least one product column.');
      return;
    }

    // Build the bulk payload
    const groupedPayloads = [];

    Object.keys(matrix).forEach(empId => {
      const empData = matrix[empId];
      const items = [];
      let totalAmount = 0;

      columns.forEach(col => {
        const qtyStr = empData[col.id];
        if (qtyStr && parseFloat(qtyStr) > 0) {
          const qty = parseFloat(qtyStr);
          const rate = parseFloat(col.rate) || 0;
          const total = qty * rate;
          totalAmount += total;
          items.push({
            itemName: col.productName,
            quantity: qty,
            pieceRate: rate,
            total: total.toFixed(2)
          });
        }
      });

      if (items.length > 0) {
        groupedPayloads.push({
          date: date,
          employeeId: parseInt(empId),
          totalAmount: totalAmount.toFixed(2),
          items: items
        });
      }
    });

    if (groupedPayloads.length === 0) {
      alert('No quantities entered. Please enter quantities for at least one employee.');
      return;
    }

    try {
      const savePromises = groupedPayloads.map(data => erpApi.saveDailyProduction(data));
      await Promise.all(savePromises);
      setMessage('Matrix Production saved successfully!');
      handleClear();
      fetchInitialData();
    } catch (error) {
      alert('Error saving production data.');
    }
  };

  const handleDelete = async (id) => {
    if (window.confirm('Are you sure you want to delete this daily record?')) {
      try {
        await erpApi.deleteDailyProduction(id);
        setMessage('Record deleted successfully!');
        fetchInitialData();
      } catch (error) {
        alert('Error deleting record.');
      }
    }
  };

  const calculateColTotal = (colId) => {
    let total = 0;
    Object.keys(matrix).forEach(empId => {
      total += parseFloat(matrix[empId]?.[colId]) || 0;
    });
    return total;
  };

  return (
    <div className="space-y-[14px]">
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 hover:-translate-y-[1px] hover:border-[#dbe3ef] transition-all duration-150">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Daily Production Matrix
        </h2>

        <div className="flex flex-col md:flex-row gap-4 mb-[18px] items-end bg-slate-50 p-[14px] rounded-[18px] border border-slate-200">
          <div className="w-full md:w-1/4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Date *</label>
            <input type="date" value={date} onChange={e => setDate(e.target.value)} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm transition-all font-bold" />
          </div>
          
          <div className="w-full md:w-1/2">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Add Product Column</label>
            <div className="flex gap-2">
              <select value={selectedProductId} onChange={e => setSelectedProductId(e.target.value)} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[13px] focus:outline-none focus:border-active font-bold">
                <option value="">Select Product...</option>
                {products.map(p => (
                  <option key={p.id} value={p.id}>{p.name}</option>
                ))}
              </select>
              <button onClick={handleAddColumn} className="px-[16px] bg-active text-white font-[900] rounded-[14px] whitespace-nowrap shadow-md hover:-translate-y-[1px] transition-all">
                + Add
              </button>
            </div>
          </div>
        </div>

        <div className="overflow-x-auto border border-slate-200 rounded-[18px] shadow-sm">
          <table className="w-full text-left border-collapse bg-white">
            <thead>
              <tr>
                <th className="p-[12px] bg-slate-100 border-b border-r border-slate-200 min-w-[200px] sticky left-0 z-10 shadow-[2px_0_5px_-2px_rgba(0,0,0,0.1)]">
                  <div className="text-[11px] font-[900] text-slate-500 uppercase tracking-wide">Contractual Employees</div>
                </th>
                {columns.map(col => (
                  <th key={col.id} className="p-[14px] bg-slate-50 border-b border-r border-slate-200 min-w-[160px] align-middle relative group text-center">
                    <button onClick={() => handleRemoveColumn(col.id)} className="absolute top-2 right-2 text-red-400 hover:text-red-600 opacity-0 group-hover:opacity-100 transition-opacity font-bold text-lg">×</button>
                    <div className="text-[18px] font-black text-indigo-900 leading-tight px-4 tracking-tight">{col.productName}</div>
                  </th>
                ))}
                {columns.length === 0 && (
                  <th className="p-[20px] text-center text-slate-400 text-[12px] font-bold italic border-b border-slate-200">
                    Add product columns to begin entry...
                  </th>
                )}
              </tr>
            </thead>
            <tbody>
              {Object.keys(employeesByRole).map(role => (
                <React.Fragment key={role}>
                  {/* Category Header Row */}
                  <tr>
                    <td colSpan={columns.length + 1} className="bg-slate-200 p-[8px_12px] text-[11px] font-[900] text-slate-700 uppercase tracking-[1px] sticky left-0 z-10 border-y border-slate-300">
                      {role}
                    </td>
                  </tr>
                  
                  {/* Employee Rows */}
                  {employeesByRole[role].map(emp => (
                    <tr key={emp.id} className="hover:bg-slate-50 transition-colors">
                      <td className="p-[10px_12px] border-b border-r border-slate-200 font-bold text-[13px] text-slate-700 sticky left-0 bg-white/95 backdrop-blur shadow-[2px_0_5px_-2px_rgba(0,0,0,0.05)]">
                        {emp.name}
                      </td>
                      {columns.map(col => (
                        <td key={col.id} className="p-[6px] border-b border-r border-slate-200 bg-white group hover:bg-indigo-50/50 transition-colors">
                          <input 
                            type="number" 
                            placeholder="Qty"
                            value={(matrix[emp.id] && matrix[emp.id][col.id]) || ''}
                            onChange={(e) => handleCellChange(emp.id, col.id, e.target.value)}
                            className="w-full h-[36px] px-[8px] bg-transparent text-center border border-transparent group-hover:border-indigo-200 focus:border-indigo-500 focus:bg-white focus:ring-[3px] focus:ring-indigo-100 rounded-[8px] text-[14px] font-[800] text-indigo-900 placeholder-slate-300 outline-none transition-all"
                          />
                        </td>
                      ))}
                      {columns.length === 0 && <td className="border-b border-slate-200"></td>}
                    </tr>
                  ))}
                </React.Fragment>
              ))}
            </tbody>
            <tfoot>
              <tr>
                <td className="p-[12px] bg-slate-100 border-t-2 border-r border-slate-300 font-black text-[12px] text-slate-800 sticky left-0 z-10 shadow-[2px_0_5px_-2px_rgba(0,0,0,0.1)] text-right uppercase tracking-wider">
                  Total Units
                </td>
                {columns.map(col => (
                  <td key={col.id} className="p-[12px] bg-indigo-50 border-t-4 border-t-active border-r border-slate-300 text-center shadow-[inset_0_2px_10px_rgba(0,0,0,0.02)]">
                    <div className="text-[24px] font-black text-indigo-900 tracking-tight">{calculateColTotal(col.id)}</div>
                    <div className="text-[11px] font-bold text-indigo-500 uppercase tracking-widest mt-1">Total Pcs</div>
                  </td>
                ))}
                {columns.length === 0 && <td className="bg-slate-100 border-t-2 border-r border-slate-300"></td>}
              </tr>
            </tfoot>
          </table>
        </div>

        <div className="flex justify-end gap-[8px] mt-[18px] bg-slate-50 p-[12px] border border-slate-200 rounded-[18px]">
          <button onClick={handleClear} className="min-h-[40px] px-[16px] py-[10px] bg-slate-200 text-slate-900 border border-slate-300 rounded-[14px] font-[900] hover:-translate-y-[1px] transition-all">Clear Grid</button>
          <button onClick={handleSave} className="min-h-[40px] px-[16px] py-[10px] bg-active text-white rounded-[14px] font-[900] shadow-[0_10px_24px_rgba(15,23,42,0.12)] hover:-translate-y-[1px] transition-all">Save Bulk Production</button>
        </div>
        
        {message && (
          <div className="inline-block mt-[12px] bg-green-50 border border-green-200 text-green-700 p-[10px_12px] rounded-[14px] font-[900] text-[13px]">
            {message}
          </div>
        )}
      </div>

      {/* Recent Logs Table remains for viewing history */}
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Recent Production Logs (History)
        </h2>
        <table className="w-full border-separate border-spacing-y-[8px] text-[14px]">
          <thead>
            <tr>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Date</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Employee Name</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Items Produced</th>
              <th className="text-right font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Actions</th>
            </tr>
          </thead>
          <tbody>
            {records.map((r, i) => (
              <tr key={i} className="hover:bg-slate-50 transition-all">
                <td className="bg-white border-y border-slate-200 border-l rounded-l-[14px] p-[10px] font-[800] text-slate-800">{r.date.split('T')[0]}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] font-bold text-slate-700">{r.employee?.name}</td>
                <td className="bg-white border-y border-slate-200 p-[10px]">
                  <div className="flex flex-col gap-1">
                    {r.items.map((item, idx) => (
                      <div key={idx} className="text-[11px] font-bold text-slate-500">
                        {item.itemName} (Qty: {item.quantity})
                      </div>
                    ))}
                  </div>
                </td>
                <td className="bg-white border-y border-slate-200 border-r rounded-r-[14px] p-[10px] text-right">
                  <div className="flex justify-end gap-2">
                    <button onClick={() => handleDelete(r.id)} className="px-3 py-1 bg-red-50 text-red-600 hover:bg-red-100 rounded-[8px] font-bold text-[11px] transition-colors">
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            ))}
            {records.length === 0 && (
              <tr>
                <td colSpan={4} className="bg-white border border-slate-200 rounded-[14px] p-[10px] text-center text-slate-500">No production logs found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
