import '../../domain/models/factory_order.dart';
import '../../domain/models/sales_order.dart';
import '../services/api_client.dart';

class SalesOrderRepository {
  SalesOrderRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<RepDashboardStats> fetchRepDashboard() async {
    final raw = await _apiClient.getRepDashboard();
    return RepDashboardStats.fromJson(raw);
  }

  Future<List<SalesOrder>> fetchPendingOrders() async {
    final raw = await _apiClient.getPendingSalesOrders();
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SalesOrder.fromJson)
        .toList();
  }

  Future<List<SalesOrder>> fetchApprovedOrders({bool factoryView = false}) async {
    final raw = await _apiClient.getApprovedSalesOrders(factoryView: factoryView);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(SalesOrder.fromJson)
        .toList();
  }

  Future<FactoryOrder> fetchFactoryViewOrder(int id) async {
    final raw = await _apiClient.getSalesOrderFactoryView(id);
    return FactoryOrder.fromJson(raw);
  }

  Future<SalesOrder> createSalesOrder({
    int? customerId,
    SalesOrderLeadCustomer? newCustomerData,
    required double subtotal,
    required List<SalesOrderItem> items,
  }) async {
    final payload = <String, dynamic>{
      'customerId': customerId,
      'newCustomerData': newCustomerData?.toJson(),
      'subtotal': subtotal,
      'items': items.map((i) => i.toPayload()).toList(),
    };
    final raw = await _apiClient.createSalesOrder(payload);
    return SalesOrder.fromJson(raw);
  }

  Future<Map<String, dynamic>> approveCustomer(int orderId) {
    return _apiClient.approveSalesOrderCustomer(orderId);
  }

  Future<SalesOrder> linkCustomerToOrder(int orderId, int customerId) async {
    final raw = await _apiClient.linkCustomerToOrder(orderId, customerId);
    final inner = raw['order'];
    if (inner is Map<String, dynamic>) {
      return SalesOrder.fromJson(inner);
    }
    return SalesOrder.fromJson(raw);
  }

  Future<SalesOrder> updateOrderStatus(int orderId, String status) async {
    final raw = await _apiClient.updateSalesOrderStatus(orderId, status);
    return SalesOrder.fromJson(raw);
  }
}

