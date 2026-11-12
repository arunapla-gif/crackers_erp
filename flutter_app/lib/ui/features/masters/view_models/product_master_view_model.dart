import 'package:flutter/foundation.dart';

import 'package:crackers_erp/core/utils/product_sorting.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/domain/models/product.dart';

class ProductMasterViewModel extends ChangeNotifier {
  ProductMasterViewModel({required MasterRepository masterRepository})
    : _masterRepo = masterRepository;

  final MasterRepository _masterRepo;

  List<Product> _products = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  String _searchQuery = '';

  int? _editingId;
  String _code = '';
  String _name = '';
  String _category = '';
  String _subCategory = '';
  String _type = 'INV';
  String _hsn = '3604';
  String _tax = '18.00';
  String _rate = '0.00';
  String _boxesPerCase = '1';
  String _unitQty = '1';
  String _unit = 'Case';
  String _status = 'Active';
  int? _factoryAliasId;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get searchQuery => _searchQuery;

  int? get editingId => _editingId;
  String get code => _code;
  String get name => _name;
  String get category => _category;
  String get subCategory => _subCategory;
  String get type => _type;
  String get hsn => _hsn;
  String get tax => _tax;
  String get rate => _rate;
  String get boxesPerCase => _boxesPerCase;
  String get unitQty => _unitQty;
  String get unit => _unit;
  String get status => _status;
  int? get factoryAliasId => _factoryAliasId;

  List<Product> get aliasCandidates =>
      _products.where((p) => p.id != _editingId).toList();

  Product? get selectedAlias {
    if (_factoryAliasId == null) return null;
    for (final p in _products) {
      if (p.id == _factoryAliasId) return p;
    }
    return null;
  }

  Map<String, List<Product>> groupedByType(String targetType) {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = _products.where((p) {
      if (p.type.toUpperCase() != targetType) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q) ||
          (p.category ?? '').toLowerCase().contains(q) ||
          (p.subCategory ?? '').toLowerCase().contains(q);
    });

    final groups = <String, List<Product>>{};
    for (final p in filtered) {
      final key = p.displaySubCategory;
      groups.putIfAbsent(key, () => []).add(p);
    }

    final sortedKeys = groups.keys.toList()..sort(compareSubCategories);
    final result = <String, List<Product>>{};
    for (final key in sortedKeys) {
      final list = groups[key]!
        ..sort((a, b) => compareProductNamesByNumericOrder(a.name, b.name));
      result[key] = list;
    }
    return result;
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _masterRepo.fetchProducts(),
        _masterRepo.fetchNextProductCode(type: _type),
      ]);
      _products = results[0] as List<Product>;
      if (_editingId == null && _code.isEmpty) {
        _code = results[1] as String;
      }
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setType(String newType) async {
    _type = newType;
    notifyListeners();
    try {
      _code = await _masterRepo.fetchNextProductCode(type: newType);
    } catch (_) {
      // Keep existing code if offline
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateField({
    String? code,
    String? name,
    String? category,
    String? subCategory,
    String? hsn,
    String? tax,
    String? rate,
    String? boxesPerCase,
    String? unitQty,
    String? unit,
    int? factoryAliasId,
    bool clearFactoryAlias = false,
  }) {
    if (code != null) _code = code.toUpperCase();
    if (name != null) _name = name;
    if (category != null) _category = category.toUpperCase();
    if (subCategory != null) _subCategory = subCategory.toUpperCase();
    if (hsn != null) _hsn = hsn;
    if (tax != null) _tax = tax;
    if (rate != null) _rate = rate;
    if (boxesPerCase != null) _boxesPerCase = boxesPerCase;
    if (unitQty != null) _unitQty = unitQty;
    if (unit != null) _unit = unit;
    if (clearFactoryAlias) {
      _factoryAliasId = null;
    } else if (factoryAliasId != null) {
      _factoryAliasId = factoryAliasId;
    }
    notifyListeners();
  }

  void editProduct(Product p) {
    _editingId = p.id;
    _code = p.code;
    _name = p.name;
    _category = p.category ?? '';
    _subCategory = p.subCategory ?? '';
    _type = p.type;
    _hsn = p.hsn;
    _tax = p.tax.toString();
    _rate = p.rate.toString();
    _boxesPerCase = p.boxesPerCase.toString();
    _unitQty = p.unitQty.toString();
    _unit = p.unit;
    _status = p.status;
    _factoryAliasId = p.factoryAliasId;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> clearForm() async {
    _editingId = null;
    _name = '';
    _category = '';
    _subCategory = '';
    _type = 'INV';
    _hsn = '3604';
    _tax = '18.00';
    _rate = '0.00';
    _boxesPerCase = '1';
    _unitQty = '1';
    _unit = 'Case';
    _status = 'Active';
    _factoryAliasId = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      _code = await _masterRepo.fetchNextProductCode(type: 'INV');
    } catch (_) {
      _code = '';
    }
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> saveProduct() async {
    if (_code.trim().isEmpty || _name.trim().isEmpty) {
      _errorMessage = 'Product Code and Name are required.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final savedCode = _code.trim().toUpperCase();
      await _masterRepo.saveProduct(
        Product(
          id: _editingId ?? 0,
          code: savedCode,
          name: _name.trim(),
          type: _type,
          category: _category.trim(),
          subCategory: _subCategory.trim(),
          hsn: _hsn.trim().isEmpty ? '3604' : _hsn.trim(),
          tax: double.tryParse(_tax.trim()) ?? 18.0,
          rate: double.tryParse(_rate.trim()) ?? 0.0,
          boxesPerCase: (int.tryParse(_boxesPerCase.trim()) ?? 1).clamp(1, 999999),
          unitQty: (int.tryParse(_unitQty.trim()) ?? 1).clamp(1, 999999),
          unit: _unit,
          status: _status,
          factoryAliasId: _factoryAliasId,
        ),
      );
      await clearForm();
      _products = await _masterRepo.fetchProducts();
      _successMessage = 'Product $savedCode saved successfully!';
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatus(Product p) async {
    final nextStatus = p.isActive ? 'Inactive' : 'Active';
    _errorMessage = null;
    try {
      await _masterRepo.saveProduct(
        Product(
          id: p.id,
          code: p.code,
          name: p.name,
          type: p.type,
          category: p.category,
          subCategory: p.subCategory,
          hsn: p.hsn,
          tax: p.tax,
          rate: p.rate,
          boxesPerCase: p.boxesPerCase,
          unitQty: p.unitQty,
          unit: p.unit,
          packUnit: p.packUnit,
          status: nextStatus,
          factoryAliasId: p.factoryAliasId,
        ),
      );
      _products = await _masterRepo.fetchProducts();
      _successMessage = 'Product "${p.name}" marked as $nextStatus!';
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    }
    notifyListeners();
  }

  void reset() {
    _products = const [];
    _searchQuery = '';
    _code = '';
    _editingId = null;
    _name = '';
    _category = '';
    _subCategory = '';
    _type = 'INV';
    _hsn = '3604';
    _tax = '18.00';
    _rate = '0.00';
    _boxesPerCase = '1';
    _unitQty = '1';
    _unit = 'Case';
    _status = 'Active';
    _factoryAliasId = null;
    _errorMessage = null;
    _successMessage = null;
  }
}
