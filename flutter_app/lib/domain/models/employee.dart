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
  });

  final int id;
  final String name;
  final String? mobile;
  final String? role;
  final String paymentType; // 'Monthly' | 'Contractual'
  final String? unit;
  final String status; // 'Active' | 'Inactive'
  final double advanceBalance;

  bool get isActive => status.toLowerCase() != 'inactive';
  bool get isContractual => paymentType.toLowerCase() == 'contractual';
  String get roleGroup => (role == null || role!.trim().isEmpty) ? 'Unassigned' : role!.trim();

  Employee copyWith({
    int? id,
    String? name,
    String? mobile,
    String? role,
    String? paymentType,
    String? unit,
    String? status,
    double? advanceBalance,
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
    );
  }

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      mobile: parseOptionalString(json['mobile']),
      role: parseOptionalString(json['role']),
      paymentType: (json['paymentType'] ?? 'Monthly').toString(),
      unit: parseOptionalString(json['unit']),
      status: (json['status'] ?? 'Active').toString(),
      advanceBalance: parseDouble(json['advanceBalance']),
    );
  }

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
}

