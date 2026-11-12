import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/domain/models/employee_advance.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';

class EmployeesAdvancesViewModel extends ChangeNotifier {
  EmployeesAdvancesViewModel({required EmployeeRepository employeeRepository})
    : _employeeRepository = employeeRepository;

  final EmployeeRepository _employeeRepository;

  List<Employee> _employees = const [];
  List<EmployeeAdvance> _recentAdvances = const [];
  final Map<int, List<EmployeeAdvance>> _advancesByEmployee =
      <int, List<EmployeeAdvance>>{};

  String _searchQuery = '';
  String _roleFilter = 'All';
  String _paymentTypeFilter = 'All'; // All | Contractual | Monthly
  bool _activeOnly = true;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLoadingEmployeeAdvances = false;
  String? _errorMessage;
  String? _statusMessage;
  bool _disposed = false;

  List<Employee> get employees => _employees;
  List<EmployeeAdvance> get recentAdvances => _recentAdvances;
  String get searchQuery => _searchQuery;
  String get roleFilter => _roleFilter;
  String get paymentTypeFilter => _paymentTypeFilter;
  bool get activeOnly => _activeOnly;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLoadingEmployeeAdvances => _isLoadingEmployeeAdvances;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  List<String> get availableRoles {
    final roles = SplayTreeSet<String>.from(
      _employees.map((e) => e.roleGroup),
    );
    return ['All', ...roles];
  }

  List<Employee> get filteredEmployees {
    final q = _searchQuery.trim().toLowerCase();
    return _employees.where((emp) {
      if (_activeOnly && !emp.isActive) return false;
      if (_roleFilter != 'All' && emp.roleGroup != _roleFilter) return false;
      if (_paymentTypeFilter != 'All' &&
          emp.paymentType.toLowerCase() != _paymentTypeFilter.toLowerCase()) {
        return false;
      }
      if (q.isEmpty) return true;
      return emp.name.toLowerCase().contains(q) ||
          (emp.mobile ?? '').toLowerCase().contains(q) ||
          emp.roleGroup.toLowerCase().contains(q) ||
          (emp.unit ?? '').toLowerCase().contains(q);
    }).toList();
  }

  int get activeWorkersCount => _employees.where((e) => e.isActive).length;
  int get contractualActiveCount =>
      _employees.where((e) => e.isActive && e.isContractual).length;
  double get totalAdvanceOutstanding =>
      _employees.fold(0.0, (sum, e) => sum + e.advanceBalance);

  List<EmployeeAdvance> advancesForEmployee(int employeeId) {
    return _advancesByEmployee[employeeId] ?? const [];
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final results = await Future.wait<dynamic>([
        _employeeRepository.fetchEmployees(),
        _employeeRepository.fetchRecentAdvances(limit: 80),
      ]);
      _employees = results[0] as List<Employee>;
      _recentAdvances = results[1] as List<EmployeeAdvance>;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load workers and advances.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    _safeNotify();
  }

  void setRoleFilter(String role) {
    _roleFilter = role;
    _safeNotify();
  }

  void setPaymentTypeFilter(String type) {
    _paymentTypeFilter = type;
    _safeNotify();
  }

  void setActiveOnly(bool value) {
    _activeOnly = value;
    _safeNotify();
  }

  Future<bool> saveEmployee({
    int? id,
    required String name,
    String? mobile,
    String? role,
    required String paymentType,
    String? unit,
    required String status,
    double? salary,
    bool includeSalary = false,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Worker name is required.';
      _safeNotify();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      final emp = Employee(
        id: id ?? 0,
        name: trimmedName,
        mobile: parseOptionalString(mobile),
        role: parseOptionalString(role),
        paymentType: paymentType,
        unit: parseOptionalString(unit),
        status: status,
        advanceBalance: 0,
        salary: includeSalary ? (salary ?? 0) : null,
      );

      final saved = includeSalary
          ? await _employeeRepository.saveEmployeeAdmin(emp)
          : await _employeeRepository.saveEmployee(emp);

      final updatedList = List<Employee>.from(_employees);
      final idx = updatedList.indexWhere((e) => e.id == saved.id);
      if (idx >= 0) {
        updatedList[idx] = saved;
      } else {
        updatedList.add(saved);
      }
      updatedList.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _employees = updatedList;
      _statusMessage = id == null
          ? 'Added worker "${saved.name}".'
          : 'Updated "${saved.name}".';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to save worker details.';
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  Future<bool> toggleEmployeeStatus(
    Employee employee, {
    bool includeSalary = false,
  }) {
    final nextStatus = employee.isActive ? 'Inactive' : 'Active';
    return saveEmployee(
      id: employee.id,
      name: employee.name,
      mobile: employee.mobile,
      role: employee.role,
      paymentType: employee.paymentType,
      unit: employee.unit,
      status: nextStatus,
      salary: employee.salary,
      includeSalary: includeSalary,
    );
  }

  Future<bool> deleteEmployee(Employee employee) async {
    _isSaving = true;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      await _employeeRepository.deleteEmployee(employee.id);
      _employees = _employees.where((e) => e.id != employee.id).toList();
      _advancesByEmployee.remove(employee.id);
      _statusMessage = 'Deleted employee "${employee.name}".';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to delete employee.';
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  Future<void> loadEmployeeAdvances(int employeeId) async {
    _isLoadingEmployeeAdvances = true;
    _safeNotify();

    try {
      final list = await _employeeRepository.fetchEmployeeAdvances(employeeId);
      _advancesByEmployee[employeeId] = list;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load worker advance ledger.';
    } finally {
      _isLoadingEmployeeAdvances = false;
      _safeNotify();
    }
  }

  Future<bool> giveAdvance({
    required Employee employee,
    required DateTime date,
    required double amount,
    String? description,
  }) async {
    if (amount <= 0) {
      _errorMessage = 'Enter a valid positive advance amount.';
      _safeNotify();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      await _employeeRepository.giveAdvance(
        employeeId: employee.id,
        date: toIsoCalendarDate(date),
        amount: amount,
        description: description,
      );

      final results = await Future.wait<dynamic>([
        _employeeRepository.fetchEmployees(),
        _employeeRepository.fetchRecentAdvances(limit: 80),
        _employeeRepository.fetchEmployeeAdvances(employee.id),
      ]);
      _employees = results[0] as List<Employee>;
      _recentAdvances = results[1] as List<EmployeeAdvance>;
      _advancesByEmployee[employee.id] = results[2] as List<EmployeeAdvance>;
      _statusMessage =
          'Issued ₹${amount.toStringAsFixed(0)} advance to ${employee.name}.';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to record cash advance.';
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
    _employees = const [];
    _recentAdvances = const [];
    _advancesByEmployee.clear();
    _searchQuery = '';
    _roleFilter = 'All';
    _paymentTypeFilter = 'All';
    _activeOnly = true;
    _isLoading = false;
    _isSaving = false;
    _isLoadingEmployeeAdvances = false;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
