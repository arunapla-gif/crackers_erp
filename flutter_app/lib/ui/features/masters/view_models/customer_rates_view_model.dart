import 'package:flutter/foundation.dart';

import 'package:crackers_erp/core/utils/product_sorting.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/domain/models/product.dart';

class CustomerRatesViewModel extends ChangeNotifier {
  CustomerRatesViewModel({required MasterRepository masterRepository})
    : _masterRepo = masterRepository;

  final MasterRepository _masterRepo;

  List<Customer> _customers = const [];
  List<Product> _products = const [];
  Customer? _selectedCustomer;
  Map<int, String> _rateInputs = const {};
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingRates = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  List<Customer> get customers => _customers;
  List<Product> get products => _products;
  Customer? get selectedCustomer => _selectedCustomer;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isLoadingRates => _isLoadingRates;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  String rateTextFor(int productId) => _rateInputs[productId] ?? '';

  int get customRateCount => _rateInputs.values
      .where((v) => v.trim().isNotEmpty && double.tryParse(v.trim()) != null)
      .length;

  Map<String, List<Product>> get groupedProducts {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = _products.where((p) {
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q) ||
          (p.category ?? '').toLowerCase().contains(q) ||
          (p.subCategory ?? '').toLowerCase().contains(q);
    });

    final map = <String, List<Product>>{};
    for (final p in filtered) {
      final key = p.displaySubCategory;
      map.putIfAbsent(key, () => []).add(p);
    }

    final sortedKeys = map.keys.toList()..sort(compareSubCategories);
    final ordered = <String, List<Product>>{};
    for (final key in sortedKeys) {
      final list = map[key]!
        ..sort((a, b) => compareProductNamesByNumericOrder(a.name, b.name));
      ordered[key] = list;
    }
    return ordered;
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _masterRepo.fetchCustomers(),
        _masterRepo.fetchProducts(),
      ]);
      _customers = results[0] as List<Customer>;
      final allProducts = results[1] as List<Product>;
      _products = allProducts.where((p) => !p.isWip && !p.isRm).toList();
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCustomer(Customer? customer) async {
    _selectedCustomer = customer;
    _rateInputs = const {};
    _errorMessage = null;
    _successMessage = null;
    if (customer == null) {
      notifyListeners();
      return;
    }

    _isLoadingRates = true;
    notifyListeners();
    try {
      final prices = await _masterRepo.fetchCustomerPrices(customer.id);
      final map = <int, String>{};
      for (final cp in prices) {
        map[cp.productId] = cp.rate.toStringAsFixed(2);
      }
      _rateInputs = map;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoadingRates = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCustomRate(int productId, String rawValue) {
    final next = Map<int, String>.from(_rateInputs);
    if (rawValue.trim().isEmpty) {
      next.remove(productId);
    } else {
      next[productId] = rawValue;
    }
    _rateInputs = next;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> saveRates() async {
    final customer = _selectedCustomer;
    if (customer == null) return;
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final payload = <Map<String, dynamic>>[];
      _rateInputs.forEach((productId, value) {
        final trimmed = value.trim();
        if (trimmed.isNotEmpty) {
          final parsed = double.tryParse(trimmed);
          if (parsed != null) {
            payload.add({'productId': productId, 'rate': parsed});
          }
        }
      });
      await _masterRepo.saveCustomerPrices(customer.id, payload);
      _successMessage =
          'Custom rates saved for ${customer.name} (${payload.length} overrides)!';
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    _customers = const [];
    _products = const [];
    _selectedCustomer = null;
    _rateInputs = const {};
    _searchQuery = '';
    _errorMessage = null;
    _successMessage = null;
  }
}
