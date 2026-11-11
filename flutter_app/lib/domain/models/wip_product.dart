import 'json_helpers.dart';

class WipProduct {
  const WipProduct({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    this.category,
    this.subCategory,
    required this.unit,
    required this.boxesPerCase,
    required this.status,
  });

  final int id;
  final String code;
  final String name;
  final String type;
  final String? category;
  final String? subCategory;
  final String unit;
  final int boxesPerCase;
  final String status;

  bool get isActive => status.toLowerCase() != 'inactive';
  bool get isWip => type.toUpperCase() == 'WIP';

  String get displayGroup {
    if (subCategory != null && subCategory!.isNotEmpty) return subCategory!;
    if (category != null && category!.isNotEmpty) return category!;
    return 'FACTORY WIP';
  }

  factory WipProduct.fromJson(Map<String, dynamic> json) {
    return WipProduct(
      id: parseInt(json['id']),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString().trim(),
      type: (json['type'] ?? 'WIP').toString(),
      category: parseOptionalString(json['category']),
      subCategory: parseOptionalString(json['subCategory']),
      unit: (json['unit'] ?? 'Pcs').toString(),
      boxesPerCase: parseInt(json['boxesPerCase'], fallback: 1),
      status: (json['status'] ?? 'Active').toString(),
    );
  }
}

