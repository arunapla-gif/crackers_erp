import React from 'react';

export default function MachineMaster() {
  return (
    <div className="space-y-[14px]">
      <div className="bg-white/88 backdrop-blur-[14px] rounded-[26px] p-[18px] shadow-[0_18px_48px_rgba(15,23,42,0.08)] border border-slate-200">
        <h2 className="text-[13px] font-black text-active uppercase tracking-[0.7px] flex items-center gap-[10px] mb-4">
          <span className="w-[9px] h-[9px] rounded-full bg-active shadow-[0_0_0_5px_color-mix(in_srgb,var(--active)_14%,transparent)]"></span>
          Machine Master
        </h2>
        <div className="flex flex-col items-center justify-center min-h-[300px] text-center p-6">
          <div className="w-[64px] h-[64px] rounded-full bg-yellow-50 grid place-items-center mb-4 border-[3px] border-yellow-100">
            <span className="text-[28px]">⚙️</span>
          </div>
          <h3 className="font-black text-slate-700 text-lg">Machine Management</h3>
          <p className="text-sm font-bold text-slate-500 mt-2 max-w-[300px]">
            This is a placeholder for the Machine Master. Here you can configure factory machines, maintenance schedules, and capacity.
          </p>
        </div>
      </div>
    </div>
  );
}
