import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';

export default function PayrollEntry() {
  const [payoutDate, setPayoutDate] = useState(''); // Stores the selected Saturday date
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  const [employeesByRole, setEmployeesByRole] = useState({});
  const [employees, setEmployees] = useState([]);
  const [matrix, setMatrix] = useState({}); // { empId: { basicSalary, allowance, deduction, netSalary, status, paymentType, products: {}, logs: [] } }
  const [uniqueProducts, setUniqueProducts] = useState([]);
  const [expandedRows, setExpandedRows] = useState([]); // Array of empIds that are expanded
  
  const [payrolls, setPayrolls] = useState([]);
  const [isFetchingLogs, setIsFetchingLogs] = useState(false);
  const [message, setMessage] = useState('');

  const calculateNetSalary = (basic, allow, deduc) => {
    const b = parseFloat(basic) || 0;
    const a = parseFloat(allow) || 0;
    const d = parseFloat(deduc) || 0;
    return (b + a - d).toFixed(2);
  };

  const fetchInitialData = async () => {
    try {
      const [emps, pays] = await Promise.all([
        erpApi.getEmployees(),
        erpApi.getPayrolls()
      ]);
      const activeEmps = emps.filter(e => e.status === 'Active');
      setEmployees(activeEmps);
      setPayrolls(pays);

      const grouped = {};
      const initialMatrix = {};
      
      activeEmps.forEach(emp => {
        const role = emp.role || 'Unassigned';
        if (!grouped[role]) grouped[role] = [];
        grouped[role].push(emp);
        
        initialMatrix[emp.id] = {
          basicSalary: emp.paymentType === 'Monthly' ? emp.salary : '',
          allowance: '',
          deduction: '',
          advanceBalance: parseFloat(emp.advanceBalance || 0),
          netSalary: emp.paymentType === 'Monthly' ? emp.salary : '0.00',
          status: 'Paid',
          paymentType: emp.paymentType,
          products: {},
          logs: []
        };
      });
      
      setEmployeesByRole(grouped);
      setMatrix(initialMatrix);
    } catch (e) {
      console.log('Error fetching initial data', e);
    }
  };

  useEffect(() => {
    fetchInitialData();
  }, []);

  const handleDateChange = (e) => {
    const value = e.target.value;
    setPayoutDate(value);

    if (value) {
      const pd = new Date(value);
      if (!isNaN(pd.getTime())) {
        const end = new Date(pd);
        end.setDate(pd.getDate() - 2); // Thursday
        const start = new Date(end);
        start.setDate(end.getDate() - 6); // Friday
        
        setStartDate(start.toISOString().split('T')[0]);
        setEndDate(end.toISOString().split('T')[0]);
      }
    } else {
      setStartDate('');
      setEndDate('');
    }
  };

  const handleFetchAllLogs = async () => {
    if (!startDate || !endDate) {
      alert('Please select a Payout Date first.');
      return;
    }
    
    setIsFetchingLogs(true);
    try {
      const contractualEmps = employees.filter(e => e.paymentType === 'Contractual');
      const promises = contractualEmps.map(emp => 
        erpApi.getAggregateProduction(emp.id, startDate, endDate).then(data => ({ id: emp.id, data }))
      );
      
      const results = await Promise.all(promises);
      const newMatrix = { ...matrix };
      const allProducts = new Set();
      
      results.forEach(res => {
        const basic = parseFloat(res.data.totalAmount || 0).toFixed(2);
        
        const prodQuantities = {};
        const aggregatedLogs = {};

        if (res.data.details) {
          res.data.details.forEach(log => {
            const dateStr = log.date.split('T')[0];
            
            if (!aggregatedLogs[dateStr]) {
              aggregatedLogs[dateStr] = {
                id: dateStr,
                date: log.date,
                totalAmount: 0,
                itemsMap: {}
              };
            }
            
            aggregatedLogs[dateStr].totalAmount += parseFloat(log.totalAmount || 0);

            log.items.forEach(item => {
              allProducts.add(item.itemName);
              prodQuantities[item.itemName] = (prodQuantities[item.itemName] || 0) + item.quantity;
              
              aggregatedLogs[dateStr].itemsMap[item.itemName] = (aggregatedLogs[dateStr].itemsMap[item.itemName] || 0) + item.quantity;
            });
          });
        }
        
        const processedLogs = Object.values(aggregatedLogs).map(agg => ({
           id: agg.id,
           date: agg.date,
           totalAmount: agg.totalAmount,
           items: Object.keys(agg.itemsMap).map(k => ({ itemName: k, quantity: agg.itemsMap[k] }))
        })).sort((a, b) => new Date(a.date) - new Date(b.date));

        newMatrix[res.id] = {
          ...newMatrix[res.id],
          basicSalary: basic,
          products: prodQuantities,
          logs: processedLogs,
          netSalary: calculateNetSalary(basic, newMatrix[res.id].allowance, newMatrix[res.id].deduction)
        };
      });
      
      const sortedProducts = Array.from(allProducts).sort((a, b) => 
        a.localeCompare(b, undefined, { numeric: true, sensitivity: 'base' })
      );
      
      setUniqueProducts(sortedProducts);
      setMatrix(newMatrix);
      setMessage('Weekly wages and item quantities calculated for all contractual employees!');
    } catch (e) {
      alert('Error fetching aggregate production logs.');
    }
    setIsFetchingLogs(false);
  };

  const handleCellChange = (empId, field, value) => {
    setMatrix(prev => {
      const empData = { ...prev[empId], [field]: value };
      if (['basicSalary', 'allowance', 'deduction'].includes(field)) {
        empData.netSalary = calculateNetSalary(empData.basicSalary, empData.allowance, empData.deduction);
      }
      return { ...prev, [empId]: empData };
    });
  };

  const handleClear = () => {
    setPayoutDate('');
    setStartDate('');
    setEndDate('');
    setMessage('');
    setUniqueProducts([]);
    setExpandedRows([]);
    fetchInitialData(); // Resets matrix
  };

  const toggleRow = (empId) => {
    setExpandedRows(prev => 
      prev.includes(empId) ? prev.filter(id => id !== empId) : [...prev, empId]
    );
  };

  const handleSaveAll = async () => {
    if (!payoutDate) {
      alert('Payout Date is required');
      return;
    }

    const payloads = [];
    Object.keys(matrix).forEach(empId => {
      const row = matrix[empId];
      if (parseFloat(row.netSalary) > 0 || parseFloat(row.basicSalary) > 0) {
        payloads.push({
          employeeId: parseInt(empId),
          month: payoutDate, // Keep DB compatibility
          paymentType: row.paymentType,
          daysWorked: 0,
          basicSalary: parseFloat(row.basicSalary || 0),
          allowance: parseFloat(row.allowance || 0),
          deduction: parseFloat(row.deduction || 0),
          netSalary: parseFloat(row.netSalary || 0),
          status: row.status,
          periodStr: startDate && endDate ? `${new Date(startDate).toLocaleDateString('en-GB')} to ${new Date(endDate).toLocaleDateString('en-GB')}` : payoutDate
        });
      }
    });

    if (payloads.length === 0) {
      alert('No valid payroll records to save (Net Salary > 0 required).');
      return;
    }

    try {
      const promises = payloads.map(data => erpApi.savePayroll(data));
      await Promise.all(promises);
      setMessage('Bulk Payroll saved successfully!');
      handleClear();
    } catch (error) {
      alert('Error saving bulk payroll to DB.');
    }
  };

  return (
    <div className="space-y-[14px] print:space-y-0 print:m-0 print:p-0 print-area">
      <style type="text/css" media="print">
        {`
          @page { size: landscape; margin: 10mm; }
          body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
          body * { visibility: hidden; }
          .print-area, .print-area * { visibility: visible; }
          .print-area { position: absolute; left: 0; top: 0; width: 100%; }
        `}
      </style>
      
      {/* Custom Print Header */}
      <div className="hidden print:block mb-6 text-center">
        <h1 className="text-2xl font-black text-slate-900 uppercase tracking-widest border-b-2 border-slate-900 pb-2 inline-block">Consolidated Payroll</h1>
        {startDate && endDate && (
          <p className="text-[14px] font-bold text-slate-600 mt-2">
            Period: {new Date(startDate).toLocaleDateString()} to {new Date(endDate).toLocaleDateString()}
          </p>
        )}
      </div>

      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 hover:-translate-y-[1px] hover:border-[#dbe3ef] transition-all duration-150 print:p-0 print:border-none print:shadow-none print:bg-transparent">
        <div className="flex justify-between items-center mb-4 print:hidden">
          <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px]">
            <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
            Consolidated Payroll Entry
          </h2>
        </div>

        <div className="flex flex-col md:flex-row gap-4 mb-[18px] items-start bg-slate-50 p-[14px] rounded-[18px] border border-slate-200 print:hidden">
          <div className="w-full md:w-1/4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Payout Date (Saturday) *</label>
            <input 
              type="date" 
              value={payoutDate} 
              onChange={handleDateChange} 
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-active focus:ring-[4px] focus:ring-active/15 shadow-sm transition-all font-bold" 
            />
            {payoutDate && new Date(payoutDate).getDay() !== 6 && (
              <div className="mt-[6px] text-[11px] font-[800] text-red-500 bg-red-50/50 p-1.5 rounded-[8px] inline-block">
                Warning: Not a Saturday!
              </div>
            )}
          </div>
          
          <div className="w-full md:w-1/4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">From Date (Customizable)</label>
            <input 
              type="date" 
              value={startDate} 
              onChange={(e) => setStartDate(e.target.value)} 
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-indigo-400 focus:ring-[4px] focus:ring-indigo-400/15 shadow-sm transition-all font-bold text-indigo-700" 
            />
          </div>

          <div className="w-full md:w-1/4">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">To Date (Customizable)</label>
            <input 
              type="date" 
              value={endDate} 
              onChange={(e) => setEndDate(e.target.value)} 
              className="w-full min-h-[43px] px-[12px] py-[11px] bg-white border border-slate-300 rounded-[14px] text-[14px] focus:outline-none focus:border-indigo-400 focus:ring-[4px] focus:ring-indigo-400/15 shadow-sm transition-all font-bold text-indigo-700" 
            />
          </div>

          <div className="w-full md:w-1/4 flex justify-end items-end h-[62px]">
             <button 
                onClick={handleFetchAllLogs} 
                disabled={isFetchingLogs || !startDate || !endDate}
                className="w-full min-h-[43px] px-[16px] bg-indigo-50 text-indigo-700 border border-indigo-200 rounded-[14px] text-[13px] font-black hover:bg-indigo-100 transition-all shadow-sm disabled:opacity-50 disabled:cursor-not-allowed"
              >
                {isFetchingLogs ? 'Calculating...' : 'Calculate Wages ⟳'}
              </button>
          </div>
        </div>

        <div className="overflow-x-auto border border-slate-200 rounded-[18px] shadow-sm print:overflow-visible print:border-none print:shadow-none print:w-full">
          <table className="w-full text-left border-collapse bg-white print:text-[11px] print:w-full">
            <thead>
              <tr>
                <th className="p-[16px_18px] bg-slate-100 border-b border-r border-slate-200 min-w-[200px] sticky left-0 z-10 shadow-[2px_0_5px_-2px_rgba(0,0,0,0.1)] print:relative print:shadow-none print:border-slate-400 print:p-[8px]">
                  <div className="text-[13px] font-[900] text-slate-500 uppercase tracking-wide print:text-[11px] print:text-black">Employees</div>
                </th>
                {uniqueProducts.map(prod => (
                  <th key={prod} className="p-[14px_16px] bg-slate-50 border-b border-r border-slate-200 min-w-[80px] text-center text-[13px] font-[900] text-slate-500 uppercase tracking-wide print:border-slate-400 print:p-[8px] print:text-[11px] print:text-black">
                    {prod}
                  </th>
                ))}
                <th className="p-[14px_16px] bg-slate-50 border-b border-r border-slate-200 min-w-[140px] text-center text-[13px] font-[900] text-slate-500 uppercase tracking-wide print:border-slate-400 print:p-[8px] print:text-[11px] print:text-black">
                  Base / Piece Wages
                </th>
                <th className="p-[14px_16px] bg-slate-50 border-b border-r border-slate-200 min-w-[140px] text-center text-[13px] font-[900] text-slate-500 uppercase tracking-wide print:border-slate-400 print:p-[8px] print:text-[11px] print:text-black">
                  Allowances (+)
                </th>
                <th className="p-[14px_16px] bg-slate-50 border-b border-r border-slate-200 min-w-[140px] text-center text-[13px] font-[900] text-slate-500 uppercase tracking-wide print:border-slate-400 print:p-[8px] print:text-[11px] print:text-black">
                  Deductions (-)
                  <div className="text-[9px] font-black text-rose-400 mt-[2px] tracking-wider">/ ADV. RECOVERY</div>
                </th>
                <th className="p-[14px_16px] bg-slate-50 border-b border-r border-slate-200 min-w-[150px] text-right text-[13px] font-[900] text-slate-500 uppercase tracking-wide print:border-slate-400 print:p-[8px] print:text-[11px] print:text-black">
                  Net Salary
                </th>
                <th className="p-[14px_16px] bg-slate-50 border-b border-slate-200 min-w-[120px] text-center text-[13px] font-[900] text-slate-500 uppercase tracking-wide print:border-slate-400 print:border-r print:p-[8px] print:text-[11px] print:text-black">
                  Status
                </th>
              </tr>
            </thead>
            <tbody>
              {Object.keys(employeesByRole).map(role => {
                let roleBasic = 0, roleAllowance = 0, roleDeduction = 0, roleNet = 0;
                const roleProducts = {};
                
                employeesByRole[role].forEach(emp => {
                  const empData = matrix[emp.id];
                  if (empData) {
                    roleBasic += parseFloat(empData.basicSalary || 0);
                    roleAllowance += parseFloat(empData.allowance || 0);
                    roleDeduction += parseFloat(empData.deduction || 0);
                    roleNet += parseFloat(empData.netSalary || 0);
                    uniqueProducts.forEach(prod => {
                      roleProducts[prod] = (roleProducts[prod] || 0) + (empData.products?.[prod] || 0);
                    });
                  }
                });

                return (
                  <React.Fragment key={role}>
                    <tr>
                      <td colSpan={6 + uniqueProducts.length} className="bg-slate-200 p-[12px_16px] text-[14px] font-[900] text-slate-800 uppercase tracking-[1px] sticky left-0 z-10 border-y border-slate-300 print:relative print:p-[8px] print:text-[12px] print:border-slate-400 print:bg-slate-100 print:border-x">
                        {role}
                      </td>
                    </tr>
                    {employeesByRole[role].map(emp => (
                      <React.Fragment key={emp.id}>
                        <tr className="hover:bg-slate-50 transition-colors">
                          <td 
                            className="p-[12px_16px] border-b border-r border-slate-200 font-bold text-[15px] text-slate-700 sticky left-0 bg-white/95 backdrop-blur shadow-[2px_0_5px_-2px_rgba(0,0,0,0.05)] cursor-pointer hover:bg-indigo-50 transition-colors print:relative print:shadow-none print:border-slate-400 print:p-[6px_8px] print:text-[11px]"
                            onClick={() => toggleRow(emp.id)}
                          >
                            <div className="flex items-center justify-between">
                              <div className="flex items-center gap-[10px]">
                                <span className={`text-[12px] text-indigo-400 transition-transform duration-200 print:hidden ${expandedRows.includes(emp.id) ? 'rotate-90' : ''}`}>
                                  ▶
                                </span>
                                <span>{emp.name}</span>
                              </div>
                              <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider print:text-[9px] print:text-slate-500">{emp.paymentType}</span>
                            </div>
                          </td>
                        {uniqueProducts.map(prod => (
                           <td key={prod} className="p-[8px_12px] border-b border-r border-slate-200 bg-slate-50/50 text-center text-[15px] font-black text-indigo-700 print:border-slate-400 print:p-[6px_8px] print:text-[11px] print:text-black">
                             {matrix[emp.id]?.products?.[prod] || '-'}
                           </td>
                        ))}
                        <td className="p-[8px_12px] border-b border-r border-slate-200 bg-white group hover:bg-indigo-50/50 transition-colors print:border-slate-400 print:p-[6px_8px]">
                          <input 
                            type="number" 
                            value={matrix[emp.id]?.basicSalary || ''}
                            onChange={(e) => handleCellChange(emp.id, 'basicSalary', e.target.value)}
                            readOnly={emp.paymentType === 'Contractual'}
                            className={`w-full h-[40px] px-[8px] bg-transparent text-center border border-transparent group-hover:border-indigo-200 focus:border-indigo-500 focus:bg-white focus:ring-[3px] focus:ring-indigo-100 rounded-[8px] text-[16px] font-[800] text-indigo-900 placeholder-slate-300 outline-none transition-all print:hidden ${emp.paymentType === 'Contractual' ? 'opacity-70' : ''}`}
                          />
                          <span className="hidden print:inline-block w-full text-center text-[11px] font-bold text-black">{matrix[emp.id]?.basicSalary || '0.00'}</span>
                        </td>
                        <td className="p-[8px_12px] border-b border-r border-slate-200 bg-white group hover:bg-indigo-50/50 transition-colors print:border-slate-400 print:p-[6px_8px]">
                          <input 
                            type="number" 
                            value={matrix[emp.id]?.allowance || ''}
                            onChange={(e) => handleCellChange(emp.id, 'allowance', e.target.value)}
                            className="w-full h-[40px] px-[8px] bg-transparent text-center border border-transparent group-hover:border-indigo-200 focus:border-indigo-500 focus:bg-white focus:ring-[3px] focus:ring-indigo-100 rounded-[8px] text-[16px] font-[800] text-green-700 placeholder-slate-300 outline-none transition-all print:hidden"
                          />
                          <span className="hidden print:inline-block w-full text-center text-[11px] font-bold text-black">{matrix[emp.id]?.allowance || '0.00'}</span>
                        </td>
                        <td className="p-[8px_12px] border-b border-r border-slate-200 bg-white group hover:bg-indigo-50/50 transition-colors print:border-slate-400 print:p-[6px_8px] relative">
                          <input 
                            type="number" 
                            value={matrix[emp.id]?.deduction || ''}
                            onChange={(e) => handleCellChange(emp.id, 'deduction', e.target.value)}
                            className="w-full h-[40px] px-[8px] bg-transparent text-center border border-transparent group-hover:border-indigo-200 focus:border-indigo-500 focus:bg-white focus:ring-[3px] focus:ring-indigo-100 rounded-[8px] text-[16px] font-[800] text-red-600 placeholder-slate-300 outline-none transition-all print:hidden"
                          />
                          {matrix[emp.id]?.advanceBalance > 0 && (
                             <div className="text-[9px] font-black text-rose-500 text-center mt-1 print:hidden tracking-wider bg-rose-50 rounded-md py-[2px]">
                               BAL: ₹{matrix[emp.id].advanceBalance.toFixed(2)}
                             </div>
                          )}
                          <span className="hidden print:inline-block w-full text-center text-[11px] font-bold text-black">{matrix[emp.id]?.deduction || '0.00'}</span>
                        </td>
                        <td className="p-[12px_16px] border-b border-r border-slate-200 font-black text-[18px] text-slate-800 text-right bg-slate-50/50 print:border-slate-400 print:p-[6px_8px] print:text-[11px] print:text-black">
                          {matrix[emp.id]?.netSalary || '0.00'}
                        </td>
                        <td className="p-[8px_12px] border-b border-slate-200 bg-white group print:border-slate-400 print:border-r print:p-[6px_8px]">
                          <select 
                            value={matrix[emp.id]?.status || 'Paid'}
                            onChange={(e) => handleCellChange(emp.id, 'status', e.target.value)}
                            className="w-full h-[40px] bg-transparent text-center border border-transparent focus:border-indigo-500 focus:bg-white rounded-[8px] text-[14px] font-[800] text-slate-700 outline-none cursor-pointer print:hidden"
                          >
                            <option value="Paid">Paid</option>
                            <option value="Pending">Pending</option>
                          </select>
                          <span className="hidden print:inline-block w-full text-center text-[11px] font-bold text-black">{matrix[emp.id]?.status || 'Paid'}</span>
                        </td>
                      </tr>
                    
                    {/* Expandable Daily Logs Row */}
                    {expandedRows.includes(emp.id) && matrix[emp.id]?.logs?.length > 0 && (
                      <tr className="bg-slate-50/50 shadow-[inset_0_3px_6px_rgba(0,0,0,0.02)]">
                        <td colSpan={6 + uniqueProducts.length} className="p-[16px_24px] md:p-[20px_40px] border-b border-slate-200">
                          <div className="bg-white rounded-[16px] border border-slate-200 shadow-[0_4px_12px_rgba(0,0,0,0.03)] overflow-hidden relative">
                            <div className="absolute left-0 top-0 bottom-0 w-[4px] bg-indigo-400"></div>
                            
                            <div className="p-[12px_16px] bg-slate-50/50 border-b border-slate-100 flex items-center justify-between">
                               <h4 className="text-[12px] font-black text-slate-700 uppercase tracking-wide flex items-center gap-2 pl-2">
                                  <span className="w-2 h-2 rounded-full bg-indigo-400"></span>
                                  Daily Production Breakdown
                               </h4>
                            </div>

                            <table className="w-full text-left border-collapse">
                              <thead>
                                <tr>
                                  <th className="p-[10px_16px] pl-[24px] bg-slate-50 border-b border-slate-200 text-[11px] font-[900] text-slate-500 uppercase tracking-wider">Date</th>
                                  {uniqueProducts.map(prod => (
                                    <th key={prod} className="p-[10px_16px] bg-slate-50 border-b border-slate-200 text-center text-[11px] font-[900] text-slate-500 uppercase tracking-wider">{prod}</th>
                                  ))}
                                  <th className="p-[10px_16px] bg-slate-50 border-b border-slate-200 text-right text-[11px] font-[900] text-slate-500 uppercase tracking-wider">Daily Wage (₹)</th>
                                </tr>
                              </thead>
                              <tbody>
                                {matrix[emp.id].logs.map(log => (
                                  <tr key={log.id} className="hover:bg-slate-50/80 border-b border-slate-100 last:border-0 transition-colors">
                                    <td className="p-[10px_16px] pl-[24px] text-[12px] font-bold text-slate-700 whitespace-nowrap">
                                      {new Date(log.date).toLocaleDateString('en-GB', { weekday: 'short', month: 'short', day: '2-digit' })}
                                    </td>
                                    {uniqueProducts.map(prod => {
                                      const item = log.items.find(i => i.itemName === prod);
                                      return (
                                        <td key={prod} className="p-[10px_16px] text-center text-[13px] font-black text-slate-600">
                                          {item && item.quantity > 0 ? (
                                            <span className="bg-slate-100 px-2 py-1 rounded-md border border-slate-200 inline-block min-w-[32px]">{item.quantity}</span>
                                          ) : (
                                            <span className="text-slate-300">-</span>
                                          )}
                                        </td>
                                      );
                                    })}
                                    <td className="p-[10px_16px] text-right text-[14px] font-black text-indigo-600">
                                      ₹{parseFloat(log.totalAmount || 0).toFixed(2)}
                                    </td>
                                  </tr>
                                ))}
                              </tbody>
                            </table>
                          </div>
                        </td>
                      </tr>
                    )}
                    {expandedRows.includes(emp.id) && (!matrix[emp.id]?.logs || matrix[emp.id].logs.length === 0) && (
                      <tr className="bg-slate-50/50">
                        <td colSpan={6 + uniqueProducts.length} className="p-[16px_24px] md:p-[20px_40px] border-b border-slate-200">
                           <div className="bg-white rounded-[16px] border border-dashed border-slate-300 p-[24px] text-center text-[13px] font-bold text-slate-400 italic shadow-sm relative overflow-hidden">
                              <div className="absolute left-0 top-0 bottom-0 w-[4px] bg-slate-300"></div>
                              No daily logs found for this period.
                           </div>
                        </td>
                      </tr>
                    )}
                  </React.Fragment>
                ))}
                    
                    {/* Category Subtotal Row */}
                    {employeesByRole[role].length > 0 && (
                      <tr className="bg-slate-100 border-t-2 border-b-4 border-slate-300 print:border-b-2 print:border-t print:border-slate-400 print:bg-slate-100">
                        <td className="p-[14px_16px] font-black text-[14px] text-slate-800 text-right sticky left-0 z-10 shadow-[2px_0_5px_-2px_rgba(0,0,0,0.1)] uppercase tracking-wider print:relative print:shadow-none print:border-x print:border-slate-400 print:p-[8px] print:text-[11px] print:text-black">
                          {role} TOTAL
                        </td>
                        {uniqueProducts.map(prod => (
                          <td key={prod} className="p-[14px_16px] text-center text-[16px] font-black text-slate-700 bg-slate-200/50 print:bg-transparent print:border-r print:border-slate-400 print:p-[8px] print:text-[12px] print:text-black">
                            {roleProducts[prod] || '-'}
                          </td>
                        ))}
                        <td className="p-[14px_16px] text-center text-[16px] font-black text-slate-800 print:border-r print:border-slate-400 print:p-[8px] print:text-[12px] print:text-black">
                          {roleBasic.toFixed(2)}
                        </td>
                        <td className="p-[14px_16px] text-center text-[16px] font-black text-green-700 print:border-r print:border-slate-400 print:p-[8px] print:text-[12px] print:text-black">
                          {roleAllowance.toFixed(2)}
                        </td>
                        <td className="p-[14px_16px] text-center text-[16px] font-black text-red-600 print:border-r print:border-slate-400 print:p-[8px] print:text-[12px] print:text-black">
                          {roleDeduction.toFixed(2)}
                        </td>
                        <td className="p-[14px_16px] text-right text-[18px] font-black text-indigo-800 bg-indigo-50/50 print:bg-transparent print:border-r print:border-slate-400 print:p-[8px] print:text-[12px] print:text-black">
                          {roleNet.toFixed(2)}
                        </td>
                        <td className="p-[14px_16px] bg-slate-100 border-r border-slate-200 print:border-slate-400 print:bg-transparent"></td>
                      </tr>
                    )}
                  </React.Fragment>
                );
              })}
              {employees.length === 0 && (
                <tr>
                  <td colSpan={6 + uniqueProducts.length} className="p-[20px] text-center text-slate-400 text-[12px] font-bold italic border-b border-slate-200">
                    No active employees found.
                  </td>
                </tr>
              )}
            </tbody>
            <tfoot>
              {(() => {
                let grandBasic = 0, grandAllowance = 0, grandDeduction = 0, grandNet = 0;
                const grandProducts = {};
                employees.forEach(emp => {
                  const empData = matrix[emp.id];
                  if (empData) {
                    grandBasic += parseFloat(empData.basicSalary || 0);
                    grandAllowance += parseFloat(empData.allowance || 0);
                    grandDeduction += parseFloat(empData.deduction || 0);
                    grandNet += parseFloat(empData.netSalary || 0);
                    uniqueProducts.forEach(prod => {
                      grandProducts[prod] = (grandProducts[prod] || 0) + (empData.products?.[prod] || 0);
                    });
                  }
                });
                return (
                  <tr>
                    <td className="p-[16px] bg-slate-800 border-t-4 border-slate-400 font-black text-[15px] text-white text-right sticky left-0 z-10 shadow-[2px_0_5px_-2px_rgba(0,0,0,0.2)] uppercase tracking-widest print:bg-slate-200 print:text-black print:border-2 print:border-slate-500 print:relative print:shadow-none print:p-[10px] print:text-[13px]">
                      GRAND TOTAL
                    </td>
                    {uniqueProducts.map(prod => (
                      <td key={prod} className="p-[16px] bg-slate-700 border-t-4 border-slate-400 text-center text-[18px] font-black text-white print:bg-slate-100 print:text-black print:border-2 print:border-slate-500 print:p-[10px] print:text-[13px]">
                        {grandProducts[prod] > 0 ? grandProducts[prod] : '-'}
                      </td>
                    ))}
                    <td className="p-[16px] bg-slate-800 border-t-4 border-slate-400 text-center text-[18px] font-black text-white print:bg-slate-200 print:text-black print:border-2 print:border-slate-500 print:p-[10px] print:text-[13px]">
                      {grandBasic.toFixed(2)}
                    </td>
                    <td className="p-[16px] bg-slate-800 border-t-4 border-slate-400 text-center text-[18px] font-black text-green-400 print:bg-slate-200 print:text-black print:border-2 print:border-slate-500 print:p-[10px] print:text-[13px]">
                      {grandAllowance.toFixed(2)}
                    </td>
                    <td className="p-[16px] bg-slate-800 border-t-4 border-slate-400 text-center text-[18px] font-black text-red-400 print:bg-slate-200 print:text-black print:border-2 print:border-slate-500 print:p-[10px] print:text-[13px]">
                      {grandDeduction.toFixed(2)}
                    </td>
                    <td className="p-[16px] bg-indigo-900 border-t-4 border-indigo-500 text-right text-[22px] font-black text-indigo-200 print:bg-slate-200 print:text-black print:border-2 print:border-slate-500 print:p-[10px] print:text-[14px]">
                      {grandNet.toFixed(2)}
                    </td>
                    <td className="p-[16px] bg-slate-800 border-t-4 border-slate-400 border-r border-slate-700 print:bg-slate-200 print:border-2 print:border-slate-500"></td>
                  </tr>
                );
              })()}
            </tfoot>
          </table>
        </div>

        <div className="flex justify-end gap-[8px] mt-[18px] bg-slate-50 p-[12px] border border-slate-200 rounded-[18px] print:hidden">
          <button onClick={() => window.print()} className="min-h-[40px] px-[16px] py-[10px] bg-slate-800 text-white border border-slate-700 rounded-[14px] font-[900] shadow-[0_10px_24px_rgba(15,23,42,0.12)] hover:-translate-y-[1px] transition-all flex items-center gap-2">
             <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" /></svg>
             Print Report
          </button>
          <button onClick={handleClear} className="min-h-[40px] px-[16px] py-[10px] bg-slate-200 text-slate-900 border border-slate-300 rounded-[14px] font-[900] hover:-translate-y-[1px] transition-all ml-2">Clear Grid</button>
          <button onClick={handleSaveAll} className="min-h-[40px] px-[16px] py-[10px] bg-active text-white rounded-[14px] font-[900] shadow-[0_10px_24px_rgba(15,23,42,0.12)] hover:-translate-y-[1px] transition-all">Save Bulk Payroll</button>
        </div>
        
        {message && (
          <div className="inline-block mt-[12px] bg-green-50 border border-green-200 text-green-700 p-[10px_12px] rounded-[14px] font-[900] text-[13px] print:hidden">
            {message}
          </div>
        )}
      </div>

      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto print:hidden">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Recent Payrolls History
        </h2>
        <table className="w-full border-separate border-spacing-y-[8px] text-[14px]">
          <thead>
            <tr>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Date (Period)</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Employee Name</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Type</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Base / Piece Wages (₹)</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Net Salary (₹)</th>
              <th className="text-center font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Status</th>
            </tr>
          </thead>
          <tbody>
            {payrolls.map((p, i) => (
              <tr key={i} className="hover:bg-slate-50 transition-all">
                <td className="bg-white border-y border-slate-200 border-l rounded-l-[14px] p-[10px] font-[800] text-slate-800">{p.month}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] font-bold text-slate-700">{p.employee?.name}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-700 text-[11px] font-bold">{p.paymentType}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-600">{p.basicSalary}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-slate-800 font-black">{p.netSalary}</td>
                <td className="bg-white border-y border-slate-200 border-r rounded-r-[14px] p-[10px] text-center">
                  <span className={`inline-block px-2 py-1 rounded-[6px] text-[10px] font-bold uppercase tracking-wider ${p.status === 'Pending' ? 'bg-orange-100 text-orange-600' : 'bg-green-100 text-green-600'}`}>
                    {p.status || 'Paid'}
                  </span>
                </td>
              </tr>
            ))}
            {payrolls.length === 0 && (
              <tr>
                <td colSpan={6} className="bg-white border border-slate-200 rounded-[14px] p-[10px] text-center text-slate-500">No payroll records found.</td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
