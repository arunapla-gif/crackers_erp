import 'package:flutter_test/flutter_test.dart';

import 'package:crackers_erp/data/repositories/admin_repository.dart';
import 'package:crackers_erp/data/repositories/billing_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/repositories/sales_order_repository.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/domain/models/user_session.dart';
import 'package:crackers_erp/ui/features/sales/view_models/billing_view_model.dart';
import 'package:crackers_erp/ui/features/sales/view_models/sales_order_view_model.dart';

import '../../support/fakes.dart';

void main() {
  group('BillingViewModel', () {
    late FakeApiClient api;
    late InMemoryLocalStorageService storage;
    late BillingViewModel vm;

    setUp(() {
      api = FakeApiClient();
      api.productsData.addAll([
        {
          'id': 10,
          'code': 'INV010',
          'name': '12cm Electric Sparklers',
          'type': 'INV',
          'category': 'Sparklers',
          'hsn': '3604',
          'tax': 18,
          'rate': 100.0,
          'boxesPerCase': 10,
          'unit_qty': 1,
          'unit': 'Case',
          'status': 'Active',
        },
        {
          'id': 11,
          'code': 'INV011',
          'name': 'Flower Pots Special',
          'type': 'INV',
          'category': 'Pots',
          'hsn': '3604',
          'tax': 18,
          'rate': 250.0,
          'boxesPerCase': 5,
          'unit_qty': 1,
          'unit': 'Case',
          'status': 'Active',
        },
      ]);
      storage = InMemoryLocalStorageService();
      vm = BillingViewModel(
        billingRepository: BillingRepository(apiClient: api, storage: storage),
        masterRepository: MasterRepository(apiClient: api),
        adminRepository: AdminRepository(apiClient: api),
      );
    });

    tearDown(() => vm.dispose());

    test('auto-selects single active company profile and sets next serial number', () async {
      await vm.initialize();

      expect(vm.selectedProfile?.id, equals(1));
      expect(vm.isGatewayOpen, isFalse);
      expect(vm.header.series, equals('SGFI'));
      expect(vm.header.number, equals('0011'));
      expect(vm.originState, equals('Tamil Nadu'));
    });

    test('computes intra-state CGST/SGST and inter-state IGST accurately', () async {
      await vm.initialize();
      final rowId = vm.rows.first.id;
      final p = vm.products.firstWhere((e) => e.id == 10);

      vm.selectProductForRow(rowId, p);
      vm.updateRow(rowId, qty: 3); // 3 * 100 = 300, 18% GST = 54 (27 + 27)

      expect(vm.totals.subtotal, closeTo(300.0, 0.01));
      expect(vm.totals.tax, closeTo(54.0, 0.01));
      expect(vm.totals.cgst, closeTo(27.0, 0.01));
      expect(vm.totals.sgst, closeTo(27.0, 0.01));
      expect(vm.totals.igst, closeTo(0.0, 0.01));
      expect(vm.totals.grandTotal, closeTo(354.0, 0.01));

      // Switch customer state to Karnataka => inter-state IGST
      vm.setBillState('Karnataka');
      expect(vm.totals.cgst, closeTo(0.0, 0.01));
      expect(vm.totals.sgst, closeTo(0.0, 0.01));
      expect(vm.totals.igst, closeTo(54.0, 0.01));
      expect(vm.totals.grandTotal, closeTo(354.0, 0.01));
    });

    test('EST mode zeroes GST and evaluates percentage & fixed additional charges', () async {
      await vm.initialize();
      final rowId = vm.rows.first.id;
      final p = vm.products.firstWhere((e) => e.id == 11); // rate 250

      vm.selectProductForRow(rowId, p);
      vm.updateRow(rowId, qty: 4); // subtotal = 1000
      vm.setDocType('EST');

      expect(vm.header.series, equals('SGFE'));
      expect(vm.header.number, equals('0005'));
      expect(vm.totals.tax, equals(0.0));
      expect(vm.totals.cgst, equals(0.0));
      expect(vm.totals.igst, equals(0.0));

      final c1 = vm.chargeRows.first.id;
      vm.updateChargeRow(
        c1,
        name: 'Packing',
        mode: 'ADD',
        type: 'PERCENT',
        value: 5, // +50
      );
      vm.addChargeRow();
      final c2 = vm.chargeRows.last.id;
      vm.updateChargeRow(
        c2,
        name: 'Cash Discount',
        mode: 'DEDUCT',
        type: 'AMOUNT',
        value: 25, // -25
      );

      expect(vm.totals.charges, closeTo(25.0, 0.01));
      expect(vm.totals.grandTotal, closeTo(1025.0, 0.01));
    });

    test('selecting customer applies custom rate overrides and saves payload', () async {
      api.customerPricesData[1] = [
        {'id': 1, 'customerId': 1, 'productId': 10, 'rate': 85.0},
      ];
      await vm.initialize();

      final rowId = vm.rows.first.id;
      final prod = vm.products.firstWhere((e) => e.id == 10);
      vm.selectProductForRow(rowId, prod);
      vm.updateRow(rowId, qty: 2);
      expect(vm.totals.subtotal, closeTo(200.0, 0.01));

      final customer = vm.customers.firstWhere((c) => c.id == 1);
      await vm.selectCustomer(customer);

      // Custom rate 85 * qty 2 = 170, 18% GST = 30.6 -> 200.6
      expect(vm.rows.first.rate, closeTo(85.0, 0.01));
      expect(vm.totals.subtotal, closeTo(170.0, 0.01));
      expect(vm.totals.tax, closeTo(30.6, 0.01));
      expect(vm.totals.grandTotal, closeTo(200.6, 0.01));

      final savedNumber = await vm.saveDocument();
      expect(savedNumber, equals('SGFI0011'));
      expect(api.lastSavedInvoicePayload?['number'], equals('SGFI0011'));
      expect(api.lastSavedInvoicePayload?['subtotal'], closeTo(170.0, 0.01));
      expect(api.lastSavedInvoicePayload?['grand_total'], closeTo(200.6, 0.01));
      expect(vm.header.number, equals('0012'));
    });
  });

  group('SalesOrderViewModel', () {
    late FakeApiClient api;
    late SalesOrderViewModel vm;

    setUp(() {
      api = FakeApiClient();
      api.productsData = [
        {
          'id': 20,
          'code': 'EP020',
          'name': '10cm Sparklers EP',
          'type': 'EP',
          'category': 'Sparklers',
          'subCategory': '10cm Sparklers',
          'hsn': '3604',
          'tax': 18,
          'rate': 150.0,
          'boxesPerCase': 20,
          'unit_qty': 1,
          'unit': 'Box',
          'status': 'Active',
        },
        {
          'id': 21,
          'code': 'EP021',
          'name': 'Ground Chakkar Deluxe EP',
          'type': 'EP',
          'category': 'Chakkars',
          'subCategory': 'Chakkar',
          'hsn': '3604',
          'tax': 18,
          'rate': 220.0,
          'boxesPerCase': 10,
          'unit_qty': 1,
          'unit': 'Box',
          'status': 'Active',
        },
      ];
      vm = SalesOrderViewModel(
        salesOrderRepository: SalesOrderRepository(apiClient: api),
        masterRepository: MasterRepository(apiClient: api),
      );
    });

    tearDown(() => vm.dispose());

    test('calculates boxesPerCase multiplication and applies customer rates', () async {
      api.customerPricesData[1] = [
        {'id': 1, 'customerId': 1, 'productId': 20, 'rate': 120.0},
      ];
      await vm.initialize();

      expect(vm.epProducts.length, equals(2));
      vm.setCartQty(20, 3); // 3 cases * 20 boxes * 150 = 9000
      expect(vm.subtotal, closeTo(9000.0, 0.01));

      await vm.selectCustomer(Customer.fromJson(api.customersData.first));
      // Custom rate 120 * 20 boxes * 3 cases = 7200
      expect(vm.subtotal, closeTo(7200.0, 0.01));
    });

    test('filters EP catalog strictly by Rep allowedCategories', () async {
      final repRestrictedEmpty = UserAccount.fromJson({
        'id': 5,
        'username': 'rep_empty',
        'role': 'REP',
        'status': 'Active',
        'permissions': {'allowedCategories': <String>[]},
      });
      await vm.initialize(user: repRestrictedEmpty);
      expect(vm.epProducts, isEmpty);

      final repSparklersOnly = UserAccount.fromJson({
        'id': 6,
        'username': 'rep_sparklers',
        'role': 'REP',
        'status': 'Active',
        'permissions': {
          'allowedCategories': ['Sparklers'],
        },
      });
      await vm.initialize(user: repSparklersOnly);
      expect(vm.epProducts.length, equals(1));
      expect(vm.epProducts.first.category, equals('Sparklers'));
    });

    test('validates lead details & submits new GST lead order', () async {
      await vm.initialize();
      vm.toggleNewCustomer(true);
      vm.setCartQty(20, 2);

      // Unregistered validation checks
      vm.updateLead(name: 'New Shop', idNumber: '', pincode: '626');
      expect(await vm.submitOrder(), isFalse);
      expect(vm.errorMessage, contains('Aadhaar / PAN'));

      vm.updateLead(idNumber: 'ABCDE1234F', pincode: '62612');
      expect(await vm.submitOrder(), isFalse);
      expect(vm.errorMessage, contains('6-digit Pincode'));

      // Switch to GST lead and verify via GSTIN
      vm.setNewCustomerType('GST');
      vm.updateLead(gstin: '33AABCS1429B1Z5');
      await vm.verifyGstin();
      expect(vm.lead.name, equals('Sample Trade Co'));
      expect(vm.lead.city, equals('Sivakasi'));

      final ok = await vm.submitOrder();
      expect(ok, isTrue);
      expect(api.lastSavedSalesOrderPayload?['customerId'], isNull);
      expect(
        (api.lastSavedSalesOrderPayload?['newCustomerData']
            as Map<String, dynamic>)['gstin'],
        equals('33AABCS1429B1Z5'),
      );
      expect(
        (api.lastSavedSalesOrderPayload?['items'] as List<dynamic>).length,
        equals(1),
      );
      expect(vm.cart, isEmpty);
    });
  });

  test('Product.isEp and natural numeric grouping sanity check', () {
    final p = Product.fromJson({
      'id': 1,
      'code': 'EP01',
      'name': '15cm Green Sparklers',
      'type': 'EP',
      'category': 'Sparklers',
      'rate': 180,
      'boxesPerCase': 10,
      'unit': 'Box',
    });
    expect(p.isEp, isTrue);
  });
}

