import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/repositories/auth_repository.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/auth/views/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';

void main() {
  testWidgets('LoginScreen validates inputs and authenticates Supervisor', (
    WidgetTester tester,
  ) async {
    final api = FakeApiClient();
    final storage = InMemoryLocalStorageService();
    final authVm = AuthViewModel(
      authRepository: AuthRepository(apiClient: api, storage: storage),
    );
    addTearDown(authVm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ErpTheme.buildLightTheme(),
        home: LoginScreen(viewModel: authVm),
      ),
    );

    expect(find.text('Crackers ERP'), findsOneWidget);
    expect(find.text('Factory Supervisor App'), findsOneWidget);

    // Submit empty form shows validation errors
    await tester.tap(find.text('Sign In to Factory Portal'));
    await tester.pump();
    expect(find.text('Enter username'), findsOneWidget);
    expect(find.text('Enter your numeric PIN'), findsOneWidget);

    // Enter valid credentials and sign in
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'supervisor1');
    await tester.enterText(fields.at(1), '1234');
    await tester.tap(find.text('Sign In to Factory Portal'));
    await tester.pumpAndSettle();

    expect(authVm.isAuthenticated, isTrue);
    expect(authVm.currentUser?.username, equals('supervisor1'));
  });

  testWidgets('LoginScreen surfaces server error message on invalid PIN', (
    WidgetTester tester,
  ) async {
    final api = FakeApiClient()..shouldFailLogin = true;
    final storage = InMemoryLocalStorageService();
    final authVm = AuthViewModel(
      authRepository: AuthRepository(apiClient: api, storage: storage),
    );
    addTearDown(authVm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ErpTheme.buildLightTheme(),
        home: LoginScreen(viewModel: authVm),
      ),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'supervisor1');
    await tester.enterText(fields.at(1), '0000');
    await tester.tap(find.text('Sign In to Factory Portal'));
    await tester.pumpAndSettle();

    expect(authVm.isAuthenticated, isFalse);
    expect(find.text('Invalid username or PIN'), findsOneWidget);
  });
}

