import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/erp_theme.dart';
import '../../domain/models/user_session.dart';
import '../features/auth/view_models/auth_view_model.dart';
import '../features/production/view_models/daily_production_view_model.dart';

class ErpShellScope extends InheritedWidget {
  const ErpShellScope({
    required this.isEmbedded,
    required super.child,
    super.key,
  });

  final bool isEmbedded;

  static bool isEmbeddedShell(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ErpShellScope>();
    return scope?.isEmbedded ?? false;
  }

  @override
  bool updateShouldNotify(ErpShellScope oldWidget) =>
      isEmbedded != oldWidget.isEmbedded;
}

class ErpScreenScaffold extends StatelessWidget {
  const ErpScreenScaffold({
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor,
    super.key,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final embedded = ErpShellScope.isEmbeddedShell(context);
    return Scaffold(
      backgroundColor: backgroundColor ?? ErpTheme.slate50,
      appBar: embedded
          ? null
          : AppBar(
              title: Text(title),
              actions: actions,
            ),
      floatingActionButton: floatingActionButton,
      body: body,
    );
  }
}

class ErpNavMenuItem {
  const ErpNavMenuItem({
    required this.id,
    required this.path,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.docType,
  });

  final String id;
  final String path;
  final String title;
  final String subtitle;
  final IconData icon;
  final String? docType;
}

class ErpRouteMeta {
  const ErpRouteMeta({
    required this.title,
    required this.badge,
    required this.section,
  });

  final String title;
  final String badge;
  final ErpSection section;
}

ErpRouteMeta resolveRouteMeta(
  String location, {
  String activeDocType = 'INV',
  String activeDocNumber = 'SGFI-0001',
}) {
  if (location.startsWith('/billing-history')) {
    return const ErpRouteMeta(
      title: 'Billing History',
      badge: 'BILLING HISTORY',
      section: ErpSection.sales,
    );
  }
  if (location.startsWith('/billing')) {
    final prefix = switch (activeDocType) {
      'EST' => 'ESTIMATE',
      'PRO' => 'PERFORMA',
      _ => 'INVOICE',
    };
    return ErpRouteMeta(
      title: 'Billing',
      badge: '$prefix • $activeDocNumber',
      section: ErpSection.sales,
    );
  }
  if (location.startsWith('/sales-order')) {
    return const ErpRouteMeta(
      title: 'Sales Order Entry',
      badge: 'SALES ORDER',
      section: ErpSection.sales,
    );
  }
  if (location.startsWith('/pending-orders')) {
    return const ErpRouteMeta(
      title: 'Pending Sales Orders',
      badge: 'PENDING ORDERS',
      section: ErpSection.sales,
    );
  }
  if (location.startsWith('/customer-rates')) {
    return const ErpRouteMeta(
      title: 'Customer Rates',
      badge: 'CUSTOMER RATES',
      section: ErpSection.sales,
    );
  }
  if (location.startsWith('/customers')) {
    return const ErpRouteMeta(
      title: 'Customer Master',
      badge: 'CUSTOMER MASTER',
      section: ErpSection.sales,
    );
  }
  if (location.startsWith('/transporters')) {
    return const ErpRouteMeta(
      title: 'Transporter Master',
      badge: 'TRANSPORTERS',
      section: ErpSection.sales,
    );
  }
  if (location.startsWith('/vehicles')) {
    return const ErpRouteMeta(
      title: 'Vehicle Master',
      badge: 'VEHICLES',
      section: ErpSection.sales,
    );
  }
  if (location.startsWith('/purchase')) {
    return const ErpRouteMeta(
      title: 'Purchase Entry',
      badge: 'PURCHASE ENTRY',
      section: ErpSection.purchases,
    );
  }
  if (location.startsWith('/suppliers')) {
    return const ErpRouteMeta(
      title: 'Supplier Master',
      badge: 'SUPPLIER MASTER',
      section: ErpSection.purchases,
    );
  }
  if (location.startsWith('/materials')) {
    return const ErpRouteMeta(
      title: 'Material Master',
      badge: 'RAW MATERIALS',
      section: ErpSection.purchases,
    );
  }
  if (location.startsWith('/stock')) {
    return const ErpRouteMeta(
      title: 'Godown Stock Ledger',
      badge: 'STOCK LEDGER',
      section: ErpSection.godown,
    );
  }
  if (location.startsWith('/transfers')) {
    return const ErpRouteMeta(
      title: 'Stock Transfer',
      badge: 'STOCK TRANSFER',
      section: ErpSection.godown,
    );
  }
  if (location.startsWith('/godowns')) {
    return const ErpRouteMeta(
      title: 'Godown Master',
      badge: 'GODOWN MASTER',
      section: ErpSection.godown,
    );
  }
  if (location.startsWith('/products')) {
    return const ErpRouteMeta(
      title: 'Product Master',
      badge: 'PRODUCT MASTER',
      section: ErpSection.godown,
    );
  }
  if (location.startsWith('/production')) {
    return const ErpRouteMeta(
      title: 'Production Entry',
      badge: 'PRODUCTION',
      section: ErpSection.production,
    );
  }
  if (location.startsWith('/machines')) {
    return const ErpRouteMeta(
      title: 'Processing Master',
      badge: 'PROCESSINGS',
      section: ErpSection.production,
    );
  }
  if (location.startsWith('/factory-orders')) {
    return const ErpRouteMeta(
      title: 'Factory Orders',
      badge: 'FACTORY ORDERS',
      section: ErpSection.production,
    );
  }
  if (location.startsWith('/payroll')) {
    return const ErpRouteMeta(
      title: 'Payroll Entry',
      badge: 'PAYROLL',
      section: ErpSection.hr,
    );
  }
  if (location.startsWith('/employees')) {
    return const ErpRouteMeta(
      title: 'Employee Master',
      badge: 'EMPLOYEES',
      section: ErpSection.hr,
    );
  }
  if (location.startsWith('/company-profiles')) {
    return const ErpRouteMeta(
      title: 'Company Profiles',
      badge: 'COMPANY PROFILES',
      section: ErpSection.admin,
    );
  }
  if (location.startsWith('/users')) {
    return const ErpRouteMeta(
      title: 'User Management',
      badge: 'USERS & RBAC',
      section: ErpSection.admin,
    );
  }
  if (location.startsWith('/eway-bills')) {
    return const ErpRouteMeta(
      title: 'E-Way Bill Fetcher',
      badge: 'E-WAY BILLS',
      section: ErpSection.admin,
    );
  }
  if (location.startsWith('/inventory-history')) {
    return const ErpRouteMeta(
      title: 'Inventory History',
      badge: 'INVENTORY HISTORY',
      section: ErpSection.admin,
    );
  }
  if (location.startsWith('/legacy')) {
    return const ErpRouteMeta(
      title: 'Old ERP Portal',
      badge: 'LEGACY ARCHIVE',
      section: ErpSection.admin,
    );
  }
  return const ErpRouteMeta(
    title: 'Crackers ERP',
    badge: 'MASTER',
    section: ErpSection.sales,
  );
}

class ErpShellScaffold extends StatelessWidget {
  const ErpShellScaffold({
    required this.location,
    required this.child,
    required this.authViewModel,
    required this.productionViewModel,
    this.activeDocType = 'INV',
    this.activeDocNumber = 'SGFI-0001',
    this.onSelectDocType,
    super.key,
  });

  final String location;
  final Widget child;
  final AuthViewModel authViewModel;
  final DailyProductionViewModel productionViewModel;
  final String activeDocType;
  final String activeDocNumber;
  final void Function(String docType)? onSelectDocType;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([authViewModel, productionViewModel]),
      builder: (context, _) {
        final user = authViewModel.currentUser;
        if (user == null) return child;

        if (user.isSupervisor) {
          return _SupervisorShellScaffold(
            location: location,
            authViewModel: authViewModel,
            productionViewModel: productionViewModel,
            child: child,
          );
        }

        if (user.isRep) {
          return _RepShellScaffold(
            authViewModel: authViewModel,
            child: child,
          );
        }

        // Dashboard landing screen renders fullscreen without sticky Header.
        if (location == '/') {
          return child;
        }

        return _ErpAdminStaffShell(
          location: location,
          user: user,
          authViewModel: authViewModel,
          productionViewModel: productionViewModel,
          activeDocType: activeDocType,
          activeDocNumber: activeDocNumber,
          onSelectDocType: onSelectDocType,
          child: child,
        );
      },
    );
  }
}

class _SupervisorShellScaffold extends StatelessWidget {
  const _SupervisorShellScaffold({
    required this.location,
    required this.child,
    required this.authViewModel,
    required this.productionViewModel,
  });

  final String location;
  final Widget child;
  final AuthViewModel authViewModel;
  final DailyProductionViewModel productionViewModel;

  int get _selectedIndex {
    if (location.startsWith('/employees')) return 1;
    if (location.startsWith('/factory-orders')) return 2;
    return 0;
  }

  void _goIndex(BuildContext context, int idx) {
    switch (idx) {
      case 0:
        context.go('/production');
      case 1:
        context.go('/employees');
      case 2:
        context.go('/factory-orders');
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    if (productionViewModel.hasUnsavedChanges) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Unsaved Production Entries'),
          content: const Text(
            'You have unsaved production entries stored as a local draft. Sign out anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Stay'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: ErpTheme.dangerRose),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await authViewModel.logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = authViewModel.currentUser;
    final hasUnsaved = productionViewModel.hasUnsavedChanges;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;

        if (isWide) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (idx) => _goIndex(context, idx),
                  extended: constraints.maxWidth >= 1000,
                  backgroundColor: Colors.white,
                  indicatorColor: ErpTheme.productionAmberSoft,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 12,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ErpTheme.productionAmber,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.local_fire_department_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        if (constraints.maxWidth >= 1000) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Crackers ERP',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: ErpTheme.slate900,
                            ),
                          ),
                          if (user != null)
                            Text(
                              '${user.username} (${user.role})',
                              style: const TextStyle(
                                fontSize: 11,
                                color: ErpTheme.slate500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: IconButton(
                          onPressed: () => _confirmLogout(context),
                          tooltip: 'Sign Out',
                          icon: const Icon(Icons.logout_rounded),
                          color: ErpTheme.dangerRose,
                        ),
                      ),
                    ),
                  ),
                  destinations: [
                    NavigationRailDestination(
                      icon: Badge(
                        isLabelVisible: hasUnsaved,
                        child: const Icon(Icons.precision_manufacturing_outlined),
                      ),
                      selectedIcon: Badge(
                        isLabelVisible: hasUnsaved,
                        child: const Icon(
                          Icons.precision_manufacturing,
                          color: ErpTheme.productionAmber,
                        ),
                      ),
                      label: const Text('Production'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.groups_outlined),
                      selectedIcon: Icon(
                        Icons.groups,
                        color: ErpTheme.hrIndigo,
                      ),
                      label: Text('Workers & Adv'),
                    ),
                    const NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(
                        Icons.inventory_2,
                        color: ErpTheme.ordersEmerald,
                      ),
                      label: Text('Factory Orders'),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, color: ErpTheme.slate200),
                Expanded(child: child),
              ],
            ),
          );
        }

        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (idx) => _goIndex(context, idx),
            backgroundColor: Colors.white,
            indicatorColor: ErpTheme.productionAmberSoft,
            destinations: [
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: hasUnsaved,
                  child: const Icon(Icons.precision_manufacturing_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: hasUnsaved,
                  child: const Icon(
                    Icons.precision_manufacturing,
                    color: ErpTheme.productionAmber,
                  ),
                ),
                label: 'Production',
              ),
              const NavigationDestination(
                icon: Icon(Icons.groups_outlined),
                selectedIcon: Icon(
                  Icons.groups,
                  color: ErpTheme.hrIndigo,
                ),
                label: 'Workers & Adv',
              ),
              const NavigationDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(
                  Icons.inventory_2,
                  color: ErpTheme.ordersEmerald,
                ),
                label: 'Orders',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RepShellScaffold extends StatelessWidget {
  const _RepShellScaffold({
    required this.child,
    required this.authViewModel,
  });

  final Widget child;
  final AuthViewModel authViewModel;

  @override
  Widget build(BuildContext context) {
    return ErpShellScope(
      isEmbedded: true,
      child: Scaffold(
        backgroundColor: ErpTheme.slate50,
        appBar: AppBar(
          title: const Text('Sales Order Portal'),
          actions: [
            AccountAppBarAction(authViewModel: authViewModel),
          ],
        ),
        body: child,
      ),
    );
  }
}

class _ErpAdminStaffShell extends StatelessWidget {
  const _ErpAdminStaffShell({
    required this.location,
    required this.child,
    required this.user,
    required this.authViewModel,
    required this.productionViewModel,
    required this.activeDocType,
    required this.activeDocNumber,
    this.onSelectDocType,
  });

  final String location;
  final Widget child;
  final UserAccount user;
  final AuthViewModel authViewModel;
  final DailyProductionViewModel productionViewModel;
  final String activeDocType;
  final String activeDocNumber;
  final void Function(String docType)? onSelectDocType;

  List<ErpNavMenuItem> _salesItems() => [
    if (user.isAdmin)
      const ErpNavMenuItem(
        id: 'pending-orders',
        path: '/pending-orders',
        title: 'Pending Orders',
        subtitle: 'Review rep orders',
        icon: Icons.notifications_active_outlined,
      ),
    if (user.canView('billing')) ...[
      const ErpNavMenuItem(
        id: 'billing-inv',
        path: '/billing',
        docType: 'INV',
        title: 'Invoice',
        subtitle: 'Create Tax Invoice',
        icon: Icons.receipt_long_outlined,
      ),
      const ErpNavMenuItem(
        id: 'billing-est',
        path: '/billing',
        docType: 'EST',
        title: 'Estimate',
        subtitle: 'Draft an estimate',
        icon: Icons.description_outlined,
      ),
      const ErpNavMenuItem(
        id: 'billing-pro',
        path: '/billing',
        docType: 'PRO',
        title: 'Performa',
        subtitle: 'Generate performa',
        icon: Icons.assignment_outlined,
      ),
    ],
    if (user.canView('reports'))
      const ErpNavMenuItem(
        id: 'billing-history',
        path: '/billing-history',
        title: 'Billing History',
        subtitle: 'View past invoices',
        icon: Icons.history_rounded,
      ),
    if (user.canView('customers'))
      const ErpNavMenuItem(
        id: 'customers',
        path: '/customers',
        title: 'Customer Master',
        subtitle: 'Manage customers',
        icon: Icons.people_outline,
      ),
    if (user.isAdmin)
      const ErpNavMenuItem(
        id: 'customer-rates',
        path: '/customer-rates',
        title: 'Customer Rates',
        subtitle: 'Custom pricing',
        icon: Icons.price_change_outlined,
      ),
    if (user.canView('transporters'))
      const ErpNavMenuItem(
        id: 'transporters',
        path: '/transporters',
        title: 'Transporter Master',
        subtitle: 'Logistics & shipping',
        icon: Icons.local_shipping_outlined,
      ),
    if (user.canView('vehicles'))
      const ErpNavMenuItem(
        id: 'vehicles',
        path: '/vehicles',
        title: 'Vehicle Master',
        subtitle: 'Manage dispatch fleet',
        icon: Icons.fire_truck_outlined,
      ),
  ];

  List<ErpNavMenuItem> _purchasesItems() => [
    if (user.canView('purchase'))
      const ErpNavMenuItem(
        id: 'purchase',
        path: '/purchase',
        title: 'Purchase Entry',
        subtitle: 'Record inward stock',
        icon: Icons.shopping_cart_checkout_outlined,
      ),
    if (user.canView('suppliers'))
      const ErpNavMenuItem(
        id: 'suppliers',
        path: '/suppliers',
        title: 'Supplier Master',
        subtitle: 'Manage suppliers',
        icon: Icons.factory_outlined,
      ),
    if (user.canView('materials'))
      const ErpNavMenuItem(
        id: 'materials',
        path: '/materials',
        title: 'Material Master',
        subtitle: 'Manage raw materials',
        icon: Icons.inventory_2_outlined,
      ),
  ];

  List<ErpNavMenuItem> _godownItems() => [
    if (user.canView('stock'))
      const ErpNavMenuItem(
        id: 'stock',
        path: '/stock',
        title: 'Stock Ledger',
        subtitle: 'View inventory',
        icon: Icons.bar_chart_rounded,
      ),
    if (user.canView('transfers'))
      const ErpNavMenuItem(
        id: 'transfers',
        path: '/transfers',
        title: 'Stock Transfer',
        subtitle: 'Move between godowns',
        icon: Icons.swap_horiz_rounded,
      ),
    if (user.canView('godowns'))
      const ErpNavMenuItem(
        id: 'godowns',
        path: '/godowns',
        title: 'Godown Master',
        subtitle: 'Manage locations',
        icon: Icons.warehouse_outlined,
      ),
    if (user.canView('products'))
      const ErpNavMenuItem(
        id: 'products',
        path: '/products',
        title: 'Product Master',
        subtitle: 'Finished goods & EP/WIP',
        icon: Icons.auto_awesome_outlined,
      ),
    if (user.canView('materials'))
      const ErpNavMenuItem(
        id: 'godown-materials',
        path: '/materials',
        title: 'Material Master',
        subtitle: 'Raw materials',
        icon: Icons.inventory_2_outlined,
      ),
    if (user.canView('vehicles'))
      const ErpNavMenuItem(
        id: 'godown-vehicles',
        path: '/vehicles',
        title: 'Vehicle Master',
        subtitle: 'Transport logistics',
        icon: Icons.local_shipping_outlined,
      ),
  ];

  List<ErpNavMenuItem> _productionItems() => [
    if (user.canView('production'))
      const ErpNavMenuItem(
        id: 'production',
        path: '/production',
        title: 'Production Entry',
        subtitle: 'Log daily production',
        icon: Icons.precision_manufacturing_outlined,
      ),
    if (user.canView('machines'))
      const ErpNavMenuItem(
        id: 'machines',
        path: '/machines',
        title: 'Processing Master',
        subtitle: 'Factory processing types',
        icon: Icons.settings_outlined,
      ),
    if (user.canViewFactoryOrders)
      const ErpNavMenuItem(
        id: 'factory-orders',
        path: '/factory-orders',
        title: 'Factory Orders',
        subtitle: 'Approved dispatch packing slips',
        icon: Icons.fact_check_outlined,
      ),
  ];

  List<ErpNavMenuItem> _hrItems() => [
    if (user.canView('payroll'))
      const ErpNavMenuItem(
        id: 'payroll',
        path: '/payroll',
        title: 'Payroll Entry',
        subtitle: 'Manage salary payouts',
        icon: Icons.payments_outlined,
      ),
    if (user.canView('employees'))
      const ErpNavMenuItem(
        id: 'employees',
        path: '/employees',
        title: 'Employee Master',
        subtitle: 'Manage staff & advances',
        icon: Icons.groups_outlined,
      ),
  ];

  List<ErpNavMenuItem> _adminItems() => [
    if (user.isAdmin)
      const ErpNavMenuItem(
        id: 'company-profiles',
        path: '/company-profiles',
        title: 'Company Profiles',
        subtitle: 'Multi-GSTIN Branches & Series',
        icon: Icons.apartment_outlined,
      ),
    if (user.isAdmin)
      const ErpNavMenuItem(
        id: 'users',
        path: '/users',
        title: 'User Management',
        subtitle: 'Manage staff access',
        icon: Icons.security_outlined,
      ),
    if (user.canView('reports'))
      const ErpNavMenuItem(
        id: 'eway-bills',
        path: '/eway-bills',
        title: 'E-Way Bill Fetcher',
        subtitle: 'Gov portal sync',
        icon: Icons.public_outlined,
      ),
    if (user.canView('reports'))
      const ErpNavMenuItem(
        id: 'inventory-history',
        path: '/inventory-history',
        title: 'Inventory History',
        subtitle: 'Purchases & transfers log',
        icon: Icons.timeline_rounded,
      ),
    if (user.canView('reports'))
      const ErpNavMenuItem(
        id: 'legacy',
        path: '/legacy',
        title: 'Old ERP Portal',
        subtitle: 'Historical MS Access data',
        icon: Icons.account_balance_outlined,
      ),
  ];

  void _navigateItem(BuildContext context, ErpNavMenuItem item) {
    if (item.docType != null) {
      onSelectDocType?.call(item.docType!);
    }
    context.go(item.path);
  }

  @override
  Widget build(BuildContext context) {
    final meta = resolveRouteMeta(
      location,
      activeDocType: activeDocType,
      activeDocNumber: activeDocNumber,
    );
    final palette = ErpTheme.paletteFor(meta.section);

    final sections = <({String label, ErpSectionPalette palette, List<ErpNavMenuItem> items})>[
      if (user.showSalesSection)
        (
          label: 'Sales',
          palette: ErpTheme.paletteFor(ErpSection.sales),
          items: _salesItems(),
        ),
      if (user.showPurchasesSection)
        (
          label: 'Purchases',
          palette: ErpTheme.paletteFor(ErpSection.purchases),
          items: _purchasesItems(),
        ),
      if (user.showGodownSection)
        (
          label: 'Godown',
          palette: ErpTheme.paletteFor(ErpSection.godown),
          items: _godownItems(),
        ),
      if (user.showProductionSection)
        (
          label: 'Production',
          palette: ErpTheme.paletteFor(ErpSection.production),
          items: _productionItems(),
        ),
      if (user.showHrSection)
        (
          label: 'HR',
          palette: ErpTheme.paletteFor(ErpSection.hr),
          items: _hrItems(),
        ),
      if (user.showAdminSection)
        (
          label: 'Admin',
          palette: ErpTheme.paletteFor(ErpSection.admin),
          items: _adminItems(),
        ),
    ].where((s) => s.items.isNotEmpty).toList();

    return ErpShellScope(
      isEmbedded: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 900;
          if (isDesktop) {
            return Scaffold(
              backgroundColor: ErpTheme.slate50,
              body: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: ErpTheme.slate200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: palette.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'ERP',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Crackers Billing ERP',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: ErpTheme.slate900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: palette.soft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            meta.badge,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: palette.dark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              alignment: WrapAlignment.end,
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                            OutlinedButton.icon(
                              onPressed: () => context.go('/'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: ErpTheme.slate100,
                                foregroundColor: ErpTheme.slate700,
                                side: const BorderSide(color: ErpTheme.slate200),
                                shape: const StadiumBorder(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              icon: const Icon(Icons.home_rounded, size: 16),
                              label: const Text('Home'),
                            ),
                            for (final sec in sections)
                              PopupMenuButton<ErpNavMenuItem>(
                                tooltip: sec.label,
                                offset: const Offset(0, 44),
                                onSelected: (item) =>
                                    _navigateItem(context, item),
                                itemBuilder: (context) => sec.items
                                    .map(
                                      (item) => PopupMenuItem<ErpNavMenuItem>(
                                        value: item,
                                        child: Row(
                                          children: [
                                            Icon(
                                              item.icon,
                                              size: 18,
                                              color: sec.palette.dark,
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    item.title,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 13,
                                                      color: ErpTheme.slate900,
                                                    ),
                                                  ),
                                                  Text(
                                                    item.subtitle,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      color: ErpTheme.slate500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: sec.palette.soft,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: sec.palette.primary
                                          .withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        sec.label,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          color: sec.palette.dark,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Icon(
                                        Icons.arrow_drop_down_rounded,
                                        size: 18,
                                        color: sec.palette.dark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 1,
                          height: 28,
                          color: ErpTheme.slate200,
                        ),
                        const SizedBox(width: 8),
                        AccountAppBarAction(
                          authViewModel: authViewModel,
                          hasUnsavedProduction:
                              productionViewModel.hasUnsavedChanges,
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            );
          }

          // Mobile / Narrow Tablet Layout with Drawer + Colored Header Bar
          return Scaffold(
            backgroundColor: ErpTheme.slate50,
            appBar: AppBar(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    meta.badge,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: palette.dark,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Dashboard Home',
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                ),
                AccountAppBarAction(
                  authViewModel: authViewModel,
                  hasUnsavedProduction: productionViewModel.hasUnsavedChanges,
                ),
              ],
            ),
            drawer: Drawer(
              backgroundColor: Colors.white,
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: palette.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'ERP',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Crackers ERP',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: ErpTheme.slate900,
                                  ),
                                ),
                                Text(
                                  '${user.username} • ${user.role}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: ErpTheme.slate500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.dashboard_outlined),
                      title: const Text(
                        'Home Dashboard',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/');
                      },
                    ),
                    for (final sec in sections) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          sec.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: sec.palette.dark,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      for (final item in sec.items)
                        ListTile(
                          dense: true,
                          leading: Icon(
                            item.icon,
                            size: 20,
                            color: sec.palette.dark,
                          ),
                          selected: location == item.path &&
                              (item.docType == null ||
                                  item.docType == activeDocType),
                          selectedTileColor: sec.palette.soft,
                          title: Text(
                            item.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            _navigateItem(context, item);
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ),
            body: child,
          );
        },
      ),
    );
  }
}

class AccountAppBarAction extends StatelessWidget {
  const AccountAppBarAction({
    required this.authViewModel,
    this.hasUnsavedProduction = false,
    super.key,
  });

  final AuthViewModel authViewModel;
  final bool hasUnsavedProduction;

  @override
  Widget build(BuildContext context) {
    final user = authViewModel.currentUser;
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Account & Server',
      onSelected: (value) async {
        if (value == 'logout') {
          if (hasUnsavedProduction) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Sign Out?'),
                content: const Text(
                  'Unsaved production changes stay stored locally in your draft for this date.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: ErpTheme.dangerRose,
                    ),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            );
            if (confirm != true) return;
          }
          await authViewModel.logout();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate900,
                ),
              ),
              Text(
                'Role: ${user.role}',
                style: const TextStyle(fontSize: 12, color: ErpTheme.slate500),
              ),
              const SizedBox(height: 4),
              Text(
                authViewModel.apiBaseUrl,
                style: const TextStyle(fontSize: 10, color: ErpTheme.slate500),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 18, color: ErpTheme.dangerRose),
              SizedBox(width: 8),
              Text(
                'Sign Out',
                style: TextStyle(
                  color: ErpTheme.dangerRose,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ErpTheme.slate100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ErpTheme.slate200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 18,
                color: ErpTheme.slate700,
              ),
              const SizedBox(width: 6),
              Text(
                user.username,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ErpTheme.slate900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
