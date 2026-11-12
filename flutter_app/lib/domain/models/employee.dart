import 'json_helpers.dart';

class Employee {
  const Employee({
    required this.id,
    required this.name,
    this.mobile,
    this.role,
    required this.paymentType,
    this.unit,
    required this.status,
    required this.advanceBalance,
    this.salary,
  });

  final int id;
  final String name;
  final String? mobile;
  final String? role;
  final String paymentType; // 'Monthly' | 'Contractual'
  final String? unit;
  final String status; // 'Active' | 'Inactive'
  final double advanceBalance;
  final double? salary;

  bool get isActive => status.toLowerCase() != 'inactive';
  bool get isContractual => paymentType.toLowerCase() == 'contractual';
  String get roleGroup =>
      (role == null || role!.trim().isEmpty) ? 'Unassigned' : role!.trim();

  Employee copyWith({
    int? id,
    String? name,
    String? mobile,
    String? role,
    String? paymentType,
    String? unit,
    String? status,
    double? advanceBalance,
    double? salary,
  }) {
    return Employee(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      role: role ?? this.role,
      paymentType: paymentType ?? this.paymentType,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      advanceBalance: advanceBalance ?? this.advanceBalance,
      salary: salary ?? this.salary,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    final rawSalary = json['salary'];
    return Employee(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      mobile: parseOptionalString(json['mobile']),
      role: parseOptionalString(json['role']),
      paymentType: (json['paymentType'] ?? 'Monthly').toString(),
      unit: parseOptionalString(json['unit']),
      status: (json['status'] ?? 'Active').toString(),
      advanceBalance: parseDouble(json['advanceBalance']),
      salary: rawSalary == null ? null : parseDouble(rawSalary),
    );
  }

  /// Rate-free payload strictly preserving Supervisor privacy.
  Map<String, dynamic> toSupervisorPayload() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      'mobile': mobile,
      'role': role,
      'paymentType': paymentType,
      'unit': unit,
      'status': status,
    };
  }

  /// Full payload used by Admin/HR Staff when setting salaries/piece rates.
  Map<String, dynamic> toAdminPayload() {
    return {
      if (id > 0) 'id': id,
      'name': name,
      'mobile': mobile,
      'role': role,
      'salary': salary ?? 0,
      'paymentType': paymentType,
      'unit': unit,
      'status': status,
    };
  }
}
