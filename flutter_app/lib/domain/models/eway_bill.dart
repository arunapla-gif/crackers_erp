import 'json_helpers.dart';

class EwayBillDayResult {
  const EwayBillDayResult({required this.date, required this.data});

  final String date;
  final Object? data;

  factory EwayBillDayResult.fromJson(Map<String, dynamic> json) {
    return EwayBillDayResult(
      date: (json['date'] ?? '').toString(),
      data: json['data'],
    );
  }
}

class EwayBillDayError {
  const EwayBillDayError({required this.date, required this.error});

  final String date;
  final Object? error;

  factory EwayBillDayError.fromJson(Map<String, dynamic> json) {
    return EwayBillDayError(
      date: (json['date'] ?? '').toString(),
      error: json['error'],
    );
  }
}

class EwayBillReportResponse {
  const EwayBillReportResponse({
    required this.message,
    required this.totalDaysSuccess,
    required this.totalDaysFailed,
    required this.results,
    required this.errors,
  });

  final String message;
  final int totalDaysSuccess;
  final int totalDaysFailed;
  final List<EwayBillDayResult> results;
  final List<EwayBillDayError> errors;

  factory EwayBillReportResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final rawErrors = json['errors'];
    return EwayBillReportResponse(
      message: (json['message'] ?? '').toString(),
      totalDaysSuccess: parseInt(json['totalDaysSuccess']),
      totalDaysFailed: parseInt(json['totalDaysFailed']),
      results: rawData is List
          ? rawData
                .whereType<Map<String, dynamic>>()
                .map(EwayBillDayResult.fromJson)
                .toList()
          : const [],
      errors: rawErrors is List
          ? rawErrors
                .whereType<Map<String, dynamic>>()
                .map(EwayBillDayError.fromJson)
                .toList()
          : const [],
    );
  }
}

