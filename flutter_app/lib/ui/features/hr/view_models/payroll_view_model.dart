import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:crackers_erp/core/utils/product_sorting.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/data/repositories/payroll_repository.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import 'package:crackers_erp/domain/models/payroll.dart';

class PayrollTotals {
  const PayrollTotals({
    this.basic = 0,
    this.allowance = 0,
    this.deduction = 0,
    this.net = 0,
    this.productTotals = const {},
  });

  final double basic;
  final double allowance;
  final double deduction;
  final double net;
  final Map<String, int> productTotals;
}

class PayrollViewModel extends ChangeNotifier {
  PayrollViewModel({
    required EmployeeRepository employeeRepository,
    required PayrollRepository payrollRepository,
  }) : _employeeRepository = employeeRepository,
       _payrollRepository = payrollRepository;

  final EmployeeRepository _employeeRepository;
  final PayrollRepository _payrollRepository;

  DateTime? _payoutDate;
  DateTime? _startDate;
  DateTime? _endDate;

  List<Employee> _employees = const [];
  List<PayrollRecord> _payrolls = const [];
  Map<int, PayrollWorksheetRow> _rowsByEmpId = <int, PayrollWorksheetRow>{};
  List<String> _uniqueProducts = const [];
  final Set<int> _expandedEmployeeIds = <int>{};

  bool _isLoading = false;
  bool _isCalculating = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _statusMessage;
  bool _disposed = false;

  DateTime? get payoutDate => _payoutDate;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  String? get isoPayoutDate =>
      _payoutDate == null ? null : toIsoCalendarDate(_payoutDate!);
  String? get isoStartDate =>
      _startDate == null ? null : toIsoCalendarDate(_startDate!);
  String? get isoEndDate =>
      _endDate == null ? null : toIsoCalendarDate(_endDate!);

  bool get isPayoutSaturday =>
      _payoutDate == null || _payoutDate!.weekday == DateTime.saturday;

  List<Employee> get employees => _employees;
  List<PayrollRecord> get payrolls => _payrolls;
  List<String> get uniqueProducts => _uniqueProducts;
  Set<int> get expandedEmployeeIds => _expandedEmployeeIds;

  bool get isLoading => _isLoading;
  bool get isCalculating => _isCalculating;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  Map<String, List<Employee>> get employeesByRole {
    final grouped = SplayTreeMap<String, List<Employee>>(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    for (final emp in _employees) {
      grouped.putIfAbsent(emp.roleGroup, () => <Employee>[]).add(emp);
    }
    return grouped;
  }

  PayrollWorksheetRow? rowFor(int empId) => _rowsByEmpId[empId];

  bool isExpanded(int empId) => _expandedEmployeeIds.contains(empId);

  PayrollTotals totalsForRole(String role) {
    final list = employeesByRole[role] ?? const <Employee>[];
    return _aggregateRows(list.map((e) => _rowsByEmpId[e.id]).whereType<PayrollWorksheetRow>());
  }

  PayrollTotals get grandTotals => _aggregateRows(_rowsByEmpId.values);

  PayrollTotals _aggregateRows(Iterable<PayrollWorksheetRow> rows) {
    var basic = 0.0;
    var allowance = 0.0;
    var deduction = 0.0;
    var net = 0.0;
    final prodTotals = <String, int>{};

    for (final row in rows) {
      basic += row.basicSalary;
      allowance += row.allowance;
      deduction += row.deduction;
      net += row.netSalary;
      for (final prod in _uniqueProducts) {
        final q = row.productQuantities[prod] ?? 0;
        if (q > 0) {
          prodTotals[prod] = (prodTotals[prod] ?? 0) + q;
        }
      }
    }

    return PayrollTotals(
      basic: double.parse(basic.toStringAsFixed(2)),
      allowance: double.parse(allowance.toStringAsFixed(2)),
      deduction: double.parse(deduction.toStringAsFixed(2)),
      net: double.parse(net.toStringAsFixed(2)),
      productTotals: prodTotals,
    );
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final results = await Future.wait<dynamic>([
        _employeeRepository.fetchEmployees(),
        _payrollRepository.fetchPayrolls(),
      ]);

      final allEmps = results[0] as List<Employee>;
      _employees = allEmps.where((e) => e.isActive).toList();
      _payrolls = results[1] as List<PayrollRecord>;
      _rebuildInitialRows();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load payroll data.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void _rebuildInitialRows() {
    final nextRows = <int, PayrollWorksheetRow>{};
    for (final emp in _employees) {
      final basic = emp.paymentType == 'Monthly' ? (emp.salary ?? 0.0) : 0.0;
      nextRows[emp.id] = PayrollWorksheetRow(
        employee: emp,
        basicSalary: basic,
        allowance: 0.0,
        deduction: 0.0,
        advanceBalance: emp.advanceBalance,
        netSalary: basic,
        status: 'Paid',
      );
    }
    _rowsByEmpId = nextRows;
  }

  void setPayoutDate(DateTime date) {
    final clean = DateTime(date.year, date.month, date.day);
    _payoutDate = clean;
    final end = DateTime(clean.year, clean.month, clean.day - 2); // Thursday
    final start = DateTime(end.year, end.month, end.day - 6); // Friday
    _endDate = end;
    _startDate = start;
    _errorMessage = null;
    _safeNotify();
  }

  void setStartDate(DateTime date) {
    _startDate = DateTime(date.year, date.month, date.day);
    _safeNotify();
  }

  void setEndDate(DateTime date) {
    _endDate = DateTime(date.year, date.month, date.day);
    _safeNotify();
  }

  void toggleExpanded(int empId) {
    if (_expandedEmployeeIds.contains(empId)) {
      _expandedEmployeeIds.remove(empId);
    } else {
      _expandedEmployeeIds.add(empId);
    }
    _safeNotify();
  }

  void updateRow(
    int empId, {
    double? basicSalary,
    double? allowance,
    double? deduction,
    String? status,
  }) {
    final existing = _rowsByEmpId[empId];
    if (existing == null) return;
    final nextBasic = basicSalary ?? existing.basicSalary;
    final nextAllow = allowance ?? existing.allowance;
    final nextDeduct = deduction ?? existing.deduction;
    final nextNet = double.parse(
      (nextBasic + nextAllow - nextDeduct).toStringAsFixed(2),
    );
    _rowsByEmpId[empId] = existing.copyWith(
      basicSalary: nextBasic,
      allowance: nextAllow,
      deduction: nextDeduct,
      netSalary: nextNet,
      status: status ?? existing.status,
    );
    _safeNotify();
  }

  Future<bool> calculateContractualWages() async {
    if (_startDate == null || _endDate == null) {
      _errorMessage = 'Please select a Payout Date first.';
      _safeNotify();
      return false;
    }

    _isCalculating = true;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      final contractual = _employees.where((e) => e.isContractual).toList();
      final results = await Future.wait(
        contractual.map((emp) async {
          final data = await _payrollRepository.fetchAggregateProduction(
            employeeId: emp.id,
            startDate: isoStartDate!,
            endDate: isoEndDate!,
          );
          return (empId: emp.id, result: data);
        }),
      );

      final allProducts = <String>{};

      for (final entry in results) {
        final existing = _rowsByEmpId[entry.empId];
        if (existing == null) continue;

        final prodQuantities = <String, int>{};
        final groupedByDay = <String, ({DateTime date, double total, Map<String, int> items})>{};

        for (final log in entry.result.details) {
          final dayKey = log.isoDate;
          final currentDay = groupedByDay[dayKey];
          final itemsMap = currentDay?.items ?? <String, int>{};
          final nextTotal = (currentDay?.total ?? 0.0) + log.totalAmount;

          for (final item in log.items) {
            if (item.quantity <= 0 || item.itemName.trim().isEmpty) continue;
            allProducts.add(item.itemName);
            prodQuantities[item.itemName] =
                (prodQuantities[item.itemName] ?? 0) + item.quantity;
            itemsMap[item.itemName] = (itemsMap[item.itemName] ?? 0) + item.quantity;
          }

          groupedByDay[dayKey] = (
            date: log.date,
            total: nextTotal,
            items: itemsMap,
          );
        }

        final processedLogs = groupedByDay.entries.map((e) {
          return PayrollDailyLog(
            isoDate: e.key,
            date: e.value.date,
            totalAmount: double.parse(e.value.total.toStringAsFixed(2)),
            items: e.value.items.entries
                .map(
                  (itemEntry) => PayrollDailyLogItem(
                    itemName: itemEntry.key,
                    quantity: itemEntry.value,
                  ),
                )
                .toList(),
          );
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        final basic = double.parse(
          entry.result.totalAmount.toStringAsFixed(2),
        );
        final net = double.parse(
          (basic + existing.allowance - existing.deduction).toStringAsFixed(2),
        );

        _rowsByEmpId[entry.empId] = existing.copyWith(
          basicSalary: basic,
          netSalary: net,
          productQuantities: prodQuantities,
          dailyLogs: processedLogs,
        );
      }

      final sortedProds = allProducts.toList()..sort(naturalCompareStrings);
      _uniqueProducts = sortedProds;
      _statusMessage =
          'Weekly wages & piece counts calculated for ${contractual.length} contractual workers.';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to fetch aggregate production wages.';
      return false;
    } finally {
      _isCalculating = false;
      _safeNotify();
    }
  }

  Future<void> clearGrid() async {
    _payoutDate = null;
    _startDate = null;
    _endDate = null;
    _uniqueProducts = const [];
    _expandedEmployeeIds.clear();
    _statusMessage = null;
    _errorMessage = null;
    await loadAll();
  }

  Future<bool> saveBulkPayroll() async {
    if (_payoutDate == null) {
      _errorMessage = 'Payout Date is required.';
      _safeNotify();
      return false;
    }

    final periodLabel = (_startDate != null && _endDate != null)
        ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} to ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
        : isoPayoutDate!;

    final payloads = <Map<String, dynamic>>[];
    for (final row in _rowsByEmpId.values) {
      if (row.netSalary > 0 || row.basicSalary > 0) {
        payloads.add({
          'employeeId': row.employee.id,
          'month': isoPayoutDate,
          'paymentType': row.employee.paymentType,
          'daysWorked': 0,
          'basicSalary': row.basicSalary,
          'allowance': row.allowance,
          'deduction': row.deduction,
          'netSalary': row.netSalary,
          'status': row.status,
          'periodStr': periodLabel,
        });
      }
    }

    if (payloads.isEmpty) {
      _errorMessage =
          'No valid payroll records to save (Net Salary or Base Wage > 0 required).';
      _safeNotify();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      await Future.wait(payloads.map(_payrollRepository.savePayroll));
      _payoutDate = null;
      _startDate = null;
      _endDate = null;
      _uniqueProducts = const [];
      _expandedEmployeeIds.clear();

      final results = await Future.wait<dynamic>([
        _employeeRepository.fetchEmployees(),
        _payrollRepository.fetchPayrolls(),
      ]);
      final allEmps = results[0] as List<Employee>;
      _employees = allEmps.where((e) => e.isActive).toList();
      _payrolls = results[1] as List<PayrollRecord>;
      _rebuildInitialRows();

      _statusMessage =
          'Saved ${payloads.length} payroll entries! Advance balances updated.';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to save bulk payroll.';
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  void clearMessages() {
    if (_errorMessage != null || _statusMessage != null) {
      _errorMessage = null;
      _statusMessage = null;
      _safeNotify();
    }
  }

  void reset() {
    _payoutDate = null;
    _startDate = null;
    _endDate = null;
    _employees = const [];
    _payrolls = const [];
    _rowsByEmpId = <int, PayrollWorksheetRow>{};
    _uniqueProducts = const [];
    _expandedEmployeeIds.clear();
    _isLoading = false;
    _isCalculating = false;
    _isSaving = false;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

