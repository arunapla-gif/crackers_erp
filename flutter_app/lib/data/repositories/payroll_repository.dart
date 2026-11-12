import '../../domain/models/payroll.dart';
import '../services/api_client.dart';

class PayrollRepository {
  PayrollRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<PayrollRecord>> fetchPayrolls() async {
    final raw = await _apiClient.getPayrolls();
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PayrollRecord.fromJson)
        .toList();
  }

  Future<PayrollRecord> savePayroll(Map<String, dynamic> payload) async {
    final raw = await _apiClient.savePayroll(payload);
    return PayrollRecord.fromJson(raw);
  }

  Future<AggregateProductionResult> fetchAggregateProduction({
    required int employeeId,
    required String startDate,
    required String endDate,
  }) async {
    final raw = await _apiClient.getAggregateProduction(
      employeeId: employeeId,
      startDate: startDate,
      endDate: endDate,
    );
    return AggregateProductionResult.fromJson(raw);
  }
}

