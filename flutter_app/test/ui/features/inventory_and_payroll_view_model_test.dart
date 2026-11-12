import 'package:flutter_test/flutter_test.dart';

import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/data/repositories/inventory_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/repositories/payroll_repository.dart';
import 'package:crackers_erp/domain/models/supplier.dart';
import 'package:crackers_erp/ui/features/hr/view_models/payroll_view_model.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/purchase_view_model.dart';
import 'package:crackers_erp/ui/features/inventory/view_models/transfer_view_model.dart';

import '../../support/fakes.dart';

void main() {
  group('PurchaseViewModel', () {
    late FakeApiClient api;
    late PurchaseViewModel vm;

    setUp(() {
      api = FakeApiClient();
      api.productsData.add({
        'id': 30,
        'code': 'RM001',
        'name': 'Aluminium Powder Grade A',
        'type': 'RM',
        'category': 'Chemicals',
        'tax': 18,
        'rate': 400.0,
        'unit_qty': 25,
        'unit': 'Kg',
        'pack_unit': 'Bag',
        'status': 'Active',
      });
      api.suppliersData.add({
        'id': 2,
        'name': 'Bangalore Chemical Traders',
        'type': 'Raw Material',
        'state': 'Karnataka',
        'status': 'Active',
      });
      vm = PurchaseViewModel(
        inventoryRepository: InventoryRepository(apiClient: api),
        masterRepository: MasterRepository(apiClient: api),
      );
    });

    tearDown(() => vm.dispose());

    test('computes pack quantity, discount, intra vs inter-state GST and saves', () async {
      await vm.loadAll();

      expect(vm.rawMaterials.length, equals(1));
      expect(vm.rawMaterials.first.code, equals('RM001'));

      final rowId = vm.rows.first.localId;
      vm.selectRowGodown(rowId, vm.godowns.first);
      vm.selectRowProduct(rowId, vm.rawMaterials.first);
      // 2 bags * 25 kg = 50 kg * 400 = 20000 - 1000 disc = 19000 taxable; 18% GST = 3420 -> 22420
      vm.updateRowNumbers(rowId, packs: 2, discount: 1000);

      expect(vm.rows.first.qty, equals(50));
      expect(vm.rows.first.amount, closeTo(20000.0, 0.01));
      expect(vm.totalTax, closeTo(3420.0, 0.01));
      expect(vm.grandTotal, closeTo(22420.0, 0.01));

      // Tamil Nadu supplier -> intra-state CGST + SGST
      vm.selectSupplier(Supplier.fromJson(api.suppliersData.first));
      expect(vm.isIntraState, isTrue);
      expect(vm.cgst, closeTo(1710.0, 0.01));
      expect(vm.sgst, closeTo(1710.0, 0.01));
      expect(vm.igst, equals(0.0));

      // Karnataka supplier -> inter-state IGST
      vm.selectSupplier(Supplier.fromJson(api.suppliersData[1]));
      expect(vm.isIntraState, isFalse);
      expect(vm.cgst, equals(0.0));
      expect(vm.sgst, equals(0.0));
      expect(vm.igst, closeTo(3420.0, 0.01));

      final ok = await vm.savePurchase();
      expect(ok, isTrue);
      expect(api.lastSavedPurchasePayload?['igst'], closeTo(3420.0, 0.01));
      expect(api.lastSavedPurchasePayload?['qty'], equals(50));
      expect(api.purchasesData.length, equals(1));
    });

    test('rejects invalid purchase missing supplier or godown', () async {
      await vm.loadAll();
      expect(await vm.savePurchase(), isFalse);
      expect(vm.errorMessage, contains('Supplier name is required'));

      vm.selectSupplier(Supplier.fromJson(api.suppliersData.first));
      vm.selectRowProduct(vm.rows.first.localId, vm.rawMaterials.first);
      expect(await vm.savePurchase(), isFalse);
      expect(vm.errorMessage, contains('Destination Godown'));
    });
  });

  group('TransferViewModel', () {
    late FakeApiClient api;
    late TransferViewModel vm;

    setUp(() {
      api = FakeApiClient();
      api.stockLedgerData = [
        {
          'id': 1,
          'godownId': 1,
          'godownName': 'Main RM Godown',
          'product': 'Finished Sparklers Box',
          'qty': 40,
          'avgRate': 1200.0,
          'value': 48000.0,
        },
      ];
      vm = TransferViewModel(
        inventoryRepository: InventoryRepository(apiClient: api),
        masterRepository: MasterRepository(apiClient: api),
      );
    });

    tearDown(() => vm.dispose());

    test('validates same godown and available stock before saving transfer', () async {
      await vm.loadAll();

      final rowId = vm.rows.first.localId;
      final prod = vm.products.firstWhere((p) => p.name == 'Finished Sparklers Box');
      final g1 = vm.godowns[0];
      final g2 = vm.godowns[1];

      vm.selectVehicle(vm.vehicles.first);
      vm.selectFromGodown(rowId, g1);
      vm.selectProduct(rowId, prod);

      expect(vm.availableQtyForRow(vm.rows.first), equals(40));
      expect(vm.rows.first.rate, closeTo(1200.0, 0.01));

      // Same From & To godown blocked
      vm.selectToGodown(rowId, g1);
      expect(await vm.saveTransfer(), isFalse);
      expect(vm.errorMessage, contains('cannot be the same'));

      // Qty exceeding stock blocked
      vm.selectToGodown(rowId, g2);
      vm.updateRowQty(rowId, 55);
      expect(await vm.saveTransfer(), isFalse);
      expect(vm.errorMessage, contains('Insufficient stock'));

      // Valid transfer succeeds
      vm.updateRowQty(rowId, 15);
      expect(vm.totalValue, closeTo(18000.0, 0.01));
      expect(await vm.saveTransfer(), isTrue);
      expect(api.lastSavedTransferPayload?['qty'], equals(15));
      expect(api.transfersData.length, equals(1));
    });
  });

  group('PayrollViewModel', () {
    late FakeApiClient api;
    late PayrollViewModel vm;

    setUp(() {
      api = FakeApiClient();
      api.employeesData[2]['salary'] = '15000.00'; // Ramesh S (Monthly)
      api.aggregateProductionByEmployee[11] = {
        'totalAmount': 2450.0,
        'details': [
          {
            'date': '2026-04-28T00:00:00.000Z',
            'totalAmount': 1250.0,
            'items': [
              {'itemName': '12cm Electric Sparklers (WIP)', 'quantity': 100},
              {'itemName': '8cm Electric Sparklers (WIP)', 'quantity': 80},
            ],
          },
          {
            'date': '2026-04-29T00:00:00.000Z',
            'totalAmount': 1200.0,
            'items': [
              {'itemName': '10cm Colour Sparklers (WIP)', 'quantity': 90},
              {'itemName': '12cm Electric Sparklers (WIP)', 'quantity': 50},
            ],
          },
        ],
      };
      vm = PayrollViewModel(
        employeeRepository: EmployeeRepository(apiClient: api),
        payrollRepository: PayrollRepository(apiClient: api),
      );
    });

    tearDown(() => vm.dispose());

    test('computes Friday-Thursday period across month boundaries', () {
      // Saturday May 2, 2026 -> Friday Apr 24 to Thursday Apr 30
      vm.setPayoutDate(DateTime(2026, 5, 2));
      expect(vm.isPayoutSaturday, isTrue);
      expect(vm.isoStartDate, equals('2026-04-24'));
      expect(vm.isoEndDate, equals('2026-04-30'));

      // Saturday Mar 7, 2026 -> Friday Feb 27 to Thursday Mar 5
      vm.setPayoutDate(DateTime(2026, 3, 7));
      expect(vm.isPayoutSaturday, isTrue);
      expect(vm.isoStartDate, equals('2026-02-27'));
      expect(vm.isoEndDate, equals('2026-03-05'));

      // Non-Saturday check
      vm.setPayoutDate(DateTime(2026, 5, 4));
      expect(vm.isPayoutSaturday, isFalse);
    });

    test('aggregates contractual wages, natural sorts products & saves payroll', () async {
      await vm.loadAll();
      vm.setPayoutDate(DateTime(2026, 5, 2));

      final calcOk = await vm.calculateContractualWages();
      expect(calcOk, isTrue);

      // Natural sort puts 8cm before 10cm before 12cm
      expect(
        vm.uniqueProducts,
        equals([
          '8cm Electric Sparklers (WIP)',
          '10cm Colour Sparklers (WIP)',
          '12cm Electric Sparklers (WIP)',
        ]),
      );

      final mariRow = vm.rowFor(11)!;
      expect(mariRow.basicSalary, closeTo(2450.0, 0.01));
      expect(mariRow.productQuantities['12cm Electric Sparklers (WIP)'], equals(150));
      expect(mariRow.dailyLogs.length, equals(2));

      // Add allowance & advance deduction
      vm.updateRow(11, allowance: 300, deduction: 500);
      expect(vm.rowFor(11)!.netSalary, closeTo(2250.0, 0.01));

      // Monthly employee Ramesh S has 15000 basic + Mariappan 2250 = 17250 grand net
      expect(vm.grandTotals.net, closeTo(17250.0, 0.01));

      final saveOk = await vm.saveBulkPayroll();
      expect(saveOk, isTrue);
      expect(api.payrollsData.length, equals(2));
      expect(api.lastSavedPayrollPayload?['periodStr'], equals('24/04/2026 to 30/04/2026'));
    });
  });
}

