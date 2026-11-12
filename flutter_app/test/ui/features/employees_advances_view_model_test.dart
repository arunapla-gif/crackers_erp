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

    test('supports Temporary category filtering and Admin conversion', () async {
      api
        ..roleToLogin = 'ADMIN'
        ..employeesData.add({
          'id': 20,
          'name': 'Karthik Temp',
          'mobile': '9842100099',
          'role': 'Packing',
          'paymentType': 'Contractual',
          'employmentType': 'Temporary',
          'unit': 'Unit 2',
          'status': 'Active',
          'advanceBalance': '200.00',
          'salary': 18,
        });

      await vm.loadAll();
      expect(vm.temporaryActiveCount, equals(1));
      expect(vm.regularActiveCount, equals(3));

      vm.setEmploymentTypeFilter('Temporary');
      expect(vm.filteredEmployees.length, equals(1));
      expect(vm.filteredEmployees.first.name, equals('Karthik Temp'));
      expect(vm.filteredEmployees.first.isTemporary, isTrue);

      final converted = await vm.convertToRegular(
        employee: vm.filteredEmployees.first,
        paymentType: 'Monthly',
        salary: 14000,
      );
      expect(converted, isTrue);

      final refreshed = vm.employees.firstWhere((e) => e.id == 20);
      expect(refreshed.isTemporary, isFalse);
      expect(refreshed.employmentType, equals('Regular'));
      expect(refreshed.paymentType, equals('Monthly'));
      expect(refreshed.salary, equals(14000.0));
      expect(refreshed.advanceBalance, equals(200.0));
    });
  });
}

