import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/data/repositories/production_repository.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import 'package:crackers_erp/ui/features/production/view_models/daily_production_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  group('DailyProductionViewModel', () {
    late FakeApiClient api;
    late InMemoryLocalStorageService storage;
    late DailyProductionViewModel vm;

    setUp(() {
      api = FakeApiClient();
      storage = InMemoryLocalStorageService();
      vm = DailyProductionViewModel(
        productionRepository: ProductionRepository(
          apiClient: api,
          storage: storage,
        ),
        employeeRepository: EmployeeRepository(apiClient: api),
      );
    });

    tearDown(() => vm.dispose());

    test('loads only WIP products and Contractual workers by default', () async {
      await vm.loadInitialData();

      expect(vm.wipProducts.length, equals(2));
      expect(vm.wipProducts.any((p) => p.type == 'Finished Goods'), isFalse);
      expect(vm.activeWorkers.length, equals(2)); // Excludes Monthly employee #13
      expect(vm.activeItemNames.length, equals(2));
    });

    test('persists local draft on quantity change and saves via bulk API', () async {
      await vm.loadInitialData();

      vm.setQuantity(11, '12cm Electric Sparklers (WIP)', 120);
      vm.incrementQuantity(12, '12cm Electric Sparklers (WIP)', 40);

      expect(vm.hasUnsavedChanges, isTrue);
      expect(vm.totalPiecesEntered, equals(160));
      expect(vm.activeWorkersLoggedCount, equals(2));

      // Verify draft was written locally
      final savedDraft = storage.getProductionDraft(toIsoCalendarDate(vm.selectedDate));
      expect(savedDraft?[11]?['12cm Electric Sparklers (WIP)'], equals(120));
      expect(savedDraft?[12]?['12cm Electric Sparklers (WIP)'], equals(40));

      final ok = await vm.saveAll();
      expect(ok, isTrue);
      expect(vm.hasUnsavedChanges, isFalse);
      expect(
        storage.getProductionDraft(toIsoCalendarDate(vm.selectedDate)),
        isNull,
      );
      expect(api.lastSavedProductionBulkPayload?['entries'], isNotEmpty);

      // Verify no wage rate fields were ever submitted
      final submittedEntries = (api.lastSavedProductionBulkPayload?['entries'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      for (final entry in submittedEntries) {
        final items = (entry['items'] as List<dynamic>).cast<Map<String, dynamic>>();
        for (final item in items) {
          expect(item.containsKey('pieceRate'), isFalse);
          expect(item.containsKey('total'), isFalse);
        }
      }
    });

    test('deletes saved history record and syncs state', () async {
      await vm.loadInitialData();
      vm.setQuantity(11, '12cm Electric Sparklers (WIP)', 50);
      await vm.saveAll();
      expect(vm.recentHistory.length, equals(1));

      final rec = vm.recentHistory.first;
      final ok = await vm.deleteHistoryRecord(rec);
      expect(ok, isTrue);
      expect(api.lastDeletedProductionId, equals(rec.id));
      expect(vm.recentHistory, isEmpty);
      expect(vm.getQuantity(11, '12cm Electric Sparklers (WIP)'), equals(0));
    });

    test('persists preferred entry mode across reloads (defaults to matrix)', () async {
      await vm.loadInitialData();
      expect(vm.entryMode, equals(ProductionEntryMode.matrix));

      vm.setEntryMode(ProductionEntryMode.byWorker);
      expect(storage.getProductionEntryMode(), equals('byWorker'));

      final reloadedVm = DailyProductionViewModel(
        productionRepository: ProductionRepository(
          apiClient: api,
          storage: storage,
        ),
        employeeRepository: EmployeeRepository(apiClient: api),
      );
      addTearDown(reloadedVm.dispose);
      await reloadedVm.loadInitialData();
      expect(reloadedVm.entryMode, equals(ProductionEntryMode.byWorker));
    });

    test('worker search matches in English, Tamil, and bilingual formats', () async {
      api.employeesData.add({
        'id': 99,
        'name': 'Muthu (முத்து)',
        'role': 'Filling',
        'paymentType': 'Contractual',
        'status': 'Active',
        'advanceBalance': '0.00',
      });

      await vm.loadInitialData();

      // Search in lowercase English
      vm.setWorkerSearch('muthu');
      expect(vm.filteredWorkers.any((w) => w.id == 99), isTrue);

      // Search in uppercase English
      vm.setWorkerSearch('MUTHU');
      expect(vm.filteredWorkers.any((w) => w.id == 99), isTrue);

      // Search in Tamil script
      vm.setWorkerSearch('முத்து');
      expect(vm.filteredWorkers.any((w) => w.id == 99), isTrue);

      // Unrelated search excludes worker
      vm.setWorkerSearch('kaliappan');
      expect(vm.filteredWorkers.any((w) => w.id == 99), isFalse);
    });

    test('prioritizes fixed Tape, Chemical, and Valayam Contract roles with Tamil mappings', () async {
      api.employeesData.addAll([
        {
          'id': 101,
          'name': 'Abi (அபி)',
          'role': 'Tape',
          'paymentType': 'Contractual',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
        {
          'id': 102,
          'name': 'Muniyasamy (முனியசாமி)',
          'role': 'Chemical',
          'paymentType': 'Contractual',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
        {
          'id': 103,
          'name': 'Vasanth (வசந்த்)',
          'role': 'Valayam Contract',
          'paymentType': 'Contractual',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
        {
          'id': 104,
          'name': 'Karthi Appa (கார்த்தி அப்பா)',
          'role': 'Box Packing',
          'paymentType': 'Contractual',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
      ]);

      await vm.loadInitialData();

      // Check Tamil role translations
      expect(DailyProductionViewModel.getRoleTamilName('Tape'), equals('டேப்'));
      expect(DailyProductionViewModel.getRoleTamilName('Chemical'), equals('கெமிக்கல்'));
      expect(DailyProductionViewModel.getRoleTamilName('Valayam Contract'), equals('வளையம் ஒப்பந்தம்'));
      expect(DailyProductionViewModel.getRoleTamilName('Box Packing'), equals('பேக்கிங்'));

      // Check headcount calculation
      expect(vm.getWorkerCountForRole('Tape'), equals(1));
      expect(vm.getWorkerCountForRole('Chemical'), equals(1));
      expect(vm.getWorkerCountForRole('Valayam Contract'), equals(1));
      expect(vm.getWorkerCountForRole('Box Packing'), equals(1));

      // Available roles order: All, Tape, Chemical, Valayam Contract, then others (Packing, Rolling, Box Packing)
      final roles = vm.availableRoles;
      expect(roles[0], equals('All'));
      expect(roles[1], equals('Tape'));
      expect(roles[2], equals('Chemical'));
      expect(roles[3], equals('Valayam Contract'));

      // Filtered workers by role maintains the fixed canonical sequence
      final grouped = vm.filteredWorkersByRole;
      final roleKeys = grouped.keys.toList();
      expect(roleKeys[0], equals('Tape'));
      expect(roleKeys[1], equals('Chemical'));
      expect(roleKeys[2], equals('Valayam Contract'));

      // Role filter isolates workers cleanly
      vm.setRoleFilter('Chemical');
      expect(vm.filteredWorkers.length, equals(1));
      expect(vm.filteredWorkers.first.englishName, equals('Muniyasamy'));
    });

    test('Idea 2: isolates WIP product columns and subtotals by department/role', () async {
      api.employeesData.addAll([
        {
          'id': 101,
          'name': 'Abi (அபி)',
          'role': 'Tape',
          'paymentType': 'Contractual',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
        {
          'id': 102,
          'name': 'Muniyasamy (முனியசாமி)',
          'role': 'Chemical',
          'paymentType': 'Contractual',
          'status': 'Active',
          'advanceBalance': '0.00',
        },
      ]);
      api.productsData.addAll([
        {
          'id': 201,
          'code': 'TAPE-01',
          'name': '10 KVR 48 Tape',
          'type': 'WIP',
          'category': 'Tape',
          'unit': 'Pcs',
          'boxesPerCase': 1,
          'status': 'Active',
        },
        {
          'id': 202,
          'code': 'CHEM-01',
          'name': 'Red Dipping Chemical',
          'type': 'WIP',
          'category': 'Chemical',
          'unit': 'Pcs',
          'boxesPerCase': 1,
          'status': 'Active',
        },
      ]);

      await vm.loadInitialData();

      // Check smart initial mapping
      final tapeItems = vm.getActiveItemsForRole('Tape');
      final chemItems = vm.getActiveItemsForRole('Chemical');
      expect(tapeItems.contains('10 KVR 48 Tape'), isTrue);
      expect(tapeItems.contains('Red Dipping Chemical'), isFalse);
      expect(chemItems.contains('Red Dipping Chemical'), isTrue);
      expect(chemItems.contains('10 KVR 48 Tape'), isFalse);

      // Add a column specifically to Tape
      vm.addActiveItemForRole('Tape', 'Special Custom Tape (WIP)');
      expect(vm.getActiveItemsForRole('Tape').contains('Special Custom Tape (WIP)'), isTrue);
      expect(vm.getActiveItemsForRole('Chemical').contains('Special Custom Tape (WIP)'), isFalse);

      // Set quantities for Tape worker and Chemical worker
      vm.setQuantity(101, '10 KVR 48 Tape', 60);
      vm.setQuantity(101, 'Special Custom Tape (WIP)', 40);
      vm.setQuantity(102, 'Red Dipping Chemical', 35);

      // Verify department totals
      expect(vm.getRoleTotalQuantity('Tape'), equals(100));
      expect(vm.getRoleTotalQuantity('Chemical'), equals(35));
      expect(vm.getRoleItemTotalQuantity('Tape', '10 KVR 48 Tape'), equals(60));
      expect(vm.getRoleItemTotalQuantity('Tape', 'Special Custom Tape (WIP)'), equals(40));
      expect(vm.getRoleItemTotalQuantity('Chemical', 'Red Dipping Chemical'), equals(35));
      expect(vm.totalPiecesEntered, equals(135));

      // Remove column from Tape with clearDraft: true
      vm.removeActiveItemForRole('Tape', 'Special Custom Tape (WIP)', clearDraft: true);
      expect(vm.getActiveItemsForRole('Tape').contains('Special Custom Tape (WIP)'), isFalse);
      expect(vm.getQuantity(101, 'Special Custom Tape (WIP)'), equals(0));
      expect(vm.getRoleTotalQuantity('Tape'), equals(60));
      expect(vm.getRoleTotalQuantity('Chemical'), equals(35)); // Chemical remains intact
    });
  });
}

