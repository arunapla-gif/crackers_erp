import 'dart:io';
import 'dart:ui' as ui;
import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/repositories/auth_repository.dart';
import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/data/repositories/production_repository.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'package:crackers_erp/ui/features/production/views/daily_production_matrix_page.dart';
import 'package:crackers_erp/ui/features/production/views/daily_production_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  testWidgets(
    'Daily Production 2-Screen Flow: Opens Hub, reviews summary, enters Matrix Workspace, and saves bulk log with zero rupees',
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

      // Screen 1: Hub appears with summary and Open Matrix Entry button
      expect(find.text('Daily Production Hub'), findsOneWidget);
      expect(find.byKey(const ValueKey('open-matrix-entry-button')), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);

      // Tap Open Matrix Entry button -> navigates to Screen 2 (Fullscreen Matrix)
      await tester.tap(find.byKey(const ValueKey('open-matrix-entry-button')));
      await tester.pump();
      await tester.pumpAndSettle();

      // Screen 2: Dedicated Fullscreen Matrix appears
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

      expect(find.text('Save Worksheet'), findsOneWidget);

      await tester.tap(find.text('Save Worksheet'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(api.productionsData.length, equals(1));
    },
  );

  testWidgets(
    'Supervisor can use Fullscreen Matrix on Android phone viewport with quick qty, Next auto-jump, and zero rupees',
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
          home: DailyProductionMatrixPage(
            viewModel: prodVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Supervisor sees Dedicated Matrix directly on screen without extra filters
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

      // Close keypad via close button
      await tester.tap(find.byTooltip('Done / Close Keypad'));
      await tester.pumpAndSettle();

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
          home: DailyProductionMatrixPage(
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
        find.widgetWithText(TextField, 'Filter worker name or role...'),
        'muthu',
      );
      await tester.pumpAndSettle();
      expect(find.text('முத்து'), findsWidgets);

      // Search query not matching hides the worker
      await tester.enterText(
        find.widgetWithText(TextField, 'Filter worker name or role...'),
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
          home: DailyProductionMatrixPage(
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
          home: DailyProductionMatrixPage(
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
      await tester.ensureVisible(valayamTab);
      await tester.tap(valayamTab);
      await tester.pumpAndSettle();

      // Vasanth should be visible, others hidden
      expect(find.text('வசந்த்'), findsWidgets);
      expect(find.text('முனியசாமி'), findsNothing);
      expect(find.text('அபி'), findsNothing);

      // 7. Reset back to All
      final allTab = find.widgetWithText(FilterChip, 'All (3)').first;
      await tester.ensureVisible(allTab);
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
        {'id': 9, 'name': 'Abirami (அபிராமி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 10, 'name': 'Sowmiya (சௌமியா)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 13, 'name': 'Santhi (சாந்தி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 14, 'name': 'Karthik Raja (கார்த்திக் ராஜா)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 15, 'name': 'Subramani (சுப்பிரமணி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 16, 'name': 'Muthulakshmi (முத்துலட்சுமி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 17, 'name': 'Vijaya (விஜயா)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 18, 'name': 'Muthumari (முத்துமாரி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 19, 'name': 'Ramalakshmi (ராமலட்சுமி)', 'role': 'Tape', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 5, 'name': 'Muniyasamy (முனியசாமி)', 'role': 'Chemical', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 20, 'name': 'Vasanth (வசந்த்)', 'role': 'Valayam Contract', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
        {'id': 22, 'name': 'Karthi Appa (கார்த்தி அப்பா)', 'role': 'Box Packing', 'paymentType': 'Contractual', 'employmentType': 'Regular', 'status': 'Active', 'advanceBalance': '0.00'},
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
            child: DailyProductionMatrixPage(
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

      // 3. Test Category Filter to Chemical (Muniyasamy)
      await tester.tap(find.widgetWithText(FilterChip, 'Chemical • கெமிக்கல் (1)'));
      await tester.pumpAndSettle();

      expect(find.text('முனியசாமி'), findsWidgets);
      expect(find.text('மணிமேகலை'), findsNothing);
      expect(find.text('வசந்த்'), findsNothing);
      expect(find.text('கார்த்தி அப்பா'), findsNothing);

      // 4. Test Category Filter to Valayam Contract (Vasanth)
      final valayamChip = find.widgetWithText(
        FilterChip,
        'Valayam Contract • வளையம் ஒப்பந்தம் (1)',
      );
      await tester.ensureVisible(valayamChip);
      await tester.tap(valayamChip);
      await tester.pumpAndSettle();

      expect(find.text('வசந்த்'), findsWidgets);
      expect(find.text('முனியசாமி'), findsNothing);

      // 5. Reset to All
      final allChip = find.widgetWithText(FilterChip, 'All (17)');
      await tester.ensureVisible(allChip);
      await tester.tap(allChip);
      await tester.pumpAndSettle();
      expect(find.text('மணிமேகலை'), findsWidgets);

      // 6. Capture clean screenshot of the matrix
      await tester.runAsync(() async {
        final boundary =
            repaintKey.currentContext?.findRenderObject()
                as RenderRepaintBoundary?;
        if (boundary != null) {
          final image = await boundary.toImage(pixelRatio: 2.0);
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
    'Daily Production Hub displays WIP products and launches dedicated fullscreen Matrix Workspace',
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

      // 1. Verify Screen 1 is the Hub
      expect(find.text('Daily Production Hub'), findsOneWidget);
      expect(find.textContaining('WIP Products for Today'), findsOneWidget);
      expect(find.byKey(const ValueKey('open-matrix-entry-button')), findsOneWidget);

      // 2. Pick products button and 1-tap prev/next day arrows exist on Hub
      expect(find.byKey(const ValueKey('hub-add-wip-button')), findsOneWidget);
      final prevDayBtn = find.byKey(const ValueKey('hub-prev-day-button'));
      final nextDayBtn = find.byKey(const ValueKey('hub-next-day-button'));
      expect(prevDayBtn, findsOneWidget);
      expect(nextDayBtn, findsOneWidget);

      final initialIso = prodVm.selectedIsoDate;
      await tester.tap(prevDayBtn);
      await tester.pumpAndSettle();
      expect(prodVm.selectedIsoDate, isNot(equals(initialIso)));

      await tester.tap(nextDayBtn);
      await tester.pumpAndSettle();
      expect(prodVm.selectedIsoDate, equals(initialIso));

      // 3. Open via a specific department, return to Hub, then tap main CTA -> resets cleanly to All
      prodVm.setRoleFilter('Packing');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open-matrix-entry-button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(prodVm.selectedRoleFilter, equals('All'));
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
          home: DailyProductionMatrixPage(
            viewModel: prodVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
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

      // Prev ↑ jumps back up to emp 12 and lets us adjust its value
      await tester.tap(find.byKey(const ValueKey('matrix-prev-worker-button')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('+10')));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(12, '12cm Electric Sparklers (WIP)'), equals(1560));

      // Close keypad via close button
      await tester.tap(find.byTooltip('Done / Close Keypad'));
      await tester.pumpAndSettle();

      // Keypad is closed and summary bar reappears with Save Worksheet
      expect(keypadFinder, findsNothing);
      expect(find.text('Save Worksheet'), findsOneWidget);
    },
  );

  testWidgets(
    'DailyProductionMatrixPage operates smoothly in Landscape mode with side-by-side keypad and zero rupees',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(844, 390);
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
          home: DailyProductionMatrixPage(
            viewModel: prodVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Zero rupees
      expect(find.textContaining('₹'), findsNothing);

      // Tap cell for worker 12 (Selvi)
      final cellFinder = find.byKey(
        const ValueKey('matrix_12_12cm Electric Sparklers (WIP)'),
      );
      await tester.ensureVisible(cellFinder);
      await tester.tap(cellFinder);
      await tester.pumpAndSettle();

      // Keypad is docked side-by-side on the right
      final keypadFinder = find.byKey(const ValueKey('matrix-docked-keypad'));
      expect(keypadFinder, findsOneWidget);

      // Verify side-by-side layout: left table is still visible!
      expect(cellFinder, findsOneWidget);

      // Tap quick stepper +50 on the keypad
      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('+50')));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(12, '12cm Electric Sparklers (WIP)'), equals(50));

      // Tap 'Next ↓' on the keypad
      await tester.tap(find.byKey(const ValueKey('matrix-next-worker-button')));
      await tester.pumpAndSettle();

      // Type 7, 5 on keypad for emp 11
      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('7')));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(of: keypadFinder, matching: find.text('5')));
      await tester.pumpAndSettle();
      expect(prodVm.getQuantity(11, '12cm Electric Sparklers (WIP)'), equals(75));

      // Close keypad via close button
      await tester.tap(find.byTooltip('Done / Close Keypad'));
      await tester.pumpAndSettle();
      expect(keypadFinder, findsNothing);

      // Bottom bar is visible with Save Worksheet
      expect(find.text('Save Worksheet'), findsOneWidget);
      await tester.tap(find.text('Save Worksheet'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(api.productionsData.length, equals(2));
    },
  );

  testWidgets(
    'Sticky product column headers stay pinned at top when vertically scrolling through 14+ workers on phone viewport',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = FakeApiClient();
      api.employeesData.clear();
      for (var i = 1; i <= 16; i++) {
        api.employeesData.add({
          'id': 200 + i,
          'name': 'Worker $i (தொழிலாளர் $i)',
          'role': 'Tape',
          'paymentType': 'Contractual',
          'employmentType': 'Regular',
          'status': 'Active',
          'advanceBalance': '0.00',
        });
      }

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
          home: DailyProductionMatrixPage(
            viewModel: prodVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Capture initial header Y position
      final headerFinder = find.text('WORKERS\n(PINNED)');
      expect(headerFinder, findsOneWidget);
      final initialTop = tester.getTopLeft(headerFinder).dy;

      // Scroll down to bring the last worker into view
      final lastWorkerFinder = find.text('தொழிலாளர் 16');
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
      await tester.pumpAndSettle();

      expect(lastWorkerFinder, findsOneWidget);
      // Sticky header must remain pinned at the top of the scroll viewport
      expect(headerFinder, findsOneWidget);
      final afterScrollTop = tester.getTopLeft(headerFinder).dy;
      expect(afterScrollTop, lessThanOrEqualTo(initialTop));
      expect(afterScrollTop, greaterThanOrEqualTo(75.0));
    },
  );

  testWidgets(
    'Quick + WIP button inside Screen 2 opens searchable picker and adds a new product column on the spot',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = FakeApiClient();
      api.productsData.add({
        'id': 99,
        'name': '10 KVR 48 (WIP)',
        'code': 'WIP-99',
        'productType': 'WIP',
        'group': 'Sparklers',
        'unit': 'Pcs',
        'baseRate': 0,
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
          home: DailyProductionMatrixPage(
            viewModel: prodVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Ensure 10 KVR 48 (WIP) is not active yet before testing quick add
      prodVm.removeActiveItem('10 KVR 48 (WIP)');
      await tester.pumpAndSettle();
      expect(prodVm.activeItemNames, isNot(contains('10 KVR 48 (WIP)')));

      // Tap pinned + WIP button inside Screen 2
      final quickAddBtn = find.byKey(
        const ValueKey('matrix-quick-add-wip-button'),
      );
      expect(quickAddBtn, findsOneWidget);
      await tester.tap(quickAddBtn);
      await tester.pumpAndSettle();

      expect(find.text('Add / Select WIP Columns'), findsOneWidget);
      expect(find.text('10 KVR 48 (WIP)'), findsOneWidget);

      // Select the new product and close sheet
      await tester.tap(find.text('10 KVR 48 (WIP)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      // New product is now active in the matrix
      expect(prodVm.activeItemNames, contains('10 KVR 48 (WIP)'));
    },
  );

  testWidgets(
    'Pending Only filter chip hides already-logged workers and shows remaining unfilled workers',
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
          home: DailyProductionMatrixPage(
            viewModel: prodVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Log pieces for worker 12 (Selvi), leaving worker 11 (Rajan) unfilled
      prodVm.setQuantity(12, '12cm Electric Sparklers (WIP)', 40);
      await tester.pumpAndSettle();

      // Pending chip shows 1 pending worker
      final pendingChip = find.byKey(const ValueKey('matrix-pending-only-chip'));
      expect(pendingChip, findsOneWidget);
      expect(find.text('Pending (1)'), findsOneWidget);

      await tester.tap(pendingChip);
      await tester.pumpAndSettle();

      // Worker 12 cell is hidden, Worker 11 cell remains visible
      expect(
        find.byKey(const ValueKey('matrix_12_12cm Electric Sparklers (WIP)')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('matrix_11_12cm Electric Sparklers (WIP)')),
        findsOneWidget,
      );

      // Log worker 11 as well -> shows 'All Workers Logged!'
      prodVm.setQuantity(11, '12cm Electric Sparklers (WIP)', 20);
      await tester.pumpAndSettle();
      expect(find.text('All Workers Logged!'), findsOneWidget);

      // Tap 'Show All Workers' restores both workers
      await tester.tap(find.text('Show All Workers'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('matrix_12_12cm Electric Sparklers (WIP)')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Hub prompts confirmation before removing a WIP product chip that already has entered quantities',
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

      const item = '12cm Electric Sparklers (WIP)';
      prodVm.setQuantity(12, item, 75);
      await tester.pumpAndSettle();

      final removeBtn = find.byKey(const ValueKey('hub-remove-wip-$item'));
      await tester.ensureVisible(removeBtn);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog appears instead of immediate deletion
      expect(find.text('Remove WIP Product?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(prodVm.activeItemNames, contains(item));
      expect(prodVm.getQuantity(12, item), equals(75));

      // Confirming removes the chip and clears the draft quantity
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove & Clear'));
      await tester.pumpAndSettle();
      expect(prodVm.activeItemNames, isNot(contains(item)));
      expect(prodVm.getQuantity(12, item), equals(0));
    },
  );

  testWidgets(
    'Hub unsaved draft banner provides direct Save Now button to sync without re-entering matrix',
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

      // Draft banner hidden when clean
      expect(find.byKey(const ValueKey('hub-save-draft-button')), findsNothing);

      // Enter draft pieces -> banner appears with Save Now
      prodVm.setQuantity(12, '12cm Electric Sparklers (WIP)', 60);
      await tester.pumpAndSettle();

      final saveNowBtn = find.byKey(const ValueKey('hub-save-draft-button'));
      expect(saveNowBtn, findsOneWidget);
      expect(find.text('Unsaved Production Draft'), findsOneWidget);

      await tester.tap(saveNowBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Synced directly from Hub and draft banner disappears
      expect(api.productionsData.length, equals(1));
      expect(prodVm.hasUnsavedChanges, isFalse);
      expect(find.byKey(const ValueKey('hub-save-draft-button')), findsNothing);

      // Hub CTA switches to exclusive Edit Worksheet button when saved entries exist
      expect(find.text('Edit Worksheet (1 Saved)'), findsOneWidget);

      // Open Saved Logs (History) and tap the exclusive Edit button -> jumps straight into Matrix
      await tester.tap(find.byTooltip('Saved Logs'));
      await tester.pumpAndSettle();

      final historyEditBtn = find.byKey(
        ValueKey('history-edit-record-${prodVm.recentHistory.first.id}'),
      );
      expect(historyEditBtn, findsOneWidget);
      await tester.tap(historyEditBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Directly inside Screen 2 Matrix ready to edit
      expect(find.text('WORKERS\n(PINNED)'), findsOneWidget);
      expect(find.text('Save Worksheet'), findsOneWidget);
    },
  );

  testWidgets(
    'Supervisor can quick-add a Temporary worker directly from Matrix with zero-rupee secrecy',
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
          home: DailyProductionMatrixPage(
            viewModel: prodVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap pinned + Temp pill inside Matrix
      final quickTempBtn = find.byKey(
        const ValueKey('matrix-quick-add-temp-worker-button'),
      );
      expect(quickTempBtn, findsOneWidget);
      await tester.tap(quickTempBtn);
      await tester.pumpAndSettle();

      // Zero-rupee secrecy inside the quick-add sheet
      expect(find.text('Quick Add Temporary Worker'), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);
      expect(find.textContaining('Salary'), findsNothing);

      // Enter worker name and pick Packing role preset
      await tester.enterText(
        find.byKey(const ValueKey('quick-temp-name-field')),
        'Karthik',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Packing'));
      await tester.pumpAndSettle();

      // Save
      final saveBtn = find.byKey(const ValueKey('quick-temp-save-button'));
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify payload sent to backend
      expect(api.lastSavedEmployeePayload, isNotNull);
      expect(api.lastSavedEmployeePayload!['employmentType'], 'Temporary');
      expect(api.lastSavedEmployeePayload!['role'], 'Packing');
      expect(api.lastSavedEmployeePayload!.containsKey('salary'), isFalse);

      // Worker immediately appears in the Matrix with TEMP badge
      expect(
        prodVm.employees.any(
          (e) => e.englishName == 'Karthik' && e.isTemporary,
        ),
        isTrue,
      );
      expect(find.textContaining('TEMP'), findsWidgets);
    },
  );

  testWidgets(
    'On-Demand Temp Roster hides absent temp workers by default and lets supervisor check in only who arrived today',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = FakeApiClient();
      api.employeesData.addAll([
        {
          'id': 301,
          'name': 'TempRavi (டெம்ப் ரவி)',
          'role': 'Tape',
          'paymentType': 'Contractual',
          'employmentType': 'Temporary',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
        {
          'id': 302,
          'name': 'TempSuresh (டெம்ப் சுரேஷ்)',
          'role': 'Tape',
          'paymentType': 'Contractual',
          'employmentType': 'Temporary',
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
          home: DailyProductionMatrixPage(
            viewModel: prodVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Absent temp workers are hidden from today's Matrix by default
      expect(prodVm.temporaryPoolCount, equals(2));
      expect(prodVm.selectedTempCountForDate, equals(0));
      expect(prodVm.activeWorkers.any((e) => e.id == 301), isFalse);
      expect(prodVm.activeWorkers.any((e) => e.id == 302), isFalse);
      expect(find.text('Temp (0/2)'), findsOneWidget);

      // Open On-Demand Temp Roster sheet
      await tester.tap(
        find.byKey(const ValueKey('matrix-quick-add-temp-worker-button')),
      );
      await tester.pumpAndSettle();

      expect(find.text("Today's Temp Roster"), findsOneWidget);
      expect(find.byKey(const ValueKey('temp-roster-item-301')), findsOneWidget);
      expect(find.byKey(const ValueKey('temp-roster-item-302')), findsOneWidget);

      // Tick only TempRavi (301) and apply
      await tester.tap(find.byKey(const ValueKey('temp-roster-item-301')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('temp-roster-apply-button')));
      await tester.pumpAndSettle();

      // Only TempRavi (301) is now visible in today's Matrix; TempSuresh (302) remains hidden
      expect(prodVm.selectedTempCountForDate, equals(1));
      expect(prodVm.activeWorkers.any((e) => e.id == 301), isTrue);
      expect(prodVm.activeWorkers.any((e) => e.id == 302), isFalse);
      expect(find.text('Temp (1/2)'), findsOneWidget);
    },
  );

  testWidgets(
    'Tapping Next in Matrix scrolls viewport vertically to follow the focused worker row',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = FakeApiClient();
      api.employeesData.clear();
      for (var i = 1; i <= 16; i++) {
        final padded = i.toString().padLeft(2, '0');
        api.employeesData.add({
          'id': 400 + i,
          'name': 'Worker $padded (தொழிலாளர் $padded)',
          'role': 'Tape',
          'paymentType': 'Contractual',
          'employmentType': 'Regular',
          'status': 'Active',
          'advanceBalance': '0.00',
        });
      }

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
          home: DailyProductionMatrixPage(
            viewModel: prodVm,
            authViewModel: authVm,
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap first worker's cell to focus & open docked keypad
      final firstCell = find.byKey(
        const ValueKey('matrix_401_12cm Electric Sparklers (WIP)'),
      );
      expect(firstCell, findsOneWidget);
      await tester.tap(firstCell);
      await tester.pumpAndSettle();

      final customScrollView = tester.widget<CustomScrollView>(
        find.byType(CustomScrollView),
      );
      final initialOffset = customScrollView.controller!.offset;

      // Tap Next 10 times to advance down to Worker 11
      final nextBtn = find.byKey(const ValueKey('matrix-next-worker-button'));
      for (var step = 0; step < 10; step++) {
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      }

      // Vertical scroll offset must have advanced significantly so Worker 11 stays visible
      final scrolledOffset = customScrollView.controller!.offset;
      expect(scrolledOffset, greaterThan(initialOffset + 100));

      // Worker 11's cell is visibly inside the viewport above the docked keypad
      final targetCell = find.byKey(
        const ValueKey('matrix_411_12cm Electric Sparklers (WIP)'),
      );
      final cellRect = tester.getRect(targetCell);
      final keypadRect = tester.getRect(
        find.byKey(const ValueKey('matrix-docked-keypad')),
      );
      expect(cellRect.bottom, lessThanOrEqualTo(keypadRect.top + 4));
      expect(cellRect.top, greaterThan(0));
    },
  );
}
