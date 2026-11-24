import 'json_helpers.dart';

class PackingGodownRef {
  const PackingGodownRef({required this.id, required this.name});

  final int id;
  final String name;

  factory PackingGodownRef.fromJson(Map<String, dynamic> json) {
    return PackingGodownRef(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
    );
  }
}

class DispatchTransporterRef {
  const DispatchTransporterRef({
    required this.id,
    required this.name,
    this.city,
  });

  final int id;
  final String name;
  final String? city;

  factory DispatchTransporterRef.fromJson(Map<String, dynamic> json) {
    return DispatchTransporterRef(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString(),
      city: parseOptionalString(json['city']),
    );
  }
}

class DispatchVehicleRef {
  const DispatchVehicleRef({
    required this.id,
    required this.no,
    this.name,
    this.drivers = const [],
  });

  final int id;
  final String no;
  final String? name;
  final List<String> drivers;

  factory DispatchVehicleRef.fromJson(Map<String, dynamic> json) {
    final rawDrivers = json['drivers'];
    final driversList = rawDrivers is List
        ? rawDrivers
              .map((d) {
                if (d is Map) {
                  return (d['name'] ?? d['driverName'] ?? '').toString().trim();
                }
                return d.toString().trim();
              })
              .where((s) => s.isNotEmpty)
              .toList()
        : <String>[];
    return DispatchVehicleRef(
      id: parseInt(json['id']),
      no: (json['no'] ?? '').toString(),
      name: parseOptionalString(json['name']),
      drivers: driversList,
    );
  }
}

class PackingProductStatus {
  const PackingProductStatus({
    required this.id,
    required this.code,
    required this.name,
    required this.boxesPerCase,
    required this.looseInnerBoxes,
    required this.factoryCartons,
    required this.totalCartons,
    required this.readyToSealCartons,
    required this.neededForNextCarton,
    this.category,
    this.subCategory,
    this.unit = 'Case',
    this.packUnit = 'Box',
    this.wipProductId,
    this.wipCode,
    this.wipName,
    this.godownCartons = const {},
  });

  final int id;
  final String code;
  final String name;
  final String? category;
  final String? subCategory;
  final int boxesPerCase;
  final String unit;
  final String packUnit;
  final int? wipProductId;
  final String? wipCode;
  final String? wipName;
  final int looseInnerBoxes;
  final int factoryCartons;
  final Map<String, int> godownCartons;
  final int totalCartons;
  final int readyToSealCartons;
  final int neededForNextCarton;

  int get remainderLooseBoxes =>
      boxesPerCase > 0 ? looseInnerBoxes % boxesPerCase : 0;

  double get progressToNextCarton =>
      boxesPerCase > 0 ? (remainderLooseBoxes / boxesPerCase).clamp(0.0, 1.0) : 0.0;

  factory PackingProductStatus.fromJson(Map<String, dynamic> json) {
    final rawGodowns = json['godownCartons'];
    final godownMap = <String, int>{};
    if (rawGodowns is Map) {
      rawGodowns.forEach((k, v) {
        godownMap[k.toString()] = parseInt(v);
      });
    }
    final bpc = parseInt(json['boxesPerCase'], fallback: 1);
    final safeBpc = bpc > 0 ? bpc : 1;
    final loose = parseInt(json['looseInnerBoxes']);
    final ready = json.containsKey('readyToSealCartons')
        ? parseInt(json['readyToSealCartons'])
        : loose ~/ safeBpc;
    final rem = loose % safeBpc;
    final needed = json.containsKey('neededForNextCarton')
        ? parseInt(json['neededForNextCarton'])
        : (rem == 0 ? safeBpc : safeBpc - rem);

    return PackingProductStatus(
      id: parseInt(json['id']),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: parseOptionalString(json['category']),
      subCategory: parseOptionalString(json['subCategory']),
      boxesPerCase: safeBpc,
      unit: parseOptionalString(json['unit']) ?? 'Case',
      packUnit: parseOptionalString(json['packUnit']) ?? 'Box',
      wipProductId: json['wipProductId'] != null ? parseInt(json['wipProductId']) : null,
      wipCode: parseOptionalString(json['wipCode']),
      wipName: parseOptionalString(json['wipName']),
      looseInnerBoxes: loose,
      factoryCartons: parseInt(json['factoryCartons']),
      godownCartons: godownMap,
      totalCartons: parseInt(json['totalCartons']),
      readyToSealCartons: ready,
      neededForNextCarton: needed,
    );
  }
}

class PackingEntryRecord {
  const PackingEntryRecord({
    required this.id,
    required this.date,
    required this.entryType,
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.innerBoxesPacked,
    required this.damagedBoxes,
    required this.masterCartonsSealed,
    required this.boxesPerCase,
    required this.innerBoxesConsumed,
    required this.looseRemainingAfter,
    required this.createdBy,
    required this.createdAt,
    this.subCategory,
    this.targetGodownName,
    this.remarks,
  });

  final int id;
  final DateTime date;
  final String entryType; // INNER_BOX | MASTER_CARTON
  final int productId;
  final String productCode;
  final String productName;
  final String? subCategory;
  final int innerBoxesPacked;
  final int damagedBoxes;
  final int masterCartonsSealed;
  final int boxesPerCase;
  final int innerBoxesConsumed;
  final int looseRemainingAfter;
  final String? targetGodownName;
  final String? remarks;
  final String createdBy;
  final DateTime createdAt;

  bool get isMasterCarton => entryType.toUpperCase() == 'MASTER_CARTON';

  factory PackingEntryRecord.fromJson(Map<String, dynamic> json) {
    return PackingEntryRecord(
      id: parseInt(json['id']),
      date: parseDateTime(json['date']),
      entryType: (json['entryType'] ?? 'INNER_BOX').toString(),
      productId: parseInt(json['productId']),
      productCode: (json['productCode'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      subCategory: parseOptionalString(json['subCategory']),
      innerBoxesPacked: parseInt(json['innerBoxesPacked']),
      damagedBoxes: parseInt(json['damagedBoxes']),
      masterCartonsSealed: parseInt(json['masterCartonsSealed']),
      boxesPerCase: parseInt(json['boxesPerCase'], fallback: 1),
      innerBoxesConsumed: parseInt(json['innerBoxesConsumed']),
      looseRemainingAfter: parseInt(json['looseRemainingAfter']),
      targetGodownName: parseOptionalString(json['targetGodownName']),
      remarks: parseOptionalString(json['remarks']),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdAt: parseDateTime(json['createdAt']),
    );
  }
}

class PackingSummary {
  const PackingSummary({
    required this.factoryGodownId,
    required this.godowns,
    required this.products,
    required this.recentEntries,
  });

  final int? factoryGodownId;
  final List<PackingGodownRef> godowns;
  final List<PackingProductStatus> products;
  final List<PackingEntryRecord> recentEntries;

  int get totalFactoryCartons =>
      products.fold(0, (sum, p) => sum + p.factoryCartons);
  int get totalLooseInnerBoxes =>
      products.fold(0, (sum, p) => sum + p.looseInnerBoxes);
  int get totalReadyToSealCartons =>
      products.fold(0, (sum, p) => sum + p.readyToSealCartons);

  factory PackingSummary.fromJson(Map<String, dynamic> json) {
    final rawGodowns =
        json['godowns'] is List ? json['godowns'] as List<dynamic> : const <dynamic>[];
    final rawProducts =
        json['products'] is List ? json['products'] as List<dynamic> : const <dynamic>[];
    final rawEntries = json['recentEntries'] is List
        ? json['recentEntries'] as List<dynamic>
        : const <dynamic>[];

    return PackingSummary(
      factoryGodownId: json['factoryGodownId'] != null
          ? parseInt(json['factoryGodownId'])
          : null,
      godowns: rawGodowns
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => PackingGodownRef.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      products: rawProducts
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => PackingProductStatus.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      recentEntries: rawEntries
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => PackingEntryRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class DispatchStockItem {
  const DispatchStockItem({
    required this.productId,
    required this.code,
    required this.name,
    required this.boxesPerCase,
    required this.availableCartons,
    this.subCategory,
  });

  final int productId;
  final String code;
  final String name;
  final String? subCategory;
  final int boxesPerCase;
  final int availableCartons;

  factory DispatchStockItem.fromJson(Map<String, dynamic> json) {
    return DispatchStockItem(
      productId: parseInt(json['productId']),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      subCategory: parseOptionalString(json['subCategory']),
      boxesPerCase: parseInt(json['boxesPerCase'], fallback: 1),
      availableCartons: parseInt(json['availableCartons']),
    );
  }
}

class FactoryDispatchLineItem {
  const FactoryDispatchLineItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.cartons,
    required this.boxesPerCase,
    required this.totalBoxes,
    this.subCategory,
  });

  final int id;
  final int productId;
  final String productName;
  final String? subCategory;
  final int cartons;
  final int boxesPerCase;
  final int totalBoxes;

  factory FactoryDispatchLineItem.fromJson(Map<String, dynamic> json) {
    return FactoryDispatchLineItem(
      id: parseInt(json['id']),
      productId: parseInt(json['productId']),
      productName: (json['productName'] ?? '').toString(),
      subCategory: parseOptionalString(json['subCategory']),
      cartons: parseInt(json['cartons']),
      boxesPerCase: parseInt(json['boxesPerCase'], fallback: 1),
      totalBoxes: parseInt(json['totalBoxes']),
    );
  }
}

class FactoryDispatchRecord {
  const FactoryDispatchRecord({
    required this.id,
    required this.challanNo,
    required this.date,
    required this.destinationType,
    required this.fromGodownId,
    required this.fromGodownName,
    required this.totalCartons,
    required this.totalBoxes,
    required this.createdBy,
    required this.createdAt,
    required this.items,
    this.toGodownId,
    this.toGodownName,
    this.transporterId,
    this.transporterName,
    this.customerName,
    this.lrNumber,
    this.vehicleNo,
    this.driverName,
    this.remarks,
  });

  final int id;
  final String challanNo;
  final DateTime date;
  final String destinationType; // GODOWN | TRANSPORTER
  final int fromGodownId;
  final String fromGodownName;
  final int? toGodownId;
  final String? toGodownName;
  final int? transporterId;
  final String? transporterName;
  final String? customerName;
  final String? lrNumber;
  final String? vehicleNo;
  final String? driverName;
  final String? remarks;
  final int totalCartons;
  final int totalBoxes;
  final String createdBy;
  final DateTime createdAt;
  final List<FactoryDispatchLineItem> items;

  bool get isOwnGodown => destinationType.toUpperCase() == 'GODOWN';

  String get destinationDisplay => isOwnGodown
      ? (toGodownName ?? 'Own Godown')
      : (transporterName ?? 'Transporter');

  factory FactoryDispatchRecord.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] is List
        ? json['items'] as List<dynamic>
        : const <dynamic>[];
    return FactoryDispatchRecord(
      id: parseInt(json['id']),
      challanNo: (json['challanNo'] ?? '').toString(),
      date: parseDateTime(json['date']),
      destinationType: (json['destinationType'] ?? 'GODOWN').toString(),
      fromGodownId: parseInt(json['fromGodownId']),
      fromGodownName: (json['fromGodownName'] ?? '').toString(),
      toGodownId: json['toGodownId'] != null ? parseInt(json['toGodownId']) : null,
      toGodownName: parseOptionalString(json['toGodownName']),
      transporterId:
          json['transporterId'] != null ? parseInt(json['transporterId']) : null,
      transporterName: parseOptionalString(json['transporterName']),
      customerName: parseOptionalString(json['customerName']),
      lrNumber: parseOptionalString(json['lrNumber']),
      vehicleNo: parseOptionalString(json['vehicleNo']),
      driverName: parseOptionalString(json['driverName']),
      remarks: parseOptionalString(json['remarks']),
      totalCartons: parseInt(json['totalCartons']),
      totalBoxes: parseInt(json['totalBoxes']),
      createdBy: (json['createdBy'] ?? '').toString(),
      createdAt: parseDateTime(json['createdAt']),
      items: rawItems
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                FactoryDispatchLineItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
    );
  }
}

class FactoryDispatchOverview {
  const FactoryDispatchOverview({
    required this.dispatches,
    required this.godowns,
    required this.transporters,
    required this.vehicles,
    required this.stockByGodown,
  });

  final List<FactoryDispatchRecord> dispatches;
  final List<PackingGodownRef> godowns;
  final List<DispatchTransporterRef> transporters;
  final List<DispatchVehicleRef> vehicles;
  final Map<int, List<DispatchStockItem>> stockByGodown;

  List<DispatchStockItem> stockForGodown(int? godownId) {
    if (godownId == null) return const [];
    return stockByGodown[godownId] ?? const [];
  }

  factory FactoryDispatchOverview.fromJson(Map<String, dynamic> json) {
    final rawDispatches = json['dispatches'] is List
        ? json['dispatches'] as List<dynamic>
        : const <dynamic>[];
    final rawGodowns = json['godowns'] is List
        ? json['godowns'] as List<dynamic>
        : const <dynamic>[];
    final rawTransporters = json['transporters'] is List
        ? json['transporters'] as List<dynamic>
        : const <dynamic>[];
    final rawVehicles = json['vehicles'] is List
        ? json['vehicles'] as List<dynamic>
        : const <dynamic>[];
    final rawStock = json['stockByGodown'];
    final stockMap = <int, List<DispatchStockItem>>{};
    if (rawStock is Map) {
      rawStock.forEach((key, value) {
        final gid = parseInt(key);
        if (value is List) {
          stockMap[gid] = value
              .whereType<Map<dynamic, dynamic>>()
              .map(
                (item) =>
                    DispatchStockItem.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
        }
      });
    }

    return FactoryDispatchOverview(
      dispatches: rawDispatches
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) => FactoryDispatchRecord.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      godowns: rawGodowns
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => PackingGodownRef.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      transporters: rawTransporters
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (e) =>
                DispatchTransporterRef.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList(),
      vehicles: rawVehicles
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => DispatchVehicleRef.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      stockByGodown: stockMap,
    );
  }
}
