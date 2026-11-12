import 'json_helpers.dart';

class Product {
  const Product({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.category,
    this.subCategory,
    required this.hsn,
    required this.tax,
    required this.rate,
    required this.boxesPerCase,
    required this.unitQty,
    required this.unit,
    this.packUnit,
    required this.status,
    this.factoryAliasId,
    this.factoryAliasName,
  });

  final int id;
  final String code;
  final String name;
  final String type; // 'INV' | 'EP' | 'WIP' | 'RM'
  final String? category;
  final String? subCategory;
  final String hsn;
  final double tax;
  final double rate;
  final int boxesPerCase;
  final int unitQty;
  final String unit;
  final String? packUnit;
  final String status;
  final int? factoryAliasId;
  final String? factoryAliasName;

  bool get isActive => status.toLowerCase() != 'inactive';
  bool get isInv => type.toUpperCase() == 'INV';
  bool get isEp => type.toUpperCase() == 'EP';
  bool get isWip => type.toUpperCase() == 'WIP';
  bool get isRm => type.toUpperCase() == 'RM';

  String get displaySubCategory =>
      (subCategory == null || subCategory!.trim().isEmpty)
          ? (category == null || category!.trim().isEmpty
              ? 'UNCATEGORIZED'
              : category!.trim())
          : subCategory!.trim();

  factory Product.fromJson(Map<String, dynamic> json) {
    final aliasRaw = json['factoryAlias'];
    return Product(
      id: parseInt(json['id']),
      code: (json['code'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
      type: (json['type'] ?? 'INV').toString().trim(),
      category: parseOptionalString(json['category']),
      subCategory: parseOptionalString(json['subCategory']),
      hsn: parseOptionalString(json['hsn']) ?? '3604',
      tax: parseDouble(json['tax'], fallback: 18),
      rate: parseDouble(json['rate']),
      boxesPerCase: parseInt(json['boxesPerCase'], fallback: 1).clamp(1, 999999),
      unitQty: parseInt(json['unit_qty'], fallback: 1).clamp(1, 999999),
      unit: parseOptionalString(json['unit']) ?? 'Case',
      packUnit: parseOptionalString(json['pack_unit']),
      status: parseOptionalString(json['status']) ?? 'Active',
      factoryAliasId: json['factoryAliasId'] == null
          ? null
          : parseInt(json['factoryAliasId']),
      factoryAliasName: aliasRaw is Map<String, dynamic>
          ? parseOptionalString(aliasRaw['name'])
          : null,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'id': id,
      'code': code.trim(),
      'name': name.trim(),
      'type': type,
      'category': parseOptionalString(category),
      'subCategory': parseOptionalString(subCategory),
      'hsn': hsn.trim().isEmpty ? '3604' : hsn.trim(),
      'tax': tax,
      'rate': rate,
      'boxesPerCase': boxesPerCase,
      'unit_qty': unitQty,
      'unit': unit.trim().isEmpty ? 'Case' : unit.trim(),
      'pack_unit': parseOptionalString(packUnit),
      'status': status,
      'factoryAliasId': factoryAliasId,
    };
  }
}

