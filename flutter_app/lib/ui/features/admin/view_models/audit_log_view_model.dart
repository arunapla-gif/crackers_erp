import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/admin_repository.dart';
import 'package:crackers_erp/domain/models/audit_log.dart';

class AuditLogViewModel extends ChangeNotifier {
  AuditLogViewModel({required AdminRepository adminRepository})
    : _adminRepository = adminRepository;

  final AdminRepository _adminRepository;

  List<AuditLogEntry> _logs = const [];
  List<String> _users = const [];
  String _moduleFilter = 'all';
  String _actionFilter = 'all';
  String _userFilter = 'all';
  String _searchQuery = '';
  bool _onlyFlagged = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  List<AuditLogEntry> get logs => _logs;
  List<String> get users => _users;
  String get moduleFilter => _moduleFilter;
  String get actionFilter => _actionFilter;
  String get userFilter => _userFilter;
  String get searchQuery => _searchQuery;
  bool get onlyFlagged => _onlyFlagged;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get flaggedCount => _logs.where((l) => l.isFlagged).length;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadLogs() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();
    try {
      final page = await _adminRepository.fetchAuditLogs(
        module: _moduleFilter,
        action: _actionFilter,
        username: _userFilter,
        search: _searchQuery,
        onlyFlagged: _onlyFlagged,
      );
      _logs = page.logs;
      _users = page.users;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load audit logs.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> setModuleFilter(String module) async {
    if (_moduleFilter == module) return;
    _moduleFilter = module;
    await loadLogs();
  }

  Future<void> setActionFilter(String action) async {
    if (_actionFilter == action) return;
    _actionFilter = action;
    await loadLogs();
  }

  Future<void> setUserFilter(String username) async {
    if (_userFilter == username) return;
    _userFilter = username;
    await loadLogs();
  }

  Future<void> toggleOnlyFlagged(bool value) async {
    if (_onlyFlagged == value) return;
    _onlyFlagged = value;
    await loadLogs();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query.trim();
    await loadLogs();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  void reset() {
    _logs = const [];
    _users = const [];
    _moduleFilter = 'all';
    _actionFilter = 'all';
    _userFilter = 'all';
    _searchQuery = '';
    _onlyFlagged = false;
    _isLoading = false;
    _errorMessage = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
