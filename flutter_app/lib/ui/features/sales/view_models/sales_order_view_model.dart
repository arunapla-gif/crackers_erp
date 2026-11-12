import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:crackers_erp/core/utils/product_sorting.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/repositories/sales_order_repository.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/domain/models/sales_order.dart';
import 'package:crackers_erp/domain/models/user_session.dart';

class SalesOrderViewModel extends ChangeNotifier {
  SalesOrderViewModel({
    required SalesOrderRepository salesOrderRepository,
    required MasterRepository masterRepository,
  }) : _orderRepo = salesOrderRepository,
       _masterRepo = masterRepository;

  final SalesOrderRepository _orderRepo;
  final MasterRepository _masterRepo;

  List<Product> _epProducts = const [];
  List<Customer> _customers = const [];
  List<RepRecentOrder> _recentOrders = const [];
  Map<int, double> _customRates = const {};
  final Map<int, int> _cart = <int, int>{}; // productId -> Cases

  bool _isLoading = false;
  bool _isLoadingHistory = false;
  bool _isVerifyingGstin = false;
  bool _isSubmitting = false;
  bool _isNewCustomer = false;
  String _newCustomerType = 'UNREGISTERED'; // 'GST' | 'UNREGISTERED'
  int? _selectedCustomerId;
  SalesOrderLeadCustomer _lead = const SalesOrderLeadCustomer(name: '');
  String _activeTab = 'NEW_ORDER'; // 'NEW_ORDER' | 'HISTORY'
  String? _errorMessage;
  String? _successMessage;

  List<Product> get epProducts => List.unmodifiable(_epProducts);
  List<Customer> get customers => List.unmodifiable(_customers);
  List<RepRecentOrder> get recentOrders => List.unmodifiable(_recentOrders);
  Map<int, int> get cart => Map.unmodifiable(_cart);
  bool get isLoading => _isLoading;
  bool get isLoadingHistory => _isLoadingHistory;
  bool get isVerifyingGstin => _isVerifyingGstin;
  bool get isSubmitting => _isSubmitting;
  bool get isNewCustomer => _isNewCustomer;
  String get newCustomerType => _newCustomerType;
  int? get selectedCustomerId => _selectedCustomerId;
  SalesOrderLeadCustomer get lead => _lead;
  String get activeTab => _activeTab;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Customer? get selectedCustomer {
    if (_selectedCustomerId == null) return null;
    for (final c in _customers) {
      if (c.id == _selectedCustomerId) return c;
    }
    return null;
  }

  /// Grouped map: Category -> Sorted SubCategory -> Sorted EP Products
  Map<String, Map<String, List<Product>>> get groupedCatalog {
    final map = SplayTreeMap<String, SplayTreeMap<String, List<Product>>>();
    for (final p in _epProducts) {
      final cat = (p.category == null || p.category!.trim().isEmpty)
          ? 'UNCATEGORIZED'
          : p.category!.trim();
      final sub = (p.subCategory == null || p.subCategory!.trim().isEmpty)
          ? 'STANDARD'
          : p.subCategory!.trim();
      map.putIfAbsent(
        cat,
        () => SplayTreeMap<String, List<Product>>(compareSubCategories),
      );
      map[cat]!.putIfAbsent(sub, () => <Product>[]);
      map[cat]![sub]!.add(p);
    }
    for (final subMap in map.values) {
      for (final list in subMap.values) {
        list.sort(
          (a, b) => compareProductNamesByNumericOrder(a.name, b.name),
        );
      }
    }
    return map;
  }

  double rateForProduct(Product p) => _customRates[p.id] ?? p.rate;

  int quantityFor(int productId) => _cart[productId] ?? 0;

  List<SalesOrderItem> get cartItems {
    final result = <SalesOrderItem>[];
    for (final entry in _cart.entries) {
      if (entry.value <= 0) continue;
      Product? match;
      for (final p in _epProducts) {
        if (p.id == entry.key) {
          match = p;
          break;
        }
      }
      if (match == null) continue;
      final rate = rateForProduct(match);
      final total = rate * match.boxesPerCase * entry.value;
      result.add(
        SalesOrderItem(
          productId: match.id,
          product: match.name,
          qty: entry.value,
          rate: rate,
          total: double.parse(total.toStringAsFixed(2)),
        ),
      );
    }
    return result;
  }

  double get subtotal => cartItems.fold(0.0, (sum, item) => sum + item.total);

  Future<void> initialize({UserAccount? user}) async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _masterRepo.fetchProducts(),
        _masterRepo.fetchCustomers(),
      ]);
      var prods = (results[0] as List<Product>)
          .where((p) => p.isActive && p.isEp)
          .toList();
      if (user != null && user.isRep && user.allowedCategories != null) {
        final allowed = user.allowedCategories!;
        if (allowed.isEmpty) {
          prods = [];
        } else {
          prods = prods
              .where(
                (p) =>
                    (p.category != null && allowed.contains(p.category)) ||
                    (p.subCategory != null && allowed.contains(p.subCategory)),
              )
              .toList();
        }
      }
      _epProducts = prods;
      _customers = (results[1] as List<Customer>)
          .where((c) => c.isActive)
          .toList();
    } catch (e) {
      _errorMessage = 'Failed to load catalog: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setTab(String tab) async {
    _activeTab = tab;
    notifyListeners();
    if (tab == 'HISTORY') {
      await loadHistory();
    }
  }

  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final stats = await _orderRepo.fetchRepDashboard();
      _recentOrders = stats.recentOrders;
    } catch (e) {
      _errorMessage = 'Failed to load order history: $e';
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  Future<void> selectCustomer(Customer? customer) async {
    _selectedCustomerId = customer?.id;
    _customRates = const {};
    notifyListeners();
    if (customer != null && !_isNewCustomer) {
      try {
        final prices = await _masterRepo.fetchCustomerPrices(customer.id);
        final map = <int, double>{};
        for (final p in prices) {
          map[p.productId] = p.rate;
        }
        _customRates = map;
        notifyListeners();
      } catch (_) {}
    }
  }

  void toggleNewCustomer(bool isNew) {
    _isNewCustomer = isNew;
    if (isNew) {
      _selectedCustomerId = null;
      _customRates = const {};
    }
    notifyListeners();
  }

  void setNewCustomerType(String type) {
    _newCustomerType = type;
    _lead = SalesOrderLeadCustomer(
      name: _lead.name,
      mobile: _lead.mobile,
      city: _lead.city,
      state: _lead.state,
      pincode: _lead.pincode,
      idNumber: _lead.idNumber,
      gstin: _lead.gstin,
      type: type,
    );
    notifyListeners();
  }

  void updateLead({
    String? name,
    String? mobile,
    String? city,
    String? state,
    String? pincode,
    String? idNumber,
    String? gstin,
  }) {
    _lead = SalesOrderLeadCustomer(
      name: name ?? _lead.name,
      mobile: mobile ?? _lead.mobile,
      city: city ?? _lead.city,
      state: state ?? _lead.state,
      pincode: pincode ?? _lead.pincode,
      idNumber: idNumber ?? _lead.idNumber,
      gstin: gstin ?? _lead.gstin,
      type: _newCustomerType,
    );
    notifyListeners();
  }

  Future<void> verifyGstin() async {
    final g = _lead.gstin.trim().toUpperCase();
    if (g.length != 15) {
      _errorMessage = 'Enter a valid 15-character GSTIN.';
      notifyListeners();
      return;
    }
    _isVerifyingGstin = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final details = await _masterRepo.verifyGstin(g);
      _lead = SalesOrderLeadCustomer(
        name: details.preferredName,
        mobile: _lead.mobile,
        city: details.city,
        state: details.state,
        pincode: details.pincode,
        idNumber: _lead.idNumber,
        gstin: g,
        type: 'GST',
      );
    } catch (e) {
      _errorMessage = 'GSTIN verification failed: $e';
    } finally {
      _isVerifyingGstin = false;
      notifyListeners();
    }
  }

  void setCartQty(int productId, int qty) {
    if (qty <= 0) {
      _cart.remove(productId);
    } else {
      _cart[productId] = qty;
    }
    notifyListeners();
  }

  void incrementCartQty(int productId, int delta) {
    final next = (_cart[productId] ?? 0) + delta;
    setCartQty(productId, next);
  }

  String? _validateOrder() {
    if (!_isNewCustomer && _selectedCustomerId == null) {
      return 'Please select a customer or add a new lead.';
    }
    if (_isNewCustomer) {
      if (_newCustomerType == 'GST' && _lead.gstin.trim().length != 15) {
        return 'Please enter a valid 15-character GSTIN.';
      }
      if (_newCustomerType == 'UNREGISTERED') {
        if (_lead.idNumber.trim().isEmpty) {
          return 'Please provide Aadhaar / PAN for Unregistered customer.';
        }
        if (_lead.pincode.trim().length != 6) {
          return 'Please provide a 6-digit Pincode for Unregistered customer.';
        }
      }
      if (_lead.name.trim().isEmpty) {
        return 'Please provide the customer Name (or Fetch via GSTIN).';
      }
    }
    if (cartItems.isEmpty) {
      return 'Add at least one item to your order.';
    }
    return null;
  }

  Future<bool> submitOrder() async {
    final validationError = _validateOrder();
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _orderRepo.createSalesOrder(
        customerId: _isNewCustomer ? null : _selectedCustomerId,
        newCustomerData: _isNewCustomer ? _lead : null,
        subtotal: double.parse(subtotal.toStringAsFixed(2)),
        items: cartItems,
      );
      _cart.clear();
      _selectedCustomerId = null;
      _customRates = const {};
      _isNewCustomer = false;
      _newCustomerType = 'UNREGISTERED';
      _lead = const SalesOrderLeadCustomer(name: '');
      _successMessage = 'Order submitted successfully for approval!';
      return true;
    } catch (e) {
      _errorMessage = 'Error submitting order: $e';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void reset() {
    _epProducts = const [];
    _customers = const [];
    _recentOrders = const [];
    _customRates = const {};
    _cart.clear();
    _isNewCustomer = false;
    _selectedCustomerId = null;
    _lead = const SalesOrderLeadCustomer(name: '');
    _activeTab = 'NEW_ORDER';
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}

