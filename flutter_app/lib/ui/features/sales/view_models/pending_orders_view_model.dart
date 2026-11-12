import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/repositories/sales_order_repository.dart';
import 'package:crackers_erp/domain/models/factory_order.dart';
import 'package:crackers_erp/domain/models/sales_order.dart';

class PendingOrdersViewModel extends ChangeNotifier {
  PendingOrdersViewModel({required SalesOrderRepository salesOrderRepository})
    : _orderRepo = salesOrderRepository;

  final SalesOrderRepository _orderRepo;

  String _activeTab = 'PENDING'; // 'PENDING' | 'APPROVED'
  List<SalesOrder> _orders = const [];
  bool _isLoading = false;
  bool _isBusyAction = false;
  String? _errorMessage;
  String? _successMessage;

  String get activeTab => _activeTab;
  List<SalesOrder> get orders => List.unmodifiable(_orders);
  bool get isLoading => _isLoading;
  bool get isBusyAction => _isBusyAction;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> setTab(String tab) async {
    _activeTab = tab;
    notifyListeners();
    await fetchOrders();
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _orders = _activeTab == 'PENDING'
          ? await _orderRepo.fetchPendingOrders()
          : await _orderRepo.fetchApprovedOrders();
    } catch (e) {
      _errorMessage = 'Failed to load orders: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> approveLeadCustomer(int orderId) async {
    _isBusyAction = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _orderRepo.approveCustomer(orderId);
      _successMessage = 'Lead approved and added to Customer Master.';
      await fetchOrders();
      return true;
    } catch (e) {
      _errorMessage = 'Error approving lead customer: $e';
      return false;
    } finally {
      _isBusyAction = false;
      notifyListeners();
    }
  }

  Future<bool> approveOrderForPerforma(SalesOrder order) async {
    if (order.customerId == null) {
      _errorMessage =
          'Please approve or verify the new customer lead before approving the order.';
      notifyListeners();
      return false;
    }
    _isBusyAction = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _orderRepo.updateOrderStatus(order.id, 'APPROVED');
      return true;
    } catch (e) {
      _errorMessage = 'Error approving order: $e';
      return false;
    } finally {
      _isBusyAction = false;
      notifyListeners();
    }
  }

  Future<bool> rejectOrder(int orderId) async {
    _isBusyAction = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _orderRepo.updateOrderStatus(orderId, 'REJECTED');
      _successMessage = 'Order #$orderId rejected.';
      await fetchOrders();
      return true;
    } catch (e) {
      _errorMessage = 'Error rejecting order: $e';
      return false;
    } finally {
      _isBusyAction = false;
      notifyListeners();
    }
  }

  Future<FactoryOrder?> fetchFactorySlip(int orderId) async {
    try {
      return await _orderRepo.fetchFactoryViewOrder(orderId);
    } catch (e) {
      _errorMessage = 'Error loading factory slip: $e';
      notifyListeners();
      return null;
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void reset() {
    _activeTab = 'PENDING';
    _orders = const [];
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

