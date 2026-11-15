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

    test('persists preferred entry mode across reloads', () async {
      await vm.loadInitialData();
      expect(vm.entryMode, equals(ProductionEntryMode.byItem));

      vm.setEntryMode(ProductionEntryMode.matrix);
      expect(storage.getProductionEntryMode(), equals('matrix'));

      final reloadedVm = DailyProductionViewModel(
        productionRepository: ProductionRepository(
          apiClient: api,
          storage: storage,
        ),
        employeeRepository: EmployeeRepository(apiClient: api),
      );
      addTearDown(reloadedVm.dispose);
      await reloadedVm.loadInitialData();
      expect(reloadedVm.entryMode, equals(ProductionEntryMode.matrix));
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
  });
}

