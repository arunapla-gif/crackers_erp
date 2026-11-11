import '../../domain/models/user_session.dart';
import '../models/api_exceptions.dart';
import '../services/api_client.dart';
import '../services/local_storage_service.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required LocalStorageService storage,
  }) : _apiClient = apiClient,
       _storage = storage;

  final ApiClient _apiClient;
  final LocalStorageService _storage;

  AuthSession? loadCachedSession() {
    final token = _storage.getToken();
    final userMap = _storage.getUserJson();
    if (token == null || userMap == null) return null;
    try {
      final user = UserAccount.fromJson(userMap);
      if (user.id <= 0 || user.username.isEmpty) return null;
      return AuthSession(token: token, user: user);
    } catch (_) {
      return null;
    }
  }

  Future<UserAccount?> verifySession() async {
    final token = _storage.getToken();
    if (token == null) return null;
    final data = await _apiClient.getMe();
    final userRaw = data['user'];
    if (userRaw is! Map<String, dynamic>) {
      throw const ApiException('Invalid profile response from server.');
    }
    final user = UserAccount.fromJson(userRaw);
    await _storage.saveUserJson(user.toJson());
    return user;
  }

  Future<AuthSession> login({
    required String username,
    required String pin,
  }) async {
    final data = await _apiClient.login(username, pin);
    final token = (data['token'] ?? '').toString().trim();
    final userRaw = data['user'];
    if (token.isEmpty || userRaw is! Map<String, dynamic>) {
      throw const ApiException('Invalid login response from server.');
    }

    final user = UserAccount.fromJson(userRaw);
    if (!user.canAccessSupervisorApp) {
      throw ApiException(
        'User "${user.username}" (${user.role}) does not have Supervisor or Factory Production permissions.',
        statusCode: 403,
      );
    }

    await _storage.saveToken(token);
    await _storage.saveUserJson(user.toJson());
    return AuthSession(token: token, user: user);
  }

  Future<void> logout() async {
    await _storage.clearAuth();
  }

  String getApiBaseUrl() => _storage.getApiBaseUrl();

  Future<void> setApiBaseUrl(String? url) => _storage.saveApiBaseUrl(url);
}

