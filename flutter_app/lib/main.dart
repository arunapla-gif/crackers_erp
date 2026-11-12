import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/routing/app_router.dart';
import 'core/theme/erp_theme.dart';
import 'data/repositories/admin_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/billing_repository.dart';
import 'data/repositories/employee_repository.dart';
import 'data/repositories/factory_order_repository.dart';
import 'data/repositories/inventory_repository.dart';
import 'data/repositories/legacy_repository.dart';
import 'data/repositories/master_repository.dart';
import 'data/repositories/payroll_repository.dart';
import 'data/repositories/production_repository.dart';
import 'data/repositories/sales_order_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/app_updater_service.dart';
import 'data/services/local_storage_service.dart';
import 'ui/core/app_update_dialog.dart';
import 'ui/features/admin/view_models/company_profile_view_model.dart';
import 'ui/features/admin/view_models/eway_bill_report_view_model.dart';
import 'ui/features/admin/view_models/user_master_view_model.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/employees/view_models/employees_advances_view_model.dart';
import 'ui/features/factory_orders/view_models/factory_orders_view_model.dart';
import 'ui/features/hr/view_models/payroll_view_model.dart';
import 'ui/features/inventory/view_models/inventory_history_view_model.dart';
import 'ui/features/inventory/view_models/purchase_view_model.dart';
import 'ui/features/inventory/view_models/stock_view_model.dart';
import 'ui/features/inventory/view_models/transfer_view_model.dart';
import 'ui/features/legacy/view_models/legacy_view_model.dart';
import 'ui/features/masters/view_models/customer_master_view_model.dart';
import 'ui/features/masters/view_models/customer_rates_view_model.dart';
import 'ui/features/masters/view_models/godown_master_view_model.dart';
import 'ui/features/masters/view_models/material_master_view_model.dart';
import 'ui/features/masters/view_models/product_master_view_model.dart';
import 'ui/features/masters/view_models/supplier_master_view_model.dart';
import 'ui/features/masters/view_models/transporter_master_view_model.dart';
import 'ui/features/masters/view_models/vehicle_master_view_model.dart';
import 'ui/features/production/view_models/daily_production_view_model.dart';
import 'ui/features/sales/view_models/billing_history_view_model.dart';
import 'ui/features/sales/view_models/billing_view_model.dart';
import 'ui/features/sales/view_models/pending_orders_view_model.dart';
import 'ui/features/sales/view_models/sales_order_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  final storage = await SharedPrefsLocalStorageService.create();

  late AuthViewModel authViewModel;
  final apiClient = HttpApiClient(
    baseUrlProvider: storage.getApiBaseUrl,
    tokenProvider: storage.getToken,
    onUnauthorized: () => authViewModel.handleUnauthorized(),
  );

  final authRepository = AuthRepository(apiClient: apiClient, storage: storage);
  final billingRepository = BillingRepository(
    apiClient: apiClient,
    storage: storage,
  );
  final masterRepository = MasterRepository(apiClient: apiClient);
  final adminRepository = AdminRepository(apiClient: apiClient);
  final salesOrderRepository = SalesOrderRepository(apiClient: apiClient);
  final productionRepository = ProductionRepository(
    apiClient: apiClient,
    storage: storage,
  );
  final employeeRepository = EmployeeRepository(apiClient: apiClient);
  final factoryOrderRepository = FactoryOrderRepository(apiClient: apiClient);
  final inventoryRepository = InventoryRepository(apiClient: apiClient);
  final payrollRepository = PayrollRepository(apiClient: apiClient);
  final legacyRepository = LegacyRepository(apiClient: apiClient);

  authViewModel = AuthViewModel(authRepository: authRepository);
  final billingViewModel = BillingViewModel(
    billingRepository: billingRepository,
    masterRepository: masterRepository,
    adminRepository: adminRepository,
  );
  final salesOrderViewModel = SalesOrderViewModel(
    salesOrderRepository: salesOrderRepository,
    masterRepository: masterRepository,
  );
  final pendingOrdersViewModel = PendingOrdersViewModel(
    salesOrderRepository: salesOrderRepository,
  );
  final billingHistoryViewModel = BillingHistoryViewModel(
    billingRepository: billingRepository,
  );
  final customerMasterViewModel = CustomerMasterViewModel(
    masterRepository: masterRepository,
    adminRepository: adminRepository,
    salesOrderRepository: salesOrderRepository,
  );
  final customerRatesViewModel = CustomerRatesViewModel(
    masterRepository: masterRepository,
  );
  final supplierMasterViewModel = SupplierMasterViewModel(
    masterRepository: masterRepository,
  );
  final transporterMasterViewModel = TransporterMasterViewModel(
    masterRepository: masterRepository,
  );
  final vehicleMasterViewModel = VehicleMasterViewModel(
    masterRepository: masterRepository,
  );
  final godownMasterViewModel = GodownMasterViewModel(
    masterRepository: masterRepository,
  );
  final productMasterViewModel = ProductMasterViewModel(
    masterRepository: masterRepository,
  );
  final materialMasterViewModel = MaterialMasterViewModel(
    masterRepository: masterRepository,
  );
  final productionViewModel = DailyProductionViewModel(
    productionRepository: productionRepository,
    employeeRepository: employeeRepository,
  );
  final employeesViewModel = EmployeesAdvancesViewModel(
    employeeRepository: employeeRepository,
  );
  final factoryOrdersViewModel = FactoryOrdersViewModel(
    orderRepository: factoryOrderRepository,
  );
  final purchaseViewModel = PurchaseViewModel(
    inventoryRepository: inventoryRepository,
    masterRepository: masterRepository,
  );
  final stockViewModel = StockViewModel(
    inventoryRepository: inventoryRepository,
    masterRepository: masterRepository,
  );
  final transferViewModel = TransferViewModel(
    inventoryRepository: inventoryRepository,
    masterRepository: masterRepository,
  );
  final inventoryHistoryViewModel = InventoryHistoryViewModel(
    inventoryRepository: inventoryRepository,
  );
  final payrollViewModel = PayrollViewModel(
    employeeRepository: employeeRepository,
    payrollRepository: payrollRepository,
  );
  final companyProfileViewModel = CompanyProfileViewModel(
    adminRepository: adminRepository,
    masterRepository: masterRepository,
  );
  final userMasterViewModel = UserMasterViewModel(
    adminRepository: adminRepository,
    masterRepository: masterRepository,
  );
  final ewayBillReportViewModel = EwayBillReportViewModel(
    billingRepository: billingRepository,
  );
  final legacyViewModel = LegacyViewModel(
    legacyRepository: legacyRepository,
  );

  authViewModel.initialize();

  authViewModel.addListener(() {
    if (!authViewModel.isAuthenticated) {
      billingViewModel.reset();
      salesOrderViewModel.reset();
      pendingOrdersViewModel.reset();
      billingHistoryViewModel.reset();
      customerMasterViewModel.reset();
      customerRatesViewModel.reset();
      supplierMasterViewModel.reset();
      transporterMasterViewModel.reset();
      vehicleMasterViewModel.reset();
      godownMasterViewModel.reset();
      productMasterViewModel.reset();
      materialMasterViewModel.reset();
      productionViewModel.reset();
      employeesViewModel.reset();
      factoryOrdersViewModel.reset();
      purchaseViewModel.reset();
      stockViewModel.reset();
      transferViewModel.reset();
      inventoryHistoryViewModel.reset();
      payrollViewModel.reset();
      companyProfileViewModel.reset();
      userMasterViewModel.reset();
      ewayBillReportViewModel.reset();
      legacyViewModel.reset();
    }
  });

  final appRouter = AppRouter(
    authViewModel: authViewModel,
    billingRepository: billingRepository,
    masterRepository: masterRepository,
    billingViewModel: billingViewModel,
    salesOrderViewModel: salesOrderViewModel,
    pendingOrdersViewModel: pendingOrdersViewModel,
    billingHistoryViewModel: billingHistoryViewModel,
    customerMasterViewModel: customerMasterViewModel,
    customerRatesViewModel: customerRatesViewModel,
    supplierMasterViewModel: supplierMasterViewModel,
    transporterMasterViewModel: transporterMasterViewModel,
    vehicleMasterViewModel: vehicleMasterViewModel,
    godownMasterViewModel: godownMasterViewModel,
    productMasterViewModel: productMasterViewModel,
    materialMasterViewModel: materialMasterViewModel,
    productionViewModel: productionViewModel,
    employeesViewModel: employeesViewModel,
    factoryOrdersViewModel: factoryOrdersViewModel,
    purchaseViewModel: purchaseViewModel,
    stockViewModel: stockViewModel,
    transferViewModel: transferViewModel,
    inventoryHistoryViewModel: inventoryHistoryViewModel,
    payrollViewModel: payrollViewModel,
    companyProfileViewModel: companyProfileViewModel,
    userMasterViewModel: userMasterViewModel,
    ewayBillReportViewModel: ewayBillReportViewModel,
    legacyViewModel: legacyViewModel,
  );

  final appUpdateController = AppUpdateController(
    updaterService: createPlatformAppUpdaterService(),
    apiBaseUrlProvider: storage.getApiBaseUrl,
  );

  runApp(
    CrackersErpApp(
      appRouter: appRouter,
      appUpdateController: appUpdateController,
    ),
  );
}

class CrackersErpApp extends StatelessWidget {
  const CrackersErpApp({
    required this.appRouter,
    required this.appUpdateController,
    super.key,
  });

  final AppRouter appRouter;
  final AppUpdateController appUpdateController;

  @override
  Widget build(BuildContext context) {
    return AppUpdateScope(
      controller: appUpdateController,
      child: MaterialApp.router(
        title: 'Crackers Billing ERP',
        debugShowCheckedModeBanner: false,
        theme: ErpTheme.buildLightTheme(),
        routerConfig: appRouter.router,
      ),
    );
  }
}
