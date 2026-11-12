import 'package:flutter_test/flutter_test.dart';

import 'package:crackers_erp/data/repositories/admin_repository.dart';
import 'package:crackers_erp/data/repositories/billing_repository.dart';
import 'package:crackers_erp/data/repositories/legacy_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/domain/models/erp_user.dart';
import 'package:crackers_erp/ui/features/admin/view_models/company_profile_view_model.dart';
import 'package:crackers_erp/ui/features/admin/view_models/eway_bill_report_view_model.dart';
import 'package:crackers_erp/ui/features/admin/view_models/user_master_view_model.dart';
import 'package:crackers_erp/ui/features/legacy/view_models/legacy_view_model.dart';

import '../../support/fakes.dart';

void main() {
  group('CompanyProfileViewModel', () {
    late FakeApiClient api;
    late CompanyProfileViewModel vm;

    setUp(() {
      api = FakeApiClient();
      vm = CompanyProfileViewModel(
        adminRepository: AdminRepository(apiClient: api),
        masterRepository: MasterRepository(apiClient: api),
      );
    });

    tearDown(() => vm.dispose());

    test('loads credentials, auto-fills GSTIN details, saves profile and series', () async {
      await vm.initialize();
      expect(vm.profiles.length, equals(1));
      expect(vm.credentials?.whitebooksUsername, equals('wb_demo'));

      // 15-char GSTIN triggers verifyGstin auto-fill
      await vm.setGstin('33AABCS1429B1Z5');
      expect(vm.name, equals('Sample Trade Co'));
      expect(vm.city, equals('Sivakasi'));
      expect(vm.pincode, equals('626123'));

      expect(await vm.saveProfile(), isTrue);
      expect(vm.profiles.length, equals(2));

      final created = vm.profiles.last;
      vm.selectProfileForSeries(created);
      vm.setSeriesPrefix('b2b');
      vm.setSeriesName('Branch 2 Invoice');
      vm.setSeriesDocType('INV');
      vm.setSeriesLastNumber('5');

      expect(await vm.saveBillingSeries(), isTrue);
      final refreshed = vm.profiles.firstWhere((p) => p.id == created.id);
      expect(refreshed.billingSeries.length, equals(1));
      expect(refreshed.billingSeries.first.prefix, equals('B2B'));

      final seriesId = refreshed.billingSeries.first.id;
      expect(await vm.deleteBillingSeries(seriesId), isTrue);
      final afterDelete = vm.profiles.firstWhere((p) => p.id == created.id);
      expect(afterDelete.billingSeries, isEmpty);
    });
  });

  group('UserMasterViewModel', () {
    late FakeApiClient api;
    late UserMasterViewModel vm;

    setUp(() {
      api = FakeApiClient(
        users: [
          {
            'id': 1,
            'username': 'admin',
            'role': 'ADMIN',
            'status': 'Active',
            'permissions': <String, dynamic>{},
          },
          {
            'id': 2,
            'username': 'cashier1',
            'role': 'STAFF',
            'status': 'Active',
            'permissions': {
              'billing': {'view': true, 'add': true, 'edit': false, 'delete': false},
            },
          },
        ],
      );
      api.productsData.addAll([
        {
          'id': 50,
          'code': 'EP050',
          'name': '10cm Box',
          'type': 'EP',
          'category': 'Sparklers',
          'subCategory': '600 COUNT',
          'status': 'Active',
        },
        {
          'id': 51,
          'code': 'EP051',
          'name': '8cm Box',
          'type': 'EP',
          'category': 'Sparklers',
          'subCategory': '400 COUNT',
          'status': 'Active',
        },
      ]);
      vm = UserMasterViewModel(
        adminRepository: AdminRepository(apiClient: api),
        masterRepository: MasterRepository(apiClient: api),
      );
    });

    tearDown(() => vm.dispose());

    test('protects super admin account and persists STAFF/REP RBAC permissions', () async {
      await vm.initialize();
      expect(vm.users.length, equals(2));
      expect(vm.categories, equals(['Chakkar', 'Sparklers']));
      expect(vm.subCategories, equals(['400 COUNT', '600 COUNT']));

      // Block disabling 'admin'
      final adminUser = vm.users.firstWhere((u) => u.username == 'admin');
      expect(await vm.toggleUserStatus(adminUser), isFalse);
      expect(vm.errorMessage, contains('Cannot disable'));

      // Editing 'admin' locks role & status changes
      vm.editUser(adminUser);
      expect(vm.isEditingSuperAdmin, isTrue);
      vm.setRole('STAFF');
      expect(vm.role, equals('ADMIN'));

      // Create new Sales Rep with category restrictions
      vm.clearForm();
      vm.setUsername('rep_south');
      vm.setPin('4321');
      vm.setRole('REP');
      vm.toggleCategory('Sparklers');

      expect(await vm.saveUser(), isTrue);
      final savedRep = vm.users.firstWhere((u) => u.username == 'rep_south');
      expect(savedRep.role, equals('REP'));
      expect(savedRep.allowedCategories, equals(['Sparklers']));

      // Disable cashier1 cleanly
      final cashier = vm.users.firstWhere((u) => u.username == 'cashier1');
      expect(await vm.toggleUserStatus(cashier), isTrue);
      final updatedCashier = vm.users.firstWhere((u) => u.id == cashier.id);
      expect(updatedCashier.status, equals('Inactive'));
    });

    test('ErpUser parsing keeps module permissions for STAFF', () {
      final staff = ErpUser.fromJson({
        'id': 9,
        'username': 'clerk',
        'role': 'STAFF',
        'status': 'Active',
        'permissions': {
          'purchase': {'view': true, 'add': true},
        },
      });
      expect(staff.modulePermissions['purchase']?.view, isTrue);
      expect(staff.modulePermissions['purchase']?.delete, isFalse);
    });
  });

  group('EwayBillReportViewModel', () {
    test('requests selected day timeframe and exposes results & errors', () async {
      final api = FakeApiClient();
      final storage = InMemoryLocalStorageService();
      api.ewayBillReportOverride = {
        'message': 'Synced',
        'totalDaysSuccess': 2,
        'totalDaysFailed': 1,
        'data': [
          {
            'date': '10/11/2026',
            'data': [
              {'ewbNo': '331000123456', 'docNo': 'SGFI0010'},
            ],
          },
        ],
        'errors': [
          {'date': '09/11/2026', 'error': 'Rate limit exceeded'},
        ],
      };

      final vm = EwayBillReportViewModel(
        billingRepository: BillingRepository(apiClient: api, storage: storage),
      );
      addTearDown(vm.dispose);

      await vm.initialize();
      expect(api.lastEwayBillDaysRequested, equals(7));
      expect(vm.report?.totalDaysSuccess, equals(2));
      expect(vm.report?.results.length, equals(1));
      expect(vm.report?.errors.length, equals(1));

      await vm.setDays(15);
      expect(api.lastEwayBillDaysRequested, equals(15));
    });
  });

  group('LegacyViewModel', () {
    late FakeApiClient api;
    late LegacyViewModel vm;

    setUp(() {
      api = FakeApiClient();
      api.legacyAnalyticsData = {
        'financials': {
          'totalPurchases': 125000.0,
          'totalEstimates': 340000.0,
          'totalWages': 85000.0,
          'totalPayments': 95000.0,
        },
        'counts': {
          'customers': 2,
          'suppliers': 1,
          'employees': 1,
          'purchases': 1,
          'estimates': 2,
          'workentries': 1,
        },
      };
      api.legacyTrendProductsData = ['Paper', 'Sulphur'];
      api.legacyPriceTrendsByProduct['Paper'] = [
        {'date': '01-01-2024', 'rate': 40.0, 'qty': 100.0, 'pctChange': 0.0},
        {'date': '15-03-2024', 'rate': 44.0, 'qty': 150.0, 'pctChange': 10.0},
      ];
      api.legacyCustomersData = [
        {
          'CustomerID': 10,
          'Customername': 'Muthu Crackers, Madurai',
          'Openingbalance': 5000.0,
        },
        {
          'CustomerID': 20,
          'Customername': 'Kaveri Fireworks',
          'Openingbalance': 12000.0,
        },
      ];
      api.legacyEstimatesData = [
        {
          'SalesID': 1001,
          'Salesdate': '12-02-2024',
          'Customeraccountnumber': 10,
          'Netamount': 15000.0,
        },
        {
          'SalesID': 1002,
          'Salesdate': '20-04-2024',
          'Customeraccountnumber': 20,
          'Netamount': 45000.0,
        },
      ];
      api.legacyEmployeesData = [
        {'EmployeeID': 7, 'EmployeeName': 'Velmurugan', 'City': 'Sivakasi'},
      ];
      api.legacyPayrollProductsData = [
        {'ParticularID': 99, 'Particularname': '12cm Box Packing'},
      ];
      api.legacyWorkentriesData = [
        {
          'WorkerID': 55,
          'EmployeeId': 7,
          'Workerdate': '10-03-2024',
          'Netamount': 950.0,
        },
      ];
      api.legacyWorkentryParticularsById[55] = [
        {'ProductID': 99, 'Quantity': 50, 'Total': 950.0},
      ];
      vm = LegacyViewModel(legacyRepository: LegacyRepository(apiClient: api));
    });

    tearDown(() => vm.dispose());

    test('loads overview analytics, price trends, enriches tables, filters & exports CSV', () async {
      await vm.initialize();
      expect(vm.analytics?.totalEstimates, equals(340000.0));
      expect(vm.trendProducts, equals(['Paper', 'Sulphur']));

      await vm.selectTrendProduct('Paper');
      expect(vm.priceTrends.length, equals(2));
      expect(vm.priceTrends.last.pctChange, equals(10.0));

      // Estimates tab: joins Customername from legacyCustomersData
      await vm.setActiveTab(LegacyTab.estimates);
      expect(vm.totalCount, equals(2));
      expect(vm.processedRecords.first['CustomerName'], equals('Kaveri Fireworks'));
      expect(
        vm.processedRecords.last['CustomerName'],
        equals('Muthu Crackers, Madurai'),
      );

      // Date range filter (March-May 2024 includes only SalesID 1002)
      vm.setDateFrom(DateTime(2024, 3, 1));
      vm.setDateTo(DateTime(2024, 5, 1));
      expect(vm.totalCount, equals(1));
      expect(vm.processedRecords.first['SalesID'], equals(1002));

      vm.clearDates();
      vm.setSearchTerm('Muthu');
      expect(vm.totalCount, equals(1));
      final csv = vm.buildCsvForCurrentTab();
      // CSV properly quotes fields containing commas
      expect(csv, contains('"Muthu Crackers, Madurai"'));

      // Workentries tab: enriches EmployeeName & lazy Workentry ProductName
      await vm.setActiveTab(LegacyTab.workentries);
      expect(vm.processedRecords.first['EmployeeName'], equals('Velmurugan'));
      await vm.toggleWorkExpand(55);
      expect(
        vm.workItemsFor(55).first['ProductName'],
        equals('12cm Box Packing'),
      );
    });
  });
}
