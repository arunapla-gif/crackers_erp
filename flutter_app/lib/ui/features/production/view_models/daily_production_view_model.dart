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
  ProductionEntryMode _entryMode = ProductionEntryMode.matrix;
  String _workerSearch = '';
  String _selectedRoleFilter = 'All';
  bool _includeMonthlyWorkers = false;

  List<WipProduct> _wipProducts = const [];
  List<Employee> _employees = const [];
  List<DailyProductionRecord> _dateRecords = const [];
  List<DailyProductionRecord> _recentHistory = const [];

  List<String> _pinnedItemNames = const [];
  final List<String> _activeItemNames = <String>[];
  final Map<String, List<String>> _activeItemsByRole = <String, List<String>>{};

  // Map<employeeId, Map<itemName, qty>>
  Map<int, Map<String, int>> _baselineByEmp = <int, Map<String, int>>{};
  Map<int, Map<String, int>> _draftByEmp = <int, Map<String, int>>{};
  // On-demand Temp Roster: Map<isoDate, Set<employeeId>>
  final Map<String, Set<int>> _selectedTempIdsByDate = <String, Set<int>>{};

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
  Map<String, List<String>> get activeItemsByRole => Map.unmodifiable(_activeItemsByRole);

  List<String> getActiveItemsForRole(String role) {
    if (_activeItemsByRole.containsKey(role) && _activeItemsByRole[role]!.isNotEmpty) {
      return List.unmodifiable(_activeItemsByRole[role]!);
    }
    final derived = _deriveActiveItemsForRole(role);
    _activeItemsByRole[role] = derived;
    return List.unmodifiable(derived);
  }

  void addActiveItemForRole(String role, String itemName) {
    final list = _activeItemsByRole.putIfAbsent(role, () => <String>[]);
    if (!list.contains(itemName)) {
      list.add(itemName);
    }
    sortItemNamesByCategoryOrder(list);
    if (!_activeItemNames.contains(itemName)) {
      _activeItemNames.add(itemName);
    }
    sortItemNamesByCategoryOrder(_activeItemNames);
    _safeNotify();
  }

  void removeActiveItemForRole(String role, String itemName, {bool clearDraft = false}) {
    final list = _activeItemsByRole[role];
    if (list != null) {
      list.remove(itemName);
    }
    if (clearDraft) {
      final roleWorkers = activeWorkers.where(
        (e) => e.roleGroup.trim().toLowerCase() == role.trim().toLowerCase(),
      );
      for (final emp in roleWorkers) {
        _draftByEmp[emp.id]?.remove(itemName);
      }
      _persistDraftSnapshot();
    }
    final anyRoleUsing = _activeItemsByRole.values.any((items) => items.contains(itemName));
    if (!anyRoleUsing) {
      _activeItemNames.remove(itemName);
    }
    _safeNotify();
  }

  int getRoleTotalQuantity(String role) {
    var total = 0;
    final workers = activeWorkers.where(
      (e) => e.roleGroup.trim().toLowerCase() == role.trim().toLowerCase(),
    );
    for (final w in workers) {
      final items = _draftByEmp[w.id];
      if (items != null) {
        for (final qty in items.values) {
          if (qty > 0) total += qty;
        }
      }
    }
    return total;
  }

  int getRoleItemTotalQuantity(String role, String itemName) {
    var total = 0;
    final workers = activeWorkers.where(
      (e) => e.roleGroup.trim().toLowerCase() == role.trim().toLowerCase(),
    );
    for (final w in workers) {
      total += _draftByEmp[w.id]?[itemName] ?? 0;
    }
    return total;
  }

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasRestoredLocalDraft => _hasRestoredLocalDraft;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  List<Employee> get _eligibleActiveEmployees {
    final active = _employees.where((e) => e.isActive).toList();
    if (_includeMonthlyWorkers) return active;
    final contractual = active.where((e) => e.isContractual).toList();
    return contractual.isNotEmpty ? contractual : active;
  }

  /// All active temporary workers in the pool (for the On-Demand Temp Roster picker).
  List<Employee> get allTemporaryWorkers {
    final temps = _employees
        .where((e) => e.isActive && e.isTemporary)
        .toList();
    temps.sort((a, b) {
      final roleCmp = compareRoles(a.roleGroup, b.roleGroup);
      if (roleCmp != 0) return roleCmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return temps;
  }

  /// Whether a temporary worker is included on the currently selected date's roster
  /// (either explicitly checked in or already having saved/draft pieces for this date).
  bool isTempWorkerOnTodayRoster(int employeeId) {
    final manualIds = _selectedTempIdsByDate[selectedIsoDate];
    if (manualIds != null && manualIds.contains(employeeId)) return true;
    final draftItems = _draftByEmp[employeeId];
    if (draftItems != null && draftItems.values.any((q) => q > 0)) return true;
    final baseItems = _baselineByEmp[employeeId];
    if (baseItems != null && baseItems.values.any((q) => q > 0)) return true;
    return false;
  }

  /// Whether a temporary worker has saved or draft pieces on the selected date
  /// (locked onto the roster until cleared).
  bool tempWorkerHasPiecesForDate(int employeeId) {
    final draftItems = _draftByEmp[employeeId];
    if (draftItems != null && draftItems.values.any((q) => q > 0)) return true;
    final baseItems = _baselineByEmp[employeeId];
    if (baseItems != null && baseItems.values.any((q) => q > 0)) return true;
    return false;
  }

  Set<int> get selectedTempIdsForDate {
    final ids = <int>{};
    for (final emp in allTemporaryWorkers) {
      if (isTempWorkerOnTodayRoster(emp.id)) {
        ids.add(emp.id);
      }
    }
    return ids;
  }

  int get temporaryPoolCount => allTemporaryWorkers.length;

  int get selectedTempCountForDate => selectedTempIdsForDate.length;

  void addTempWorkerToDateRoster(int employeeId) {
    final set = _selectedTempIdsByDate.putIfAbsent(
      selectedIsoDate,
      () => <int>{},
    );
    if (set.add(employeeId)) {
      _safeNotify();
    }
  }

  void setTempRosterForDate(Set<int> employeeIds) {
    _selectedTempIdsByDate[selectedIsoDate] = Set<int>.from(employeeIds);
    _safeNotify();
  }

  List<Employee> get activeWorkers {
    return _eligibleActiveEmployees.where((e) {
      if (!e.isTemporary) return true;
      return isTempWorkerOnTodayRoster(e.id);
    }).toList();
  }

  /// Canonical factory roles in fixed sequence: Tape, Chemical, Valayam Contract.
  static const List<String> canonicalFixedRoles = [
    'Tape',
    'Chemical',
    'Valayam Contract',
  ];

  /// Natural numeric comparator so "400 COUNT" < "600 COUNT" < "700 COUNT" < "800 COUNT" < "1000 COUNT".
  static final RegExp _naturalTokenRegex = RegExp(r'(\d+|\D+)');

  static int compareNatural(String a, String b) {
    final cleanA = a.trim().toLowerCase();
    final cleanB = b.trim().toLowerCase();
    if (cleanA == cleanB) return 0;
    if (cleanA.isEmpty) return 1;
    if (cleanB.isEmpty) return -1;

    final tokensA = _naturalTokenRegex
        .allMatches(cleanA)
        .map((m) => m.group(0)!)
        .toList();
    final tokensB = _naturalTokenRegex
        .allMatches(cleanB)
        .map((m) => m.group(0)!)
        .toList();

    final minLen =
        tokensA.length < tokensB.length ? tokensA.length : tokensB.length;
    for (var i = 0; i < minLen; i++) {
      final tA = tokensA[i];
      final tB = tokensB[i];
      if (tA == tB) continue;
      final numA = int.tryParse(tA);
      final numB = int.tryParse(tB);
      if (numA != null && numB != null) {
        final cmp = numA.compareTo(numB);
        if (cmp != 0) return cmp;
      }
      return tA.compareTo(tB);
    }
    return tokensA.length.compareTo(tokensB.length);
  }

  /// Sorts WIP products by Category (canonical roles first, empty last),
  /// then Sub-Category in natural numeric order (e.g. 400 COUNT, 600 COUNT, 700 COUNT, 800 COUNT),
  /// then Product Name in natural numeric order.
  static int compareWipProducts(WipProduct a, WipProduct b) {
    final catA = (a.category ?? '').trim();
    final catB = (b.category ?? '').trim();
    if (catA.isEmpty != catB.isEmpty) {
      return catA.isEmpty ? 1 : -1;
    }
    if (catA.isNotEmpty) {
      final catCmp = compareRoles(catA, catB);
      if (catCmp != 0) return catCmp;
    }

    final subA = (a.subCategory ?? '').trim();
    final subB = (b.subCategory ?? '').trim();
    if (subA.isEmpty != subB.isEmpty) {
      return subA.isEmpty ? 1 : -1;
    }
    if (subA.isNotEmpty) {
      final subCmp = compareNatural(subA, subB);
      if (subCmp != 0) return subCmp;
    }

    return compareNatural(a.name, b.name);
  }

  /// Returns active WIP products ordered by Category -> Sub-Category (natural) -> Name.
  List<WipProduct> get sortedWipProducts {
    final list = List<WipProduct>.from(_wipProducts);
    list.sort(compareWipProducts);
    return list;
  }

  static List<String> _keywordsForRole(String role) {
    final cleanRole = role.trim().toLowerCase();
    if (cleanRole == 'tape') {
      return const ['tape', 'டேப்'];
    } else if (cleanRole == 'chemical') {
      return const ['chemical', 'dipping', 'கெமிக்கல்', 'டீப்பிங்'];
    } else if (cleanRole == 'valayam contract' || cleanRole == 'valayam') {
      return const ['valayam', 'ring', 'வளையம்'];
    } else if (cleanRole == 'box packing' || cleanRole == 'packing') {
      return const ['packing', 'pack', 'box', 'பேக்கிங்'];
    } else if (cleanRole == 'rolling') {
      return const ['rolling', 'roll', 'ரோலிங்'];
    } else if (cleanRole == 'filling') {
      return const ['filling', 'fill', 'ஃபில்லிங்'];
    }
    return [cleanRole];
  }

  /// Matches a WIP product to a worker department/role:
  /// If the product has a `category` set in DB, matches strictly on `category`
  /// (so `category = Tape` goes to Tape workers). Falls back to name/subCategory
  /// keywords only when `category` is blank.
  bool doesWipProductMatchRole(WipProduct prod, String role) {
    final cleanRole = role.trim().toLowerCase();
    if (cleanRole.isEmpty || cleanRole == 'all') return true;
    final keywords = _keywordsForRole(cleanRole);
    final catLower = (prod.category ?? '').trim().toLowerCase();
    if (catLower.isNotEmpty) {
      if (catLower == cleanRole) return true;
      return keywords.any((kw) => catLower.contains(kw) || cleanRole.contains(catLower));
    }
    final nameLower = prod.name.toLowerCase();
    final subLower = (prod.subCategory ?? '').toLowerCase();
    return keywords.any((kw) => nameLower.contains(kw) || subLower.contains(kw));
  }

  void sortItemNamesByCategoryOrder(List<String> names) {
    names.sort((a, b) {
      final prodA = findWipProductByName(a);
      final prodB = findWipProductByName(b);
      if (prodA != null && prodB != null) {
        return compareWipProducts(prodA, prodB);
      }
      if (prodA != null) return -1;
      if (prodB != null) return 1;
      return compareNatural(a, b);
    });
  }

  /// Strict comparator that prioritizes canonical factory roles, then sorts alphabetically.
  static int compareRoles(String a, String b) {
    if (a == b) return 0;
    final cleanA = a.trim().toLowerCase();
    final cleanB = b.trim().toLowerCase();
    if (cleanA == cleanB) return a.compareTo(b);

    final indexA = canonicalFixedRoles.indexWhere((r) => r.toLowerCase() == cleanA);
    final indexB = canonicalFixedRoles.indexWhere((r) => r.toLowerCase() == cleanB);
    if (indexA != -1 && indexB != -1) {
      return indexA.compareTo(indexB);
    }
    if (indexA != -1) return -1;
    if (indexB != -1) return 1;
    return cleanA.compareTo(cleanB);
  }

  /// Maps factory roles to their Tamil designations for floor supervisors.
  static String getRoleTamilName(String role) {
    final clean = role.trim().toLowerCase();
    if (clean == 'tape') return 'டேப்';
    if (clean == 'chemical') return 'கெமிக்கல்';
    if (clean == 'valayam contract' || clean == 'valayam') return 'வளையம் ஒப்பந்தம்';
    if (clean == 'box packing' || clean == 'packing') return 'பேக்கிங்';
    if (clean == 'rolling') return 'ரோலிங்';
    if (clean == 'filling') return 'ஃபில்லிங்';
    return '';
  }

  /// Headcount of active workers assigned to the given role (or all active if 'All').
  int getWorkerCountForRole(String role) {
    if (role == 'All') return activeWorkers.length;
    return activeWorkers.where(
      (e) => e.roleGroup.trim().toLowerCase() == role.trim().toLowerCase(),
    ).length;
  }

  List<String> get availableRoles {
    final activeRoles = activeWorkers.map((e) => e.roleGroup).toSet();
    final sortedRoles = activeRoles.toList()..sort(compareRoles);
    return ['All', ...sortedRoles];
  }

  List<Employee> get filteredWorkers {
    final q = _workerSearch.trim().toLowerCase();
    final list = activeWorkers.where((emp) {
      if (_selectedRoleFilter != 'All' && emp.roleGroup != _selectedRoleFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return emp.matchesSearchQuery(_workerSearch) ||
          emp.roleGroup.toLowerCase().contains(q) ||
          (emp.unit ?? '').toLowerCase().contains(q);
    }).toList();

    list.sort((a, b) {
      final roleCmp = compareRoles(a.roleGroup, b.roleGroup);
      if (roleCmp != 0) return roleCmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }

  Map<String, List<Employee>> get filteredWorkersByRole {
    final grouped = SplayTreeMap<String, List<Employee>>(compareRoles);
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
      final savedModeName = _productionRepository.loadEntryMode();
      if (savedModeName != null) {
        for (final mode in ProductionEntryMode.values) {
          if (mode.name == savedModeName) {
            _entryMode = mode;
            break;
          }
        }
      }

      final results = await Future.wait<dynamic>([
        _productionRepository.fetchWipProducts(),
        _employeeRepository.fetchEmployees(),
        _productionRepository.fetchDailyProductions(date: selectedIsoDate),
        _productionRepository.fetchDailyProductions(limit: 40),
      ]);

      final fetchedWip = List<WipProduct>.from(results[0] as List<WipProduct>)
        ..sort(compareWipProducts);
      _wipProducts = fetchedWip;
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

  Future<bool> copyFromPreviousDay({DateTime? sourceDate}) async {
    final prevDate = sourceDate ?? _selectedDate.subtract(const Duration(days: 1));
    final prevIsoDate = toIsoCalendarDate(prevDate);

    _isLoading = true;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      final records = await _productionRepository.fetchDailyProductions(
        date: prevIsoDate,
      );
      if (records.isEmpty) {
        _errorMessage = 'No production records found for $prevIsoDate.';
        return false;
      }

      final newDraft = <int, Map<String, int>>{};
      for (final rec in records) {
        final empItems = newDraft.putIfAbsent(rec.employeeId, () => <String, int>{});
        for (final item in rec.items) {
          if (item.quantity > 0 && item.itemName.trim().isNotEmpty) {
            empItems[item.itemName] = item.quantity;
          }
        }
      }

      _draftByEmp = newDraft;
      _rebuildActiveItems();
      _persistDraftSnapshot();
      _hasRestoredLocalDraft = true;
      _statusMessage = 'Prefilled ${records.length} worker entries from $prevIsoDate.';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to copy previous day worksheet.';
      return false;
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  String generateCsv() {
    final buffer = StringBuffer();
    buffer.writeln('Date,Department,Worker ID,Worker Name,Item Name,Quantity');
    final groupedRoles = filteredWorkersByRole;
    for (final roleEntry in groupedRoles.entries) {
      final role = roleEntry.key;
      for (final emp in roleEntry.value) {
        final entries = getWorkerEntries(emp.id);
        for (final item in entries.entries) {
          if (item.value > 0) {
            final cleanName = '"${emp.name.replaceAll('"', '""')}"';
            final cleanItem = '"${item.key.replaceAll('"', '""')}"';
            buffer.writeln('$selectedIsoDate,$role,${emp.id},$cleanName,$cleanItem,${item.value}');
          }
        }
      }
    }
    return buffer.toString();
  }

  void setEntryMode(ProductionEntryMode mode) {
    if (_entryMode == mode) return;
    _entryMode = mode;
    _productionRepository.saveEntryMode(mode.name);
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
      final emp = _employees.cast<Employee?>().firstWhere(
        (e) => e?.id == employeeId,
        orElse: () => null,
      );
      if (emp != null) {
        final list = _activeItemsByRole.putIfAbsent(emp.roleGroup, () => <String>[]);
        if (!list.contains(itemName)) {
          list.add(itemName);
        }
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
    }
    sortItemNamesByCategoryOrder(_activeItemNames);
    if (_selectedRoleFilter != 'All') {
      addActiveItemForRole(_selectedRoleFilter, itemName);
    } else {
      for (final role in availableRoles) {
        if (role != 'All') {
          final list = _activeItemsByRole.putIfAbsent(role, () => <String>[]);
          if (!list.contains(itemName)) {
            list.add(itemName);
          }
          sortItemNamesByCategoryOrder(list);
        }
      }
    }
    _safeNotify();
  }

  void removeActiveItem(String itemName, {bool clearDraft = false}) {
    _activeItemNames.remove(itemName);
    for (final list in _activeItemsByRole.values) {
      list.remove(itemName);
    }
    if (clearDraft) {
      for (final empItems in _draftByEmp.values) {
        empItems.remove(itemName);
      }
      _persistDraftSnapshot();
    }
    _safeNotify();
  }

  void clearActiveItems() {
    _activeItemNames.clear();
    _activeItemsByRole.clear();
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
    _statusMessage = 'Worksheet draft discarded.';
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
      _statusMessage = 'Saved production worksheet for $selectedIsoDate.';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to save daily production worksheet.';
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
    _entryMode = ProductionEntryMode.matrix;
    _workerSearch = '';
    _selectedRoleFilter = 'All';
    _includeMonthlyWorkers = false;
    _wipProducts = const [];
    _employees = const [];
    _dateRecords = const [];
    _recentHistory = const [];
    _activeItemNames.clear();
    _activeItemsByRole.clear();
    _baselineByEmp = <int, Map<String, int>>{};
    _draftByEmp = <int, Map<String, int>>{};
    _selectedTempIdsByDate.clear();
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

  List<String> _deriveActiveItemsForRole(String role) {
    final cleanRole = role.trim().toLowerCase();
    final items = <String>[];

    // 1. Logged quantities for this role
    final workersInRole = activeWorkers.where(
      (e) => e.roleGroup.trim().toLowerCase() == cleanRole,
    );
    final workerIds = workersInRole.map((e) => e.id).toSet();
    for (final empId in workerIds) {
      final empItems = _draftByEmp[empId];
      if (empItems != null) {
        for (final entry in empItems.entries) {
          if (entry.value > 0 && !items.contains(entry.key)) {
            items.add(entry.key);
          }
        }
      }
    }

    // 2. Category-based matching in natural sub-category order
    for (final prod in sortedWipProducts.where((p) => p.isActive)) {
      if (doesWipProductMatchRole(prod, role) && !items.contains(prod.name)) {
        items.add(prod.name);
      }
    }

    // 3. Fallback: if no category matched, use pinned items or first active WIP products
    if (items.isEmpty) {
      for (final pinned in _pinnedItemNames) {
        if (!items.contains(pinned)) items.add(pinned);
      }
      if (items.isEmpty) {
        for (final prod in sortedWipProducts.where((p) => p.isActive).take(2)) {
          if (!items.contains(prod.name)) items.add(prod.name);
        }
      }
    }

    sortItemNamesByCategoryOrder(items);
    return items;
  }

  void _rebuildActiveItems() {
    _activeItemsByRole.clear();
    for (final role in availableRoles) {
      if (role != 'All') {
        _activeItemsByRole[role] = _deriveActiveItemsForRole(role);
      }
    }

    final allItems = <String>{};
    for (final list in _activeItemsByRole.values) {
      allItems.addAll(list);
    }
    for (final pinned in _pinnedItemNames) {
      allItems.add(pinned);
    }
    for (final empItems in _draftByEmp.values) {
      for (final entry in empItems.entries) {
        if (entry.value > 0) allItems.add(entry.key);
      }
    }
    if (allItems.isEmpty) {
      for (final p in _wipProducts.where((p) => p.isActive).take(3)) {
        allItems.add(p.name);
      }
    }

    _activeItemNames
      ..clear()
      ..addAll(allItems);
    sortItemNamesByCategoryOrder(_activeItemNames);
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
      if (!_mapsEqualNormalized(_baselineByEmp[id], _draftByEmp[id])) {
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

  static bool _mapsEqualNormalized(Map<String, int>? a, Map<String, int>? b) {
    if (identical(a, b)) return true;
    if ((a == null || a.isEmpty) && (b == null || b.isEmpty)) return true;
    if (a != null) {
      for (final entry in a.entries) {
        final key = entry.key.trim();
        final val = entry.value;
        if (key.isEmpty || val <= 0) continue;
        if ((b?[entry.key] ?? 0) != val) return false;
      }
    }
    if (b != null) {
      for (final entry in b.entries) {
        final key = entry.key.trim();
        final val = entry.value;
        if (key.isEmpty || val <= 0) continue;
        if ((a?[entry.key] ?? 0) != val) return false;
      }
    }
    return true;
  }

  static bool _matricesEqual(
    Map<int, Map<String, int>> a,
    Map<int, Map<String, int>> b,
  ) {
    if (identical(a, b)) return true;
    final ids = <int>{...a.keys, ...b.keys};
    for (final id in ids) {
      if (!_mapsEqualNormalized(a[id], b[id])) {
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

  /// Quickly registers a walk-in Temporary worker directly from Daily Production
  /// without exposing any wage or salary fields.
  Future<Employee?> addQuickTemporaryWorker({
    required String name,
    required String role,
    String? mobile,
    String paymentType = 'Contractual',
  }) async {
    final trimmedName = name.trim();
    final trimmedRole = role.trim();
    if (trimmedName.isEmpty || trimmedRole.isEmpty) {
      _errorMessage = 'Worker name and department are required.';
      _safeNotify();
      return null;
    }

    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      final draft = Employee(
        id: 0,
        name: trimmedName,
        mobile: (mobile == null || mobile.trim().isEmpty)
            ? null
            : mobile.trim(),
        role: trimmedRole,
        paymentType: paymentType,
        employmentType: 'Temporary',
        status: 'Active',
        advanceBalance: 0,
      );
      final saved = await _employeeRepository.saveEmployee(draft);
      final updated = List<Employee>.from(_employees)
        ..removeWhere((e) => e.id == saved.id)
        ..add(saved)
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      _employees = updated;
      _selectedTempIdsByDate
          .putIfAbsent(selectedIsoDate, () => <int>{})
          .add(saved.id);
      if (!saved.isContractual && !_includeMonthlyWorkers) {
        _includeMonthlyWorkers = true;
      }
      _statusMessage =
          'Added temporary worker ${saved.displayEnglishName} (${saved.roleGroup}).';
      _safeNotify();
      return saved;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      _safeNotify();
      return null;
    } catch (e) {
      _errorMessage = 'Could not add temporary worker: $e';
      _safeNotify();
      return null;
    }
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
