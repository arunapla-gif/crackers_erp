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
      await tester.ensureVisible(find.text('+10').first);
      await tester.pumpAndSettle();
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

  testWidgets(
    'Supervisor can use Matrix on Android phone viewport with Focus Grid, quick qty, and zero rupees',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

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

      // Supervisor sees Matrix option and can switch to it
      expect(find.text('Matrix'), findsOneWidget);
      await tester.ensureVisible(find.text('Matrix'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Matrix'));
      await tester.pumpAndSettle();

      expect(find.text('WORKERS\n(PINNED)'), findsOneWidget);
      expect(find.text('Save Matrix'), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);

      // Focus first cell (Packing -> emp 12), use +10, Next -> emp 11 (+25), Next -> Col 2 emp 12 (+50)
      final cellFinder = find.byKey(
        const ValueKey('matrix_12_12cm Electric Sparklers (WIP)'),
      );
      await tester.ensureVisible(cellFinder);
      await tester.pumpAndSettle();
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();

      expect(find.text('+10'), findsOneWidget);
      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(12, '12cm Electric Sparklers (WIP)'), equals(10));

      await tester.tap(find.text('Next ↓'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+25'));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(11, '12cm Electric Sparklers (WIP)'), equals(25));

      await tester.tap(find.text('Next ↓'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('+50'));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(12, 'Ground Chakkar Big (WIP)'), equals(50));

      // Enter and exit Focus Grid mode cleanly
      await tester.ensureVisible(find.text('Focus Grid'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Focus Grid'));
      await tester.pumpAndSettle();
      expect(find.text('Exit Focus'), findsOneWidget);

      await tester.tap(find.text('Save Matrix'));
      await tester.pumpAndSettle();
      expect(api.productionsData.length, equals(2));
    },
  );

  testWidgets(
    'Matrix displays Tamil worker name by default, supports English search & toggle',
    (WidgetTester tester) async {
      final api = FakeApiClient();
      api.employeesData.add({
        'id': 77,
        'name': 'Muthu (முத்து)',
        'role': 'Packing',
        'paymentType': 'Contractual',
        'employmentType': 'Regular',
        'unit': 'Unit 1',
        'status': 'Active',
        'advanceBalance': '0.00',
        'salary': null,
      });

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

      // Switch to Matrix
      await tester.ensureVisible(find.text('Matrix'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Matrix'));
      await tester.pumpAndSettle();

      // By default in Matrix, language toggle shows [தமிழ்] selected and displays 'முத்து'
      expect(find.text('தமிழ்'), findsOneWidget);
      expect(find.text('Eng'), findsOneWidget);
      expect(find.text('Both'), findsOneWidget);
      expect(find.text('முத்து'), findsWidgets);

      // Search in English matches the worker
      await tester.enterText(
        find.widgetWithText(TextField, 'Filter worker name, role or unit...'),
        'muthu',
      );
      await tester.pumpAndSettle();
      expect(find.text('முத்து'), findsWidgets);

      // Search query not matching hides the worker
      await tester.enterText(
        find.widgetWithText(TextField, 'Filter worker name, role or unit...'),
        'unknown_worker_xyz',
      );
      await tester.pumpAndSettle();
      expect(find.text('முத்து'), findsNothing);

      // Clear search
      await tester.enterText(
        find.widgetWithText(TextField, 'Filter worker name, role or unit...'),
        '',
      );
      await tester.pumpAndSettle();

      // Toggle to English: shows 'Muthu'
      await tester.tap(find.text('Eng'));
      await tester.pumpAndSettle();
      expect(find.text('Muthu'), findsWidgets);

      // Toggle to Both: shows 'Muthu (முத்து)'
      await tester.tap(find.text('Both'));
      await tester.pumpAndSettle();
      expect(find.text('Muthu (முத்து)'), findsWidgets);
    },
  );

  testWidgets(
    'Daily Production Entry displays fixed Tape, Chemical, and Valayam Contract sections and filter chips',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = FakeApiClient();
      api.employeesData.addAll([
        {
          'id': 101,
          'name': 'Abi (அபி)',
          'role': 'Tape',
          'paymentType': 'Contractual',
          'employmentType': 'Regular',
          'unit': 'Unit 1',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
        {
          'id': 102,
          'name': 'Muniyasamy (முனியசாமி)',
          'role': 'Chemical',
          'paymentType': 'Contractual',
          'employmentType': 'Regular',
          'unit': 'Unit 1',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
        {
          'id': 103,
          'name': 'Vasanth (வசந்த்)',
          'role': 'Valayam Contract',
          'paymentType': 'Contractual',
          'employmentType': 'Regular',
          'unit': 'Unit 1',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
      ]);

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

      // Check fixed role chips with Tamil labels and counts
      expect(find.textContaining('Tape • டேப்'), findsOneWidget);
      expect(find.textContaining('Chemical • கெமிக்கல்'), findsOneWidget);
      expect(
        find.textContaining('Valayam Contract • வளையம் ஒப்பந்தம்'),
        findsOneWidget,
      );

      // In By Item mode, under WIP item, check fixed role section headers
      expect(find.text('TAPE'), findsWidgets);
      expect(find.text('• டேப்'), findsWidgets);
      expect(find.text('CHEMICAL'), findsWidgets);
      expect(find.text('• கெமிக்கல்'), findsWidgets);
      expect(find.text('VALAYAM CONTRACT'), findsWidgets);
      expect(find.text('• வளையம் ஒப்பந்தம்'), findsWidgets);

      // Check workers are displayed with Tamil names
      expect(find.text('அபி'), findsWidgets);
      expect(find.text('முனியசாமி'), findsWidgets);
      expect(find.text('வசந்த்'), findsWidgets);

      // Tap Chemical chip: only Chemical worker Muniyasamy is displayed
      final chemChip = find.textContaining('Chemical • கெமிக்கல்');
      await tester.ensureVisible(chemChip);
      await tester.pumpAndSettle();
      await tester.tap(chemChip);
      await tester.pumpAndSettle();

      expect(find.text('முனியசாமி'), findsWidgets);
      expect(find.text('அபி'), findsNothing);
      expect(find.text('வசந்த்'), findsNothing);

      // Reset to All Workers
      final allChip = find.textContaining('All Workers');
      await tester.ensureVisible(allChip);
      await tester.pumpAndSettle();
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      // Switch to By Worker mode
      final byWorkerSegment = find.text('By Worker');
      await tester.ensureVisible(byWorkerSegment);
      await tester.pumpAndSettle();
      await tester.tap(byWorkerSegment);
      await tester.pumpAndSettle();

      // Check By Worker role headers
      expect(find.text('TAPE'), findsWidgets);
      expect(find.text('CHEMICAL'), findsWidgets);
      expect(find.text('VALAYAM CONTRACT'), findsWidgets);

      // Switch to Matrix mode
      final matrixSegment = find.text('Matrix');
      await tester.ensureVisible(matrixSegment);
      await tester.pumpAndSettle();
      await tester.tap(matrixSegment);
      await tester.pumpAndSettle();

      // Check Matrix frozen column headers include Tamil mappings
      expect(find.textContaining('TAPE • டேப்'), findsOneWidget);
      expect(find.textContaining('CHEMICAL • கெமிக்கல்'), findsOneWidget);
      expect(
        find.textContaining('VALAYAM CONTRACT • வளையம் ஒப்பந்தம்'),
        findsOneWidget,
      );
    },
  );
}
