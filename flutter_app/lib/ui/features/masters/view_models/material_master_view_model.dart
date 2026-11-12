import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/domain/models/product.dart';

class MaterialMasterViewModel extends ChangeNotifier {
  MaterialMasterViewModel({required MasterRepository masterRepository})
    : _masterRepo = masterRepository;

  final MasterRepository _masterRepo;

  List<Product> _materials = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;
  String _searchQuery = '';

  int? _editingId;
  String _code = '';
  String _name = '';
  String _category = '';
  String _hsn = '';
  String _tax = '18.00';
  String _unit = 'Kg';
  String _packUnit = 'Bag';
  String _unitQty = '1';
  String _status = 'Active';

  List<Product> get materials => _materials;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get searchQuery => _searchQuery;

  int? get editingId => _editingId;
  String get code => _code;
  String get name => _name;
  String get category => _category;
  String get hsn => _hsn;
  String get tax => _tax;
  String get unit => _unit;
  String get packUnit => _packUnit;
  String get unitQty => _unitQty;
  String get status => _status;

  List<Product> get filteredMaterials {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _materials;
    return _materials.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.code.toLowerCase().contains(q) ||
          (m.category ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _masterRepo.fetchProducts(),
        _masterRepo.fetchNextProductCode(type: 'RM'),
      ]);
      final all = results[0] as List<Product>;
      _materials = all.where((p) => p.isRm).toList();
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

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateField({
    String? code,
    String? name,
    String? category,
    String? hsn,
    String? tax,
    String? unit,
    String? packUnit,
    String? unitQty,
  }) {
    if (code != null) _code = code.toUpperCase();
    if (name != null) _name = name;
    if (category != null) _category = category;
    if (hsn != null) _hsn = hsn;
    if (tax != null) _tax = tax;
    if (unit != null) _unit = unit;
    if (packUnit != null) _packUnit = packUnit;
    if (unitQty != null) _unitQty = unitQty;
    notifyListeners();
  }

  void editMaterial(Product m) {
    _editingId = m.id;
    _code = m.code;
    _name = m.name;
    _category = m.category ?? '';
    _hsn = m.hsn;
    _tax = _normalizeTaxChoice(m.tax);
    _unit = m.unit;
    _packUnit = m.packUnit ?? 'Bag';
    _unitQty = m.unitQty.toString();
    _status = m.status;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  String _normalizeTaxChoice(double value) {
    final s = value.toStringAsFixed(2);
    if (const ['0.00', '5.00', '12.00', '18.00', '28.00'].contains(s)) {
      return s;
    }
    return '18.00';
  }

  Future<void> clearForm() async {
    _editingId = null;
    _name = '';
    _category = '';
    _hsn = '';
    _tax = '18.00';
    _unit = 'Kg';
    _packUnit = 'Bag';
    _unitQty = '1';
    _status = 'Active';
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      _code = await _masterRepo.fetchNextProductCode(type: 'RM');
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

  Future<bool> saveMaterial() async {
    if (_code.trim().isEmpty || _name.trim().isEmpty) {
      _errorMessage = 'Material Code and Name are required.';
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
          type: 'RM',
          category: _category.trim(),
          hsn: _hsn.trim(),
          tax: double.tryParse(_tax) ?? 18.0,
          rate: 0.0,
          boxesPerCase: 1,
          unitQty: (int.tryParse(_unitQty.trim()) ?? 1).clamp(1, 999999),
          unit: _unit,
          packUnit: _packUnit,
          status: _status,
        ),
      );
      await clearForm();
      final all = await _masterRepo.fetchProducts();
      _materials = all.where((p) => p.isRm).toList();
      _successMessage = 'Material $savedCode saved successfully!';
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatus(Product m) async {
    final nextStatus = m.isActive ? 'Inactive' : 'Active';
    _errorMessage = null;
    try {
      await _masterRepo.saveProduct(
        Product(
          id: m.id,
          code: m.code,
          name: m.name,
          type: 'RM',
          category: m.category,
          hsn: m.hsn,
          tax: m.tax,
          rate: m.rate,
          boxesPerCase: m.boxesPerCase,
          unitQty: m.unitQty,
          unit: m.unit,
          packUnit: m.packUnit,
          status: nextStatus,
        ),
      );
      final all = await _masterRepo.fetchProducts();
      _materials = all.where((p) => p.isRm).toList();
      _successMessage = 'Material "${m.name}" marked as $nextStatus!';
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    }
    notifyListeners();
  }

  void reset() {
    _materials = const [];
    _searchQuery = '';
    _code = '';
    _editingId = null;
    _name = '';
    _category = '';
    _hsn = '';
    _tax = '18.00';
    _unit = 'Kg';
    _packUnit = 'Bag';
    _unitQty = '1';
    _status = 'Active';
    _errorMessage = null;
    _successMessage = null;
  }
}
