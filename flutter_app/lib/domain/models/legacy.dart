import 'json_helpers.dart';

class LegacyAnalytics {
  const LegacyAnalytics({
    required this.totalPurchases,
    required this.totalEstimates,
    required this.totalWages,
    required this.totalPayments,
    required this.customersCount,
    required this.suppliersCount,
    required this.employeesCount,
    required this.purchasesCount,
    required this.estimatesCount,
    required this.workentriesCount,
  });

  final double totalPurchases;
  final double totalEstimates;
  final double totalWages;
  final double totalPayments;
  final int customersCount;
  final int suppliersCount;
  final int employeesCount;
  final int purchasesCount;
  final int estimatesCount;
  final int workentriesCount;

  factory LegacyAnalytics.fromJson(Map<String, dynamic> json) {
    final f = json['financials'] is Map<String, dynamic>
        ? json['financials'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final c = json['counts'] is Map<String, dynamic>
        ? json['counts'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return LegacyAnalytics(
      totalPurchases: parseDouble(f['totalPurchases']),
      totalEstimates: parseDouble(f['totalEstimates']),
      totalWages: parseDouble(f['totalWages']),
      totalPayments: parseDouble(f['totalPayments']),
      customersCount: parseInt(c['customers']),
      suppliersCount: parseInt(c['suppliers']),
      employeesCount: parseInt(c['employees']),
      purchasesCount: parseInt(c['purchases']),
      estimatesCount: parseInt(c['estimates']),
      workentriesCount: parseInt(c['workentries']),
    );
  }
}

class PriceTrendPoint {
  const PriceTrendPoint({
    required this.date,
    required this.rate,
    required this.qty,
    required this.pctChange,
  });

  final String date;
  final double rate;
  final double qty;
  final double pctChange;

  factory PriceTrendPoint.fromJson(Map<String, dynamic> json) {
    return PriceTrendPoint(
      date: (json['date'] ?? '').toString(),
      rate: parseDouble(json['rate']),
      qty: parseDouble(json['qty']),
      pctChange: parseDouble(json['pctChange']),
    );
  }
}

DateTime parseLegacyDateString(String? dateStr) {
  final raw = (dateStr ?? '').trim();
  if (raw.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
  final parts = raw.split('-');
  if (parts.length == 3) {
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }
  return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

