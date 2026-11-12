import 'package:flutter/foundation.dart';

import '../../domain/models/employee.dart';
import '../../domain/models/employee_advance.dart';
import '../services/api_client.dart';

List<Employee> _parseEmployees(List<dynamic> rawList) {
  final list = rawList
      .whereType<Map<String, dynamic>>()
      .map(Employee.fromJson)
      .toList();
  list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

List<EmployeeAdvance> _parseAdvances(List<dynamic> rawList) {
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(EmployeeAdvance.fromJson)
      .toList();
}

class EmployeeRepository {
  EmployeeRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Employee>> fetchEmployees() async {
    final raw = await _apiClient.getEmployees();
    if (raw.length < 60) return _parseEmployees(raw);
    return compute(_parseEmployees, raw);
  }

  Future<Employee> saveEmployee(Employee employee) async {
    final raw = await _apiClient.saveEmployee(employee.toSupervisorPayload());
    return Employee.fromJson(raw);
  }

  Future<Employee> saveEmployeeAdmin(Employee employee) async {
    final raw = await _apiClient.saveEmployee(employee.toAdminPayload());
    return Employee.fromJson(raw);
  }

  Future<void> deleteEmployee(int id) async {
    await _apiClient.deleteEmployee(id);
  }

  Future<List<EmployeeAdvance>> fetchRecentAdvances({int limit = 80}) async {
    final raw = await _apiClient.getRecentAdvances(limit: limit);
    if (raw.length < 60) return _parseAdvances(raw);
    return compute(_parseAdvances, raw);
  }

  Future<List<EmployeeAdvance>> fetchEmployeeAdvances(int employeeId) async {
    final raw = await _apiClient.getEmployeeAdvances(employeeId);
    if (raw.length < 60) return _parseAdvances(raw);
    return compute(_parseAdvances, raw);
  }

  Future<EmployeeAdvance> giveAdvance({
    required int employeeId,
    required String date,
    required double amount,
    String? description,
  }) async {
    final raw = await _apiClient.giveAdvance(
      employeeId: employeeId,
      date: date,
      amount: amount,
      description: description,
    );
    return EmployeeAdvance.fromJson(raw);
  }
}
