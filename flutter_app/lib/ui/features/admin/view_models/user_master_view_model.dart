import 'package:flutter/foundation.dart';

import 'package:crackers_erp/core/utils/product_sorting.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/admin_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/domain/models/erp_user.dart';

class ErpPermissionModule {
  const ErpPermissionModule({required this.id, required this.label});

  final String id;
  final String label;
}

class UserMasterViewModel extends ChangeNotifier {
  UserMasterViewModel({
    required AdminRepository adminRepository,
    required MasterRepository masterRepository,
  }) : _adminRepository = adminRepository,
       _masterRepository = masterRepository {
    _modulePermissions = _buildDefaultPermissions();
  }

  static const List<ErpPermissionModule> modules = [
    ErpPermissionModule(id: 'billing', label: 'Billing'),
    ErpPermissionModule(id: 'customers', label: 'Customers'),
    ErpPermissionModule(id: 'suppliers', label: 'Suppliers'),
    ErpPermissionModule(id: 'products', label: 'Products'),
    ErpPermissionModule(id: 'transporters', label: 'Transporters'),
    ErpPermissionModule(id: 'godowns', label: 'Godowns'),
    ErpPermissionModule(id: 'purchase', label: 'Purchase Entry'),
    ErpPermissionModule(id: 'stock', label: 'Stock Ledger'),
    ErpPermissionModule(id: 'vehicles', label: 'Vehicles'),
    ErpPermissionModule(id: 'transfers', label: 'Stock Transfer'),
    ErpPermissionModule(id: 'production', label: 'Production'),
    ErpPermissionModule(id: 'materials', label: 'Materials'),
    ErpPermissionModule(id: 'machines', label: 'Machines'),
    ErpPermissionModule(id: 'employees', label: 'Employees & Advances'),
    ErpPermissionModule(id: 'payroll', label: 'Payroll'),
    ErpPermissionModule(id: 'reports', label: 'Reports'),
  ];

  static Map<String, ErpModulePermission> _buildDefaultPermissions() {
    return {
      for (final m in modules) m.id: const ErpModulePermission(),
    };
  }

  final AdminRepository _adminRepository;
  final MasterRepository _masterRepository;

  List<ErpUser> _users = [];
  List<String> _categories = [];
  List<String> _subCategories = [];
  bool _initialized = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  // Form State
  int? _editingId;
  String _username = '';
  String _pin = '';
  String _role = 'STAFF';
  String _status = 'Active';
  late Map<String, ErpModulePermission> _modulePermissions;
  List<String> _allowedCategories = [];

  List<ErpUser> get users => List.unmodifiable(_users);
  List<String> get categories => List.unmodifiable(_categories);
  List<String> get subCategories => List.unmodifiable(_subCategories);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  int? get editingId => _editingId;
  bool get isEditing => _editingId != null;
  String get username => _username;
  String get pin => _pin;
  String get role => _role;
  String get status => _status;
  bool get isEditingSuperAdmin => _username.trim().toLowerCase() == 'admin';
  Map<String, ErpModulePermission> get modulePermissions =>
      Map.unmodifiable(_modulePermissions);
  List<String> get allowedCategories => List.unmodifiable(_allowedCategories);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedUsers = await _adminRepository.fetchUsers();
      _users = fetchedUsers;

      final products = await _masterRepository.fetchProducts();
      final catSet = <String>{};
      final subCatSet = <String>{};
      for (final p in products) {
        final cat = p.category?.trim() ?? '';
        final subCat = p.subCategory?.trim() ?? '';
        if (cat.isNotEmpty) catSet.add(cat);
        if (subCat.isNotEmpty) subCatSet.add(subCat);
      }
      final cats = catSet.toList()..sort();
      final subCats = subCatSet.toList()..sort(compareSubCategories);
      _categories = cats;
      _subCategories = subCats;
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : 'Failed to load users or categories: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setUsername(String value) {
    if (isEditingSuperAdmin) return;
    _username = value;
  }

  void setPin(String value) {
    _pin = value;
  }

  void setRole(String value) {
    if (isEditingSuperAdmin) return;
    _role = value;
    notifyListeners();
  }

  void setStatus(String value) {
    if (isEditingSuperAdmin) return;
    _status = value;
    notifyListeners();
  }

  void setModulePermission(String moduleId, String action, bool checked) {
    final current =
        _modulePermissions[moduleId] ?? const ErpModulePermission();
    _modulePermissions[moduleId] = switch (action) {
      'view' => current.copyWith(view: checked),
      'add' => current.copyWith(add: checked),
      'edit' => current.copyWith(edit: checked),
      'delete' => current.copyWith(delete: checked),
      _ => current,
    };
    notifyListeners();
  }

  void toggleAllModulePermissions(String moduleId, bool checked) {
    _modulePermissions[moduleId] = ErpModulePermission(
      view: checked,
      add: checked,
      edit: checked,
      delete: checked,
    );
    notifyListeners();
  }

  void toggleCategory(String category) {
    if (_allowedCategories.contains(category)) {
      _allowedCategories = _allowedCategories
          .where((c) => c != category)
          .toList();
    } else {
      _allowedCategories = [..._allowedCategories, category];
    }
    notifyListeners();
  }

  void editUser(ErpUser user) {
    _editingId = user.id;
    _username = user.username;
    _pin = ''; // Never show existing PIN
    _role = user.role;
    _status = user.status;
    _modulePermissions = _buildDefaultPermissions();
    user.modulePermissions.forEach((key, perm) {
      _modulePermissions[key] = perm;
    });
    _allowedCategories = List<String>.from(
      user.allowedCategories ?? const <String>[],
    );
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearForm() {
    _editingId = null;
    _username = '';
    _pin = '';
    _role = 'STAFF';
    _status = 'Active';
    _modulePermissions = _buildDefaultPermissions();
    _allowedCategories = [];
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> saveUser() async {
    if (_username.trim().isEmpty) {
      _errorMessage = 'Username is required.';
      notifyListeners();
      return false;
    }
    if (_editingId == null && _pin.trim().isEmpty) {
      _errorMessage = 'PIN is required for new users.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final user = ErpUser(
        id: _editingId ?? 0,
        username: _username.trim(),
        role: _role,
        status: _status,
        modulePermissions: _role == 'STAFF'
            ? Map<String, ErpModulePermission>.from(_modulePermissions)
            : const {},
        allowedCategories: _role == 'REP'
            ? List<String>.from(_allowedCategories)
            : null,
      );
      await _adminRepository.saveUser(user, pin: _pin.trim());
      _users = await _adminRepository.fetchUsers();
      clearForm();
      _successMessage = 'User saved successfully!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : 'Error saving user: $e';
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> toggleUserStatus(ErpUser user) async {
    if (user.username.trim().toLowerCase() == 'admin') {
      _errorMessage = 'Cannot disable the super admin.';
      notifyListeners();
      return false;
    }

    _errorMessage = null;
    _successMessage = null;
    try {
      final newStatus = user.isActive ? 'Inactive' : 'Active';
      final updated = ErpUser(
        id: user.id,
        username: user.username,
        role: user.role,
        status: newStatus,
        modulePermissions: user.modulePermissions,
        allowedCategories: user.allowedCategories,
      );
      await _adminRepository.saveUser(updated);
      _users = await _adminRepository.fetchUsers();
      _successMessage = 'User marked as $newStatus!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : 'Error updating user status: $e';
      notifyListeners();
      return false;
    }
  }

  void dismissMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void reset() {
    _users = [];
    _categories = [];
    _subCategories = [];
    _initialized = false;
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    _successMessage = null;
    clearForm();
  }
}

