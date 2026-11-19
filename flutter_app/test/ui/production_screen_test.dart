import 'dart:io';
import 'dart:ui' as ui;
import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/repositories/auth_repository.dart';
import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/data/repositories/production_repository.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'package:crackers_erp/ui/features/production/views/daily_production_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

      // Matrix appears directly with zero rupee sign anywhere
      expect(find.text('Save Worksheet'), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);

      // Tap cell for worker 12 (Selvi)
      final cellFinder = find.byKey(
        const ValueKey('matrix_12_12cm Electric Sparklers (WIP)'),
      );
      await tester.ensureVisible(cellFinder);
      await tester.pumpAndSettle();
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();

      // Tap quick +10 stepper on the keypad
      await tester.tap(find.text('+10'));
      await tester.pumpAndSettle();

      // Close keypad via close button
      await tester.tap(find.byTooltip('Done / Close Keypad'));
      await tester.pumpAndSettle();

      expect(find.text('Save Whole Sheet'), findsOneWidget);

      await tester.tap(find.text('Save Whole Sheet'));
      await tester.pump();
      await tester.pumpAndSettle();

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

      // Supervisor sees Matrix directly on screen without extra filters
      expect(find.text('WORKERS\n(PINNED)'), findsOneWidget);
      expect(find.text('Save Worksheet'), findsOneWidget);
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

      await tester.tap(find.text('Save Worksheet'));
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

      // By default in Matrix, displays Tamil worker name 'முத்து'
      expect(find.text('முத்து'), findsWidgets);

      // Tap search icon in AppBar
      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pumpAndSettle();

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

      // Close search restores worker
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('முத்து'), findsWidgets);
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
      api.employeesData.clear();
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

      // Check fixed role chips with Tamil labels and counts in Matrix
      expect(find.textContaining('Tape • டேப்'), findsWidgets);
      expect(find.textContaining('Chemical • கெமிக்கல்'), findsWidgets);
      expect(
        find.textContaining('Valayam Contract • வளையம் ஒப்பந்தம்'),
        findsWidgets,
      );

      // Check workers are displayed with Tamil names
      expect(find.text('அபி'), findsWidgets);
      expect(find.text('முனியசாமி'), findsWidgets);
      expect(find.text('வசந்த்'), findsWidgets);

      // Tap Chemical chip: only Chemical worker Muniyasamy is displayed
      final chemChip = find.textContaining('Chemical • கெமிக்கல்').first;
      await tester.ensureVisible(chemChip);
      await tester.pumpAndSettle();
      await tester.tap(chemChip);
      await tester.pumpAndSettle();

      expect(find.text('முனியசாமி'), findsWidgets);
      expect(find.text('அபி'), findsNothing);
      expect(find.text('வசந்த்'), findsNothing);

      // Reset to All
      final allChip = find.textContaining('All (3)');
      await tester.ensureVisible(allChip);
      await tester.pumpAndSettle();
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      // Check Matrix department section headers
      expect(find.textContaining('TAPE • டேப்'), findsWidgets);
      expect(find.textContaining('CHEMICAL • கெமிக்கல்'), findsWidgets);
      expect(
        find.textContaining('VALAYAM CONTRACT • வளையம் ஒப்பந்தம்'),
        findsWidgets,
      );
    },
  );

  testWidgets(
    'Matrix display layout: Category tabs, section headers, worker columns, quick entry, and role filtering',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final api = FakeApiClient();
      api.employeesData.clear();
      api.employeesData.addAll([
        {
          'id': 101,
          'name': 'Abi (அபி)',
          'role': 'Tape',
          'paymentType': 'Contractual',
          'employmentType': 'Temporary',
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

      // 1. Verify Category Tabs in Matrix toolbar
      expect(find.widgetWithText(FilterChip, 'All (3)'), findsOneWidget);
      expect(find.textContaining('Tape • டேப் (1)'), findsWidgets);
      expect(find.textContaining('Chemical • கெமிக்கல் (1)'), findsWidgets);
      expect(
        find.textContaining('Valayam Contract • வளையம் ஒப்பந்தம் (1)'),
        findsWidgets,
      );

      // 2. Verify Pinned Headers
      expect(find.text('WORKERS\n(PINNED)'), findsOneWidget);
      expect(find.text('WORKER\nTOTAL'), findsOneWidget);

      // 3. Verify Category Section Headers
      expect(find.textContaining('TAPE • டேப் (1)'), findsWidgets);
      expect(find.textContaining('CHEMICAL • கெமிக்கல் (1)'), findsWidgets);
      expect(
        find.textContaining('VALAYAM CONTRACT • வளையம் ஒப்பந்தம் (1)'),
        findsWidgets,
      );

      // 4. Verify Workers in their respective category sections
      expect(find.text('அபி'), findsWidgets);
      expect(find.text('முனியசாமி'), findsWidgets);
      expect(find.text('வசந்த்'), findsWidgets);

      // 5. Test Category Filtering: Tap 'Chemical • கெமிக்கல் (1)' tab
      final chemTab =
          find.widgetWithText(FilterChip, 'Chemical • கெமிக்கல் (1)').first;
      await tester.tap(chemTab);
      await tester.pumpAndSettle();

      // Muniyasamy should be visible, others hidden
      expect(find.text('முனியசாமி'), findsWidgets);
      expect(find.text('அபி'), findsNothing);
      expect(find.text('வசந்த்'), findsNothing);

      // 6. Tap 'Valayam Contract' tab
      final valayamTab = find
          .widgetWithText(
            FilterChip,
            'Valayam Contract • வளையம் ஒப்பந்தம் (1)',
          )
          .first;
      await tester.tap(valayamTab);
      await tester.pumpAndSettle();

      // Vasanth should be visible, others hidden
      expect(find.text('வசந்த்'), findsWidgets);
      expect(find.text('முனியசாமி'), findsNothing);
      expect(find.text('அபி'), findsNothing);

      // 7. Reset back to All
      final allTab = find.widgetWithText(FilterChip, 'All (3)').first;
      await tester.tap(allTab);
      await tester.pumpAndSettle();

      expect(find.text('அபி'), findsWidgets);
      expect(find.text('முனியசாமி'), findsWidgets);
      expect(find.text('வசந்த்'), findsWidgets);
    },
  );

  testWidgets(
    'Verify live 17-worker factory dataset in Production Matrix with category tabs and screenshot capture',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final api = FakeApiClient();
      api.employeesData.clear();
      api.employeesData.addAll([
        {'id': 3, 'name': 'Manimegalai (மணிமேகலை)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 4, 'name': 'Jothi (ஜோதி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 6, 'name': 'Bavitha (பவித்தா)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 7, 'name': 'Seetha (சீதா)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 8, 'name': 'Kaviya (காவியா)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 15, 'name': 'Abi (அபி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 16, 'name': 'Rasammal (ராசம்மாள்)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 17, 'name': 'Kanakammal (கணகம்மாள்)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 18, 'name': 'Shree (ஸ்ரீ)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 19, 'name': 'Pandiyammal (பாண்டியம்மாள்)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 20, 'name': 'Iniya (இனியா)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 21, 'name': 'Annalakshmi (அண்ணலட்சுமி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 22, 'name': 'Rasalakshmi (ராசலட்சுமி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 23, 'name': 'Sadaiyandi (சடையாண்டி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 24, 'name': 'Muniyasamy (முனியசாமி)', 'role': 'Chemical', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 25, 'name': 'Vasanth (வசந்த்)', 'role': 'Valayam Contract', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 26, 'name': 'Karthi Appa (கார்த்தி அப்பா)', 'role': 'Box Packing', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
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
      final repaintKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          theme: ErpTheme.buildLightTheme(),
          home: RepaintBoundary(
            key: repaintKey,
            child: DailyProductionScreen(
              viewModel: prodVm,
              authViewModel: authVm,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // 1. Verify Category Tabs in Matrix toolbar
      expect(find.widgetWithText(FilterChip, 'All (17)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Tape • டேப் (14)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Chemical • கெமிக்கல் (1)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Valayam Contract • வளையம் ஒப்பந்தம் (1)'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'Box Packing • பேக்கிங் (1)'), findsOneWidget);

      // 2. Verify Category Section Headers in Matrix Body
      expect(find.textContaining('TAPE • டேப் (14)'), findsWidgets);
      expect(find.textContaining('CHEMICAL • கெமிக்கல் (1)'), findsWidgets);
      expect(find.textContaining('VALAYAM CONTRACT • வளையம் ஒப்பந்தம் (1)'), findsWidgets);
      expect(find.textContaining('BOX PACKING • பேக்கிங் (1)'), findsWidgets);

      // 3. Verify Right Track Subtotal Banners
      expect(find.textContaining('TAPE • டேப் (14 workers)'), findsWidgets);
      expect(find.textContaining('CHEMICAL • கெமிக்கல் (1 workers)'), findsWidgets);
      expect(find.textContaining('VALAYAM CONTRACT • வளையம் ஒப்பந்தம் (1 workers)'), findsWidgets);
      expect(find.textContaining('BOX PACKING • பேக்கிங் (1 workers)'), findsWidgets);

      // 4. Test Category Filter to Chemical (Muniyasamy)
      await tester.tap(find.widgetWithText(FilterChip, 'Chemical • கெமிக்கல் (1)'));
      await tester.pumpAndSettle();

      expect(find.text('முனியசாமி'), findsWidgets);
      expect(find.text('மணிமேகலை'), findsNothing);
      expect(find.text('வசந்த்'), findsNothing);
      expect(find.text('கார்த்தி அப்பா'), findsNothing);

      // 5. Test Category Filter to Valayam Contract (Vasanth)
      final valayamChip = find.widgetWithText(
        FilterChip,
        'Valayam Contract • வளையம் ஒப்பந்தம் (1)',
      );
      await tester.ensureVisible(valayamChip);
      await tester.pumpAndSettle();
      await tester.tap(valayamChip);
      await tester.pumpAndSettle();

      expect(find.text('வசந்த்'), findsWidgets);
      expect(find.text('முனியசாமி'), findsNothing);
      expect(find.text('மணிமேகலை'), findsNothing);
      expect(find.text('கார்த்தி அப்பா'), findsNothing);

      // 6. Test Category Filter to Box Packing (Karthi Appa)
      final boxPackingChip =
          find.widgetWithText(FilterChip, 'Box Packing • பேக்கிங் (1)');
      await tester.ensureVisible(boxPackingChip);
      await tester.pumpAndSettle();
      await tester.tap(boxPackingChip);
      await tester.pumpAndSettle();

      expect(find.text('கார்த்தி அப்பா'), findsWidgets);
      expect(find.text('முனியசாமி'), findsNothing);
      expect(find.text('வசந்த்'), findsNothing);
      expect(find.text('மணிமேகலை'), findsNothing);

      // 7. Reset back to All
      final allChip = find.widgetWithText(FilterChip, 'All (17)');
      await tester.ensureVisible(allChip);
      await tester.pumpAndSettle();
      await tester.tap(allChip);
      await tester.pumpAndSettle();

      // 8. Capture rendered frame to PNG for visual inspection
      await tester.runAsync(() async {
        final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            File('/Users/arun_ap/.gemini/antigravity/brain/f7071202-34e1-4867-acdb-69999a14b709/matrix_display.png')
                .writeAsBytesSync(byteData.buffer.asUint8List());
          }
        }
      });
    },
  );

  testWidgets(
    'Matrix defaults on screen and allows adding product column in 1-click across all workers',
    (tester) async {
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

      // 1. Verify screen opens directly in Matrix mode by default
      expect(prodVm.entryMode, equals(ProductionEntryMode.matrix));
      expect(find.text('WORKERS\n(PINNED)'), findsOneWidget);

      // 2. Verify React-style Quick Add Column button exists
      expect(
        find.byKey(const ValueKey('matrix-add-column-button')),
        findsOneWidget,
      );
      expect(find.text('+ Add Column'), findsOneWidget);

      // 3. Clear existing columns to test empty state and adding column
      prodVm.clearActiveItems();
      await tester.pumpAndSettle();
      expect(find.text('No WIP Product Columns Added'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('matrix-empty-add-column-button')),
        findsOneWidget,
      );

      // 4. Add product column via vm and verify it reappears
      prodVm.addActiveItem('12cm Electric Sparklers (WIP)');
      await tester.pumpAndSettle();
      expect(find.text('WORKERS\n(PINNED)'), findsOneWidget);
      expect(find.text('12cm Electric Sparklers (WIP)'), findsWidgets);
    },
  );

  testWidgets(
    'Docked In-App Keypad enables rapid numeric entry with 1-9, 00, backspace, and Next without native keyboard',
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
      await tester.pumpAndSettle();

      // Tap cell for emp 12 (Packing)
      final cellFinder = find.byKey(
        const ValueKey('matrix_12_12cm Electric Sparklers (WIP)'),
      );
      await tester.ensureVisible(cellFinder);
      await tester.pumpAndSettle();
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();

      final keypadFinder = find.byKey(const ValueKey('matrix-docked-keypad'));
      expect(keypadFinder, findsOneWidget);

      // In-app keypad is open: test numeric keys 1, 5, 0 -> 150
      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('1')));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(12, '12cm Electric Sparklers (WIP)'), equals(1));

      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('5')));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(12, '12cm Electric Sparklers (WIP)'), equals(15));

      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('0')));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(12, '12cm Electric Sparklers (WIP)'), equals(150));

      // Test double zero '00' -> 15000
      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('00')));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(12, '12cm Electric Sparklers (WIP)'), equals(15000));

      // Test backspace -> 1500
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(12, '12cm Electric Sparklers (WIP)'), equals(1500));

      // Test quick +50 -> 1550
      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('+50')));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(12, '12cm Electric Sparklers (WIP)'), equals(1550));

      // Next ↓ moves to next worker (emp 11)
      await tester.tap(find.byKey(const ValueKey('matrix-next-worker-button')));
      await tester.pumpAndSettle();

      // Type 2, 5 -> 25 for emp 11
      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('2')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('5')));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(11, '12cm Electric Sparklers (WIP)'), equals(25));

      // Close keypad via close button
      await tester.tap(find.byTooltip('Done / Close Keypad'));
      await tester.pumpAndSettle();

      // Keypad is closed and summary bar reappears with Save Whole Sheet
      expect(keypadFinder, findsNothing);
      expect(find.text('Save Whole Sheet'), findsOneWidget);
    },
  );
}
