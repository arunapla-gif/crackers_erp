import 'package:flutter/foundation.dart';

import '../../domain/models/billing.dart';
import '../../domain/models/eway_bill.dart';
import '../services/api_client.dart';
import '../services/local_storage_service.dart';

List<InvoiceRecord> _parseInvoices(List<dynamic> rawList) {
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(InvoiceRecord.fromJson)
      .toList();
}

class BillingRepository {
  BillingRepository({
    required ApiClient apiClient,
    required LocalStorageService storage,
  }) : _apiClient = apiClient,
       _storage = storage;

  final ApiClient _apiClient;
  final LocalStorageService _storage;

  Future<InvoiceRecord> fetchInvoice(String number) async {
    final raw = await _apiClient.getInvoice(number);
    return InvoiceRecord.fromJson(raw);
  }

  Future<InvoiceRecord> saveInvoice(Map<String, dynamic> payload) async {
    final raw = await _apiClient.saveInvoice(payload);
    return InvoiceRecord.fromJson(raw);
  }

  Future<List<InvoiceRecord>> fetchInvoiceHistory() async {
    final raw = await _apiClient.getInvoiceHistory();
    if (raw.length < 60) return _parseInvoices(raw);
    return compute(_parseInvoices, raw);
  }

  Future<Map<String, dynamic>> generateEwayBill(String number, String mode) {
    return _apiClient.generateEwayBill(number, mode);
  }

  Future<EwayBillReportResponse> fetchRecentEwayBills({int days = 7}) async {
    final raw = await _apiClient.getRecentEwayBills(days: days);
    return EwayBillReportResponse.fromJson(raw);
  }

  Map<String, dynamic>? loadDraftCart() => _storage.getBillingCartJson();

  Future<void> saveDraftCart(Map<String, dynamic> cartJson) =>
      _storage.saveBillingCartJson(cartJson);

  BillingHeader? loadDraftHeader() {
    final raw = _storage.getBillingHeaderJson();
    if (raw == null) return null;
    try {
      return BillingHeader.fromJson(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveDraftHeader(BillingHeader header) =>
      _storage.saveBillingHeaderJson(header.toJson());

  Future<void> clearDraft() => _storage.clearBillingDraft();
}

