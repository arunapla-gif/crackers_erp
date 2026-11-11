import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/factory_order_repository.dart';
import 'package:crackers_erp/domain/models/factory_order.dart';

class FactoryOrdersViewModel extends ChangeNotifier {
  FactoryOrdersViewModel({required FactoryOrderRepository orderRepository})
    : _orderRepository = orderRepository;

  final FactoryOrderRepository _orderRepository;

  List<FactoryOrder> _orders = const [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  List<FactoryOrder> get orders => _orders;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<FactoryOrder> get filteredOrders {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _orders;
    return _orders.where((order) {
      if ('${order.id}'.contains(q)) return true;
      if (order.customerName.toLowerCase().contains(q)) return true;
      if (order.locationLabel.toLowerCase().contains(q)) return true;
      if ((order.repUsername ?? '').toLowerCase().contains(q)) return true;
      return order.items.any((i) => i.product.toLowerCase().contains(q));
    }).toList();
  }

  int get totalCasesAcrossFiltered =>
      filteredOrders.fold(0, (sum, o) => sum + o.totalCases);

  int get totalBoxesAcrossFiltered => filteredOrders.fold(
    0,
    (sum, o) => sum + o.items.fold(0, (s, item) => s + item.totalBoxes),
  );

  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      _orders = await _orderRepository.fetchApprovedFactoryOrders();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load approved factory orders.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _safeNotify();
  }

  void reset() {
    _orders = const [];
    _searchQuery = '';
    _isLoading = false;
    _errorMessage = null;
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
