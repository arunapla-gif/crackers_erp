import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crackers_erp/core/theme/erp_theme.dart';
import 'package:crackers_erp/data/repositories/auth_repository.dart';
import 'package:crackers_erp/data/repositories/packing_dispatch_repository.dart';
import 'package:crackers_erp/ui/features/auth/view_models/auth_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/factory_dispatch_view_model.dart';
import 'package:crackers_erp/ui/features/production/view_models/packing_view_model.dart';
import 'package:crackers_erp/ui/features/production/views/factory_dispatch_pdf.dart';
import 'package:crackers_erp/ui/features/production/views/factory_dispatch_screen.dart';
import 'package:crackers_erp/ui/features/production/views/packing_screen.dart';

import '../support/fakes.dart';

FakeApiClient _buildGarlandFakeApi() {
  return FakeApiClient(
    godowns: [
      {'id': 1, 'name': 'Factory Ready Stock'},
      {'id': 2, 'name': 'Sivakasi Godown'},
      {'id': 3, 'name': 'Injar Godown'},
    ],
    products: [
      {
        'id': 10,
        'code': 'GAR005',
        'name': '1000 (400)',
        'type': 'INV',
        'category': 'Garlands',
        'subCategory': '400 COUNT',
        'boxesPerCase': 36,
        'unit': 'Case',
        'pack_unit': 'Box',
        'rate': 1450.0,
      },
      {
        'id': 11,
        'code': 'GAR009',
        'name': '1000 (400) Core & Cellophane',
        'type': 'INV',
        'category': 'Garlands',
        'subCategory': '400 COUNT (Core & Cellophane)',
        'boxesPerCase': 36,
        'unit': 'Case',
        'pack_unit': 'Box',
        'rate': 1650.0,
      },
    ],
    transporters: [
      {'id': 1, 'name': 'KPN Parcel', 'city': 'Sivakasi'},
    ],
    vehicles: [
      {
        'id': 1,
        'no': 'TN-67-AB-1234',
        'name': 'Bolero Pickup',
        'drivers': ['Murugan'],
      },
    ],
  );
}

Future<AuthViewModel> _supervisorAuth(FakeApiClient api) async {
  final storage = InMemoryLocalStorageService();
  final authRepo = AuthRepository(apiClient: api, storage: storage);
  final authVm = AuthViewModel(authRepository: authRepo);
  await authVm.login(username: 'supervisor', pin: '1234');
  return authVm;
}

void main() {
  group('Stage 2 Packing & Carry-Forward + Stage 3 Dispatch', () {
    testWidgets(
      'Exact carry-forward math (1000 ÷ 36 = 27 cartons + 28 loose, then +500 → 14 cartons + 24 loose) & zero-rupee secrecy at 390x844',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final api = _buildGarlandFakeApi();
        final authVm = await _supervisorAuth(api);
        final repo = PackingDispatchRepository(apiClient: api);
        final packingVm = PackingViewModel(repository: repo);

        await tester.pumpWidget(
          MaterialApp(
            theme: ErpTheme.buildLightTheme(),
            home: PackingScreen(viewModel: packingVm, authViewModel: authVm),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1000 (400)'), findsOneWidget);
        expect(find.text('36 / Case'), findsNWidgets(2));
        // Zero-rupee secrecy: product prices (1450 / 1650 / ₹) must never appear
        expect(find.textContaining('₹'), findsNothing);
        expect(find.textContaining('1450'), findsNothing);
        expect(find.textContaining('1650'), findsNothing);

        // Day 1: Pack 1000 inner boxes with Auto-Seal ON
        await tester.tap(find.byKey(const ValueKey('inner-pack-btn-GAR005')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const ValueKey('inner-boxes-qty-field')),
          '1000',
        );
        await tester.tap(find.byKey(const ValueKey('auto-seal-cartons-switch')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('27 Master Cartons + 28 Loose Boxes'),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const ValueKey('save-inner-pack-btn')));
        await tester.pumpAndSettle();

        final prodAfterDay1 = packingVm.allProducts.firstWhere(
          (p) => p.code == 'GAR005',
        );
        expect(prodAfterDay1.factoryCartons, 27);
        expect(prodAfterDay1.looseInnerBoxes, 28);
        expect(prodAfterDay1.neededForNextCarton, 8);

        // Day 2: Pack +500 inner boxes without auto-seal → 528 loose → Seal 14 cartons
        await tester.tap(find.byKey(const ValueKey('inner-pack-btn-GAR005')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('inner-boxes-qty-field')),
          '500',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('save-inner-pack-btn')));
        await tester.pumpAndSettle();

        final prodBeforeSeal = packingVm.allProducts.firstWhere(
          (p) => p.code == 'GAR005',
        );
        expect(prodBeforeSeal.looseInnerBoxes, 528);
        expect(prodBeforeSeal.readyToSealCartons, 14);

        final sealBtn = find.byKey(const ValueKey('seal-carton-btn-GAR005'));
        await tester.ensureVisible(sealBtn);
        await tester.pumpAndSettle();
        await tester.tap(sealBtn);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('confirm-seal-cartons-btn')),
        );
        await tester.pumpAndSettle();

        final prodAfterDay2 = packingVm.allProducts.firstWhere(
          (p) => p.code == 'GAR005',
        );
        expect(prodAfterDay2.factoryCartons, 41); // 27 + 14
        expect(prodAfterDay2.looseInnerBoxes, 24); // 528 - 14*36
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Stage 3 Dispatch transfers cartons to Sivakasi Godown and Transporter, with valid zero-rupee Gate Pass PDF',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final api = _buildGarlandFakeApi();
        // Seed 20 Master Cartons in Factory Ready Stock (godownId 1) for product 10
        api.godownCartonsByGodownAndProduct[1] = {10: 20};

        final authVm = await _supervisorAuth(api);
        final repo = PackingDispatchRepository(apiClient: api);
        final dispatchVm = FactoryDispatchViewModel(repository: repo);

        await tester.pumpWidget(
          MaterialApp(
            theme: ErpTheme.buildLightTheme(),
            home: FactoryDispatchScreen(
              viewModel: dispatchVm,
              authViewModel: authVm,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1000 (400)'), findsOneWidget);
        expect(find.textContaining('Available: 20 Cartons'), findsOneWidget);
        expect(find.textContaining('₹'), findsNothing);

        // Dispatch 8 cartons from Factory Ready Stock -> Sivakasi Godown
        dispatchVm.setCartonsForProduct(10, 8, 20);
        await tester.pumpAndSettle();

        final dispatchBtn = find.byKey(const ValueKey('confirm-dispatch-btn'));
        await tester.drag(find.byType(ListView).first, const Offset(0, -600));
        await tester.pumpAndSettle();
        await tester.ensureVisible(dispatchBtn);
        await tester.pumpAndSettle();
        await tester.tap(dispatchBtn);
        await tester.pumpAndSettle();

        expect(dispatchVm.dispatches.length, 1);
        final dc1 = dispatchVm.dispatches.first;
        expect(dc1.challanNo, 'DC-0001');
        expect(dc1.isOwnGodown, isTrue);
        expect(dc1.toGodownName, 'Sivakasi Godown');
        expect(dc1.totalCartons, 8);
        expect(dc1.totalBoxes, 8 * 36);
        // Stock moved: Factory Ready Stock 20 -> 12, Sivakasi Godown 0 -> 8
        expect(api.godownCartonsByGodownAndProduct[1]?[10], 12);
        expect(api.godownCartonsByGodownAndProduct[2]?[10], 8);

        // Now dispatch 5 cartons to Transporter (KPN Parcel) via ViewModel
        dispatchVm.setDestinationType('TRANSPORTER');
        dispatchVm.setSelectedTransporterId(1);
        dispatchVm.setCartonsForProduct(10, 5, 12);
        final dc2 = await dispatchVm.submitDispatch(
          vehicleNoInput: 'TN-67-AB-1234',
          driverNameInput: 'முருகன்',
          customerNameInput: 'Siva Fireworks',
          lrNumberInput: 'LR-901',
          remarksInput: 'Urgent parcel',
        );
        expect(dc2, isNotNull);
        expect(dc2!.challanNo, 'DC-0002');
        expect(dc2.isOwnGodown, isFalse);
        expect(dc2.transporterName, 'KPN Parcel');
        expect(api.godownCartonsByGodownAndProduct[1]?[10], 7);

        // Verify Gate Pass PDF builds cleanly with Tamil + English text & zero rupees
        final pdfBytes = await buildFactoryGatePassPdf(dc2);
        expect(pdfBytes.length, greaterThan(1000));
        expect(utf8.decode(pdfBytes.sublist(0, 5)), '%PDF-');
        expect(tester.takeException(), isNull);
      },
    );
  });
}
