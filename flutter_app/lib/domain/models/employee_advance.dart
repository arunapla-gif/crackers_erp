import 'json_helpers.dart';

class EmployeeAdvance {
  const EmployeeAdvance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.type,
    required this.amount,
    this.description,
    this.employeeName,
    this.employeeRole,
    this.employeeBalance,
  });

  final int id;
  final int employeeId;
  final DateTime date;
  final String type; // 'GIVEN' | 'RECOVERED'
  final double amount;
  final String? description;
  final String? employeeName;
  final String? employeeRole;
  final double? employeeBalance;

  bool get isGiven => type.toUpperCase() == 'GIVEN';
  bool get isRecovered => type.toUpperCase() == 'RECOVERED';

  factory EmployeeAdvance.fromJson(Map<String, dynamic> json) {
    final empRaw = json['employee'];
    final empMap = empRaw is Map<String, dynamic> ? empRaw : null;

    return EmployeeAdvance(
      id: parseInt(json['id']),
      employeeId: parseInt(json['employeeId']),
      date: parseDateTime(json['date']),
      type: (json['type'] ?? 'GIVEN').toString(),
      amount: parseDouble(json['amount']),
      description: parseOptionalString(json['description']),
      employeeName: parseOptionalString(empMap?['name']),
      employeeRole: parseOptionalString(empMap?['role']),
      employeeBalance: empMap != null ? parseDouble(empMap['advanceBalance']) : null,
    );
  }
}

