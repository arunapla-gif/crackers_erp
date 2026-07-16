import { create } from 'zustand';

export const useStore = create((set, get) => ({
  // App Global State
  currentType: 'INV', // 'INV', 'EST', 'PRO', 'MASTER'
  
  // Actions
  setCurrentType: (type) => set({ currentType: type }),

  // Billing Cart State
  originState: 'Tamil Nadu', // Default origin
  billState: 'Tamil Nadu', // Destination state
  rows: [{ id: 1, product: '', hsn: '', qty: 1, rate: 0, tax: 18, amount: 0 }],
  chargeRows: [{ id: 1, name: '', source: 'MANUAL', mode: 'ADD', type: 'AMOUNT', value: 0, amount: 0, series: 'SGFI', number: '' }],
  totals: { subtotal: 0, tax: 0, cgst: 0, sgst: 0, igst: 0, charges: 0, grandTotal: 0 },

  setOriginState: (state) => {
    set({ originState: state });
    get().calculateTotals();
  },

  setBillState: (state) => {
    set({ billState: state });
    get().calculateTotals();
  },

  addRow: () => {
    set((state) => ({
      rows: [...state.rows, { id: Date.now(), product: '', hsn: '', qty: 1, rate: 0, tax: 18, amount: 0 }]
    }));
    get().calculateTotals();
  },

  removeRow: (id) => {
    set((state) => {
      const newRows = state.rows.filter(r => r.id !== id);
      return { rows: newRows.length ? newRows : [{ id: Date.now(), product: '', hsn: '', qty: 1, rate: 0, tax: 18, amount: 0 }] };
    });
    get().calculateTotals();
  },

  updateRow: (id, field, value) => {
    set((state) => {
      const newRows = state.rows.map(row => {
        if (row.id === id) {
          const updated = { ...row, [field]: value };
          // Auto-calculate amount if qty or rate changes
          if (field === 'qty' || field === 'rate') {
            updated.amount = parseFloat((updated.qty * updated.rate).toFixed(2)) || 0;
          }
          return updated;
        }
        return row;
      });
      return { rows: newRows };
    });
    get().calculateTotals();
  },

  clearCart: () => {
    set({
      rows: [{ id: Date.now(), product: '', hsn: '', qty: 1, rate: 0, tax: 18, amount: 0 }],
      chargeRows: [{ id: Date.now(), name: '', source: 'MANUAL', mode: 'ADD', type: 'AMOUNT', value: 0, amount: 0, series: 'SGFI', number: '' }],
      totals: { subtotal: 0, tax: 0, cgst: 0, sgst: 0, igst: 0, charges: 0, grandTotal: 0 }
    });
    get().calculateTotals();
  },

  // Charge Actions
  addChargeRow: () => {
    set((state) => ({
      chargeRows: [...state.chargeRows, { id: Date.now(), name: '', source: 'MANUAL', mode: 'ADD', type: 'AMOUNT', value: 0, amount: 0, series: 'SGFI', number: '' }]
    }));
    get().calculateTotals();
  },

  removeChargeRow: (id) => {
    set((state) => {
      const newRows = state.chargeRows.filter(r => r.id !== id);
      return { chargeRows: newRows.length ? newRows : [{ id: Date.now(), name: '', source: 'MANUAL', mode: 'ADD', type: 'AMOUNT', value: 0, amount: 0, series: 'SGFI', number: '' }] };
    });
    get().calculateTotals();
  },

  updateChargeRow: (id, field, value) => {
    set((state) => {
      const newRows = state.chargeRows.map(row => {
        if (row.id === id) {
          return { ...row, [field]: value };
        }
        return row;
      });
      return { chargeRows: newRows };
    });
    get().calculateTotals();
  },

  calculateTotals: () => set((state) => {
    let subtotal = 0;
    let tax = 0;
    
    state.rows.forEach(row => {
      subtotal += row.amount;
      if (state.currentType === 'INV') {
        tax += row.amount * (row.tax / 100);
      }
    });

    let totalCharges = 0;
    let newChargeRows = state.chargeRows || [];

    if (state.currentType !== 'INV') {
      newChargeRows = newChargeRows.map(row => {
        let amt = 0;
        if (row.name || row.value) {
          amt = row.type === 'PERCENT' ? (subtotal * row.value / 100) : parseFloat(row.value);
          if (row.mode === 'DEDUCT') amt = -amt;
        }
        totalCharges += amt;
        return { ...row, amount: parseFloat(amt.toFixed(2)) };
      });
    }

    const isIntraState = state.originState.toLowerCase() === state.billState.toLowerCase();
    
    return {
      chargeRows: newChargeRows,
      totals: {
        subtotal: parseFloat(subtotal.toFixed(2)),
        tax: parseFloat(tax.toFixed(2)),
        cgst: (state.currentType === 'INV' && isIntraState) ? parseFloat((tax / 2).toFixed(2)) : 0,
        sgst: (state.currentType === 'INV' && isIntraState) ? parseFloat((tax / 2).toFixed(2)) : 0,
        igst: (state.currentType === 'INV' && !isIntraState) ? parseFloat(tax.toFixed(2)) : 0,
        charges: parseFloat(totalCharges.toFixed(2)),
        grandTotal: parseFloat((subtotal + tax + totalCharges).toFixed(2))
      }
    };
  })
}));
