import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/repositories/auth_repository.dart';
import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/data/repositories/production_repository.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'package:crackers_erp/ui/features/production/views/daily_production_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  testWidgets(
    'DailyProductionScreen updates quantities, saves bulk log, and shows zero rupees',
    (WidgetTester tester) async {
      final api = FakeApiClient();
      final storage = InMemoryLocalStorageService();
      final authVm = AuthViewModel(
        authRepository: AuthRepository(apiClient: api, storage: storage),
      );
      await authVm.login(username: 'supervisor1', pin: '1234');

      final prodVm = DailyProductionViewModel(
        productionRepository: ProductionRepository(
          apiClient: api,
          storage: storage,
        ),
        employeeRepository: EmployeeRepository(apiClient: api),
      );
      addTearDown(prodVm.dispose);
      addTearDown(authVm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ErpTheme.buildLightTheme(),
          home: DailyProductionScreen(
            viewModel: prodVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // WIP item and contractual workers appear; no rupee sign appears anywhere
      expect(find.text('12cm Electric Sparklers (WIP)'), findsOneWidget);
      expect(find.text('Mariappan K'), findsOneWidget);
      expect(find.text('Selvi R'), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);

      // Tap quick +10 stepper on the first worker row
      await tester.tap(find.text('+10').first);
      await tester.pump();

      expect(find.text('Unsaved Local Changes'), findsOneWidget);
      expect(find.text('Save Log'), findsOneWidget);

      await tester.tap(find.text('Save Log'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Unsaved Local Changes'), findsNothing);
      expect(api.productionsData.length, equals(1));
    },
  );
}
