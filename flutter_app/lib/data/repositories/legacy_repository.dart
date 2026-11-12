import '../../domain/models/legacy.dart';
import '../services/api_client.dart';

class LegacyRepository {
  LegacyRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<LegacyAnalytics> fetchAnalytics() async {
    final raw = await _apiClient.getLegacyAnalytics();
    return LegacyAnalytics.fromJson(raw);
  }

  Future<List<String>> fetchTrendProducts() async {
    final raw = await _apiClient.getLegacyAnalyticsProducts();
    return raw.map((e) => e.toString()).toList();
  }

  Future<List<PriceTrendPoint>> fetchPriceTrends(String product) async {
    final raw = await _apiClient.getLegacyAnalyticsPriceTrends(product);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(PriceTrendPoint.fromJson)
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchEstimates() async {
    final raw = await _apiClient.getLegacyEstimates();
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<Map<String, dynamic>> fetchEstimateDetails(int salesId) =>
      _apiClient.getLegacyEstimateDetails(salesId);

  Future<List<Map<String, dynamic>>> fetchPurchases() async {
    final raw = await _apiClient.getLegacyPurchases();
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchPurchaseParticulars(
    int purchaseId,
  ) async {
    final raw = await _apiClient.getLegacyPurchaseParticulars(purchaseId);
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchPurchaseCharges(
    int purchaseId,
  ) async {
    final raw = await _apiClient.getLegacyPurchaseCharges(purchaseId);
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchPayments() async {
    final raw = await _apiClient.getLegacyPayments();
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchCustomers() async {
    final raw = await _apiClient.getLegacyCustomers();
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchSuppliers() async {
    final raw = await _apiClient.getLegacySuppliers();
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    final raw = await _apiClient.getLegacyEmployees();
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchWorkentries() async {
    final raw = await _apiClient.getLegacyWorkentries();
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchWorkentryParticulars(
    int workId,
  ) async {
    final raw = await _apiClient.getLegacyWorkentryParticulars(workId);
    return raw.whereType<Map<String, dynamic>>().toList();
  }

  Future<List<Map<String, dynamic>>> fetchPayrollProducts() async {
    final raw = await _apiClient.getLegacyPayrollProducts();
    return raw.whereType<Map<String, dynamic>>().toList();
  }
}

