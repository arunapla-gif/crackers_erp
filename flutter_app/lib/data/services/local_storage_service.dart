import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';

abstract class LocalStorageService {
  String? getToken();
  Future<void> saveToken(String token);

  Map<String, dynamic>? getUserJson();
  Future<void> saveUserJson(Map<String, dynamic> userJson);
  Future<void> clearAuth();

  String getApiBaseUrl();
  Future<void> saveApiBaseUrl(String? url);

  List<String> getPinnedWipItems();
  Future<void> savePinnedWipItems(List<String> items);

  String? getProductionEntryMode();
  Future<void> saveProductionEntryMode(String mode);

  Map<int, Map<String, int>>? getProductionDraft(String isoDate);
  Future<void> saveProductionDraft(
    String isoDate,
    Map<int, Map<String, int>> entriesByEmployee,
  );
  Future<void> clearProductionDraft(String isoDate);

  Map<String, dynamic>? getBillingCartJson();
  Future<void> saveBillingCartJson(Map<String, dynamic> cartJson);
  Map<String, dynamic>? getBillingHeaderJson();
  Future<void> saveBillingHeaderJson(Map<String, dynamic> headerJson);
  Future<void> clearBillingDraft();
}

class SharedPrefsLocalStorageService implements LocalStorageService {
  SharedPrefsLocalStorageService(this._prefs);

  static const String _tokenKey = 'erp_token';
  static const String _userKey = 'erp_user';
  static const String _apiUrlKey = 'custom_api_url';
  static const String _pinnedItemsKey = 'pinned_wip_items';
  static const String _entryModeKey = 'prod_entry_mode';
  static const String _draftPrefix = 'prod_draft_';
  static const String _billingCartKey = 'crackers_erp_billing_cart';
  static const String _billingHeaderKey = 'crackers_erp_billing_header';

  final SharedPreferences _prefs;

  static Future<SharedPrefsLocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPrefsLocalStorageService(prefs);
  }

  @override
  String? getToken() {
    final token = _prefs.getString(_tokenKey)?.trim();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token.trim());
  }

  @override
  Map<String, dynamic>? getUserJson() {
    final raw = _prefs.getString(_userKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Future<void> saveUserJson(Map<String, dynamic> userJson) async {
    await _prefs.setString(_userKey, jsonEncode(userJson));
  }

  @override
  Future<void> clearAuth() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_userKey);
  }

  @override
  String getApiBaseUrl() {
    final stored = _prefs.getString(_apiUrlKey)?.trim();
    if (stored == null || stored.isEmpty) return AppConfig.defaultApiBaseUrl;
    return normalizeApiBaseUrl(stored);
  }

  @override
  Future<void> saveApiBaseUrl(String? url) async {
    final normalized = normalizeApiBaseUrl(url ?? '');
    if (normalized.isEmpty || normalized == AppConfig.defaultApiBaseUrl) {
      await _prefs.remove(_apiUrlKey);
    } else {
      await _prefs.setString(_apiUrlKey, normalized);
    }
  }

  @override
  List<String> getPinnedWipItems() {
    return List<String>.from(_prefs.getStringList(_pinnedItemsKey) ?? const []);
  }

  @override
  Future<void> savePinnedWipItems(List<String> items) async {
    await _prefs.setStringList(_pinnedItemsKey, items);
  }

  @override
  String? getProductionEntryMode() => _prefs.getString(_entryModeKey);

  @override
  Future<void> saveProductionEntryMode(String mode) async {
    await _prefs.setString(_entryModeKey, mode);
  }

  @override
  Map<int, Map<String, int>>? getProductionDraft(String isoDate) {
    final raw = _prefs.getString('$_draftPrefix$isoDate');
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final rawItems = decoded['items'];
      if (rawItems is! Map<String, dynamic>) return null;

      final result = <int, Map<String, int>>{};
      rawItems.forEach((empKey, itemMap) {
        final empId = int.tryParse(empKey);
        if (empId == null || itemMap is! Map<String, dynamic>) return;
        final itemsForEmp = <String, int>{};
        itemMap.forEach((itemName, qtyRaw) {
          final qty =
              qtyRaw is num ? qtyRaw.toInt() : int.tryParse('$qtyRaw') ?? 0;
          if (qty > 0 && itemName.trim().isNotEmpty) {
            itemsForEmp[itemName] = qty;
          }
        });
        if (itemsForEmp.isNotEmpty) {
          result[empId] = itemsForEmp;
        }
      });
      return result;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveProductionDraft(
    String isoDate,
    Map<int, Map<String, int>> entriesByEmployee,
  ) async {
    final serialized = <String, Map<String, int>>{};
    entriesByEmployee.forEach((empId, items) {
      final nonZero = <String, int>{};
      items.forEach((name, qty) {
        if (qty > 0 && name.trim().isNotEmpty) {
          nonZero[name] = qty;
        }
      });
      if (nonZero.isNotEmpty) {
        serialized['$empId'] = nonZero;
      }
    });

    if (serialized.isEmpty) {
      await clearProductionDraft(isoDate);
      return;
    }

    await _prefs.setString(
      '$_draftPrefix$isoDate',
      jsonEncode({
        'updatedAt': DateTime.now().toIso8601String(),
        'items': serialized,
      }),
    );
  }

  @override
  Future<void> clearProductionDraft(String isoDate) async {
    await _prefs.remove('$_draftPrefix$isoDate');
  }

  @override
  Map<String, dynamic>? getBillingCartJson() {
    final raw = _prefs.getString(_billingCartKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  @override
  Future<void> saveBillingCartJson(Map<String, dynamic> cartJson) async {
    await _prefs.setString(_billingCartKey, jsonEncode(cartJson));
  }

  @override
  Map<String, dynamic>? getBillingHeaderJson() {
    final raw = _prefs.getString(_billingHeaderKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  @override
  Future<void> saveBillingHeaderJson(Map<String, dynamic> headerJson) async {
    await _prefs.setString(_billingHeaderKey, jsonEncode(headerJson));
  }

  @override
  Future<void> clearBillingDraft() async {
    await _prefs.remove(_billingCartKey);
    await _prefs.remove(_billingHeaderKey);
  }

  static String normalizeApiBaseUrl(String raw) {
    var cleaned = raw.trim();
    if (cleaned.isEmpty) return '';
    while (cleaned.endsWith('/')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    final parsed = Uri.tryParse(cleaned);
    if (parsed != null && (parsed.path.isEmpty || parsed.path == '/')) {
      return '$cleaned/api';
    }
    return cleaned;
  }
}
