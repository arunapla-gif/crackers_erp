import 'json_helpers.dart';

class Employee {
  const Employee({
    required this.id,
    required this.name,
    this.mobile,
    this.role,
    required this.paymentType,
    this.employmentType = 'Regular',
    this.regularizedAt,
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
  final String employmentType; // 'Regular' | 'Temporary'
  final DateTime? regularizedAt;
  final String? unit;
  final String status; // 'Active' | 'Inactive'
  final double advanceBalance;
  final double? salary;

  bool get isActive => status.toLowerCase() != 'inactive';
  bool get isContractual => paymentType.toLowerCase() == 'contractual';
  bool get isTemporary => employmentType.toLowerCase() == 'temporary';
  bool get isRegular => !isTemporary;
  String get roleGroup =>
      (role == null || role!.trim().isEmpty) ? 'Unassigned' : role!.trim();

  Employee copyWith({
    int? id,
    String? name,
    String? mobile,
    String? role,
    String? paymentType,
    String? employmentType,
    DateTime? regularizedAt,
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
      employmentType: employmentType ?? this.employmentType,
      regularizedAt: regularizedAt ?? this.regularizedAt,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      advanceBalance: advanceBalance ?? this.advanceBalance,
      salary: salary ?? this.salary,
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    final rawSalary = json['salary'];
    final rawEmployment = (json['employmentType'] ?? 'Regular')
        .toString()
        .trim();
    final rawRegularized = json['regularizedAt'];
    return Employee(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      mobile: parseOptionalString(json['mobile']),
      role: parseOptionalString(json['role']),
      paymentType: (json['paymentType'] ?? 'Monthly').toString(),
      employmentType: rawEmployment.toLowerCase() == 'temporary'
          ? 'Temporary'
          : 'Regular',
      regularizedAt: rawRegularized == null
          ? null
          : DateTime.tryParse(rawRegularized.toString()),
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
      'employmentType': employmentType,
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
      'employmentType': employmentType,
      'unit': unit,
      'status': status,
    };
  }
}
