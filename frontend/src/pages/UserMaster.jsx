import React, { useState, useEffect } from 'react';
import { erpApi } from '../api/erpApi';
import { useAuth } from '../store/useAuth';
import { useNavigate } from 'react-router-dom';

const MODULES = [
  { id: 'billing', label: 'Billing' },
  { id: 'customers', label: 'Customers' },
  { id: 'suppliers', label: 'Suppliers' },
  { id: 'products', label: 'Products' },
  { id: 'transporters', label: 'Transporters' },
  { id: 'godowns', label: 'Godowns' },
  { id: 'purchase', label: 'Purchase Entry' },
  { id: 'stock', label: 'Stock Ledger' },
  { id: 'vehicles', label: 'Vehicles' },
  { id: 'transfers', label: 'Stock Transfer' },
  { id: 'production', label: 'Production' },
  { id: 'materials', label: 'Materials' },
  { id: 'machines', label: 'Machines' },
  { id: 'reports', label: 'Reports' }
];

const DEFAULT_PERMS = MODULES.reduce((acc, mod) => {
  acc[mod.id] = { view: false, add: false, edit: false, delete: false };
  return acc;
}, {});

export default function UserMaster() {
  const { user } = useAuth();
  const navigate = useNavigate();
  
  const [formData, setFormData] = useState({
    id: null,
    username: '',
    pin: '',
    role: 'STAFF',
    status: 'Active',
    permissions: JSON.parse(JSON.stringify(DEFAULT_PERMS))
  });
  const [users, setUsers] = useState([]);
  const [categories, setCategories] = useState([]);
  const [subCategories, setSubCategories] = useState([]);
  const [message, setMessage] = useState('');

  // Protect route
  useEffect(() => {
    if (user && user.role !== 'ADMIN') {
      navigate('/billing');
    }
  }, [user, navigate]);

  const fetchUsersAndCategories = async () => {
    try {
      const [userData, prodData] = await Promise.all([
        erpApi.getUsers(),
        erpApi.getProducts()
      ]);
      setUsers(userData);
      
      const uniqueCategories = [...new Set(prodData.map(p => p.category).filter(Boolean))].sort();
      
      const uniqueSubCategories = [...new Set(prodData.map(p => p.subCategory).filter(Boolean))].sort();
      const customOrder = ['400 COUNT', '400 COUNT (CORE & CELLOPHANE)', '600 COUNT', '700 COUNT', '800 COUNT'];
      uniqueSubCategories.sort((a, b) => {
        const indexA = customOrder.indexOf(a.toUpperCase());
        const indexB = customOrder.indexOf(b.toUpperCase());
        if (indexA !== -1 && indexB !== -1) return indexA - indexB;
        if (indexA !== -1) return -1;
        if (indexB !== -1) return 1;
        return a.localeCompare(b);
      });

      setCategories(uniqueCategories);
      setSubCategories(uniqueSubCategories);
    } catch (e) {
      console.log('Failed to fetch users or categories');
    }
  };

  useEffect(() => {
    fetchUsersAndCategories();
  }, []);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handlePermissionChange = (moduleId, permType, checked) => {
    setFormData(prev => ({
      ...prev,
      permissions: {
        ...prev.permissions,
        [moduleId]: {
          ...prev.permissions[moduleId],
          [permType]: checked
        }
      }
    }));
  };

  const handleCategoryToggle = (category) => {
    setFormData(prev => {
      const currentAllowed = prev.permissions.allowedCategories || [];
      const newAllowed = currentAllowed.includes(category)
        ? currentAllowed.filter(c => c !== category)
        : [...currentAllowed, category];
      
      return {
        ...prev,
        permissions: {
          ...prev.permissions,
          allowedCategories: newAllowed
        }
      };
    });
  };

  const handleClear = () => {
    setFormData({
      id: null,
      username: '',
      pin: '',
      role: 'STAFF',
      status: 'Active',
      permissions: JSON.parse(JSON.stringify(DEFAULT_PERMS))
    });
    setMessage('');
  };

  const handleEdit = (u) => {
    setFormData({
      id: u.id,
      username: u.username,
      pin: '', // Never show existing PIN
      role: u.role,
      status: u.status,
      permissions: u.permissions || JSON.parse(JSON.stringify(DEFAULT_PERMS))
    });
    window.scrollTo({ top: 0, behavior: 'smooth' });
  };

  const handleToggleStatus = async (u) => {
    if (u.username === 'admin') {
      alert("Cannot disable the super admin.");
      return;
    }
    const newStatus = u.status === 'Active' ? 'Inactive' : 'Active';
    try {
      await erpApi.saveUser({ ...u, status: newStatus });
      setMessage(`User marked as ${newStatus}!`);
      fetchUsersAndCategories();
    } catch (error) {
      alert('Error updating user status');
    }
  };

  const handleSave = async () => {
    if (!formData.username) {
      alert('Username is required');
      return;
    }
    if (!formData.id && !formData.pin) {
      alert('PIN is required for new users');
      return;
    }
    try {
      await erpApi.saveUser(formData);
      setMessage('User saved successfully!');
      handleClear();
      fetchUsersAndCategories();
    } catch (error) {
      alert(error.message || 'Error saving user');
    }
  };

  if (user?.role !== 'ADMIN') return null;

  return (
    <div className="space-y-[14px]">
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-rose-600 uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
          <span className="w-[9px] h-[9px] rounded-full bg-rose-500 shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          User Access & Permissions Master
        </h2>

        <div className="grid grid-cols-1 md:grid-cols-12 gap-[14px] mb-6">
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Username *</label>
            <input name="username" value={formData.username} onChange={handleChange} disabled={formData.username === 'admin'} placeholder="e.g. cashier1" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] font-bold focus:outline-none focus:border-rose-500 focus:ring-[4px] focus:ring-rose-500/15" />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">
              {formData.id ? 'Reset PIN (Leave blank to keep)' : 'PIN (Numbers only) *'}
            </label>
            <input type="password" inputMode="numeric" pattern="[0-9]*" name="pin" value={formData.pin} onChange={handleChange} placeholder="****" className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[16px] tracking-widest font-black focus:outline-none focus:border-rose-500 focus:ring-[4px] focus:ring-rose-500/15 text-center" />
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Role</label>
            <select name="role" value={formData.role} onChange={handleChange} disabled={formData.username === 'admin'} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] font-bold focus:outline-none focus:border-rose-500 focus:ring-[4px] focus:ring-rose-500/15">
              <option value="STAFF">STAFF</option>
              <option value="REP">SALES REP</option>
              <option value="ADMIN">ADMIN (Full Access)</option>
            </select>
          </div>
          <div className="col-span-1 md:col-span-3">
            <label className="block text-[12px] font-[800] text-[#334155] mb-[3px]">Status</label>
            <select name="status" value={formData.status} onChange={handleChange} disabled={formData.username === 'admin'} className="w-full min-h-[43px] px-[12px] py-[11px] bg-white/96 border border-slate-300 rounded-[14px] text-[14px] font-bold focus:outline-none focus:border-rose-500 focus:ring-[4px] focus:ring-rose-500/15">
              <option value="Active">Active</option>
              <option value="Inactive">Inactive</option>
            </select>
          </div>
        </div>

        {/* Permissions Matrix */}
        {formData.role === 'REP' && (
          <div className="mt-4 border border-slate-200 rounded-[18px] overflow-hidden mb-6">
            <div className="bg-orange-50 p-3 border-b border-orange-200">
              <h3 className="text-[12px] font-black text-orange-700 uppercase tracking-wide">Rep Allowed Product Categories</h3>
              <p className="text-[10px] text-orange-600/80 font-bold mt-1">Select which product categories or sub-categories this rep is allowed to see and sell. If none are selected, they can see all.</p>
            </div>
            
            <div className="p-4 bg-white">
              <h4 className="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-3">Main Categories</h4>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-5">
                {categories.map(cat => (
                  <label key={cat} className="flex items-center gap-2 cursor-pointer group">
                    <input 
                      type="checkbox"
                      checked={(formData.permissions.allowedCategories || []).includes(cat)}
                      onChange={() => handleCategoryToggle(cat)}
                      className="w-4 h-4 text-orange-600 bg-gray-100 border-gray-300 rounded focus:ring-orange-500"
                    />
                    <span className="text-xs font-bold text-slate-700 group-hover:text-orange-600 transition-colors">{cat}</span>
                  </label>
                ))}
              </div>

              <div className="h-[1px] w-full bg-slate-100 mb-4"></div>
              
              <h4 className="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-3">Sub-Categories</h4>
              <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                {subCategories.map(cat => (
                  <label key={cat} className="flex items-center gap-2 cursor-pointer group">
                    <input 
                      type="checkbox"
                      checked={(formData.permissions.allowedCategories || []).includes(cat)}
                      onChange={() => handleCategoryToggle(cat)}
                      className="w-4 h-4 text-orange-600 bg-gray-100 border-gray-300 rounded focus:ring-orange-500"
                    />
                    <span className="text-xs font-bold text-slate-700 group-hover:text-orange-600 transition-colors">{cat}</span>
                  </label>
                ))}
              </div>
            </div>
          </div>
        )}

        {formData.role === 'STAFF' && (
          <div className="mt-4 border border-slate-200 rounded-[18px] overflow-hidden">
            <div className="bg-slate-50 p-3 border-b border-slate-200">
              <h3 className="text-[12px] font-black text-slate-700 uppercase tracking-wide">Granular Module Permissions</h3>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full text-sm text-left">
                <thead className="bg-slate-100/50 text-xs font-black text-slate-500 uppercase">
                  <tr>
                    <th className="px-4 py-3">Module Name</th>
                    <th className="px-4 py-3 text-center">View (Access)</th>
                    <th className="px-4 py-3 text-center">Add (Create)</th>
                    <th className="px-4 py-3 text-center">Edit (Update)</th>
                    <th className="px-4 py-3 text-center">Delete</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {MODULES.map((mod) => {
                    const perms = formData.permissions[mod.id] || { view: false, add: false, edit: false, delete: false };
                    return (
                      <tr key={mod.id} className="hover:bg-slate-50/50">
                        <td className="px-4 py-3 font-bold text-slate-700">{mod.label}</td>
                        {['view', 'add', 'edit', 'delete'].map(action => (
                          <td key={action} className="px-4 py-3 text-center">
                            <input 
                              type="checkbox" 
                              checked={perms[action]}
                              onChange={(e) => handlePermissionChange(mod.id, action, e.target.checked)}
                              className="w-4 h-4 text-rose-600 bg-gray-100 border-gray-300 rounded focus:ring-rose-500 focus:ring-2 cursor-pointer"
                            />
                          </td>
                        ))}
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}

        <div className="flex justify-end gap-[8px] mt-[18px] bg-slate-50 p-[12px] border border-slate-200 rounded-[18px]">
          <button onClick={handleClear} className="min-h-[40px] px-[16px] py-[10px] bg-slate-200 text-slate-900 border border-slate-300 rounded-[14px] font-[900] hover:-translate-y-[1px] transition-all">Clear</button>
          <button onClick={handleSave} className="min-h-[40px] px-[16px] py-[10px] bg-rose-600 text-white rounded-[14px] font-[900] shadow-[0_10px_24px_rgba(225,29,72,0.2)] hover:-translate-y-[1px] transition-all">Save User</button>
        </div>
        
        {message && (
          <div className="inline-block mt-[12px] bg-green-50 border border-green-200 text-green-700 p-[10px_12px] rounded-[14px] font-[900] text-[13px]">
            {message}
          </div>
        )}
      </div>

      {/* Saved Users List */}
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200 overflow-x-auto">
        <h2 className="text-[13px] font-black text-rose-600 uppercase tracking-[0.7px] flex items-center gap-[10px] mb-3">
          <span className="w-[9px] h-[9px] rounded-full bg-rose-500 shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          System Users
        </h2>
        <table className="w-full border-separate border-spacing-y-[8px] text-[14px]">
          <thead>
            <tr>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Username</th>
              <th className="text-left font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Role</th>
              <th className="text-center font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Status</th>
              <th className="text-right font-bold text-slate-500 text-[11px] tracking-[0.5px] uppercase p-[10px]">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((u, i) => (
              <tr key={i} className={`hover:bg-slate-50 transition-all ${u.status === 'Inactive' ? 'opacity-60 grayscale' : ''}`}>
                <td className="bg-white border-y border-slate-200 border-l rounded-l-[14px] p-[10px] font-[800] text-slate-800">{u.username}</td>
                <td className="bg-white border-y border-slate-200 p-[10px] font-bold text-slate-600">
                  <span className={`px-2 py-1 rounded-[6px] text-[10px] uppercase tracking-wider ${u.role === 'ADMIN' ? 'bg-purple-100 text-purple-700' : u.role === 'REP' ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-600'}`}>{u.role}</span>
                </td>
                <td className="bg-white border-y border-slate-200 p-[10px] text-center">
                  <span className={`inline-block px-2 py-1 rounded-[6px] text-[10px] font-bold uppercase tracking-wider ${u.status === 'Inactive' ? 'bg-red-100 text-red-600' : 'bg-green-100 text-green-600'}`}>
                    {u.status}
                  </span>
                </td>
                <td className="bg-white border-y border-slate-200 border-r rounded-r-[14px] p-[10px] text-right">
                  <div className="flex justify-end gap-2">
                    <button onClick={() => handleEdit(u)} className="px-3 py-1 bg-blue-50 text-blue-600 hover:bg-blue-100 rounded-[8px] font-bold text-[11px] transition-colors">
                      Edit
                    </button>
                    {u.username !== 'admin' && (
                      <button onClick={() => handleToggleStatus(u)} className={`px-3 py-1 rounded-[8px] font-bold text-[11px] transition-colors ${u.status === 'Inactive' ? 'bg-emerald-50 text-emerald-600 hover:bg-emerald-100' : 'bg-rose-50 text-rose-600 hover:bg-rose-100'}`}>
                        {u.status === 'Inactive' ? 'Enable' : 'Disable'}
                      </button>
                    )}
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
