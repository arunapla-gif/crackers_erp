import 'json_helpers.dart';

class ProductionItemEntry {
  const ProductionItemEntry({
    required this.itemName,
    required this.quantity,
  });

  final String itemName;
  final int quantity;

  factory ProductionItemEntry.fromJson(Map<String, dynamic> json) {
    return ProductionItemEntry(
      itemName: (json['itemName'] ?? '').toString().trim(),
      quantity: parseInt(json['quantity']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemName': itemName,
      'quantity': quantity,
    };
  }
}

class DailyProductionRecord {
  const DailyProductionRecord({
    required this.id,
    required this.date,
    required this.employeeId,
    required this.employeeName,
    this.employeeRole,
    required this.items,
  });

  final int id;
  final DateTime date;
  final int employeeId;
  final String employeeName;
  final String? employeeRole;
  final List<ProductionItemEntry> items;

  String get isoDate => toIsoCalendarDate(date);
  int get totalPieces => items.fold(0, (sum, item) => sum + item.quantity);

  factory DailyProductionRecord.fromJson(Map<String, dynamic> json) {
    final empRaw = json['employee'];
    final empMap = empRaw is Map<String, dynamic> ? empRaw : null;
    final rawItems = json['items'] is List<dynamic> ? json['items'] as List<dynamic> : <dynamic>[];

    return DailyProductionRecord(
      id: parseInt(json['id']),
      date: parseDateTime(json['date']),
      employeeId: parseInt(json['employeeId']),
      employeeName: (empMap?['name'] ?? 'Employee #${json['employeeId']}').toString(),
      employeeRole: parseOptionalString(empMap?['role']),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(ProductionItemEntry.fromJson)
          .where((item) => item.itemName.isNotEmpty && item.quantity > 0)
          .toList(),
    );
  }
}

