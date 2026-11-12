import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:crackers_erp/data/repositories/billing_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/domain/models/sales_order.dart';
import 'package:crackers_erp/domain/models/user_session.dart';
import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/features/admin/view_models/company_profile_view_model.dart';
import 'package:crackers_erp/ui/features/admin/view_models/eway_bill_report_view_model.dart';
import 'package:crackers_erp/ui/features/admin/view_models/user_master_view_model.dart';
import 'package:crackers_erp/ui/features/admin/views/company_profile_screen.dart';
import 'package:crackers_erp/ui/features/admin/views/eway_bill_report_screen.dart';
import 'package:crackers_erp/ui/features/admin/views/user_master_screen.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/auth/views/login_screen.dart';
import 'package:crackers_erp/ui/features/dashboard/views/dashboard_screen.dart';
import 'package:crackers_erp/ui/features/employees/view_models/employees_advances_view_model.dart';
import 'package:crackers_erp/ui/features/employees/views/employees_advances_screen.dart';
import 'package:crackers_erp/ui/features/factory_orders/view_models/factory_orders_view_model.dart';
import 'package:crackers_erp/ui/features/factory_orders/views/factory_orders_screen.dart';
import 'package:crackers_erp/ui/features/hr/view_models/payroll_view_model.dart';
import 'package:crackers_erp/ui/features/hr/views/payroll_entry_screen.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/inventory_history_view_model.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/purchase_view_model.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/stock_view_model.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/transfer_view_model.dart';
import 'package:crackers_erp/ui/features/inventory/views/godown_stock_screen.dart';
import 'package:crackers_erp/ui/features/inventory/views/inventory_history_screen.dart';
import 'package:crackers_erp/ui/features/inventory/views/purchase_entry_screen.dart';
import 'package:crackers_erp/ui/features/inventory/views/stock_transfer_screen.dart';
import 'package:crackers_erp/ui/features/legacy/view_models/legacy_view_model.dart';
import 'package:crackers_erp/ui/features/legacy/views/legacy_dashboard_screen.dart';
import 'package:crackers_erp/ui/features/masters/view_models/customer_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/customer_rates_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/godown_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/material_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/product_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/supplier_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/transporter_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/vehicle_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/views/customer_master_screen.dart';
import 'package:crackers_erp/ui/features/masters/views/customer_rates_screen.dart';
import 'package:crackers_erp/ui/features/masters/views/godown_master_screen.dart';
import 'package:crackers_erp/ui/features/masters/views/machine_master_screen.dart';
import 'package:crackers_erp/ui/features/masters/views/material_master_screen.dart';
import 'package:crackers_erp/ui/features/masters/views/product_master_screen.dart';
import 'package:crackers_erp/ui/features/masters/views/supplier_master_screen.dart';
import 'package:crackers_erp/ui/features/masters/views/transporter_master_screen.dart';
import 'package:crackers_erp/ui/features/masters/views/vehicle_master_screen.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'package:crackers_erp/ui/features/production/views/daily_production_screen.dart';
import 'package:crackers_erp/ui/features/sales/view_models/billing_history_view_model.dart';
import 'package:crackers_erp/ui/features/sales/view_models/billing_view_model.dart';
import 'package:crackers_erp/ui/features/sales/view_models/pending_orders_view_model.dart';
import 'package:crackers_erp/ui/features/sales/view_models/sales_order_view_model.dart';
import 'package:crackers_erp/ui/features/sales/views/billing_history_screen.dart';
import 'package:crackers_erp/ui/features/sales/views/billing_screen.dart';
import 'package:crackers_erp/ui/features/sales/views/invoice_print_screen.dart';
import 'package:crackers_erp/ui/features/sales/views/pending_orders_screen.dart';
import 'package:crackers_erp/ui/features/sales/views/sales_order_screen.dart';

class AppRouter {
  AppRouter({
    required this.authViewModel,
    required this.billingRepository,
    required this.masterRepository,
    required this.billingViewModel,
    required this.salesOrderViewModel,
    required this.pendingOrdersViewModel,
    required this.billingHistoryViewModel,
    required this.customerMasterViewModel,
    required this.customerRatesViewModel,
    required this.supplierMasterViewModel,
    required this.transporterMasterViewModel,
    required this.vehicleMasterViewModel,
    required this.godownMasterViewModel,
    required this.productMasterViewModel,
    required this.materialMasterViewModel,
    required this.productionViewModel,
    required this.employeesViewModel,
    required this.factoryOrdersViewModel,
    required this.purchaseViewModel,
    required this.stockViewModel,
    required this.transferViewModel,
    required this.inventoryHistoryViewModel,
    required this.payrollViewModel,
    required this.companyProfileViewModel,
    required this.userMasterViewModel,
    required this.ewayBillReportViewModel,
    required this.legacyViewModel,
  }) {
    router = GoRouter(
      initialLocation: _defaultHomePath(),
      refreshListenable: authViewModel,
      redirect: _handleRedirect,
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(viewModel: authViewModel),
        ),
        GoRoute(
          path: '/print/invoice/:number',
          builder: (context, state) {
            final numParam = Uri.decodeComponent(
              state.pathParameters['number'] ?? '',
            );
            return InvoicePrintScreen(
              invoiceNumber: numParam,
              billingRepository: billingRepository,
              masterRepository: masterRepository,
            );
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            return ListenableBuilder(
              listenable: billingViewModel,
              builder: (context, _) {
                final h = billingViewModel.header;
                final activeNum = '${h.series}${h.number}'.trim();
                return ErpShellScaffold(
                  location: state.matchedLocation,
                  authViewModel: authViewModel,
                  productionViewModel: productionViewModel,
                  activeDocType: billingViewModel.docType,
                  activeDocNumber: activeNum.isEmpty ? 'SGFI-0001' : activeNum,
                  onSelectDocType: billingViewModel.setDocType,
                  child: child,
                );
              },
            );
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => DashboardScreen(
                authViewModel: authViewModel,
                onSelectDocType: billingViewModel.setDocType,
              ),
            ),
            // Sales & Billing
            GoRoute(
              path: '/billing',
              builder: (context, state) =>
                  BillingScreen(viewModel: billingViewModel),
            ),
            GoRoute(
              path: '/billing-history',
              builder: (context, state) =>
                  BillingHistoryScreen(viewModel: billingHistoryViewModel),
            ),
            GoRoute(
              path: '/sales-order',
              builder: (context, state) => SalesOrderScreen(
                viewModel: salesOrderViewModel,
                authViewModel: authViewModel,
              ),
            ),
            GoRoute(
              path: '/pending-orders',
              builder: (context, state) => PendingOrdersScreen(
                viewModel: pendingOrdersViewModel,
                billingViewModel: billingViewModel,
              ),
            ),

            // Production, Workers & Factory Orders
            GoRoute(
              path: '/production',
              builder: (context, state) => DailyProductionScreen(
                viewModel: productionViewModel,
                authViewModel: authViewModel,
              ),
            ),
            GoRoute(
              path: '/employees',
              builder: (context, state) => EmployeesAdvancesScreen(
                viewModel: employeesViewModel,
                authViewModel: authViewModel,
              ),
            ),
            GoRoute(
              path: '/factory-orders',
              builder: (context, state) => FactoryOrdersScreen(
                viewModel: factoryOrdersViewModel,
                authViewModel: authViewModel,
              ),
            ),

            // Masters
            GoRoute(
              path: '/customers',
              builder: (context, state) {
                final extra = state.extra;
                return CustomerMasterScreen(
                  viewModel: customerMasterViewModel,
                  initialLeadArgs: extra is VerifyCustomerLeadArgs
                      ? extra
                      : null,
                );
              },
            ),
            GoRoute(
              path: '/customer-rates',
              builder: (context, state) =>
                  CustomerRatesScreen(viewModel: customerRatesViewModel),
            ),
            GoRoute(
              path: '/suppliers',
              builder: (context, state) =>
                  SupplierMasterScreen(viewModel: supplierMasterViewModel),
            ),
            GoRoute(
              path: '/transporters',
              builder: (context, state) => TransporterMasterScreen(
                viewModel: transporterMasterViewModel,
              ),
            ),
            GoRoute(
              path: '/vehicles',
              builder: (context, state) =>
                  VehicleMasterScreen(viewModel: vehicleMasterViewModel),
            ),
            GoRoute(
              path: '/godowns',
              builder: (context, state) =>
                  GodownMasterScreen(viewModel: godownMasterViewModel),
            ),
            GoRoute(
              path: '/products',
              builder: (context, state) =>
                  ProductMasterScreen(viewModel: productMasterViewModel),
            ),
            GoRoute(
              path: '/materials',
              builder: (context, state) =>
                  MaterialMasterScreen(viewModel: materialMasterViewModel),
            ),
            GoRoute(
              path: '/machines',
              builder: (context, state) => const MachineMasterScreen(),
            ),

            // Inventory & Payroll (Milestone E)
            GoRoute(
              path: '/purchase',
              builder: (context, state) =>
                  PurchaseEntryScreen(viewModel: purchaseViewModel),
            ),
            GoRoute(
              path: '/stock',
              builder: (context, state) =>
                  GodownStockScreen(viewModel: stockViewModel),
            ),
            GoRoute(
              path: '/transfers',
              builder: (context, state) =>
                  StockTransferScreen(viewModel: transferViewModel),
            ),
            GoRoute(
              path: '/inventory-history',
              builder: (context, state) => InventoryHistoryScreen(
                viewModel: inventoryHistoryViewModel,
              ),
            ),
            GoRoute(
              path: '/payroll',
              builder: (context, state) =>
                  PayrollEntryScreen(viewModel: payrollViewModel),
            ),

            // Admin & Legacy Portal
            GoRoute(
              path: '/company-profiles',
              builder: (context, state) =>
                  CompanyProfileScreen(viewModel: companyProfileViewModel),
            ),
            GoRoute(
              path: '/users',
              builder: (context, state) => UserMasterScreen(
                viewModel: userMasterViewModel,
                authViewModel: authViewModel,
              ),
            ),
            GoRoute(
              path: '/eway-bills',
              builder: (context, state) =>
                  EwayBillReportScreen(viewModel: ewayBillReportViewModel),
            ),
            GoRoute(
              path: '/legacy',
              builder: (context, state) =>
                  LegacyDashboardScreen(viewModel: legacyViewModel),
            ),
          ],
        ),
      ],
    );
  }

  final AuthViewModel authViewModel;
  final BillingRepository billingRepository;
  final MasterRepository masterRepository;
  final BillingViewModel billingViewModel;
  final SalesOrderViewModel salesOrderViewModel;
  final PendingOrdersViewModel pendingOrdersViewModel;
  final BillingHistoryViewModel billingHistoryViewModel;
  final CustomerMasterViewModel customerMasterViewModel;
  final CustomerRatesViewModel customerRatesViewModel;
  final SupplierMasterViewModel supplierMasterViewModel;
  final TransporterMasterViewModel transporterMasterViewModel;
  final VehicleMasterViewModel vehicleMasterViewModel;
  final GodownMasterViewModel godownMasterViewModel;
  final ProductMasterViewModel productMasterViewModel;
  final MaterialMasterViewModel materialMasterViewModel;
  final DailyProductionViewModel productionViewModel;
  final EmployeesAdvancesViewModel employeesViewModel;
  final FactoryOrdersViewModel factoryOrdersViewModel;
  final PurchaseViewModel purchaseViewModel;
  final StockViewModel stockViewModel;
  final TransferViewModel transferViewModel;
  final InventoryHistoryViewModel inventoryHistoryViewModel;
  final PayrollViewModel payrollViewModel;
  final CompanyProfileViewModel companyProfileViewModel;
  final UserMasterViewModel userMasterViewModel;
  final EwayBillReportViewModel ewayBillReportViewModel;
  final LegacyViewModel legacyViewModel;
  late final GoRouter router;

  String _defaultHomePath() {
    final user = authViewModel.currentUser;
    if (user == null) return '/login';
    if (user.isSupervisor) {
      if (user.canViewProduction) return '/production';
      if (user.canViewEmployees) return '/employees';
      return '/factory-orders';
    }
    if (user.isRep) return '/sales-order';
    return '/';
  }

  bool _isRoutePermitted(UserAccount user, String loc) {
    if (user.isAdmin) return true;
    if (user.isSupervisor) {
      return loc == '/production' ||
          loc == '/employees' ||
          loc == '/factory-orders';
    }
    if (user.isRep) {
      return loc == '/sales-order';
    }
    // STAFF RBAC checks
    if (loc == '/') return true;
    if (loc.startsWith('/billing-history')) return user.canView('reports');
    if (loc.startsWith('/billing') || loc.startsWith('/print/invoice')) {
      return user.canView('billing');
    }
    if (loc.startsWith('/customers')) return user.canView('customers');
    if (loc.startsWith('/suppliers')) return user.canView('suppliers');
    if (loc.startsWith('/products')) return user.canView('products');
    if (loc.startsWith('/transporters')) return user.canView('transporters');
    if (loc.startsWith('/godowns')) return user.canView('godowns');
    if (loc.startsWith('/purchase')) return user.canView('purchase');
    if (loc.startsWith('/stock')) return user.canView('stock');
    if (loc.startsWith('/vehicles')) return user.canView('vehicles');
    if (loc.startsWith('/transfers')) return user.canView('transfers');
    if (loc.startsWith('/materials')) return user.canView('materials');
    if (loc.startsWith('/production')) return user.canView('production');
    if (loc.startsWith('/machines')) return user.canView('machines');
    if (loc.startsWith('/employees')) return user.canView('employees');
    if (loc.startsWith('/payroll')) return user.canView('payroll');
    if (loc.startsWith('/inventory-history') ||
        loc.startsWith('/eway-bills') ||
        loc.startsWith('/legacy')) {
      return user.canView('reports');
    }
    if (loc.startsWith('/pending-orders') ||
        loc.startsWith('/customer-rates') ||
        loc.startsWith('/company-profiles') ||
        loc.startsWith('/users') ||
        loc.startsWith('/factory-orders')) {
      return false;
    }
    return true;
  }

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final loggedIn = authViewModel.isAuthenticated;
    final user = authViewModel.currentUser;
    final loc = state.matchedLocation;
    final goingToLogin = loc == '/login';

    if (!loggedIn && !goingToLogin) {
      return '/login';
    }
    if (loggedIn && user != null) {
      if (goingToLogin) {
        return _defaultHomePath();
      }
      if (loc == '/' && (user.isSupervisor || user.isRep)) {
        return _defaultHomePath();
      }
      if (!_isRoutePermitted(user, loc)) {
        return _defaultHomePath();
      }
    }
    return null;
  }
}
