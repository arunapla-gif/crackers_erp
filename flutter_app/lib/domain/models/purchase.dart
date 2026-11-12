import 'godown.dart';
import 'json_helpers.dart';
import 'vehicle.dart';

class PurchaseItemEntry {
  const PurchaseItemEntry({
    required this.id,
    required this.godownId,
    this.godownName,
    this.productId,
    required this.product,
    this.packs = 0,
    this.packUnit,
    this.pricingUnit,
    required this.qty,
    required this.rate,
    required this.amount,
    this.discount = 0,
    this.taxRate = 18,
    this.taxAmt = 0,
    this.netAmount = 0,
  });

  final int id;
  final int godownId;
  final String? godownName;
  final int? productId;
  final String product;
  final int packs;
  final String? packUnit;
  final String? pricingUnit;
  final int qty;
  final double rate;
  final double amount;
  final double discount;
  final double taxRate;
  final double taxAmt;
  final double netAmount;

  PurchaseItemEntry copyWith({
    int? id,
    int? godownId,
    String? godownName,
    int? productId,
    String? product,
    int? packs,
    String? packUnit,
    String? pricingUnit,
    int? qty,
    double? rate,
    double? amount,
    double? discount,
    double? taxRate,
    double? taxAmt,
    double? netAmount,
  }) {
    return PurchaseItemEntry(
      id: id ?? this.id,
      godownId: godownId ?? this.godownId,
      godownName: godownName ?? this.godownName,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      packs: packs ?? this.packs,
      packUnit: packUnit ?? this.packUnit,
      pricingUnit: pricingUnit ?? this.pricingUnit,
      qty: qty ?? this.qty,
      rate: rate ?? this.rate,
      amount: amount ?? this.amount,
      discount: discount ?? this.discount,
      taxRate: taxRate ?? this.taxRate,
      taxAmt: taxAmt ?? this.taxAmt,
      netAmount: netAmount ?? this.netAmount,
    );
  }

  factory PurchaseItemEntry.fromJson(Map<String, dynamic> json) {
    final gRaw = json['godown'];
    return PurchaseItemEntry(
      id: parseInt(json['id']),
      godownId: parseInt(json['godownId']),
      godownName: gRaw is Map<String, dynamic>
          ? parseOptionalString(gRaw['name'])
          : null,
      productId: json['productId'] == null ? null : parseInt(json['productId']),
      product: (json['product'] ?? '').toString(),
      packs: parseInt(json['packs']),
      packUnit: parseOptionalString(json['pack_unit']),
      pricingUnit: parseOptionalString(json['pricing_unit']),
      qty: parseInt(json['qty']),
      rate: parseDouble(json['rate']),
      amount: parseDouble(json['amount']),
      discount: parseDouble(json['discount']),
      taxRate: parseDouble(json['tax_rate'], fallback: 18),
      taxAmt: parseDouble(json['tax_amt']),
      netAmount: parseDouble(json['net_amount']),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'godownId': godownId,
      'productId': productId,
      'product': product,
      'packs': packs,
      'pack_unit': packUnit,
      'pricing_unit': pricingUnit,
      'qty': qty,
      'rate': rate,
      'amount': amount,
      'discount': discount,
      'tax_rate': taxRate,
      'tax_amt': taxAmt,
      'net_amount': netAmount,
    };
  }
}

class PurchaseRecord {
  const PurchaseRecord({
    required this.id,
    required this.number,
    required this.date,
    required this.supplier,
    required this.billNo,
    required this.qty,
    required this.subtotal,
    required this.tax,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.discount,
    required this.value,
    required this.status,
    required this.items,
  });

  final int id;
  final String number;
  final DateTime date;
  final String supplier;
  final String billNo;
  final int qty;
  final double subtotal;
  final double tax;
  final double cgst;
  final double sgst;
  final double igst;
  final double discount;
  final double value;
  final String status;
  final List<PurchaseItemEntry> items;

  bool get isActive => status.toLowerCase() != 'inactive';
  String get isoDate => toIsoCalendarDate(date);

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(PurchaseItemEntry.fromJson)
              .toList()
        : const <PurchaseItemEntry>[];
    return PurchaseRecord(
      id: parseInt(json['id']),
      number: (json['number'] ?? '').toString(),
      date: parseDateTime(json['date']),
      supplier: (json['supplier'] ?? '').toString(),
      billNo: (json['billNo'] ?? '').toString(),
      qty: parseInt(json['qty']),
      subtotal: parseDouble(json['subtotal']),
      tax: parseDouble(json['tax']),
      cgst: parseDouble(json['cgst']),
      sgst: parseDouble(json['sgst']),
      igst: parseDouble(json['igst']),
      discount: parseDouble(json['discount']),
      value: parseDouble(json['value']),
      status: parseOptionalString(json['status']) ?? 'Active',
      items: items,
    );
  }
}

class StockLedgerEntry {
  const StockLedgerEntry({
    required this.id,
    required this.godownId,
    this.godown,
    this.productId,
    required this.product,
    required this.qty,
    required this.value,
    required this.avgRate,
  });

  final int id;
  final int godownId;
  final Godown? godown;
  final int? productId;
  final String product;
  final int qty;
  final double value;
  final double avgRate;

  factory StockLedgerEntry.fromJson(Map<String, dynamic> json) {
    final gRaw = json['godown'];
    return StockLedgerEntry(
      id: parseInt(json['id']),
      godownId: parseInt(json['godownId']),
      godown: gRaw is Map<String, dynamic> ? Godown.fromJson(gRaw) : null,
      productId: json['productId'] == null ? null : parseInt(json['productId']),
      product: (json['product'] ?? '').toString(),
      qty: parseInt(json['qty']),
      value: parseDouble(json['value']),
      avgRate: parseDouble(json['avgRate']),
    );
  }
}

class StockTransferItemRecord {
  const StockTransferItemRecord({
    required this.id,
    required this.fromGodownId,
    required this.toGodownId,
    this.fromGodownName,
    this.toGodownName,
    this.productId,
    required this.product,
    required this.qty,
    required this.rate,
    required this.value,
  });

  final int id;
  final int fromGodownId;
  final int toGodownId;
  final String? fromGodownName;
  final String? toGodownName;
  final int? productId;
  final String product;
  final int qty;
  final double rate;
  final double value;

  factory StockTransferItemRecord.fromJson(Map<String, dynamic> json) {
    final fromG = json['fromGodown'];
    final toG = json['toGodown'];
    return StockTransferItemRecord(
      id: parseInt(json['id']),
      fromGodownId: parseInt(json['fromGodownId']),
      toGodownId: parseInt(json['toGodownId']),
      fromGodownName: fromG is Map<String, dynamic>
          ? parseOptionalString(fromG['name'])
          : null,
      toGodownName: toG is Map<String, dynamic>
          ? parseOptionalString(toG['name'])
          : null,
      productId: json['productId'] == null ? null : parseInt(json['productId']),
      product: (json['product'] ?? '').toString(),
      qty: parseInt(json['qty']),
      rate: parseDouble(json['rate']),
      value: parseDouble(json['value']),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'fromGodownId': fromGodownId,
      'toGodownId': toGodownId,
      'productId': productId,
      'product': product,
      'qty': qty,
      'rate': rate,
      'value': value,
    };
  }
}

class StockTransferRecord {
  const StockTransferRecord({
    required this.id,
    required this.number,
    required this.date,
    this.vehicleId,
    this.vehicle,
    this.driverName,
    this.remarks,
    required this.qty,
    required this.items,
  });

  final int id;
  final String number;
  final DateTime date;
  final int? vehicleId;
  final Vehicle? vehicle;
  final String? driverName;
  final String? remarks;
  final int qty;
  final List<StockTransferItemRecord> items;

  String get isoDate => toIsoCalendarDate(date);

  factory StockTransferRecord.fromJson(Map<String, dynamic> json) {
    final vRaw = json['vehicle'];
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(StockTransferItemRecord.fromJson)
              .toList()
        : const <StockTransferItemRecord>[];
    return StockTransferRecord(
      id: parseInt(json['id']),
      number: (json['number'] ?? '').toString(),
      date: parseDateTime(json['date']),
      vehicleId: json['vehicleId'] == null ? null : parseInt(json['vehicleId']),
      vehicle: vRaw is Map<String, dynamic> ? Vehicle.fromJson(vRaw) : null,
      driverName: parseOptionalString(json['driverName']),
      remarks: parseOptionalString(json['remarks']),
      qty: parseInt(json['qty']),
      items: items,
    );
  }
}

