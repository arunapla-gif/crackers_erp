import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/repositories/admin_repository.dart';
import 'package:crackers_erp/data/repositories/auth_repository.dart';
import 'package:crackers_erp/ui/features/admin/view_models/audit_log_view_model.dart';
import 'package:crackers_erp/ui/features/admin/views/audit_log_screen.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  testWidgets(
    'Admin can view Production, Advances, and Payroll audit logs and filter Flagged Alerts',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = FakeApiClient()..roleToLogin = 'Admin';
      api.auditLogsData.addAll([
        {
          'id': 1,
          'module': 'production',
          'action': 'UPDATE',
          'targetDate': '2026-11-20',
          'employeeId': 12,
          'employeeName': 'Selvi',
          'username': 'supervisor1',
          'userRole': 'Supervisor',
          'summary': '12cm Electric Sparklers (WIP): 100 -> 250 (+150)',
          'beforeData': {
            'items': [
              {'itemName': '12cm Electric Sparklers (WIP)', 'quantity': 100},
            ],
          },
          'afterData': {
            'items': [
              {'itemName': '12cm Electric Sparklers (WIP)', 'quantity': 250},
            ],
          },
          'isBackdated': true,
          'createdAt': '2026-11-22T06:00:00.000Z',
        },
        {
          'id': 2,
          'module': 'advances',
          'action': 'CREATE',
          'targetDate': '2026-11-22',
          'employeeId': 11,
          'employeeName': 'Rajan',
          'username': 'admin',
          'userRole': 'Admin',
          'summary': 'Advance Given ₹500.00 (Festival) • Balance ₹0.00 -> ₹500.00',
          'isBackdated': false,
          'createdAt': '2026-11-22T06:05:00.000Z',
        },
        {
          'id': 3,
          'module': 'payroll',
          'action': 'CREATE',
          'targetDate': '2026-11-22',
          'employeeId': 11,
          'employeeName': 'Rajan',
          'username': 'admin',
          'userRole': 'Admin',
          'summary': 'Payroll Nov 2026: Net ₹8500.00',
          'isBackdated': false,
          'createdAt': '2026-11-22T06:10:00.000Z',
        },
      ]);

      final storage = InMemoryLocalStorageService();
      final authVm = AuthViewModel(
        authRepository: AuthRepository(apiClient: api, storage: storage),
      );
      await authVm.login(username: 'admin', pin: '1234');

      final auditVm = AuditLogViewModel(
        adminRepository: AdminRepository(apiClient: api),
      );
      addTearDown(auditVm.dispose);
      addTearDown(authVm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: ErpTheme.buildLightTheme(),
          home: AuditLogScreen(viewModel: auditVm, authViewModel: authVm),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Shows all 3 modules and flags backdated edit
      expect(find.text('BACKDATED EDIT'), findsOneWidget);
      expect(
        find.text('12cm Electric Sparklers (WIP): 100 -> 250 (+150)'),
        findsOneWidget,
      );
      expect(find.textContaining('Advance Given ₹500.00'), findsOneWidget);

      // Tap Flagged Alerts -> only the backdated production edit remains
      await tester.tap(find.byKey(const ValueKey('audit-only-flagged-chip')));
      await tester.pumpAndSettle();
      expect(find.text('BACKDATED EDIT'), findsOneWidget);
      expect(find.textContaining('Advance Given ₹500.00'), findsNothing);
    },
  );

  testWidgets('Supervisor is blocked from viewing Audit Logs', (
    WidgetTester tester,
  ) async {
    final api = FakeApiClient();
    final storage = InMemoryLocalStorageService();
    final authVm = AuthViewModel(
      authRepository: AuthRepository(apiClient: api, storage: storage),
    );
    await authVm.login(username: 'supervisor1', pin: '1234');

    final auditVm = AuditLogViewModel(
      adminRepository: AdminRepository(apiClient: api),
    );
    addTearDown(auditVm.dispose);
    addTearDown(authVm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ErpTheme.buildLightTheme(),
        home: AuditLogScreen(viewModel: auditVm, authViewModel: authVm),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Admin Access Required'), findsOneWidget);
  });
}
