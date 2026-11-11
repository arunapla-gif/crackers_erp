import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/ui/features/employees/view_models/employees_advances_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fakes.dart';

void main() {
  group('EmployeesAdvancesViewModel', () {
    late FakeApiClient api;
    late EmployeesAdvancesViewModel vm;

    setUp(() {
      api = FakeApiClient();
      vm = EmployeesAdvancesViewModel(
        employeeRepository: EmployeeRepository(apiClient: api),
      );
    });

    tearDown(() => vm.dispose());

    test('loads employees and computes active/advance summaries', () async {
      await vm.loadAll();
      expect(vm.employees.length, equals(3));
      expect(vm.activeWorkersCount, equals(3));
      expect(vm.contractualActiveCount, equals(2));
      expect(vm.totalAdvanceOutstanding, equals(1500.0));
    });

    test('filters by search query and payment type', () async {
      await vm.loadAll();
      vm.setPaymentTypeFilter('Contractual');
      expect(vm.filteredEmployees.length, equals(2));

      vm.setSearchQuery('Selvi');
      expect(vm.filteredEmployees.length, equals(1));
      expect(vm.filteredEmployees.first.name, equals('Selvi R'));
    });

    test('adds worker without sending any salary field', () async {
      await vm.loadAll();
      final ok = await vm.saveEmployee(
        name: 'Murugan P',
        mobile: '9988776655',
        role: 'Filling',
        paymentType: 'Contractual',
        unit: 'Unit 1',
        status: 'Active',
      );

      expect(ok, isTrue);
      expect(api.lastSavedEmployeePayload?.containsKey('salary'), isFalse);
      expect(vm.employees.any((e) => e.name == 'Murugan P'), isTrue);
    });

    test('records positive cash advance and updates employee balance', () async {
      await vm.loadAll();
      final selvi = vm.employees.firstWhere((e) => e.id == 12);
      expect(selvi.advanceBalance, equals(0.0));

      final invalid = await vm.giveAdvance(
        employee: selvi,
        date: DateTime(2026, 11, 11),
        amount: 0,
      );
      expect(invalid, isFalse);
      expect(vm.errorMessage, isNotNull);

      final ok = await vm.giveAdvance(
        employee: selvi,
        date: DateTime(2026, 11, 11),
        amount: 750,
        description: 'Festival Advance',
      );
      expect(ok, isTrue);
      final updatedSelvi = vm.employees.firstWhere((e) => e.id == 12);
      expect(updatedSelvi.advanceBalance, equals(750.0));
      expect(vm.advancesForEmployee(12).first.amount, equals(750.0));
    });
  });
}

