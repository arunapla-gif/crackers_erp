import 'package:flutter/foundation.dart';

import '../../domain/models/purchase.dart';
import '../services/api_client.dart';

List<PurchaseRecord> _parsePurchases(List<dynamic> rawList) {
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(PurchaseRecord.fromJson)
      .toList();
}

List<StockLedgerEntry> _parseStockLedger(List<dynamic> rawList) {
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(StockLedgerEntry.fromJson)
      .toList();
}

List<StockTransferRecord> _parseTransfers(List<dynamic> rawList) {
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(StockTransferRecord.fromJson)
      .toList();
}

class InventoryRepository {
  InventoryRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PurchaseRecord> savePurchase(Map<String, dynamic> payload) async {
    final raw = await _apiClient.savePurchase(payload);
    return PurchaseRecord.fromJson(raw);
  }

  Future<List<PurchaseRecord>> fetchPurchaseHistory() async {
    final raw = await _apiClient.getPurchaseHistory();
    if (raw.length < 60) return _parsePurchases(raw);
    return compute(_parsePurchases, raw);
  }

  Future<PurchaseRecord> togglePurchaseStatus(int id, String status) async {
    final raw = await _apiClient.togglePurchaseStatus(id, status);
    return PurchaseRecord.fromJson(raw);
  }

  Future<List<StockLedgerEntry>> fetchStockLedger() async {
    final raw = await _apiClient.getStockLedger();
    if (raw.length < 60) return _parseStockLedger(raw);
    return compute(_parseStockLedger, raw);
  }

  Future<StockTransferRecord> saveTransfer(Map<String, dynamic> payload) async {
    final raw = await _apiClient.saveTransfer(payload);
    return StockTransferRecord.fromJson(raw);
  }

  Future<List<StockTransferRecord>> fetchTransferHistory() async {
    final raw = await _apiClient.getTransferHistory();
    if (raw.length < 60) return _parseTransfers(raw);
    return compute(_parseTransfers, raw);
  }
}

