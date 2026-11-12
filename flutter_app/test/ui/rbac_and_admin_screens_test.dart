import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crackers_erp/core/routing/app_router.dart';
import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/repositories/admin_repository.dart';
import 'package:crackers_erp/data/repositories/auth_repository.dart';
import 'package:crackers_erp/data/repositories/billing_repository.dart';
import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/data/repositories/factory_order_repository.dart';
import 'package:crackers_erp/data/repositories/inventory_repository.dart';
import 'package:crackers_erp/data/repositories/legacy_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/repositories/payroll_repository.dart';
import 'package:crackers_erp/data/repositories/production_repository.dart';
import 'package:crackers_erp/data/repositories/sales_order_repository.dart';
import 'package:crackers_erp/ui/features/admin/view_models/company_profile_view_model.dart';
import 'package:crackers_erp/ui/features/admin/view_models/eway_bill_report_view_model.dart';
import 'package:crackers_erp/ui/features/admin/view_models/user_master_view_model.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/employees/view_models/employees_advances_view_model.dart';
import 'package:crackers_erp/ui/features/factory_orders/view_models/factory_orders_view_model.dart';
import 'package:crackers_erp/ui/features/hr/view_models/payroll_view_model.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/inventory_history_view_model.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/purchase_view_model.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/stock_view_model.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/transfer_view_model.dart';
import 'package:crackers_erp/ui/features/legacy/view_models/legacy_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/customer_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/customer_rates_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/godown_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/material_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/product_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/supplier_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/transporter_master_view_model.dart';
import 'package:crackers_erp/ui/features/masters/view_models/vehicle_master_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'package:crackers_erp/ui/features/sales/view_models/billing_history_view_model.dart';
import 'package:crackers_erp/ui/features/sales/view_models/billing_view_model.dart';
import 'package:crackers_erp/ui/features/sales/view_models/pending_orders_view_model.dart';
import 'package:crackers_erp/ui/features/sales/view_models/sales_order_view_model.dart';

import '../support/fakes.dart';

class _RouterHarness {
  _RouterHarness(this.api) : storage = InMemoryLocalStorageService() {
    final authRepo = AuthRepository(apiClient: api, storage: storage);
    final billingRepo = BillingRepository(apiClient: api, storage: storage);
    final masterRepo = MasterRepository(apiClient: api);
    final adminRepo = AdminRepository(apiClient: api);
    final salesOrderRepo = SalesOrderRepository(apiClient: api);
    final prodRepo = ProductionRepository(apiClient: api, storage: storage);
    final empRepo = EmployeeRepository(apiClient: api);
    final factoryOrderRepo = FactoryOrderRepository(apiClient: api);
    final invRepo = InventoryRepository(apiClient: api);
    final payrollRepo = PayrollRepository(apiClient: api);
    final legacyRepo = LegacyRepository(apiClient: api);

    authVm = AuthViewModel(authRepository: authRepo);
    billingVm = BillingViewModel(
      billingRepository: billingRepo,
      masterRepository: masterRepo,
      adminRepository: adminRepo,
    );
    salesOrderVm = SalesOrderViewModel(
      salesOrderRepository: salesOrderRepo,
      masterRepository: masterRepo,
    );
    pendingOrdersVm = PendingOrdersViewModel(
      salesOrderRepository: salesOrderRepo,
    );
    billingHistoryVm = BillingHistoryViewModel(billingRepository: billingRepo);
    customerMasterVm = CustomerMasterViewModel(
      masterRepository: masterRepo,
      adminRepository: adminRepo,
      salesOrderRepository: salesOrderRepo,
    );
    customerRatesVm = CustomerRatesViewModel(masterRepository: masterRepo);
    supplierMasterVm = SupplierMasterViewModel(masterRepository: masterRepo);
    transporterMasterVm = TransporterMasterViewModel(
      masterRepository: masterRepo,
    );
    vehicleMasterVm = VehicleMasterViewModel(masterRepository: masterRepo);
    godownMasterVm = GodownMasterViewModel(masterRepository: masterRepo);
    productMasterVm = ProductMasterViewModel(masterRepository: masterRepo);
    materialMasterVm = MaterialMasterViewModel(masterRepository: masterRepo);
    productionVm = DailyProductionViewModel(
      productionRepository: prodRepo,
      employeeRepository: empRepo,
    );
    employeesVm = EmployeesAdvancesViewModel(employeeRepository: empRepo);
    factoryOrdersVm = FactoryOrdersViewModel(orderRepository: factoryOrderRepo);
    purchaseVm = PurchaseViewModel(
      inventoryRepository: invRepo,
      masterRepository: masterRepo,
    );
    stockVm = StockViewModel(
      inventoryRepository: invRepo,
      masterRepository: masterRepo,
    );
    transferVm = TransferViewModel(
      inventoryRepository: invRepo,
      masterRepository: masterRepo,
    );
    inventoryHistoryVm = InventoryHistoryViewModel(
      inventoryRepository: invRepo,
    );
    payrollVm = PayrollViewModel(
      employeeRepository: empRepo,
      payrollRepository: payrollRepo,
    );
    companyProfileVm = CompanyProfileViewModel(
      adminRepository: adminRepo,
      masterRepository: masterRepo,
    );
    userMasterVm = UserMasterViewModel(
      adminRepository: adminRepo,
      masterRepository: masterRepo,
    );
    ewayBillVm = EwayBillReportViewModel(billingRepository: billingRepo);
    legacyVm = LegacyViewModel(legacyRepository: legacyRepo);

    appRouter = AppRouter(
      authViewModel: authVm,
      billingRepository: billingRepo,
      masterRepository: masterRepo,
      billingViewModel: billingVm,
      salesOrderViewModel: salesOrderVm,
      pendingOrdersViewModel: pendingOrdersVm,
      billingHistoryViewModel: billingHistoryVm,
      customerMasterViewModel: customerMasterVm,
      customerRatesViewModel: customerRatesVm,
      supplierMasterViewModel: supplierMasterVm,
      transporterMasterViewModel: transporterMasterVm,
      vehicleMasterViewModel: vehicleMasterVm,
      godownMasterViewModel: godownMasterVm,
      productMasterViewModel: productMasterVm,
      materialMasterViewModel: materialMasterVm,
      productionViewModel: productionVm,
      employeesViewModel: employeesVm,
      factoryOrdersViewModel: factoryOrdersVm,
      purchaseViewModel: purchaseVm,
      stockViewModel: stockVm,
      transferViewModel: transferVm,
      inventoryHistoryViewModel: inventoryHistoryVm,
      payrollViewModel: payrollVm,
      companyProfileViewModel: companyProfileVm,
      userMasterViewModel: userMasterVm,
      ewayBillReportViewModel: ewayBillVm,
      legacyViewModel: legacyVm,
    );
  }

  final FakeApiClient api;
  final InMemoryLocalStorageService storage;

  late final AuthViewModel authVm;
  late final BillingViewModel billingVm;
  late final SalesOrderViewModel salesOrderVm;
  late final PendingOrdersViewModel pendingOrdersVm;
  late final BillingHistoryViewModel billingHistoryVm;
  late final CustomerMasterViewModel customerMasterVm;
  late final CustomerRatesViewModel customerRatesVm;
  late final SupplierMasterViewModel supplierMasterVm;
  late final TransporterMasterViewModel transporterMasterVm;
  late final VehicleMasterViewModel vehicleMasterVm;
  late final GodownMasterViewModel godownMasterVm;
  late final ProductMasterViewModel productMasterVm;
  late final MaterialMasterViewModel materialMasterVm;
  late final DailyProductionViewModel productionVm;
  late final EmployeesAdvancesViewModel employeesVm;
  late final FactoryOrdersViewModel factoryOrdersVm;
  late final PurchaseViewModel purchaseVm;
  late final StockViewModel stockVm;
  late final TransferViewModel transferVm;
  late final InventoryHistoryViewModel inventoryHistoryVm;
  late final PayrollViewModel payrollVm;
  late final CompanyProfileViewModel companyProfileVm;
  late final UserMasterViewModel userMasterVm;
  late final EwayBillReportViewModel ewayBillVm;
  late final LegacyViewModel legacyVm;
  late final AppRouter appRouter;

  void dispose() {
    authVm.dispose();
    billingVm.dispose();
    salesOrderVm.dispose();
    pendingOrdersVm.dispose();
    billingHistoryVm.dispose();
    customerMasterVm.dispose();
    customerRatesVm.dispose();
    supplierMasterVm.dispose();
    transporterMasterVm.dispose();
    vehicleMasterVm.dispose();
    godownMasterVm.dispose();
    productMasterVm.dispose();
    materialMasterVm.dispose();
    productionVm.dispose();
    employeesVm.dispose();
    factoryOrdersVm.dispose();
    purchaseVm.dispose();
    stockVm.dispose();
    transferVm.dispose();
    inventoryHistoryVm.dispose();
    payrollVm.dispose();
    companyProfileVm.dispose();
    userMasterVm.dispose();
    ewayBillVm.dispose();
    legacyVm.dispose();
  }
}

Widget _buildRouterApp(_RouterHarness harness) {
  return MaterialApp.router(
    theme: ErpTheme.buildLightTheme(),
    routerConfig: harness.appRouter.router,
  );
}

void main() {
  testWidgets('Unauthenticated user redirects to /login', (tester) async {
    final harness = _RouterHarness(FakeApiClient());
    addTearDown(harness.dispose);

    await tester.pumpWidget(_buildRouterApp(harness));
    await tester.pumpAndSettle();

    expect(
      harness.appRouter.router.routerDelegate.currentConfiguration.uri.path,
      equals('/login'),
    );
    expect(find.text('Crackers ERP'), findsOneWidget);
  });

  testWidgets('SUPERVISOR redirects to /production and is blocked from billing/admin', (
    tester,
  ) async {
    final api = FakeApiClient()..roleToLogin = 'SUPERVISOR';
    final harness = _RouterHarness(api);
    addTearDown(harness.dispose);
    await harness.authVm.login(username: 'supervisor1', pin: '1234');

    await tester.pumpWidget(_buildRouterApp(harness));
    await tester.pumpAndSettle();

    expect(
      harness.appRouter.router.routerDelegate.currentConfiguration.uri.path,
      equals('/production'),
    );

    harness.appRouter.router.go('/billing');
    await tester.pumpAndSettle();
    expect(
      harness.appRouter.router.routerDelegate.currentConfiguration.uri.path,
      equals('/production'),
    );

    harness.appRouter.router.go('/users');
    await tester.pumpAndSettle();
    expect(
      harness.appRouter.router.routerDelegate.currentConfiguration.uri.path,
      equals('/production'),
    );
  });

  testWidgets('REP lands on /sales-order and cannot access /billing or /users', (
    tester,
  ) async {
    final api = FakeApiClient()..roleToLogin = 'REP';
    final harness = _RouterHarness(api);
    addTearDown(harness.dispose);
    await harness.authVm.login(username: 'rep_north', pin: '1111');

    await tester.pumpWidget(_buildRouterApp(harness));
    await tester.pumpAndSettle();

    expect(
      harness.appRouter.router.routerDelegate.currentConfiguration.uri.path,
      equals('/sales-order'),
    );

    harness.appRouter.router.go('/company-profiles');
    await tester.pumpAndSettle();
    expect(
      harness.appRouter.router.routerDelegate.currentConfiguration.uri.path,
      equals('/sales-order'),
    );
  });

  testWidgets('STAFF with billing:view accesses /billing but not /users', (
    tester,
  ) async {
    final api = FakeApiClient()
      ..roleToLogin = 'STAFF'
      ..permissionsToLogin = {
        'billing': {'view': true, 'add': true},
      };
    final harness = _RouterHarness(api);
    addTearDown(harness.dispose);
    await harness.authVm.login(username: 'biller1', pin: '2222');

    await tester.pumpWidget(_buildRouterApp(harness));
    await tester.pumpAndSettle();

    expect(
      harness.appRouter.router.routerDelegate.currentConfiguration.uri.path,
      equals('/'),
    );

    harness.appRouter.router.go('/billing');
    await tester.pumpAndSettle();
    expect(
      harness.appRouter.router.routerDelegate.currentConfiguration.uri.path,
      equals('/billing'),
    );

    harness.appRouter.router.go('/users');
    await tester.pumpAndSettle();
    expect(
      harness.appRouter.router.routerDelegate.currentConfiguration.uri.path,
      equals('/'),
    );
  });

  testWidgets('ADMIN navigates through Company Profiles, Users, E-Way Bills & Legacy Portal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = FakeApiClient(
      users: [
        {
          'id': 1,
          'username': 'admin',
          'role': 'ADMIN',
          'status': 'Active',
          'permissions': <String, dynamic>{},
        },
      ],
    )..roleToLogin = 'ADMIN';
    api.legacyAnalyticsData = {
      'financials': {
        'totalPurchases': 50000.0,
        'totalEstimates': 90000.0,
        'totalWages': 12000.0,
        'totalPayments': 40000.0,
      },
      'counts': {
        'customers': 3,
        'suppliers': 2,
        'employees': 4,
        'purchases': 5,
        'estimates': 6,
        'workentries': 7,
      },
    };
    api.legacyTrendProductsData = ['Paper'];

    final harness = _RouterHarness(api);
    addTearDown(harness.dispose);
    await harness.authVm.login(username: 'admin', pin: '1234');

    await tester.pumpWidget(_buildRouterApp(harness));
    await tester.pumpAndSettle();

    // Dashboard renders
    expect(
      harness.appRouter.router.routerDelegate.currentConfiguration.uri.path,
      equals('/'),
    );

    // Company Profiles
    harness.appRouter.router.go('/company-profiles');
    await tester.pumpAndSettle();
    expect(find.text('Company Profiles (Multi-GSTIN)'), findsOneWidget);
    expect(find.text('Sri Ganesh Fireworks'), findsOneWidget);

    // User Management
    harness.appRouter.router.go('/users');
    await tester.pumpAndSettle();
    expect(find.text('User Access & Permissions Master'), findsWidgets);

    // E-Way Bills
    harness.appRouter.router.go('/eway-bills');
    await tester.pumpAndSettle();
    expect(find.text('E-Way Bill Auto-Fetcher'), findsOneWidget);
    expect(find.text('GOV.IN PORTAL'), findsOneWidget);

    // Old ERP Portal
    harness.appRouter.router.go('/legacy');
    await tester.pumpAndSettle();
    expect(find.text('LEGACY ARCHIVE'), findsWidgets);
    expect(find.text('READ-ONLY'), findsOneWidget);
  });
}
