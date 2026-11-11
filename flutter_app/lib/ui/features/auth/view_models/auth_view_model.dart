import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/auth_repository.dart';
import 'package:crackers_erp/domain/models/user_session.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository {
    _apiBaseUrl = _authRepository.getApiBaseUrl();
  }

  final AuthRepository _authRepository;

  AuthSession? _session;
  bool _isInitialized = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _apiBaseUrl = '';
  bool _disposed = false;

  AuthSession? get session => _session;
  UserAccount? get currentUser => _session?.user;
  bool get isAuthenticated => _session != null;
  bool get isInitialized => _isInitialized;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String get apiBaseUrl => _apiBaseUrl;
  String? get token => _session?.token;

  void initialize() {
    _apiBaseUrl = _authRepository.getApiBaseUrl();
    final cached = _authRepository.loadCachedSession();
    if (cached != null && cached.user.canAccessSupervisorApp) {
      _session = cached;
    } else if (cached != null) {
      unawaited(_authRepository.logout());
      _session = null;
    }
    _isInitialized = true;
    _safeNotify();

    if (_session != null) {
      unawaited(_verifySessionInBackground());
    }
  }

  Future<void> _verifySessionInBackground() async {
    try {
      final freshUser = await _authRepository.verifySession();
      if (freshUser != null && !_disposed && _session != null) {
        if (!freshUser.canAccessSupervisorApp) {
          await logout(
            message:
                'Your account no longer has access to the Supervisor app.',
          );
          return;
        }
        _session = AuthSession(token: _session!.token, user: freshUser);
        _safeNotify();
      }
    } on NetworkUnavailableException {
      // Offline at launch: keep cached session so user can still view drafts
    } on ApiException catch (e) {
      if (e.isUnauthorized ||
          (e.isForbidden && e.message.toLowerCase().contains('token'))) {
        await logout(message: 'Session expired. Please sign in again.');
      }
    }
  }

  Future<bool> login({
    required String username,
    required String pin,
  }) async {
    final trimmedUser = username.trim();
    final trimmedPin = pin.trim();
    if (trimmedUser.isEmpty || trimmedPin.isEmpty) {
      _errorMessage = 'Enter both username and PIN.';
      _safeNotify();
      return false;
    }

    _errorMessage = null;
    _isSubmitting = true;
    _safeNotify();

    try {
      final session = await _authRepository.login(
        username: trimmedUser,
        pin: trimmedPin,
      );
      _session = session;
      _errorMessage = null;
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unexpected error while signing in.';
      return false;
    } finally {
      _isSubmitting = false;
      _safeNotify();
    }
  }

  Future<void> updateApiBaseUrl(String? url) async {
    await _authRepository.setApiBaseUrl(url);
    _apiBaseUrl = _authRepository.getApiBaseUrl();
    _safeNotify();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      _safeNotify();
    }
  }

  void handleUnauthorized() {
    if (_session == null) return;
    logout(message: 'Session expired. Please sign in again.');
  }

  Future<void> logout({String? message}) async {
    await _authRepository.logout();
    _session = null;
    _errorMessage = message;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
