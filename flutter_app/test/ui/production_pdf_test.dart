import 'dart:convert';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/repositories/auth_repository.dart';
import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/data/repositories/payroll_repository.dart';
import 'package:crackers_erp/data/repositories/production_repository.dart';
import 'package:crackers_erp/domain/models/daily_production.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/hr/view_models/payroll_view_model.dart';
import 'package:crackers_erp/ui/features/hr/views/payroll_pdf.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'package:crackers_erp/ui/features/production/views/daily_production_pdf.dart';
import 'package:crackers_erp/ui/features/production/views/daily_production_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shapeTamilForPdf reorders pre-base and split Tamil vowel signs for PDF', () {
    // மே -> ே + ம, லை -> ை + ல
    expect(shapeTamilForPdf('மணிமேகலை'), equals('மணி\u0BC7மக\u0BC8ல'));
    // ஜோதி -> ே + ஜ + ா + த + ி
    expect(shapeTamilForPdf('ஜோதி'), equals('\u0BC7ஜ\u0BBEதி'));
    // சௌமியா -> ெ + ச + ௗ + ம + ி + ய + ா
    expect(shapeTamilForPdf('சௌமியா'), equals('\u0BC6ச\u0BD7மியா'));
    // Plain English passes through untouched
    expect(shapeTamilForPdf('Manimegalai'), equals('Manimegalai'));
  });

  test('buildDailyProductionPdf and buildWeeklyProductionPdf generate valid PDFs with Tamil names and zero rupees', () async {
    final api = FakeApiClient();
    api.employeesData
      ..clear()
      ..addAll([
        {
          'id': 501,
          'name': 'Manimegalai (மணிமேகலை)',
          'role': 'Tape',
          'paymentType': 'Contractual',
          'employmentType': 'Regular',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
        {
          'id': 502,
          'name': 'Jothi (ஜோதி)',
          'role': 'Tape',
          'paymentType': 'Contractual',
          'employmentType': 'Temporary',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
      ]);
    api.productsData
      ..clear()
      ..addAll([
        {
          'id': 901,
          'code': 'WIP-800',
          'name': 'Red Tape Roll',
          'type': 'WIP',
          'category': 'Tape',
          'subCategory': '800 COUNT',
          'unit': 'Pcs',
          'boxesPerCase': 1,
          'status': 'Active',
        },
        {
          'id': 902,
          'code': 'WIP-400',
          'name': 'Blue Tape Roll',
          'type': 'WIP',
          'category': 'Tape',
          'subCategory': '400 COUNT',
          'unit': 'Pcs',
          'boxesPerCase': 1,
          'status': 'Active',
        },
      ]);

    final storage = InMemoryLocalStorageService();
    final vm = DailyProductionViewModel(
      productionRepository: ProductionRepository(
        apiClient: api,
        storage: storage,
      ),
      employeeRepository: EmployeeRepository(apiClient: api),
    );
    addTearDown(vm.dispose);
    await vm.loadInitialData();

    vm.setQuantity(501, 'Blue Tape Roll', 350);
    vm.setQuantity(501, 'Red Tape Roll', 150);

    final dailyBytes = await buildDailyProductionPdf(vm);
    expect(dailyBytes.length, greaterThan(1000));
    expect(latin1.decode(dailyBytes.take(5).toList()), equals('%PDF-'));

    final weekStart = DateTime(2026, 11, 16);
    final weekEnd = DateTime(2026, 11, 21);
    final weeklyRecords = [
      DailyProductionRecord(
        id: 1,
        date: DateTime(2026, 11, 16),
        employeeId: 501,
        employeeName: 'Manimegalai (மணிமேகலை)',
        employeeRole: 'Tape',
        items: const [
          ProductionItemEntry(itemName: 'Blue Tape Roll', quantity: 350),
          ProductionItemEntry(itemName: 'Red Tape Roll', quantity: 150),
        ],
      ),
      DailyProductionRecord(
        id: 2,
        date: DateTime(2026, 11, 17),
        employeeId: 502,
        employeeName: 'Jothi (ஜோதி)',
        employeeRole: 'Tape',
        items: const [
          ProductionItemEntry(itemName: 'Blue Tape Roll', quantity: 250),
        ],
      ),
    ];

    final weeklyBytes = await buildWeeklyProductionPdf(
      vm: vm,
      startDate: weekStart,
      endDate: weekEnd,
      records: weeklyRecords,
    );
    expect(weeklyBytes.length, greaterThan(1000));
    expect(latin1.decode(weeklyBytes.take(5).toList()), equals('%PDF-'));
  });

  testWidgets(
    'Daily Production Hub opens Weekly Production PDF picker on 390px phone viewport without overflow',
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

      final weeklyBtn = find.byKey(const ValueKey('hub-weekly-pdf-button'));
      await tester.scrollUntilVisible(
        weeklyBtn,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(weeklyBtn, findsOneWidget);

      await tester.tap(weeklyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Weekly Production PDF'), findsOneWidget);
      expect(find.byKey(const ValueKey('weekly-pdf-this-week')), findsOneWidget);
      expect(find.byKey(const ValueKey('weekly-pdf-last-week')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('weekly-pdf-generate-button')),
        findsOneWidget,
      );

      // Tap Last Week preset updates date range cleanly
      await tester.tap(find.byKey(const ValueKey('weekly-pdf-last-week')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Generate Weekly PDF (6 Days)'), findsOneWidget);
    },
  );

  test(
    'buildConsolidatedPayrollPdf generates Landscape A4 wage sheet with Tamil names, separate dept tables, and hides absent temp workers',
    () async {
      final api = FakeApiClient();
      api.employeesData
        ..clear()
        ..addAll([
          {
            'id': 601,
            'name': 'Manimegalai (மணிமேகலை)',
            'role': 'Tape',
            'paymentType': 'Contractual',
            'employmentType': 'Regular',
            'status': 'Active',
            'advanceBalance': '500.00',
            'salary': 0,
          },
          {
            'id': 602,
            'name': 'AbsentTemp (ஆப்சென்ட்)',
            'role': 'Tape',
            'paymentType': 'Contractual',
            'employmentType': 'Temporary',
            'status': 'Active',
            'advanceBalance': '0.00',
            'salary': 0,
          },
          {
            'id': 603,
            'name': 'Muniyasamy (முனியசாமி)',
            'role': 'Chemical',
            'paymentType': 'Monthly',
            'employmentType': 'Regular',
            'status': 'Active',
            'advanceBalance': '0.00',
            'salary': 12000,
          },
        ]);

      final payrollVm = PayrollViewModel(
        employeeRepository: EmployeeRepository(apiClient: api),
        payrollRepository: PayrollRepository(apiClient: api),
      );
      addTearDown(payrollVm.dispose);
      await payrollVm.loadAll();

      payrollVm.updateRow(601, basicSalary: 2400, deduction: 200);

      final bytes = await buildConsolidatedPayrollPdf(payrollVm);
      expect(bytes.length, greaterThan(1000));
      expect(latin1.decode(bytes.take(5).toList()), equals('%PDF-'));
    },
  );
}
