import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/routing/app_router.dart';
import 'core/theme/erp_theme.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/employee_repository.dart';
import 'data/repositories/factory_order_repository.dart';
import 'data/repositories/production_repository.dart';
import 'data/services/api_client.dart';
import 'data/services/local_storage_service.dart';
import 'ui/features/auth/view_models/auth_view_model.dart';
import 'ui/features/employees/view_models/employees_advances_view_model.dart';
import 'ui/features/factory_orders/view_models/factory_orders_view_model.dart';
import 'ui/features/production/view_models/daily_production_view_model.dart';

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
  final productionRepository = ProductionRepository(
    apiClient: apiClient,
    storage: storage,
  );
  final employeeRepository = EmployeeRepository(apiClient: apiClient);
  final factoryOrderRepository = FactoryOrderRepository(apiClient: apiClient);

  authViewModel = AuthViewModel(authRepository: authRepository);
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

  authViewModel.initialize();

  authViewModel.addListener(() {
    if (!authViewModel.isAuthenticated) {
      productionViewModel.reset();
      employeesViewModel.reset();
      factoryOrdersViewModel.reset();
    }
  });

  final appRouter = AppRouter(
    authViewModel: authViewModel,
    productionViewModel: productionViewModel,
    employeesViewModel: employeesViewModel,
    factoryOrdersViewModel: factoryOrdersViewModel,
  );

  runApp(CrackersErpApp(appRouter: appRouter));
}

class CrackersErpApp extends StatelessWidget {
  const CrackersErpApp({required this.appRouter, super.key});

  final AppRouter appRouter;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Crackers ERP — Supervisor',
      debugShowCheckedModeBanner: false,
      theme: ErpTheme.buildLightTheme(),
      routerConfig: appRouter.router,
    );
  }
}
