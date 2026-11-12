import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/repositories/auth_repository.dart';
import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/data/repositories/factory_order_repository.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/employees/view_models/employees_advances_view_model.dart';
import 'package:crackers_erp/ui/features/employees/views/employees_advances_screen.dart';
import 'package:crackers_erp/ui/features/factory_orders/view_models/factory_orders_view_model.dart';
import 'package:crackers_erp/ui/features/factory_orders/views/factory_orders_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  testWidgets(
    'EmployeesAdvancesScreen renders workers & advances without salary fields',
    (WidgetTester tester) async {
      final api = FakeApiClient();
      final storage = InMemoryLocalStorageService();
      final authVm = AuthViewModel(
        authRepository: AuthRepository(apiClient: api, storage: storage),
      );
      await authVm.login(username: 'supervisor1', pin: '1234');

      final empVm = EmployeesAdvancesViewModel(
        employeeRepository: EmployeeRepository(apiClient: api),
      );
      addTearDown(empVm.dispose);
      addTearDown(authVm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ErpTheme.buildLightTheme(),
          home: EmployeesAdvancesScreen(
            viewModel: empVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Mariappan K'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Selvi R'),
        250.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Selvi R'), findsOneWidget);
      expect(find.textContaining('Salary'), findsNothing);
      expect(find.textContaining('₹500'), findsWidgets);
    },
  );

  testWidgets(
    'FactoryOrdersScreen displays approved orders with cases/boxes and zero rupees',
    (WidgetTester tester) async {
      final api = FakeApiClient();
      final storage = InMemoryLocalStorageService();
      final authVm = AuthViewModel(
        authRepository: AuthRepository(apiClient: api, storage: storage),
      );
      await authVm.login(username: 'supervisor1', pin: '1234');

      final ordersVm = FactoryOrdersViewModel(
        orderRepository: FactoryOrderRepository(apiClient: api),
      );
      addTearDown(ordersVm.dispose);
      addTearDown(authVm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ErpTheme.buildLightTheme(),
          home: FactoryOrdersScreen(
            viewModel: ordersVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Sri Murugan Agencies'), findsOneWidget);
      expect(find.text('10 Cases'), findsOneWidget);
      expect(find.text('200 Boxes'), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);

      await tester.tap(find.text('Sri Murugan Agencies'));
      await tester.pumpAndSettle();
      expect(find.text('12cm Electric Box'), findsOneWidget);
    },
  );

  testWidgets(
    'Creating employee requires explicit Work Type & Category; only Admin converts Temp to Regular',
    (WidgetTester tester) async {
      final api = FakeApiClient()
        ..roleToLogin = 'SUPERVISOR'
        ..employeesData.add({
          'id': 30,
          'name': 'Season Worker Raj',
          'mobile': '9842100088',
          'role': 'Helper',
          'paymentType': 'Contractual',
          'employmentType': 'Temporary',
          'unit': 'Unit 1',
          'status': 'Active',
          'advanceBalance': '100.00',
          'salary': null,
        });
      final storage = InMemoryLocalStorageService();
      final authVm = AuthViewModel(
        authRepository: AuthRepository(apiClient: api, storage: storage),
      );
      await authVm.login(username: 'supervisor1', pin: '1234');

      final empVm = EmployeesAdvancesViewModel(
        employeeRepository: EmployeeRepository(apiClient: api),
      );
      addTearDown(empVm.dispose);
      addTearDown(authVm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ErpTheme.buildLightTheme(),
          home: EmployeesAdvancesScreen(
            viewModel: empVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Supervisor sees TEMP badge but NOT Make Regular button
      await tester.scrollUntilVisible(
        find.text('Season Worker Raj'),
        250.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('TEMP'), findsOneWidget);
      expect(find.text('Make Regular'), findsNothing);

      // Opening Add Worker has NO default selection for Work Type / Worker Category
      await tester.tap(find.text('Add Worker'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Worker Full Name *'),
        'New Seasonal Hand',
      );
      await tester.ensureVisible(find.text('Create Worker'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create Worker'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Select work type'));
      expect(find.text('Select work type'), findsOneWidget);
      await tester.ensureVisible(find.text('Select Regular or Temporary'));
      expect(find.text('Select Regular or Temporary'), findsOneWidget);

      await tester.ensureVisible(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Now login as ADMIN and verify Make Regular button works
      await authVm.logout();
      api.roleToLogin = 'ADMIN';
      await authVm.login(username: 'admin', pin: '1234');
      await empVm.loadAll();
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Season Worker Raj'),
        250.0,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Make Regular'), findsOneWidget);

      await tester.tap(find.text('Make Regular'));
      await tester.pumpAndSettle();
      expect(find.text('Convert to Regular Worker'), findsOneWidget);

      await tester.tap(find.text('Confirm Regular'));
      await tester.pumpAndSettle();

      final updated = empVm.employees.firstWhere((e) => e.id == 30);
      expect(updated.isRegular, isTrue);
      expect(find.text('Make Regular'), findsNothing);
    },
  );
}
