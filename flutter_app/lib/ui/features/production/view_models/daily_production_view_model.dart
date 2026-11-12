import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/employee_repository.dart';
import 'package:crackers_erp/data/repositories/production_repository.dart';
import 'package:crackers_erp/domain/models/daily_production.dart';
import 'package:crackers_erp/domain/models/employee.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import 'package:crackers_erp/domain/models/wip_product.dart';

enum ProductionEntryMode { byItem, byWorker, matrix }

class DailyProductionViewModel extends ChangeNotifier {
  DailyProductionViewModel({
    required ProductionRepository productionRepository,
    required EmployeeRepository employeeRepository,
  }) : _productionRepository = productionRepository,
       _employeeRepository = employeeRepository;

  final ProductionRepository _productionRepository;
  final EmployeeRepository _employeeRepository;

  DateTime _selectedDate = DateTime.now();
  ProductionEntryMode _entryMode = ProductionEntryMode.byItem;
  String _workerSearch = '';
  String _selectedRoleFilter = 'All';
  bool _includeMonthlyWorkers = false;

  List<WipProduct> _wipProducts = const [];
  List<Employee> _employees = const [];
  List<DailyProductionRecord> _dateRecords = const [];
  List<DailyProductionRecord> _recentHistory = const [];

  List<String> _pinnedItemNames = const [];
  final List<String> _activeItemNames = <String>[];

  // Map<employeeId, Map<itemName, qty>>
  Map<int, Map<String, int>> _baselineByEmp = <int, Map<String, int>>{};
  Map<int, Map<String, int>> _draftByEmp = <int, Map<String, int>>{};

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasRestoredLocalDraft = false;
  String? _errorMessage;
  String? _statusMessage;
  bool _disposed = false;

  DateTime get selectedDate => _selectedDate;
  String get selectedIsoDate => toIsoCalendarDate(_selectedDate);
  ProductionEntryMode get entryMode => _entryMode;
  String get workerSearch => _workerSearch;
  String get selectedRoleFilter => _selectedRoleFilter;
  bool get includeMonthlyWorkers => _includeMonthlyWorkers;

  List<WipProduct> get wipProducts => _wipProducts;
  List<Employee> get employees => _employees;
  List<DailyProductionRecord> get dateRecords => _dateRecords;
  List<DailyProductionRecord> get recentHistory => _recentHistory;
  List<String> get pinnedItemNames => _pinnedItemNames;
  List<String> get activeItemNames => List.unmodifiable(_activeItemNames);

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasRestoredLocalDraft => _hasRestoredLocalDraft;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  List<Employee> get activeWorkers {
    final active = _employees.where((e) => e.isActive).toList();
    if (_includeMonthlyWorkers) return active;
    final contractual = active.where((e) => e.isContractual).toList();
    return contractual.isNotEmpty ? contractual : active;
  }

  List<String> get availableRoles {
    final roles = SplayTreeSet<String>.from(
      activeWorkers.map((e) => e.roleGroup),
    );
    return ['All', ...roles];
  }

  List<Employee> get filteredWorkers {
    final q = _workerSearch.trim().toLowerCase();
    return activeWorkers.where((emp) {
      if (_selectedRoleFilter != 'All' && emp.roleGroup != _selectedRoleFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return emp.name.toLowerCase().contains(q) ||
          emp.roleGroup.toLowerCase().contains(q) ||
          (emp.unit ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Map<String, List<Employee>> get filteredWorkersByRole {
    final grouped = SplayTreeMap<String, List<Employee>>(
      (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
    );
    for (final emp in filteredWorkers) {
      grouped.putIfAbsent(emp.roleGroup, () => <Employee>[]).add(emp);
    }
    return grouped;
  }

  int get totalPiecesEntered {
    var total = 0;
    for (final empItems in _draftByEmp.values) {
      for (final qty in empItems.values) {
        if (qty > 0) total += qty;
      }
    }
    return total;
  }

  int get activeWorkersLoggedCount {
    var count = 0;
    for (final empItems in _draftByEmp.values) {
      if (empItems.values.any((qty) => qty > 0)) {
        count++;
      }
    }
    return count;
  }

  bool get hasUnsavedChanges {
    final dirtyIds = _changedEmployeeIds();
    return dirtyIds.isNotEmpty;
  }

  int getQuantity(int employeeId, String itemName) {
    return _draftByEmp[employeeId]?[itemName] ?? 0;
  }

  int getItemTotalQuantity(String itemName) {
    var total = 0;
    for (final empItems in _draftByEmp.values) {
      total += empItems[itemName] ?? 0;
    }
    return total;
  }

  int getWorkerTotalQuantity(int employeeId) {
    final items = _draftByEmp[employeeId];
    if (items == null) return 0;
    return items.values.fold(0, (sum, q) => sum + q);
  }

  Map<String, int> getWorkerEntries(int employeeId) {
    final items = _draftByEmp[employeeId];
    if (items == null) return const {};
    return Map<String, int>.fromEntries(
      items.entries.where((e) => e.value > 0),
    );
  }

  WipProduct? findWipProductByName(String name) {
    final lower = name.trim().toLowerCase();
    for (final product in _wipProducts) {
      if (product.name.toLowerCase() == lower) return product;
    }
    return null;
  }

  Future<void> loadInitialData() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      _pinnedItemNames = _productionRepository.loadPinnedItems();

      final results = await Future.wait<dynamic>([
        _productionRepository.fetchWipProducts(),
        _employeeRepository.fetchEmployees(),
        _productionRepository.fetchDailyProductions(date: selectedIsoDate),
        _productionRepository.fetchDailyProductions(limit: 40),
      ]);

      _wipProducts = results[0] as List<WipProduct>;
      _employees = results[1] as List<Employee>;
      _dateRecords = results[2] as List<DailyProductionRecord>;
      _recentHistory = results[3] as List<DailyProductionRecord>;

      _syncDayStateFromRecords(_dateRecords, checkLocalDraft: true);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load production workspace.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> selectDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);
    if (toIsoCalendarDate(normalized) == selectedIsoDate && !_isLoading) {
      return;
    }
    _selectedDate = normalized;
    _isLoading = true;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      final records = await _productionRepository.fetchDailyProductions(
        date: selectedIsoDate,
      );
      _dateRecords = records;
      _syncDayStateFromRecords(records, checkLocalDraft: true);
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load production for $selectedIsoDate.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  Future<void> refreshAll() async {
    await loadInitialData();
  }

  void setEntryMode(ProductionEntryMode mode) {
    if (_entryMode == mode) return;
    _entryMode = mode;
    _safeNotify();
  }

  void setWorkerSearch(String value) {
    _workerSearch = value;
    _safeNotify();
  }

  void setRoleFilter(String role) {
    _selectedRoleFilter = role;
    _safeNotify();
  }

  void toggleIncludeMonthlyWorkers(bool value) {
    _includeMonthlyWorkers = value;
    if (!availableRoles.contains(_selectedRoleFilter)) {
      _selectedRoleFilter = 'All';
    }
    _safeNotify();
  }

  void setQuantity(int employeeId, String itemName, int quantity) {
    final cleanQty = quantity < 0 ? 0 : quantity;
    final currentMap = _draftByEmp.putIfAbsent(employeeId, () => <String, int>{});
    if (cleanQty == 0) {
      currentMap.remove(itemName);
      if (currentMap.isEmpty) {
        _draftByEmp.remove(employeeId);
      }
    } else {
      currentMap[itemName] = cleanQty;
      if (!_activeItemNames.contains(itemName)) {
        _activeItemNames.add(itemName);
      }
    }
    _statusMessage = null;
    _persistDraftSnapshot();
    _safeNotify();
  }

  void incrementQuantity(int employeeId, String itemName, int delta) {
    final next = getQuantity(employeeId, itemName) + delta;
    setQuantity(employeeId, itemName, next);
  }

  void addActiveItem(String itemName) {
    if (!_activeItemNames.contains(itemName)) {
      _activeItemNames.add(itemName);
      _safeNotify();
    }
  }

  void removeActiveItem(String itemName) {
    _activeItemNames.remove(itemName);
    _safeNotify();
  }

  Future<void> togglePinnedItem(String itemName) async {
    final next = List<String>.from(_pinnedItemNames);
    if (next.contains(itemName)) {
      next.remove(itemName);
    } else {
      next.add(itemName);
      if (!_activeItemNames.contains(itemName)) {
        _activeItemNames.add(itemName);
      }
    }
    _pinnedItemNames = next;
    _safeNotify();
    await _productionRepository.savePinnedItems(next);
  }

  Future<void> discardDraft() async {
    _draftByEmp = _cloneMatrix(_baselineByEmp);
    _hasRestoredLocalDraft = false;
    _rebuildActiveItems();
    await _productionRepository.clearDraft(selectedIsoDate);
    _statusMessage = 'Unsaved draft discarded.';
    _safeNotify();
  }

  void clearDayEntries() {
    _draftByEmp = <int, Map<String, int>>{};
    _statusMessage = 'Cleared quantities for $selectedIsoDate.';
    _persistDraftSnapshot();
    _safeNotify();
  }

  Future<bool> saveAll() async {
    final changedIds = _changedEmployeeIds();
    if (changedIds.isEmpty) {
      _statusMessage = 'Everything is already up to date.';
      _safeNotify();
      return true;
    }

    _isSaving = true;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      final entries = changedIds.map((empId) {
        final itemMap = _draftByEmp[empId] ?? const <String, int>{};
        final items = itemMap.entries
            .where((e) => e.value > 0 && e.key.trim().isNotEmpty)
            .map((e) => {'itemName': e.key, 'quantity': e.value})
            .toList();
        return {'employeeId': empId, 'items': items};
      }).toList();

      await _productionRepository.saveDailyProductionBulk(
        date: selectedIsoDate,
        entries: entries,
      );

      await _productionRepository.clearDraft(selectedIsoDate);
      _hasRestoredLocalDraft = false;

      final refreshed = await Future.wait<List<DailyProductionRecord>>([
        _productionRepository.fetchDailyProductions(date: selectedIsoDate),
        _productionRepository.fetchDailyProductions(limit: 40),
      ]);
      _dateRecords = refreshed[0];
      _recentHistory = refreshed[1];
      _syncDayStateFromRecords(_dateRecords, checkLocalDraft: false);
      _statusMessage = 'Saved production log for $selectedIsoDate.';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to save daily production log.';
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  Future<bool> deleteHistoryRecord(DailyProductionRecord record) async {
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      await _productionRepository.deleteDailyProduction(record.id);
      _recentHistory = _recentHistory.where((r) => r.id != record.id).toList();
      if (record.isoDate == selectedIsoDate) {
        final refreshed = await _productionRepository.fetchDailyProductions(
          date: selectedIsoDate,
        );
        _dateRecords = refreshed;
        _syncDayStateFromRecords(refreshed, checkLocalDraft: false);
      }
      _statusMessage = 'Deleted production entry for ${record.employeeName}.';
      _safeNotify();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _safeNotify();
      return false;
    } catch (_) {
      _errorMessage = 'Failed to delete entry.';
      _safeNotify();
      return false;
    }
  }

  void clearMessages() {
    if (_errorMessage != null || _statusMessage != null) {
      _errorMessage = null;
      _statusMessage = null;
      _safeNotify();
    }
  }

  void reset() {
    _selectedDate = DateTime.now();
    _entryMode = ProductionEntryMode.byItem;
    _workerSearch = '';
    _selectedRoleFilter = 'All';
    _includeMonthlyWorkers = false;
    _wipProducts = const [];
    _employees = const [];
    _dateRecords = const [];
    _recentHistory = const [];
    _activeItemNames.clear();
    _baselineByEmp = <int, Map<String, int>>{};
    _draftByEmp = <int, Map<String, int>>{};
    _isLoading = false;
    _isSaving = false;
    _hasRestoredLocalDraft = false;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();
  }

  void _syncDayStateFromRecords(
    List<DailyProductionRecord> records, {
    required bool checkLocalDraft,
  }) {
    final serverMatrix = <int, Map<String, int>>{};
    for (final rec in records) {
      final empMap = serverMatrix.putIfAbsent(
        rec.employeeId,
        () => <String, int>{},
      );
      for (final item in rec.items) {
        if (item.quantity > 0 && item.itemName.trim().isNotEmpty) {
          empMap[item.itemName] = (empMap[item.itemName] ?? 0) + item.quantity;
        }
      }
    }

    _baselineByEmp = serverMatrix;
    _draftByEmp = _cloneMatrix(serverMatrix);
    _hasRestoredLocalDraft = false;

    if (checkLocalDraft) {
      final localDraft = _productionRepository.loadDraft(selectedIsoDate);
      if (localDraft != null && localDraft.isNotEmpty) {
        _draftByEmp = _cloneMatrix(localDraft);
        _hasRestoredLocalDraft = !_matricesEqual(_draftByEmp, _baselineByEmp);
      }
    }

    _rebuildActiveItems();
  }

  void _rebuildActiveItems() {
    final ordered = <String>[];
    void addUnique(String name) {
      final trimmed = name.trim();
      if (trimmed.isNotEmpty && !ordered.contains(trimmed)) {
        ordered.add(trimmed);
      }
    }

    for (final pinned in _pinnedItemNames) {
      addUnique(pinned);
    }
    for (final empItems in _draftByEmp.values) {
      for (final entry in empItems.entries) {
        if (entry.value > 0) addUnique(entry.key);
      }
    }
    if (ordered.isEmpty) {
      for (final product in _wipProducts.where((p) => p.isActive).take(3)) {
        addUnique(product.name);
      }
    }

    _activeItemNames
      ..clear()
      ..addAll(ordered);
  }

  void _persistDraftSnapshot() {
    if (_matricesEqual(_draftByEmp, _baselineByEmp)) {
      _hasRestoredLocalDraft = false;
      _productionRepository.clearDraft(selectedIsoDate);
    } else {
      _productionRepository.saveDraft(selectedIsoDate, _draftByEmp);
    }
  }

  List<int> _changedEmployeeIds() {
    final allIds = <int>{..._baselineByEmp.keys, ..._draftByEmp.keys};
    final changed = <int>[];
    for (final id in allIds) {
      final base = _normalizedNonZero(_baselineByEmp[id]);
      final draft = _normalizedNonZero(_draftByEmp[id]);
      if (!_mapsEqual(base, draft)) {
        changed.add(id);
      }
    }
    changed.sort();
    return changed;
  }

  static Map<String, int> _normalizedNonZero(Map<String, int>? source) {
    if (source == null) return const {};
    return Map<String, int>.fromEntries(
      source.entries.where((e) => e.value > 0 && e.key.trim().isNotEmpty),
    );
  }

  static bool _mapsEqual(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return false;
    }
    return true;
  }

  static bool _matricesEqual(
    Map<int, Map<String, int>> a,
    Map<int, Map<String, int>> b,
  ) {
    final ids = <int>{...a.keys, ...b.keys};
    for (final id in ids) {
      if (!_mapsEqual(_normalizedNonZero(a[id]), _normalizedNonZero(b[id]))) {
        return false;
      }
    }
    return true;
  }

  static Map<int, Map<String, int>> _cloneMatrix(
    Map<int, Map<String, int>> source,
  ) {
    final clone = <int, Map<String, int>>{};
    source.forEach((empId, items) {
      final nonZero = _normalizedNonZero(items);
      if (nonZero.isNotEmpty) {
        clone[empId] = Map<String, int>.from(nonZero);
      }
    });
    return clone;
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
