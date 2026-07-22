import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useStore } from '../store/useStore';
import { erpApi } from '../api/erpApi';

export default function PendingOrders() {
  const navigate = useNavigate();
  const [orders, setOrders] = useState([]);
  const [activeTab, setActiveTab] = useState('PENDING');
  const [loading, setLoading] = useState(true);
  const loadSalesOrderIntoBilling = useStore(state => state.loadSalesOrderIntoBilling);

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const data = activeTab === 'PENDING' ? await erpApi.getPendingSalesOrders() : await erpApi.getApprovedSalesOrders();
      setOrders(data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, [activeTab]);

  const handlePrintFactoryOrder = async (order) => {
    try {
      const factoryOrder = await erpApi.getFactoryView(order.id);
      
      const printWindow = window.open('', '', 'width=800,height=600');
      printWindow.document.write(`
        <html>
          <head>
            <title>Factory Order #${factoryOrder.id}</title>
            <style>
              body { font-family: system-ui, -apple-system, sans-serif; padding: 40px; margin: 0; color: #000; }
              .header { text-align: center; margin-bottom: 30px; border-bottom: 2px solid #000; padding-bottom: 20px; }
              h1 { margin: 0 0 5px 0; font-size: 24px; text-transform: uppercase; }
              .meta { font-size: 14px; margin-bottom: 30px; }
              table { w-full border-collapse: collapse; width: 100%; margin-top: 20px; }
              th, td { border: 1px solid #000; padding: 12px; text-align: left; }
              th { background: #f0f0f0; font-weight: bold; text-transform: uppercase; font-size: 12px; }
              .footer { margin-top: 40px; font-size: 12px; font-style: italic; text-align: center; border-top: 1px dashed #ccc; padding-top: 20px; }
            </style>
          </head>
          <body>
            <div class="header">
              <h1>FACTORY PRODUCTION ORDER</h1>
              <p style="margin: 0;">Order Ref: ${factoryOrder.id} • Date: ${new Date(factoryOrder.createdAt).toLocaleDateString()}</p>
            </div>
            
            <div class="meta">
              <strong>Customer:</strong> ${factoryOrder.customer?.name || 'N/A'}<br/>
              <strong>Sales Rep:</strong> ${order.rep?.username || 'N/A'}
            </div>
            
            <table>
              <thead>
                <tr>
                  <th>S.No</th>
                  <th>Product (Physical Item)</th>
                  <th style="text-align: right;">Quantity</th>
                </tr>
              </thead>
              <tbody>
                ${factoryOrder.items.map((item, i) => `
                  <tr>
                    <td>${i + 1}</td>
                    <td style="font-weight: bold;">${item.product}</td>
                    <td style="text-align: right; font-weight: bold; font-size: 16px;">${item.qty}</td>
                  </tr>
                `).join('')}
              </tbody>
            </table>
            
            <div class="footer">
              This document only lists the physical items required from the Godown/Factory. Pricing and premium grading have been omitted.
            </div>
            <script>
              setTimeout(() => {
                window.print();
                window.close();
              }, 500);
            </script>
          </body>
        </html>
      `);
      printWindow.document.close();
    } catch (err) {
      alert("Error printing factory order: " + (err.response?.data?.error || err.message));
    }
  };

  const handleApproveCustomer = async (id) => {
    if (!window.confirm("Approve and convert this Lead into a Master Customer?")) return;
    try {
      await erpApi.approveSalesOrderCustomer(id);
      fetchOrders();
    } catch (err) {
      alert("Error approving customer: " + (err.response?.data?.error || err.message));
    }
  };

  const handleApproveOrder = async (order) => {
    if (!order.customerId) {
      alert("Please approve the new customer first before approving the order.");
      return;
    }
    if (!window.confirm("Approve order and load into Performa Billing?")) return;
    try {
      await erpApi.updateSalesOrderStatus(order.id, 'APPROVED');
      loadSalesOrderIntoBilling(order, order.customer?.name);
      navigate('/billing');
    } catch (err) {
      alert("Error approving order: " + (err.response?.data?.error || err.message));
    }
  };

  const handleRejectOrder = async (id) => {
    if (!window.confirm("Are you sure you want to REJECT this order?")) return;
    try {
      await erpApi.updateSalesOrderStatus(id, 'REJECTED');
      fetchOrders();
    } catch (err) {
      alert("Error rejecting order: " + (err.response?.data?.error || err.message));
    }
  };

  return (
    <div className="max-w-[1200px] mx-auto space-y-6 pt-4">
      <div className="flex items-center justify-between mb-8">
        <div>
          <h1 className="text-3xl font-black text-slate-800 tracking-tight">Pending Orders</h1>
          <p className="text-sm font-bold text-slate-500 mt-1">Review and approve Sales Representative orders.</p>
        </div>
        <div className="flex bg-slate-200/50 p-1 rounded-xl">
          <button 
            onClick={() => setActiveTab('PENDING')}
            className={`px-6 py-2.5 rounded-lg text-sm font-black transition-all ${activeTab === 'PENDING' ? 'bg-white text-active shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
          >
            PENDING
          </button>
          <button 
            onClick={() => setActiveTab('APPROVED')}
            className={`px-6 py-2.5 rounded-lg text-sm font-black transition-all ${activeTab === 'APPROVED' ? 'bg-white text-active shadow-sm' : 'text-slate-500 hover:text-slate-700'}`}
          >
            APPROVED
          </button>
        </div>
        <button onClick={fetchOrders} className="bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold px-4 py-2 rounded-xl text-sm transition-colors shadow-sm ml-4">
          🔄 Refresh
        </button>
      </div>

      {loading ? (
        <div className="text-center py-20 text-slate-500 font-bold animate-pulse">Loading orders...</div>
      ) : orders.length === 0 ? (
        <div className="bg-white rounded-[24px] p-12 text-center shadow-sm border border-slate-200">
          <div className="text-5xl mb-4">👍</div>
          <h2 className="text-xl font-black text-slate-800 mb-2">All Caught Up!</h2>
          <p className="text-slate-500 font-medium">There are no pending orders requiring approval right now.</p>
        </div>
      ) : (
        <div className="grid gap-6">
          {orders.map(order => {
            const isNewCustomer = !order.customerId && order.newCustomerData;
            const newCustomerObj = isNewCustomer ? (typeof order.newCustomerData === 'string' ? JSON.parse(order.newCustomerData) : order.newCustomerData) : null;
            
            return (
              <div key={order.id} className="bg-white rounded-[24px] shadow-[0_8px_24px_rgba(15,23,42,0.04)] border border-slate-200 overflow-hidden group hover:border-active/30 transition-colors">
                {/* Header */}
                <div className="bg-slate-50 px-6 py-4 border-b border-slate-100 flex flex-col md:flex-row justify-between md:items-center gap-4">
                  <div>
                    <span className={`inline-block px-3 py-1 rounded-lg text-xs font-black tracking-widest mb-2 ${activeTab === 'PENDING' ? 'bg-amber-100 text-amber-700' : 'bg-emerald-100 text-emerald-700'}`}>
                      {activeTab === 'PENDING' ? 'PENDING APPROVAL' : 'APPROVED'}
                    </span>
                    <h3 className="text-lg font-black text-slate-800 flex items-center gap-2">
                      {isNewCustomer ? newCustomerObj?.name : order.customer?.name}
                      {isNewCustomer && <span className="bg-blue-100 text-blue-700 text-[10px] px-2 py-0.5 rounded-full tracking-widest uppercase">New Lead</span>}
                    </h3>
                    <p className="text-sm font-bold text-slate-500 mt-1">
                      Submitted by: <span className="text-active-dark">{order.rep?.username}</span> on {new Date(order.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                  <div className="text-right">
                    <p className="text-xs font-bold text-slate-400 uppercase tracking-widest">Order Subtotal</p>
                    <p className="text-2xl font-black text-slate-800">₹{parseFloat(order.subtotal).toFixed(2)}</p>
                  </div>
                </div>

                {/* Body */}
                <div className="p-6">
                  {isNewCustomer && (
                    <div className="mb-6 bg-blue-50/50 p-4 rounded-xl border border-blue-100">
                      <h4 className="text-[11px] font-black text-blue-600 uppercase tracking-widest mb-3">Lead Information</h4>
                      <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
                        <div><span className="text-slate-400 block text-xs">Mobile</span> <span className="font-bold text-slate-700">{newCustomerObj?.mobile || '-'}</span></div>
                        <div><span className="text-slate-400 block text-xs">GSTIN</span> <span className="font-bold text-slate-700 uppercase">{newCustomerObj?.gstin || '-'}</span></div>
                        <div><span className="text-slate-400 block text-xs">City</span> <span className="font-bold text-slate-700">{newCustomerObj?.city || '-'}</span></div>
                        <div><span className="text-slate-400 block text-xs">State</span> <span className="font-bold text-slate-700">{newCustomerObj?.state || '-'}</span></div>
                      </div>
                      <div className="mt-4 flex justify-end">
                        <button 
                          onClick={() => handleApproveCustomer(order.id)}
                          className="bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-6 rounded-xl text-sm shadow-[0_4px_12px_rgba(59,130,246,0.3)] transition-all"
                        >
                          Approve Lead & Add to Master
                        </button>
                      </div>
                    </div>
                  )}

                  <div>
                    <h4 className="text-[11px] font-black text-slate-400 uppercase tracking-widest mb-3">Requested Items</h4>
                    <div className="overflow-x-auto">
                      <table className="w-full text-left border-collapse">
                        <thead>
                          <tr className="border-b border-slate-100">
                            <th className="py-2 text-[11px] font-black text-slate-400 uppercase tracking-widest w-[40%]">Product</th>
                            <th className="py-2 text-[11px] font-black text-slate-400 uppercase tracking-widest text-right">Qty</th>
                            <th className="py-2 text-[11px] font-black text-slate-400 uppercase tracking-widest text-right">Rate</th>
                            <th className="py-2 text-[11px] font-black text-slate-400 uppercase tracking-widest text-right">Total</th>
                          </tr>
                        </thead>
                        <tbody>
                          {order.items.map(item => (
                            <tr key={item.id} className="border-b border-slate-50 last:border-0">
                              <td className="py-2 font-bold text-sm text-slate-700">{item.product}</td>
                              <td className="py-2 font-bold text-sm text-slate-700 text-right">{item.qty}</td>
                              <td className="py-2 font-bold text-sm text-slate-700 text-right">₹{parseFloat(item.rate).toFixed(2)}</td>
                              <td className="py-2 font-black text-sm text-slate-800 text-right">₹{parseFloat(item.total).toFixed(2)}</td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>

                {/* Footer Actions */}
                {activeTab === 'PENDING' ? (
                  <div className="bg-slate-50 px-6 py-4 flex justify-between items-center border-t border-slate-100">
                    <button 
                      onClick={() => handleRejectOrder(order.id)}
                      className="text-rose-500 hover:text-rose-600 hover:bg-rose-50 font-black text-xs uppercase tracking-widest px-4 py-2 rounded-lg transition-colors"
                    >
                      Reject Order
                    </button>
                    <button 
                      disabled={isNewCustomer}
                      onClick={() => handleApproveOrder(order)}
                      className={`font-black text-[13px] px-8 py-3 rounded-xl shadow-lg transition-all ${
                        isNewCustomer 
                        ? 'bg-slate-200 text-slate-400 cursor-not-allowed' 
                        : 'bg-active-dark text-white hover:scale-105 active:scale-95 shadow-[0_8px_20px_rgba(0,0,0,0.15)]'
                      }`}
                    >
                      {isNewCustomer ? 'Awaiting Lead Approval' : 'Approve & Create Performa'}
                    </button>
                  </div>
                ) : (
                  <div className="bg-slate-50 px-6 py-4 flex justify-end items-center border-t border-slate-100 gap-4">
                    <button 
                      onClick={() => handlePrintFactoryOrder(order)}
                      className="font-black text-[13px] px-8 py-3 rounded-xl shadow-lg transition-all bg-emerald-600 text-white hover:scale-105 active:scale-95 shadow-[0_8px_20px_rgba(0,0,0,0.15)] flex items-center gap-2"
                    >
                      <span>🖨️</span> Print Factory Order
                    </button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
