import 'package:flutter/foundation.dart';

import '../../domain/models/factory_order.dart';
import '../services/api_client.dart';

List<FactoryOrder> _parseFactoryOrders(List<dynamic> rawList) {
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(FactoryOrder.fromJson)
      .toList();
}

class FactoryOrderRepository {
  FactoryOrderRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<FactoryOrder>> fetchApprovedFactoryOrders() async {
    final raw = await _apiClient.getApprovedFactoryOrders();
    if (raw.length < 60) return _parseFactoryOrders(raw);
    return compute(_parseFactoryOrders, raw);
  }
}
