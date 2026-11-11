import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:crackers_erp/ui/core/adaptive_shell.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/auth/views/login_screen.dart';
import 'package:crackers_erp/ui/features/employees/view_models/employees_advances_view_model.dart';
import 'package:crackers_erp/ui/features/employees/views/employees_advances_screen.dart';
import 'package:crackers_erp/ui/features/factory_orders/view_models/factory_orders_view_model.dart';
import 'package:crackers_erp/ui/features/factory_orders/views/factory_orders_screen.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'package:crackers_erp/ui/features/production/views/daily_production_screen.dart';

class AppRouter {
  AppRouter({
    required this.authViewModel,
    required this.productionViewModel,
    required this.employeesViewModel,
    required this.factoryOrdersViewModel,
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
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return AdaptiveShell(
              navigationShell: navigationShell,
              authViewModel: authViewModel,
              productionViewModel: productionViewModel,
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/production',
                  builder: (context, state) => DailyProductionScreen(
                    viewModel: productionViewModel,
                    authViewModel: authViewModel,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/employees',
                  builder: (context, state) => EmployeesAdvancesScreen(
                    viewModel: employeesViewModel,
                    authViewModel: authViewModel,
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/factory-orders',
                  builder: (context, state) => FactoryOrdersScreen(
                    viewModel: factoryOrdersViewModel,
                    authViewModel: authViewModel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  final AuthViewModel authViewModel;
  final DailyProductionViewModel productionViewModel;
  final EmployeesAdvancesViewModel employeesViewModel;
  final FactoryOrdersViewModel factoryOrdersViewModel;
  late final GoRouter router;

  String _defaultHomePath() {
    final user = authViewModel.currentUser;
    if (user == null) return '/login';
    if (user.canViewProduction) return '/production';
    if (user.canViewEmployees) return '/employees';
    return '/factory-orders';
  }

  String? _handleRedirect(BuildContext context, GoRouterState state) {
    final loggedIn = authViewModel.isAuthenticated;
    final goingToLogin = state.matchedLocation == '/login';

    if (!loggedIn && !goingToLogin) {
      return '/login';
    }
    if (loggedIn && (goingToLogin || state.matchedLocation == '/')) {
      return _defaultHomePath();
    }
    return null;
  }
}
