import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/legacy_repository.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import 'package:crackers_erp/domain/models/legacy.dart';

enum LegacyTab {
  menu,
  estimates,
  purchases,
  payments,
  customers,
  suppliers,
  employees,
  workentries;

  String get title => switch (this) {
    LegacyTab.menu => 'Old ERP Portal',
    LegacyTab.estimates => 'ESTIMATES',
    LegacyTab.purchases => 'PURCHASES',
    LegacyTab.payments => 'PAYMENTS',
    LegacyTab.customers => 'CUSTOMERS',
    LegacyTab.suppliers => 'SUPPLIERS',
    LegacyTab.employees => 'EMPLOYEES',
    LegacyTab.workentries => 'WORKENTRIES',
  };

  bool get hasDateFilter =>
      this == LegacyTab.purchases ||
      this == LegacyTab.payments ||
      this == LegacyTab.estimates ||
      this == LegacyTab.workentries;
}

enum LegacySortOption {
  dateDesc,
  dateAsc,
  nameAsc,
  nameDesc,
  amtDesc,
  amtAsc;

  String get label => switch (this) {
    LegacySortOption.dateDesc => 'Newest First',
    LegacySortOption.dateAsc => 'Oldest First',
    LegacySortOption.nameAsc => 'Name (A-Z)',
    LegacySortOption.nameDesc => 'Name (Z-A)',
    LegacySortOption.amtDesc => 'Highest Amount / Balance',
    LegacySortOption.amtAsc => 'Lowest Amount / Balance',
  };
}

class LegacyViewModel extends ChangeNotifier {
  LegacyViewModel({required LegacyRepository legacyRepository})
    : _legacyRepository = legacyRepository;

  final LegacyRepository _legacyRepository;

  static const int itemsPerPage = 50;

  LegacyTab _activeTab = LegacyTab.menu;
  String _searchTerm = '';
  DateTime? _dateFrom;
  DateTime? _dateTo;
  LegacySortOption _sortBy = LegacySortOption.dateDesc;
  int _currentPage = 1;

  bool _initialized = false;
  bool _isLoading = false;
  bool _isTrendsLoading = false;
  String? _errorMessage;

  // Overview analytics & price trends
  LegacyAnalytics? _analytics;
  List<String> _trendProducts = [];
  String _selectedProduct = '';
  List<PriceTrendPoint> _priceTrends = [];

  // Cached collections
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _purchases = [];
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _estimates = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _workentries = [];
  List<Map<String, dynamic>> _payrollProducts = [];

  // Expandable details & lazy caches
  int? _expandedPurchaseId;
  int? _expandedEstimateId;
  int? _expandedWorkId;
  bool _isDetailsLoading = false;

  final Map<int, List<Map<String, dynamic>>> _purchaseItems = {};
  final Map<int, List<Map<String, dynamic>>> _purchaseCharges = {};
  final Map<int, Map<String, dynamic>> _estimateDetails = {};
  final Map<int, List<Map<String, dynamic>>> _workItems = {};

  LegacyTab get activeTab => _activeTab;
  String get searchTerm => _searchTerm;
  DateTime? get dateFrom => _dateFrom;
  DateTime? get dateTo => _dateTo;
  LegacySortOption get sortBy => _sortBy;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  bool get isTrendsLoading => _isTrendsLoading;
  bool get isDetailsLoading => _isDetailsLoading;
  String? get errorMessage => _errorMessage;

  LegacyAnalytics? get analytics => _analytics;
  List<String> get trendProducts => List.unmodifiable(_trendProducts);
  String get selectedProduct => _selectedProduct;
  List<PriceTrendPoint> get priceTrends => List.unmodifiable(_priceTrends);

  int? get expandedPurchaseId => _expandedPurchaseId;
  int? get expandedEstimateId => _expandedEstimateId;
  int? get expandedWorkId => _expandedWorkId;

  List<Map<String, dynamic>> purchaseItemsFor(int purchaseId) =>
      _purchaseItems[purchaseId] ?? const [];
  List<Map<String, dynamic>> purchaseChargesFor(int purchaseId) =>
      _purchaseCharges[purchaseId] ?? const [];
  bool hasPurchaseDetails(int purchaseId) =>
      _purchaseItems.containsKey(purchaseId);

  Map<String, dynamic>? estimateDetailsFor(int salesId) =>
      _estimateDetails[salesId];
  bool hasEstimateDetails(int salesId) =>
      _estimateDetails.containsKey(salesId);

  List<Map<String, dynamic>> workItemsFor(int workId) =>
      _workItems[workId] ?? const [];
  bool hasWorkDetails(int workId) => _workItems.containsKey(workId);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await _loadMenuOverview();
  }

  Future<void> _loadMenuOverview() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        if (_analytics == null) _legacyRepository.fetchAnalytics(),
        if (_trendProducts.isEmpty) _legacyRepository.fetchTrendProducts(),
      ]);
      var idx = 0;
      _analytics ??= results[idx++] as LegacyAnalytics;
      if (_trendProducts.isEmpty) {
        _trendProducts = results[idx] as List<String>;
      }
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : 'Failed to load legacy overview: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectTrendProduct(String product) async {
    _selectedProduct = product;
    if (product.isEmpty) {
      _priceTrends = [];
      notifyListeners();
      return;
    }

    _isTrendsLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _priceTrends = await _legacyRepository.fetchPriceTrends(product);
    } catch (e) {
      _priceTrends = [];
      _errorMessage = e is ApiException
          ? e.message
          : 'Failed to load price trends: $e';
    } finally {
      _isTrendsLoading = false;
      notifyListeners();
    }
  }

  Future<void> setActiveTab(LegacyTab tab) async {
    _activeTab = tab;
    _searchTerm = '';
    _dateFrom = null;
    _dateTo = null;
    _sortBy = LegacySortOption.dateDesc;
    _currentPage = 1;
    _expandedPurchaseId = null;
    _expandedEstimateId = null;
    _expandedWorkId = null;
    _errorMessage = null;
    notifyListeners();

    await _ensureTabLoaded(tab);
  }

  Future<void> refreshCurrentTab() async {
    switch (_activeTab) {
      case LegacyTab.menu:
        _analytics = null;
        _trendProducts = [];
        await _loadMenuOverview();
        if (_selectedProduct.isNotEmpty) {
          await selectTrendProduct(_selectedProduct);
        }
      case LegacyTab.customers:
        _customers = [];
      case LegacyTab.suppliers:
        _suppliers = [];
      case LegacyTab.employees:
        _employees = [];
      case LegacyTab.payments:
        _payments = [];
      case LegacyTab.estimates:
        _estimates = [];
      case LegacyTab.purchases:
        _purchases = [];
      case LegacyTab.workentries:
        _workentries = [];
    }
    if (_activeTab != LegacyTab.menu) {
      await _ensureTabLoaded(_activeTab);
    }
  }

  Future<void> _ensureTabLoaded(LegacyTab tab) async {
    if (tab == LegacyTab.menu) {
      if (_analytics == null || _trendProducts.isEmpty) {
        await _loadMenuOverview();
      }
      return;
    }

    final needsLoad = switch (tab) {
      LegacyTab.customers => _customers.isEmpty,
      LegacyTab.suppliers => _suppliers.isEmpty,
      LegacyTab.employees => _employees.isEmpty,
      LegacyTab.payments => _payments.isEmpty,
      LegacyTab.estimates => _estimates.isEmpty,
      LegacyTab.purchases => _purchases.isEmpty,
      LegacyTab.workentries => _workentries.isEmpty,
      LegacyTab.menu => false,
    };
    if (!needsLoad) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      switch (tab) {
        case LegacyTab.customers:
          _customers = await _legacyRepository.fetchCustomers();
        case LegacyTab.suppliers:
          _suppliers = await _legacyRepository.fetchSuppliers();
        case LegacyTab.employees:
          _employees = await _legacyRepository.fetchEmployees();
        case LegacyTab.payments:
          final payFuture = _legacyRepository.fetchPayments();
          final supData = _suppliers.isEmpty
              ? await _legacyRepository.fetchSuppliers()
              : _suppliers;
          if (_suppliers.isEmpty) _suppliers = supData;
          final payData = await payFuture;
          final supById = {
            for (final s in supData) '${s['SupplierID']}': s['Suppliername'],
          };
          _payments = payData.map((p) {
            final key = '${p['Suppliername']}';
            final name = supById[key];
            return {
              ...p,
              'SupplierNameStr': name != null ? '$name' : 'ID: $key',
            };
          }).toList();
        case LegacyTab.estimates:
          final estFuture = _legacyRepository.fetchEstimates();
          final custData = _customers.isEmpty
              ? await _legacyRepository.fetchCustomers()
              : _customers;
          if (_customers.isEmpty) _customers = custData;
          final estData = await estFuture;
          final custById = {
            for (final c in custData) '${c['CustomerID']}': c['Customername'],
          };
          _estimates = estData.map((e) {
            final key = '${e['Customeraccountnumber']}';
            final name = custById[key];
            return {
              ...e,
              'CustomerName': name != null ? '$name' : 'ID: $key',
            };
          }).toList();
        case LegacyTab.purchases:
          final purFuture = _legacyRepository.fetchPurchases();
          final supData = _suppliers.isEmpty
              ? await _legacyRepository.fetchSuppliers()
              : _suppliers;
          if (_suppliers.isEmpty) _suppliers = supData;
          final purData = await purFuture;
          final supById = {
            for (final s in supData) '${s['SupplierID']}': s['Suppliername'],
          };
          _purchases = purData.map((p) {
            final key = '${p['Supplieraccountnumber']}';
            final name = supById[key];
            return {
              ...p,
              'Suppliername': name != null ? '$name' : 'ID: $key',
            };
          }).toList();
        case LegacyTab.workentries:
          final workFuture = _legacyRepository.fetchWorkentries();
          final empFuture = _employees.isEmpty
              ? _legacyRepository.fetchEmployees()
              : Future.value(_employees);
          final prodFuture = _payrollProducts.isEmpty
              ? _legacyRepository.fetchPayrollProducts()
              : Future.value(_payrollProducts);

          final workData = await workFuture;
          final empData = await empFuture;
          final prodData = await prodFuture;
          if (_employees.isEmpty) _employees = empData;
          if (_payrollProducts.isEmpty) _payrollProducts = prodData;

          final empById = {
            for (final e in empData) '${e['EmployeeID']}': e['EmployeeName'],
          };
          _workentries = workData.map((w) {
            final key = '${w['EmployeeId']}';
            final name = empById[key];
            return {
              ...w,
              'EmployeeName': name != null ? '$name' : 'ID: $key',
            };
          }).toList();
        case LegacyTab.menu:
          break;
      }
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : 'Failed to load ${tab.title}: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleEstimateExpand(int salesId) async {
    if (_expandedEstimateId == salesId) {
      _expandedEstimateId = null;
      notifyListeners();
      return;
    }
    _expandedEstimateId = salesId;
    if (!_estimateDetails.containsKey(salesId)) {
      _isDetailsLoading = true;
      notifyListeners();
      try {
        _estimateDetails[salesId] =
            await _legacyRepository.fetchEstimateDetails(salesId);
      } catch (e) {
        _errorMessage = 'Failed to load estimate items: $e';
      } finally {
        _isDetailsLoading = false;
      }
    }
    notifyListeners();
  }

  Future<void> togglePurchaseExpand(int purchaseId) async {
    if (_expandedPurchaseId == purchaseId) {
      _expandedPurchaseId = null;
      notifyListeners();
      return;
    }
    _expandedPurchaseId = purchaseId;
    if (!_purchaseItems.containsKey(purchaseId)) {
      _isDetailsLoading = true;
      notifyListeners();
      try {
        final results = await Future.wait([
          _legacyRepository.fetchPurchaseParticulars(purchaseId),
          _legacyRepository.fetchPurchaseCharges(purchaseId),
        ]);
        _purchaseItems[purchaseId] = results[0];
        _purchaseCharges[purchaseId] = results[1];
      } catch (e) {
        _errorMessage = 'Failed to load purchase particulars: $e';
      } finally {
        _isDetailsLoading = false;
      }
    }
    notifyListeners();
  }

  Future<void> toggleWorkExpand(int workId) async {
    if (_expandedWorkId == workId) {
      _expandedWorkId = null;
      notifyListeners();
      return;
    }
    _expandedWorkId = workId;
    if (!_workItems.containsKey(workId)) {
      _isDetailsLoading = true;
      notifyListeners();
      try {
        final items = await _legacyRepository.fetchWorkentryParticulars(workId);
        final prodById = {
          for (final p in _payrollProducts)
            '${p['ParticularID']}': p['Particularname'],
        };
        _workItems[workId] = items.map((item) {
          final key = '${item['ProductID']}';
          final name = prodById[key];
          return {
            ...item,
            'ProductName': name != null ? '$name' : 'Prod ID: $key',
          };
        }).toList();
      } catch (e) {
        _errorMessage = 'Failed to load work particulars: $e';
      } finally {
        _isDetailsLoading = false;
      }
    }
    notifyListeners();
  }

  void setSearchTerm(String value) {
    _searchTerm = value;
    _currentPage = 1;
    notifyListeners();
  }

  void setDateFrom(DateTime? date) {
    _dateFrom = date;
    _currentPage = 1;
    notifyListeners();
  }

  void setDateTo(DateTime? date) {
    _dateTo = date;
    _currentPage = 1;
    notifyListeners();
  }

  void clearDates() {
    _dateFrom = null;
    _dateTo = null;
    _currentPage = 1;
    notifyListeners();
  }

  void setSortBy(LegacySortOption sort) {
    _sortBy = sort;
    _currentPage = 1;
    notifyListeners();
  }

  void setCurrentPage(int page) {
    final total = totalPages;
    _currentPage = page.clamp(1, total);
    notifyListeners();
  }

  List<Map<String, dynamic>> get _sourceRecords => switch (_activeTab) {
    LegacyTab.customers => _customers,
    LegacyTab.suppliers => _suppliers,
    LegacyTab.purchases => _purchases,
    LegacyTab.payments => _payments,
    LegacyTab.estimates => _estimates,
    LegacyTab.employees => _employees,
    LegacyTab.workentries => _workentries,
    LegacyTab.menu => const [],
  };

  List<Map<String, dynamic>> get processedRecords {
    var result = List<Map<String, dynamic>>.from(_sourceRecords);
    final tab = _activeTab;

    // 1. Search filter
    final term = _searchTerm.trim().toLowerCase();
    if (term.isNotEmpty) {
      result = result.where((item) {
        switch (tab) {
          case LegacyTab.customers:
          case LegacyTab.suppliers:
            final name =
                '${item['Customername'] ?? item['Suppliername'] ?? ''}'
                    .toLowerCase();
            final idStr = '${item['CustomerID'] ?? item['SupplierID'] ?? ''}'
                .toLowerCase();
            return name.contains(term) || idStr.contains(term);
          case LegacyTab.purchases:
            final sup = '${item['Suppliername'] ?? ''}'.toLowerCase();
            final inv = '${item['Invoiceno'] ?? ''}'.toLowerCase();
            return sup.contains(term) || inv.contains(term);
          case LegacyTab.payments:
            final sup = '${item['SupplierNameStr'] ?? ''}'.toLowerCase();
            final inv = '${item['Invoiceno'] ?? ''}'.toLowerCase();
            return sup.contains(term) || inv.contains(term);
          case LegacyTab.estimates:
            final cust = '${item['CustomerName'] ?? ''}'.toLowerCase();
            final estId = '${item['SalesID'] ?? ''}'.toLowerCase();
            return cust.contains(term) || estId.contains(term);
          case LegacyTab.employees:
            final emp = '${item['EmployeeName'] ?? ''}'.toLowerCase();
            final city = '${item['City'] ?? ''}'.toLowerCase();
            return emp.contains(term) || city.contains(term);
          case LegacyTab.workentries:
            final emp = '${item['EmployeeName'] ?? ''}'.toLowerCase();
            return emp.contains(term);
          case LegacyTab.menu:
            return true;
        }
      }).toList();
    }

    // 2. Date range filter
    if (tab.hasDateFilter && (_dateFrom != null || _dateTo != null)) {
      final from = _dateFrom != null
          ? DateTime(_dateFrom!.year, _dateFrom!.month, _dateFrom!.day)
          : DateTime.fromMillisecondsSinceEpoch(0);
      final to = _dateTo != null
          ? DateTime(
              _dateTo!.year,
              _dateTo!.month,
              _dateTo!.day,
              23,
              59,
              59,
              999,
            )
          : DateTime(2100, 12, 31, 23, 59, 59);

      result = result.where((item) {
        final dateStr = switch (tab) {
          LegacyTab.purchases => '${item['Purchasedate'] ?? ''}',
          LegacyTab.payments => '${item['Paymentdate'] ?? ''}',
          LegacyTab.estimates => '${item['Salesdate'] ?? ''}',
          LegacyTab.workentries => '${item['Workerdate'] ?? ''}',
          _ => '',
        };
        final d = parseLegacyDateString(dateStr);
        return !d.isBefore(from) && !d.isAfter(to);
      }).toList();
    }

    // 3. Sorting
    result.sort((a, b) {
      switch (_sortBy) {
        case LegacySortOption.dateDesc:
        case LegacySortOption.dateAsc:
          final descending = _sortBy == LegacySortOption.dateDesc;
          if (tab.hasDateFilter) {
            final da = _extractItemDate(a, tab);
            final db = _extractItemDate(b, tab);
            return descending ? db.compareTo(da) : da.compareTo(db);
          } else {
            final ida = parseInt(a['id']);
            final idb = parseInt(b['id']);
            return descending ? idb.compareTo(ida) : ida.compareTo(idb);
          }
        case LegacySortOption.amtDesc:
        case LegacySortOption.amtAsc:
          final descending = _sortBy == LegacySortOption.amtDesc;
          final aa = _extractItemAmount(a, tab);
          final ab = _extractItemAmount(b, tab);
          return descending ? ab.compareTo(aa) : aa.compareTo(ab);
        case LegacySortOption.nameAsc:
        case LegacySortOption.nameDesc:
          final ascending = _sortBy == LegacySortOption.nameAsc;
          final na = _extractItemName(a, tab).toLowerCase();
          final nb = _extractItemName(b, tab).toLowerCase();
          return ascending ? na.compareTo(nb) : nb.compareTo(na);
      }
    });

    return result;
  }

  DateTime _extractItemDate(Map<String, dynamic> item, LegacyTab tab) {
    final raw = switch (tab) {
      LegacyTab.purchases => '${item['Purchasedate'] ?? ''}',
      LegacyTab.payments => '${item['Paymentdate'] ?? ''}',
      LegacyTab.estimates => '${item['Salesdate'] ?? ''}',
      LegacyTab.workentries => '${item['Workerdate'] ?? ''}',
      _ => '',
    };
    return parseLegacyDateString(raw);
  }

  double _extractItemAmount(Map<String, dynamic> item, LegacyTab tab) {
    return switch (tab) {
      LegacyTab.purchases ||
      LegacyTab.estimates ||
      LegacyTab.workentries => parseDouble(item['Netamount']),
      LegacyTab.payments => parseDouble(item['Paymentamount']),
      LegacyTab.customers ||
      LegacyTab.suppliers => parseDouble(item['Openingbalance']),
      _ => 0,
    };
  }

  String _extractItemName(Map<String, dynamic> item, LegacyTab tab) {
    return switch (tab) {
      LegacyTab.customers => '${item['Customername'] ?? ''}',
      LegacyTab.suppliers => '${item['Suppliername'] ?? ''}',
      LegacyTab.employees => '${item['EmployeeName'] ?? ''}',
      LegacyTab.purchases => '${item['Suppliername'] ?? ''}',
      LegacyTab.payments => '${item['SupplierNameStr'] ?? ''}',
      LegacyTab.estimates => '${item['CustomerName'] ?? ''}',
      LegacyTab.workentries => '${item['EmployeeName'] ?? ''}',
      LegacyTab.menu => '',
    };
  }

  int get totalCount => processedRecords.length;

  int get totalPages {
    final count = totalCount;
    if (count == 0) return 1;
    return ((count - 1) ~/ itemsPerPage) + 1;
  }

  List<Map<String, dynamic>> get pagedRecords {
    final all = processedRecords;
    if (all.isEmpty) return const [];
    final safePage = _currentPage.clamp(1, totalPages);
    final start = (safePage - 1) * itemsPerPage;
    if (start >= all.length) return const [];
    final end = (start + itemsPerPage).clamp(0, all.length);
    return all.sublist(start, end);
  }

  String buildCsvForCurrentTab() {
    final rowsData = processedRecords;
    if (rowsData.isEmpty) return '';
    final keys = rowsData.first.keys.toList();
    String escapeCsv(Object? val) {
      final s = val == null ? '' : val.toString();
      return '"${s.replaceAll('"', '""')}"';
    }

    final buffer = StringBuffer()..writeln(keys.map(escapeCsv).join(','));
    for (final row in rowsData) {
      buffer.writeln(keys.map((k) => escapeCsv(row[k])).join(','));
    }
    return buffer.toString();
  }

  void dismissError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _activeTab = LegacyTab.menu;
    _searchTerm = '';
    _dateFrom = null;
    _dateTo = null;
    _sortBy = LegacySortOption.dateDesc;
    _currentPage = 1;
    _initialized = false;
    _isLoading = false;
    _isTrendsLoading = false;
    _isDetailsLoading = false;
    _errorMessage = null;
    _analytics = null;
    _trendProducts = [];
    _selectedProduct = '';
    _priceTrends = [];
    _customers = [];
    _suppliers = [];
    _purchases = [];
    _payments = [];
    _estimates = [];
    _employees = [];
    _workentries = [];
    _payrollProducts = [];
    _expandedPurchaseId = null;
    _expandedEstimateId = null;
    _expandedWorkId = null;
    _purchaseItems.clear();
    _purchaseCharges.clear();
    _estimateDetails.clear();
    _workItems.clear();
    notifyListeners();
  }
}
