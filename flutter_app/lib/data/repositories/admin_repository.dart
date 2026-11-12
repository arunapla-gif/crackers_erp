import '../../domain/models/company_profile.dart';
import '../../domain/models/erp_user.dart';
import '../services/api_client.dart';

class AdminRepository {
  AdminRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<ErpUser>> fetchUsers() async {
    final raw = await _apiClient.getUsers();
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ErpUser.fromJson)
        .toList();
  }

  Future<ErpUser> saveUser(ErpUser user, {String? pin}) async {
    final raw = await _apiClient.saveUser(user.toSavePayload(pin: pin));
    final inner = raw['user'];
    if (inner is Map<String, dynamic>) {
      return ErpUser.fromJson(inner);
    }
    return ErpUser.fromJson(raw);
  }

  Future<void> deleteUser(int id) => _apiClient.deleteUser(id);

  Future<List<ErpUser>> fetchReps() async {
    final raw = await _apiClient.getReps();
    return raw
        .whereType<Map<String, dynamic>>()
        .map(ErpUser.fromJson)
        .toList();
  }

  Future<List<CompanyProfile>> fetchCompanyProfiles() async {
    final raw = await _apiClient.getCompanyProfiles();
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CompanyProfile.fromJson)
        .toList();
  }

  Future<CompanyProfile> saveCompanyProfile(CompanyProfile profile) async {
    final raw = await _apiClient.saveCompanyProfile(profile.toPayload());
    return CompanyProfile.fromJson(raw);
  }

  Future<void> deleteCompanyProfile(int id) =>
      _apiClient.deleteCompanyProfile(id);

  Future<BillingSeries> saveBillingSeries(BillingSeries series) async {
    final raw = await _apiClient.saveBillingSeries(series.toPayload());
    return BillingSeries.fromJson(raw);
  }

  Future<void> deleteBillingSeries(int id) =>
      _apiClient.deleteBillingSeries(id);

  Future<SystemCredentials> fetchSystemCredentials() async {
    final raw = await _apiClient.getSystemCredentials();
    return SystemCredentials.fromJson(raw);
  }
}

