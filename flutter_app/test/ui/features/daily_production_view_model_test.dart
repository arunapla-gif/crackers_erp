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
  });
}

