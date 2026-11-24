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

FakeApiClient _buildGarlandFakeApi({
  List<Map<String, dynamic>>? initialProductions,
}) {
  return FakeApiClient(
    godowns: [
      {'id': 1, 'name': 'Factory Ready Stock'},
      {'id': 2, 'name': 'Sivakasi Godown'},
      {'id': 3, 'name': 'Injar Godown'},
    ],
    employees: [
      {'id': 1, 'name': 'Jothi (ஜோதி)', 'role': 'Tape', 'status': 'Active'},
      {
        'id': 2,
        'name': 'Ramesh (ரமேஷ்)',
        'role': 'Chemical',
        'status': 'Active',
      },
    ],
    products: [
      // Tape WIP items
      {
        'id': 36,
        'code': 'WIP004',
        'name': '400',
        'type': 'WIP',
        'category': 'TAPE',
        'subCategory': '400 COUNT',
        'boxesPerCase': 1,
        'rate': 10.0,
      },
      {
        'id': 37,
        'code': 'WIP005',
        'name': '800',
        'type': 'WIP',
        'category': 'TAPE',
        'subCategory': '400 COUNT',
        'boxesPerCase': 1,
        'rate': 20.0,
      },
      {
        'id': 44,
        'code': 'WIP012',
        'name': '700',
        'type': 'WIP',
        'category': 'TAPE',
        'subCategory': '700 COUNT',
        'boxesPerCase': 1,
        'rate': 15.0,
      },
      // Finished Garland Styles linked via factoryAliasId
      {
        'id': 10,
        'code': 'GAR005',
        'name': '1000 (400)',
        'type': 'INV',
        'category': 'Garlands',
        'subCategory': '400 COUNT',
        'boxesPerCase': 36,
        'factoryAliasId': 36,
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
        'factoryAliasId': 36,
        'unit': 'Case',
        'pack_unit': 'Box',
        'rate': 1650.0,
      },
      {
        'id': 12,
        'code': 'GAR006',
        'name': '2000 (800)',
        'type': 'INV',
        'category': 'Garlands',
        'subCategory': '400 COUNT',
        'boxesPerCase': 20,
        'factoryAliasId': 37,
        'unit': 'Case',
        'pack_unit': 'Box',
        'rate': 1850.0,
      },
      {
        'id': 13,
        'code': 'GAR022',
        'name': '1000 (800)',
        'type': 'INV',
        'category': 'Garlands',
        'subCategory': '800 COUNT',
        'boxesPerCase': 36,
        'factoryAliasId': 37,
        'unit': 'Case',
        'pack_unit': 'Box',
        'rate': 1550.0,
      },
      {
        'id': 14,
        'code': 'GAR017',
        'name': '1000 (700)',
        'type': 'INV',
        'category': 'Garlands',
        'subCategory': '700 COUNT',
        'boxesPerCase': 36,
        'factoryAliasId': 44,
        'unit': 'Case',
        'pack_unit': 'Box',
        'rate': 1500.0,
      },
    ],
    productions: initialProductions ?? <Map<String, dynamic>>[],
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
  group('Production-Driven Stage 2 Packing & Stage 3 Dispatch', () {
    testWidgets(
      'Lists ONLY saved Tape items, allows splitting 800 into 2000(800) & 1000(800), and enforces exact carry-forward math with zero rupees at 390x844',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Tape worker saved 1000 of '400' and 100 of '800'.
        // Chemical worker saved 500 of '700' (must NOT appear in Packing!).
        final api = _buildGarlandFakeApi(
          initialProductions: [
            {
              'id': 1,
              'date': '2026-11-24',
              'employeeId': 1, // Tape
              'items': [
                {'itemName': '400', 'quantity': 1000},
                {'itemName': '800', 'quantity': 100},
              ],
            },
            {
              'id': 2,
              'date': '2026-11-24',
              'employeeId': 2, // Chemical (ignored!)
              'items': [
                {'itemName': '700', 'quantity': 500},
              ],
            },
          ],
        );

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

        // Rule 1: ONLY Tape items '400' and '800' are listed; Chemical '700' / '1000 (700)' is NOT shown!
        expect(packingVm.pendingTapeItems.map((t) => t.wipName).toList(), [
          '400',
          '800',
        ]);
        expect(find.text('1000 (700)'), findsNothing);
        // Zero-rupee secrecy
        expect(find.textContaining('₹'), findsNothing);
        expect(find.textContaining('1450'), findsNothing);
        expect(find.textContaining('1850'), findsNothing);

        // Rule 2: Split '800' (100 Tape units) -> 60 into '2000 (800)' and 40 into '1000 (800)'
        final pack800Btn = find.byKey(const ValueKey('inner-pack-wip-800'));
        await tester.ensureVisible(pack800Btn);
        await tester.pumpAndSettle();
        await tester.tap(pack800Btn);
        await tester.pumpAndSettle();

        // Pick '2000 (800)' (GAR006) and pack 60 boxes
        await tester.tap(find.byKey(const ValueKey('style-option-GAR006')));
        await tester.enterText(
          find.byKey(const ValueKey('inner-boxes-qty-field')),
          '60',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('save-inner-pack-btn')));
        await tester.pumpAndSettle();

        // '800' still has 40 unpacked Tape units left
        expect(
          packingVm.pendingTapeItems
              .firstWhere((t) => t.wipName == '800')
              .unpackedUnits,
          40,
        );

        // Pack remaining 40 units of '800' into '1000 (800)' (GAR022)
        await tester.ensureVisible(pack800Btn);
        await tester.pumpAndSettle();
        await tester.tap(pack800Btn);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('style-option-GAR022')));
        await tester.tap(find.byKey(const ValueKey('pack-all-available-chip')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('save-inner-pack-btn')));
        await tester.pumpAndSettle();

        // '800' now has 0 unpacked units -> automatically removed from Tab 1!
        expect(
          packingVm.pendingTapeItems.any((t) => t.wipName == '800'),
          isFalse,
        );

        // Day 1 Carry-Forward Math on '400': Pack all 1000 into '1000 (400)' with Auto-Seal ON
        final pack400Btn = find.byKey(const ValueKey('inner-pack-wip-400'));
        await tester.ensureVisible(pack400Btn);
        await tester.pumpAndSettle();
        await tester.tap(pack400Btn);
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('pack-all-available-chip')));
        await tester.tap(find.byKey(const ValueKey('auto-seal-cartons-switch')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining('27 Master Cartons + 28 Loose Boxes'),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('save-inner-pack-btn')));
        await tester.pumpAndSettle();

        // Tab 1 is now completely empty because all Tape production is packed!
        expect(packingVm.pendingTapeItems, isEmpty);
        expect(find.text('No Unpacked Tape Production'), findsOneWidget);

        // Tab 2 (Master Cartons) lists ONLY the 3 styles that actually have loose boxes > 0
        expect(
          packingVm.looseMasterCartonQueue.map((p) => p.code).toSet(),
          {'GAR006', 'GAR022', 'GAR005'},
        );

        // Day 2: Tape worker saves +500 more of '400' -> pack without auto-seal -> 528 loose -> seal 14 cartons
        api.productionsData.add({
          'id': 3,
          'date': '2026-11-25',
          'employeeId': 1,
          'items': [
            {'itemName': '400', 'quantity': 500},
          ],
        });
        await packingVm.loadSummary();
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('inner-pack-wip-400')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('pack-all-available-chip')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('save-inner-pack-btn')));
        await tester.pumpAndSettle();

        // Switch to Tab 2 (Master Cartons) and seal 14 cartons of GAR005 ('1000 (400)')
        await tester.tap(find.text('Cartons (3)'));
        await tester.pumpAndSettle();

        final sealBtn = find.byKey(const ValueKey('seal-carton-btn-GAR005'));
        await tester.ensureVisible(sealBtn);
        await tester.pumpAndSettle();
        await tester.tap(sealBtn);
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('confirm-seal-cartons-btn')),
        );
        await tester.pumpAndSettle();

        final gar005 = packingVm.allProducts.firstWhere(
          (p) => p.code == 'GAR005',
        );
        expect(gar005.factoryCartons, 41); // 27 + 14
        expect(gar005.looseInnerBoxes, 24); // 528 - 14*36
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
        expect(api.godownCartonsByGodownAndProduct[1]?[10], 12);
        expect(api.godownCartonsByGodownAndProduct[2]?[10], 8);

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

        final pdfBytes = await buildFactoryGatePassPdf(dc2);
        expect(pdfBytes.length, greaterThan(1000));
        expect(utf8.decode(pdfBytes.sublist(0, 5)), '%PDF-');
        expect(tester.takeException(), isNull);
      },
    );
  });
}
