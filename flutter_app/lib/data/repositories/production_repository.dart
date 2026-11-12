import 'package:flutter/foundation.dart';

import '../../domain/models/daily_production.dart';
import '../../domain/models/wip_product.dart';
import '../services/api_client.dart';
import '../services/local_storage_service.dart';

List<WipProduct> _parseWipProducts(List<dynamic> rawList) {
  final list = rawList
      .whereType<Map<String, dynamic>>()
      .map(WipProduct.fromJson)
      .where((p) => p.isWip && p.name.isNotEmpty)
      .toList();
  list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

List<DailyProductionRecord> _parseDailyProductions(List<dynamic> rawList) {
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(DailyProductionRecord.fromJson)
      .toList();
}

class ProductionRepository {
  ProductionRepository({
    required ApiClient apiClient,
    required LocalStorageService storage,
  }) : _apiClient = apiClient,
       _storage = storage;

  final ApiClient _apiClient;
  final LocalStorageService _storage;

  Future<List<WipProduct>> fetchWipProducts() async {
    final raw = await _apiClient.getProducts();
    if (raw.length < 60) return _parseWipProducts(raw);
    return compute(_parseWipProducts, raw);
  }

  Future<List<DailyProductionRecord>> fetchDailyProductions({
    String? date,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    final raw = await _apiClient.getDailyProductions(
      date: date,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
    if (raw.length < 60) return _parseDailyProductions(raw);
    return compute(_parseDailyProductions, raw);
  }

  Future<List<DailyProductionRecord>> saveDailyProductionBulk({
    required String date,
    required List<Map<String, dynamic>> entries,
  }) async {
    final res = await _apiClient.saveDailyProductionBulk(
      date: date,
      entries: entries,
    );
    final rawRecords = res['records'];
    final list = rawRecords is List<dynamic> ? rawRecords : <dynamic>[];
    if (list.length < 60) return _parseDailyProductions(list);
    return compute(_parseDailyProductions, list);
  }

  Future<void> deleteDailyProduction(int id) async {
    await _apiClient.deleteDailyProduction(id);
  }

  List<String> loadPinnedItems() => _storage.getPinnedWipItems();

  Future<void> savePinnedItems(List<String> items) =>
      _storage.savePinnedWipItems(items);

  String? loadEntryMode() => _storage.getProductionEntryMode();

  Future<void> saveEntryMode(String mode) =>
      _storage.saveProductionEntryMode(mode);

  Map<int, Map<String, int>>? loadDraft(String isoDate) =>
      _storage.getProductionDraft(isoDate);

  Future<void> saveDraft(
    String isoDate,
    Map<int, Map<String, int>> entriesByEmployee,
  ) => _storage.saveProductionDraft(isoDate, entriesByEmployee);

  Future<void> clearDraft(String isoDate) =>
      _storage.clearProductionDraft(isoDate);
}
