import 'json_helpers.dart';

class FactoryOrderItem {
  const FactoryOrderItem({
    this.productId,
    required this.product,
    required this.qty,
    this.unit,
    this.boxesPerCase = 1,
  });

  final int? productId;
  final String product;
  final int qty;
  final String? unit;
  final int boxesPerCase;

  int get totalBoxes => qty * (boxesPerCase > 0 ? boxesPerCase : 1);

  factory FactoryOrderItem.fromJson(Map<String, dynamic> json) {
    return FactoryOrderItem(
      productId: json['productId'] != null ? parseInt(json['productId']) : null,
      product: (json['product'] ?? '').toString().trim(),
      qty: parseInt(json['qty']),
      unit: parseOptionalString(json['unit']),
      boxesPerCase: parseInt(json['boxesPerCase'], fallback: 1),
    );
  }
}

class FactoryOrder {
  const FactoryOrder({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.customerName,
    this.customerCity,
    this.customerState,
    this.repUsername,
    required this.items,
  });

  final int id;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String customerName;
  final String? customerCity;
  final String? customerState;
  final String? repUsername;
  final List<FactoryOrderItem> items;

  int get totalCases => items.fold(0, (sum, item) => sum + item.qty);

  String get locationLabel {
    final parts = [customerCity, customerState]
        .where((e) => e != null && e.trim().isNotEmpty)
        .map((e) => e!.trim())
        .toList();
    return parts.join(', ');
  }

  factory FactoryOrder.fromJson(Map<String, dynamic> json) {
    final custRaw = json['customer'];
    final custMap = custRaw is Map<String, dynamic> ? custRaw : null;
    final newCustRaw = json['newCustomerData'];
    final newCustMap = newCustRaw is Map<String, dynamic> ? newCustRaw : null;
    final repRaw = json['rep'];
    final repMap = repRaw is Map<String, dynamic> ? repRaw : null;
    final rawItems = json['items'] is List<dynamic> ? json['items'] as List<dynamic> : <dynamic>[];

    return FactoryOrder(
      id: parseInt(json['id']),
      status: (json['status'] ?? 'APPROVED').toString(),
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
      customerName:
          parseOptionalString(custMap?['name']) ??
          parseOptionalString(newCustMap?['name']) ??
          'Walk-in / Unlinked Customer',
      customerCity:
          parseOptionalString(custMap?['city']) ??
          parseOptionalString(newCustMap?['city']),
      customerState:
          parseOptionalString(custMap?['state']) ??
          parseOptionalString(newCustMap?['state']),
      repUsername: parseOptionalString(repMap?['username']),
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(FactoryOrderItem.fromJson)
          .toList(),
    );
  }
}

