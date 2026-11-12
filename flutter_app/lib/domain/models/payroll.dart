import 'employee.dart';
import 'json_helpers.dart';

class PayrollDailyLogItem {
  const PayrollDailyLogItem({
    required this.itemName,
    required this.quantity,
    this.pieceRate = 0,
    this.total = 0,
  });

  final String itemName;
  final int quantity;
  final double pieceRate;
  final double total;

  factory PayrollDailyLogItem.fromJson(Map<String, dynamic> json) {
    return PayrollDailyLogItem(
      itemName: (json['itemName'] ?? '').toString().trim(),
      quantity: parseInt(json['quantity']),
      pieceRate: parseDouble(json['pieceRate']),
      total: parseDouble(json['total']),
    );
  }
}

class PayrollDailyLog {
  const PayrollDailyLog({
    required this.isoDate,
    required this.date,
    required this.totalAmount,
    required this.items,
  });

  final String isoDate;
  final DateTime date;
  final double totalAmount;
  final List<PayrollDailyLogItem> items;

  factory PayrollDailyLog.fromJson(Map<String, dynamic> json) {
    final d = parseDateTime(json['date']);
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(PayrollDailyLogItem.fromJson)
              .toList()
        : const <PayrollDailyLogItem>[];
    return PayrollDailyLog(
      isoDate: toIsoCalendarDate(d),
      date: d,
      totalAmount: parseDouble(json['totalAmount']),
      items: items,
    );
  }
}

class AggregateProductionResult {
  const AggregateProductionResult({
    required this.totalAmount,
    required this.details,
  });

  final double totalAmount;
  final List<PayrollDailyLog> details;

  factory AggregateProductionResult.fromJson(Map<String, dynamic> json) {
    final rawDetails = json['details'];
    final details = rawDetails is List
        ? rawDetails
              .whereType<Map<String, dynamic>>()
              .map(PayrollDailyLog.fromJson)
              .toList()
        : const <PayrollDailyLog>[];
    return AggregateProductionResult(
      totalAmount: parseDouble(json['totalAmount']),
      details: details,
    );
  }
}

class PayrollWorksheetRow {
  const PayrollWorksheetRow({
    required this.employee,
    required this.basicSalary,
    required this.allowance,
    required this.deduction,
    required this.advanceBalance,
    required this.netSalary,
    required this.status,
    this.productQuantities = const {},
    this.dailyLogs = const [],
  });

  final Employee employee;
  final double basicSalary;
  final double allowance;
  final double deduction;
  final double advanceBalance;
  final double netSalary;
  final String status; // 'Paid' | 'Pending'
  final Map<String, int> productQuantities;
  final List<PayrollDailyLog> dailyLogs;

  PayrollWorksheetRow copyWith({
    Employee? employee,
    double? basicSalary,
    double? allowance,
    double? deduction,
    double? advanceBalance,
    double? netSalary,
    String? status,
    Map<String, int>? productQuantities,
    List<PayrollDailyLog>? dailyLogs,
  }) {
    return PayrollWorksheetRow(
      employee: employee ?? this.employee,
      basicSalary: basicSalary ?? this.basicSalary,
      allowance: allowance ?? this.allowance,
      deduction: deduction ?? this.deduction,
      advanceBalance: advanceBalance ?? this.advanceBalance,
      netSalary: netSalary ?? this.netSalary,
      status: status ?? this.status,
      productQuantities: productQuantities ?? this.productQuantities,
      dailyLogs: dailyLogs ?? this.dailyLogs,
    );
  }
}

class PayrollRecord {
  const PayrollRecord({
    required this.id,
    required this.employeeId,
    this.employeeName,
    this.employeeRole,
    required this.month,
    required this.paymentType,
    required this.daysWorked,
    required this.basicSalary,
    required this.allowance,
    required this.deduction,
    required this.netSalary,
    required this.status,
  });

  final int id;
  final int employeeId;
  final String? employeeName;
  final String? employeeRole;
  final String month;
  final String paymentType;
  final int daysWorked;
  final double basicSalary;
  final double allowance;
  final double deduction;
  final double netSalary;
  final String status;

  factory PayrollRecord.fromJson(Map<String, dynamic> json) {
    final empRaw = json['employee'];
    return PayrollRecord(
      id: parseInt(json['id']),
      employeeId: parseInt(json['employeeId']),
      employeeName: empRaw is Map<String, dynamic>
          ? parseOptionalString(empRaw['name'])
          : null,
      employeeRole: empRaw is Map<String, dynamic>
          ? parseOptionalString(empRaw['role'])
          : null,
      month: (json['month'] ?? '').toString(),
      paymentType: (json['paymentType'] ?? 'Monthly').toString(),
      daysWorked: parseInt(json['daysWorked']),
      basicSalary: parseDouble(json['basicSalary']),
      allowance: parseDouble(json['allowance']),
      deduction: parseDouble(json['deduction']),
      netSalary: parseDouble(json['netSalary']),
      status: (json['status'] ?? 'Paid').toString(),
    );
  }
}

