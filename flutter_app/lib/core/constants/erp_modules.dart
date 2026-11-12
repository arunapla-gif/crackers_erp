class ErpModuleInfo {
  const ErpModuleInfo({
    required this.id,
    required this.label,
    required this.category,
  });

  final String id;
  final String label;
  final String category;
}

const List<ErpModuleInfo> erpPermissionModules = [
  ErpModuleInfo(id: 'billing', label: 'Billing (INV/EST/PRO)', category: 'Sales'),
  ErpModuleInfo(id: 'customers', label: 'Customer Master', category: 'Sales'),
  ErpModuleInfo(id: 'transporters', label: 'Transporter Master', category: 'Sales'),
  ErpModuleInfo(id: 'vehicles', label: 'Vehicle Master', category: 'Sales'),
  ErpModuleInfo(id: 'purchase', label: 'Purchase Entry', category: 'Purchases'),
  ErpModuleInfo(id: 'suppliers', label: 'Supplier Master', category: 'Purchases'),
  ErpModuleInfo(id: 'materials', label: 'Material Master (RM)', category: 'Purchases'),
  ErpModuleInfo(id: 'stock', label: 'Godown Stock Ledger', category: 'Godown'),
  ErpModuleInfo(id: 'transfers', label: 'Stock Transfers', category: 'Godown'),
  ErpModuleInfo(id: 'godowns', label: 'Godown Master', category: 'Godown'),
  ErpModuleInfo(id: 'products', label: 'Product Master', category: 'Godown'),
  ErpModuleInfo(id: 'production', label: 'Daily Production', category: 'Production'),
  ErpModuleInfo(id: 'machines', label: 'Machine Master', category: 'Production'),
  ErpModuleInfo(id: 'employees', label: 'Employee Master', category: 'HR & Payroll'),
  ErpModuleInfo(id: 'payroll', label: 'Payroll Processing', category: 'HR & Payroll'),
  ErpModuleInfo(id: 'reports', label: 'Reports & History', category: 'Admin'),
];

