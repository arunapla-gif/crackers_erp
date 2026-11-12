import 'company_profile.dart';
import 'json_helpers.dart';

enum BillingDocType {
  inv('INV', 'Tax Invoice', 'INVOICE'),
  est('EST', 'Estimate', 'ESTIMATE'),
  pro('PRO', 'Performa Invoice', 'PERFORMA');

  const BillingDocType(this.code, this.title, this.shortLabel);
  final String code;
  final String title;
  final String shortLabel;

  static BillingDocType fromCode(String? code) {
    switch ((code ?? '').toUpperCase()) {
      case 'EST':
        return BillingDocType.est;
      case 'PRO':
        return BillingDocType.pro;
      case 'INV':
      default:
        return BillingDocType.inv;
    }
  }
}

class BillingRow {
  const BillingRow({
    required this.id,
    this.productId,
    required this.product,
    this.hsn = '',
    this.qty = 1,
    this.rate = 0,
    this.tax = 18,
    this.amount = 0,
  });

  final int id;
  final int? productId;
  final String product;
  final String hsn;
  final int qty;
  final double rate;
  final double tax;
  final double amount;

  BillingRow copyWith({
    int? id,
    int? productId,
    bool clearProductId = false,
    String? product,
    String? hsn,
    int? qty,
    double? rate,
    double? tax,
    double? amount,
  }) {
    return BillingRow(
      id: id ?? this.id,
      productId: clearProductId ? null : (productId ?? this.productId),
      product: product ?? this.product,
      hsn: hsn ?? this.hsn,
      qty: qty ?? this.qty,
      rate: rate ?? this.rate,
      tax: tax ?? this.tax,
      amount: amount ?? this.amount,
    );
  }

  factory BillingRow.fromJson(Map<String, dynamic> json) {
    return BillingRow(
      id: parseInt(json['id'], fallback: DateTime.now().microsecondsSinceEpoch),
      productId: json['productId'] == null ? null : parseInt(json['productId']),
      product: (json['product'] ?? '').toString(),
      hsn: (json['hsn'] ?? '').toString(),
      qty: parseInt(json['qty'], fallback: 1),
      rate: parseDouble(json['rate']),
      tax: parseDouble(json['tax'], fallback: 18),
      amount: parseDouble(json['amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'product': product,
      'hsn': hsn,
      'qty': qty,
      'rate': rate,
      'tax': tax,
      'amount': amount,
    };
  }
}

class AdditionalChargeRow {
  const AdditionalChargeRow({
    required this.id,
    this.name = '',
    this.source = 'MANUAL',
    this.mode = 'ADD',
    this.type = 'AMOUNT',
    this.value = 0,
    this.amount = 0,
    this.series = 'SGFI',
    this.number = '',
  });

  final int id;
  final String name;
  final String source; // 'MANUAL' | 'INVOICE_TAX'
  final String mode; // 'ADD' | 'DEDUCT'
  final String type; // 'AMOUNT' | 'PERCENT'
  final double value;
  final double amount;
  final String series;
  final String number;

  AdditionalChargeRow copyWith({
    int? id,
    String? name,
    String? source,
    String? mode,
    String? type,
    double? value,
    double? amount,
    String? series,
    String? number,
  }) {
    return AdditionalChargeRow(
      id: id ?? this.id,
      name: name ?? this.name,
      source: source ?? this.source,
      mode: mode ?? this.mode,
      type: type ?? this.type,
      value: value ?? this.value,
      amount: amount ?? this.amount,
      series: series ?? this.series,
      number: number ?? this.number,
    );
  }

  factory AdditionalChargeRow.fromJson(Map<String, dynamic> json) {
    return AdditionalChargeRow(
      id: parseInt(json['id'], fallback: DateTime.now().microsecondsSinceEpoch),
      name: (json['name'] ?? '').toString(),
      source: (json['source'] ?? 'MANUAL').toString(),
      mode: (json['mode'] ?? 'ADD').toString(),
      type: (json['type'] ?? 'AMOUNT').toString(),
      value: parseDouble(json['value']),
      amount: parseDouble(json['amount']),
      series: (json['series'] ?? 'SGFI').toString(),
      number: (json['number'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'source': source,
      'mode': mode,
      'type': type,
      'value': value,
      'amount': amount,
      'series': series,
      'number': number,
    };
  }
}

class BillingTotals {
  const BillingTotals({
    this.subtotal = 0,
    this.tax = 0,
    this.cgst = 0,
    this.sgst = 0,
    this.igst = 0,
    this.charges = 0,
    this.grandTotal = 0,
  });

  final double subtotal;
  final double tax;
  final double cgst;
  final double sgst;
  final double igst;
  final double charges;
  final double grandTotal;
}

class BillingHeader {
  const BillingHeader({
    required this.date,
    this.series = 'SGFI',
    this.number = '0001',
    this.customer = '',
    this.customerAddress = '',
    this.vehicleNo = '',
    this.distance = '',
    this.transporterId = '',
    this.ewayBillNo = '',
    this.companyProfileId,
    this.companyProfileName = '',
    this.dispatchAddress = '',
  });

  final String date; // YYYY-MM-DD
  final String series;
  final String number;
  final String customer;
  final String customerAddress;
  final String vehicleNo;
  final String distance;
  final String transporterId;
  final String ewayBillNo;
  final int? companyProfileId;
  final String companyProfileName;
  final String dispatchAddress;

  factory BillingHeader.initial() =>
      BillingHeader(date: toIsoCalendarDate(DateTime.now()));

  BillingHeader copyWith({
    String? date,
    String? series,
    String? number,
    String? customer,
    String? customerAddress,
    String? vehicleNo,
    String? distance,
    String? transporterId,
    String? ewayBillNo,
    int? companyProfileId,
    bool clearCompanyProfile = false,
    String? companyProfileName,
    String? dispatchAddress,
  }) {
    return BillingHeader(
      date: date ?? this.date,
      series: series ?? this.series,
      number: number ?? this.number,
      customer: customer ?? this.customer,
      customerAddress: customerAddress ?? this.customerAddress,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      distance: distance ?? this.distance,
      transporterId: transporterId ?? this.transporterId,
      ewayBillNo: ewayBillNo ?? this.ewayBillNo,
      companyProfileId: clearCompanyProfile
          ? null
          : (companyProfileId ?? this.companyProfileId),
      companyProfileName: companyProfileName ?? this.companyProfileName,
      dispatchAddress: dispatchAddress ?? this.dispatchAddress,
    );
  }

  factory BillingHeader.fromJson(Map<String, dynamic> json) {
    return BillingHeader(
      date: parseOptionalString(json['date']) ?? toIsoCalendarDate(DateTime.now()),
      series: (json['series'] ?? 'SGFI').toString(),
      number: (json['number'] ?? '0001').toString(),
      customer: (json['customer'] ?? '').toString(),
      customerAddress: (json['customerAddress'] ?? '').toString(),
      vehicleNo: (json['vehicleNo'] ?? '').toString(),
      distance: (json['distance'] ?? '').toString(),
      transporterId: (json['transporterId'] ?? '').toString(),
      ewayBillNo: (json['ewayBillNo'] ?? '').toString(),
      companyProfileId: json['companyProfileId'] == null
          ? null
          : parseInt(json['companyProfileId']),
      companyProfileName: (json['companyProfileName'] ?? '').toString(),
      dispatchAddress: (json['dispatchAddress'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'series': series,
      'number': number,
      'customer': customer,
      'customerAddress': customerAddress,
      'vehicleNo': vehicleNo,
      'distance': distance,
      'transporterId': transporterId,
      'ewayBillNo': ewayBillNo,
      'companyProfileId': companyProfileId,
      'companyProfileName': companyProfileName,
      'dispatchAddress': dispatchAddress,
    };
  }
}

class InvoiceItemRecord {
  const InvoiceItemRecord({
    required this.id,
    this.productId,
    required this.product,
    this.hsn,
    required this.qty,
    required this.rate,
    required this.tax,
    required this.total,
  });

  final int id;
  final int? productId;
  final String product;
  final String? hsn;
  final int qty;
  final double rate;
  final double tax;
  final double total;

  factory InvoiceItemRecord.fromJson(Map<String, dynamic> json) {
    return InvoiceItemRecord(
      id: parseInt(json['id']),
      productId: json['productId'] == null ? null : parseInt(json['productId']),
      product: (json['product'] ?? '').toString(),
      hsn: parseOptionalString(json['hsn']),
      qty: parseInt(json['qty'], fallback: 1),
      rate: parseDouble(json['rate']),
      tax: parseDouble(json['tax']),
      total: parseDouble(json['total']),
    );
  }
}

class InvoiceRecord {
  const InvoiceRecord({
    required this.id,
    this.series,
    required this.number,
    required this.date,
    this.customer,
    this.customerAddress,
    this.state,
    this.vehicleNo,
    this.distance,
    this.transporterId,
    this.ewayBillNo,
    this.dispatchAddress,
    required this.subtotal,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.tax,
    required this.grandTotal,
    this.items = const [],
    this.charges = const [],
    this.companyProfileId,
    this.companyProfile,
  });

  final int id;
  final String? series;
  final String number;
  final DateTime date;
  final String? customer;
  final String? customerAddress;
  final String? state;
  final String? vehicleNo;
  final int? distance;
  final String? transporterId;
  final String? ewayBillNo;
  final String? dispatchAddress;
  final double subtotal;
  final double cgst;
  final double sgst;
  final double igst;
  final double tax;
  final double grandTotal;
  final List<InvoiceItemRecord> items;
  final List<AdditionalChargeRow> charges;
  final int? companyProfileId;
  final CompanyProfile? companyProfile;

  bool get isEstimateOrProforma => tax == 0 && cgst == 0 && sgst == 0 && igst == 0;

  String get isoDate => toIsoCalendarDate(date);

  String get inferredDocKindLabel {
    final s = (series ?? '').toUpperCase();
    final n = number.toUpperCase();
    if (s.contains('PRO') || n.contains('PRO')) return 'PERFORMA';
    if (isEstimateOrProforma || s.contains('EST') || n.contains('EST')) {
      return s.contains('PRO') ? 'PERFORMA' : 'ESTIMATE';
    }
    return 'TAX INVOICE';
  }

  factory InvoiceRecord.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(InvoiceItemRecord.fromJson)
              .toList()
        : const <InvoiceItemRecord>[];

    final rawCharges = json['charges'];
    final charges = rawCharges is List
        ? rawCharges
              .whereType<Map<String, dynamic>>()
              .map(AdditionalChargeRow.fromJson)
              .toList()
        : const <AdditionalChargeRow>[];

    final profileRaw = json['companyProfile'];
    return InvoiceRecord(
      id: parseInt(json['id']),
      series: parseOptionalString(json['series']),
      number: (json['number'] ?? '').toString(),
      date: parseDateTime(json['date']),
      customer: parseOptionalString(json['customer']),
      customerAddress: parseOptionalString(json['customerAddress']),
      state: parseOptionalString(json['state']),
      vehicleNo: parseOptionalString(json['vehicleNo']),
      distance: json['distance'] == null ? null : parseInt(json['distance']),
      transporterId: parseOptionalString(json['transporterId']),
      ewayBillNo: parseOptionalString(json['ewayBillNo']),
      dispatchAddress: parseOptionalString(json['dispatchAddress']),
      subtotal: parseDouble(json['subtotal']),
      cgst: parseDouble(json['cgst']),
      sgst: parseDouble(json['sgst']),
      igst: parseDouble(json['igst']),
      tax: parseDouble(json['tax']),
      grandTotal: parseDouble(json['grand_total']),
      items: items,
      charges: charges,
      companyProfileId: json['companyProfileId'] == null
          ? null
          : parseInt(json['companyProfileId']),
      companyProfile: profileRaw is Map<String, dynamic>
          ? CompanyProfile.fromJson(profileRaw)
          : null,
    );
  }
}

class CustomerPrice {
  const CustomerPrice({
    required this.id,
    required this.customerId,
    required this.productId,
    required this.rate,
  });

  final int id;
  final int customerId;
  final int productId;
  final double rate;

  factory CustomerPrice.fromJson(Map<String, dynamic> json) {
    return CustomerPrice(
      id: parseInt(json['id']),
      customerId: parseInt(json['customerId']),
      productId: parseInt(json['productId']),
      rate: parseDouble(json['rate']),
    );
  }
}

