import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useStore } from '../store/useStore';

export default function SlideDashboard() {
  const navigate = useNavigate();
  const setCurrentType = useStore((state) => state.setCurrentType);

  const handleNavigate = (path, type) => {
    setCurrentType(type);
    navigate(path);
  };

  const cards = [
    {
      label: 'Billing',
      title: 'Invoice',
      sub: 'Invoice / Estimate / Performa',
      bg: 'bg-gradient-to-br from-rose-400 to-rose-600',
      action: () => handleNavigate('/billing', 'INV')
    },
    {
      label: 'Masters',
      title: 'Products',
      sub: 'HSN, GST, rate and unit',
      bg: 'bg-gradient-to-br from-blue-400 to-blue-600',
      action: () => handleNavigate('/products', 'MASTER')
    },
    {
      label: 'Stock',
      title: 'Transfer',
      sub: 'Godown-wise movement',
      bg: 'bg-gradient-to-br from-green-400 to-green-600',
      action: () => handleNavigate('/transfers', 'FACTORY')
    },
    {
      label: 'Reports',
      title: 'Analytics',
      sub: 'Date, month, number filters',
      bg: 'bg-gradient-to-br from-purple-400 to-purple-600',
      action: () => handleNavigate('/reports', 'MASTER')
    },
    {
      label: 'Factory',
      title: 'Production',
      sub: 'Production and Machines',
      bg: 'bg-gradient-to-br from-yellow-400 to-yellow-600',
      action: () => handleNavigate('/production', 'FACTORY')
    },
    {
      label: 'HR & Payroll',
      title: 'Payroll',
      sub: 'Manage staff & salaries',
      bg: 'bg-gradient-to-br from-indigo-400 to-indigo-600',
      action: () => handleNavigate('/payroll', 'REPORT')
    },
    {
      label: 'Legacy',
      title: 'Old ERP',
      sub: 'Historical data portal',
      bg: 'bg-gradient-to-br from-slate-700 to-slate-900',
      action: () => handleNavigate('/legacy', 'REPORT')
    }
  ];

  return (
    <section className="hidden lg:grid grid-cols-3 xl:grid-cols-7 gap-[14px] mb-[16px] overflow-hidden mt-[8px]">
      {cards.map((card, i) => (
        <div 
          key={i} 
          onClick={card.action}
          className={`relative min-h-[138px] rounded-[26px] p-[18px] text-white overflow-hidden shadow-[0_18px_46px_rgba(15,23,42,0.11)] cursor-pointer hover:-translate-y-[5px] hover:scale-[1.01] transition-all duration-[220ms] border border-white/20 ${card.bg}`}
        >
          {/* Background decoration circle */}
          <div className="absolute w-[160px] h-[160px] rounded-full -right-[50px] -top-[55px] bg-white/16"></div>
          
          <span className="inline-block text-[12px] font-[1000] bg-white/18 px-[10px] py-[7px] rounded-full z-10 relative">
            {card.label}
          </span>
          <strong className="block mt-[18px] text-[28px] font-black tracking-[-0.5px] z-10 relative">
            {card.title}
          </strong>
          <small className="block mt-[5px] text-white/86 font-[800] z-10 relative">
            {card.sub}
          </small>
        </div>
      ))}
    </section>
  );
}
