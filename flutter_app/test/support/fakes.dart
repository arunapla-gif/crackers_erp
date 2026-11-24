import 'package:crackers_erp/core/config/app_config.dart';
import 'package:crackers_erp/core/utils/tamil_transliteration.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/services/api_client.dart';
import 'package:crackers_erp/data/services/local_storage_service.dart';

class InMemoryLocalStorageService implements LocalStorageService {
  String? _token;
  Map<String, dynamic>? _userJson;
  String _apiUrl = AppConfig.defaultApiBaseUrl;
  List<String> _pinnedItems = <String>[];
  String? _entryMode;
  final Map<String, Map<int, Map<String, int>>> _drafts =
      <String, Map<int, Map<String, int>>>{};
  Map<String, dynamic>? _billingCartJson;
  Map<String, dynamic>? _billingHeaderJson;

  @override
  Future<void> clearAuth() async {
    _token = null;
    _userJson = null;
  }

  @override
  Future<void> clearProductionDraft(String isoDate) async {
    _drafts.remove(isoDate);
  }

  @override
  String getApiBaseUrl() => _apiUrl;

  @override
  List<String> getPinnedWipItems() => List<String>.from(_pinnedItems);

  @override
  Map<int, Map<String, int>>? getProductionDraft(String isoDate) {
    final stored = _drafts[isoDate];
    if (stored == null) return null;
    final copy = <int, Map<String, int>>{};
    stored.forEach((empId, items) {
      copy[empId] = Map<String, int>.from(items);
    });
    return copy;
  }

  @override
  String? getToken() => _token;

  @override
  Map<String, dynamic>? getUserJson() =>
      _userJson == null ? null : Map<String, dynamic>.from(_userJson!);

  @override
  Future<void> saveApiBaseUrl(String? url) async {
    final clean = (url ?? '').trim();
    _apiUrl = clean.isEmpty ? AppConfig.defaultApiBaseUrl : clean;
  }

  @override
  Future<void> savePinnedWipItems(List<String> items) async {
    _pinnedItems = List<String>.from(items);
  }

  @override
  String? getProductionEntryMode() => _entryMode;

  @override
  Future<void> saveProductionEntryMode(String mode) async {
    _entryMode = mode;
  }

  @override
  Future<void> saveProductionDraft(
    String isoDate,
    Map<int, Map<String, int>> entriesByEmployee,
  ) async {
    final copy = <int, Map<String, int>>{};
    entriesByEmployee.forEach((empId, items) {
      final nonZero = <String, int>{};
      items.forEach((k, v) {
        if (v > 0) nonZero[k] = v;
      });
      if (nonZero.isNotEmpty) copy[empId] = nonZero;
    });
    if (copy.isEmpty) {
      _drafts.remove(isoDate);
    } else {
      _drafts[isoDate] = copy;
    }
  }

  @override
  Future<void> saveToken(String token) async {
    _token = token;
  }

  @override
  Future<void> saveUserJson(Map<String, dynamic> userJson) async {
    _userJson = Map<String, dynamic>.from(userJson);
  }

  @override
  Map<String, dynamic>? getBillingCartJson() =>
      _billingCartJson == null
          ? null
          : Map<String, dynamic>.from(_billingCartJson!);

  @override
  Future<void> saveBillingCartJson(Map<String, dynamic> cartJson) async {
    _billingCartJson = Map<String, dynamic>.from(cartJson);
  }

  @override
  Map<String, dynamic>? getBillingHeaderJson() =>
      _billingHeaderJson == null
          ? null
          : Map<String, dynamic>.from(_billingHeaderJson!);

  @override
  Future<void> saveBillingHeaderJson(Map<String, dynamic> headerJson) async {
    _billingHeaderJson = Map<String, dynamic>.from(headerJson);
  }

  @override
  Future<void> clearBillingDraft() async {
    _billingCartJson = null;
    _billingHeaderJson = null;
  }
}

class FakeApiClient implements ApiClient {
  FakeApiClient({
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>>? employees,
    List<Map<String, dynamic>>? advances,
    List<Map<String, dynamic>>? productions,
    List<Map<String, dynamic>>? approvedOrders,
    List<Map<String, dynamic>>? pendingOrders,
    List<Map<String, dynamic>>? customers,
    List<Map<String, dynamic>>? suppliers,
    List<Map<String, dynamic>>? transporters,
    List<Map<String, dynamic>>? vehicles,
    List<Map<String, dynamic>>? godowns,
    List<Map<String, dynamic>>? companyProfiles,
    List<Map<String, dynamic>>? invoices,
    List<Map<String, dynamic>>? purchases,
    List<Map<String, dynamic>>? stockLedger,
    List<Map<String, dynamic>>? transfers,
    List<Map<String, dynamic>>? payrolls,
    List<Map<String, dynamic>>? users,
  }) : productsData = products ?? _defaultProducts(),
       employeesData = employees ?? _defaultEmployees(),
       advancesData = advances ?? <Map<String, dynamic>>[],
       productionsData = productions ?? <Map<String, dynamic>>[],
       approvedOrdersData = approvedOrders ?? _defaultOrders(),
       pendingOrdersData = pendingOrders ?? <Map<String, dynamic>>[],
       customersData = customers ?? _defaultCustomers(),
       suppliersData = suppliers ?? _defaultSuppliers(),
       transportersData = transporters ?? <Map<String, dynamic>>[],
       vehiclesData = vehicles ?? _defaultVehicles(),
       godownsData = godowns ?? _defaultGodowns(),
       companyProfilesData = companyProfiles ?? _defaultCompanyProfiles(),
       invoicesData = invoices ?? <Map<String, dynamic>>[],
       purchasesData = purchases ?? <Map<String, dynamic>>[],
       stockLedgerData = stockLedger ?? <Map<String, dynamic>>[],
       transfersData = transfers ?? <Map<String, dynamic>>[],
       payrollsData = payrolls ?? <Map<String, dynamic>>[],
       usersData = users ?? <Map<String, dynamic>>[];

  List<Map<String, dynamic>> productsData;
  List<Map<String, dynamic>> employeesData;
  List<Map<String, dynamic>> advancesData;
  List<Map<String, dynamic>> productionsData;
  List<Map<String, dynamic>> approvedOrdersData;
  List<Map<String, dynamic>> pendingOrdersData;
  List<Map<String, dynamic>> customersData;
  List<Map<String, dynamic>> suppliersData;
  List<Map<String, dynamic>> transportersData;
  List<Map<String, dynamic>> vehiclesData;
  List<Map<String, dynamic>> godownsData;
  List<Map<String, dynamic>> companyProfilesData;
  List<Map<String, dynamic>> invoicesData;
  List<Map<String, dynamic>> purchasesData;
  List<Map<String, dynamic>> stockLedgerData;
  List<Map<String, dynamic>> transfersData;
  List<Map<String, dynamic>> payrollsData;
  List<Map<String, dynamic>> usersData;
  final Map<int, List<Map<String, dynamic>>> customerPricesData = {};
  final Map<int, Map<String, dynamic>> aggregateProductionByEmployee = {};
  Map<String, dynamic>? ewayBillReportOverride;
  int? lastEwayBillDaysRequested;

  // Stage 2 & 3 Packing & Factory Dispatch in-memory state
  final Map<int, int> packingLooseBoxesByProduct = <int, int>{};
  final Map<int, Map<int, int>> godownCartonsByGodownAndProduct =
      <int, Map<int, int>>{};
  final List<Map<String, dynamic>> packingEntriesData =
      <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> factoryDispatchesData =
      <Map<String, dynamic>>[];

  Map<String, dynamic> legacyAnalyticsData = {
    'financials': {
      'totalPurchases': 0,
      'totalEstimates': 0,
      'totalWages': 0,
      'totalPayments': 0,
    },
    'counts': {
      'customers': 0,
      'suppliers': 0,
      'employees': 0,
      'purchases': 0,
      'estimates': 0,
      'workentries': 0,
    },
  };
  List<String> legacyTrendProductsData = [];
  final Map<String, List<Map<String, dynamic>>> legacyPriceTrendsByProduct = {};
  List<Map<String, dynamic>> legacyEstimatesData = [];
  final Map<int, Map<String, dynamic>> legacyEstimateDetailsById = {};
  List<Map<String, dynamic>> legacyPurchasesData = [];
  final Map<int, List<Map<String, dynamic>>> legacyPurchaseParticularsById = {};
  final Map<int, List<Map<String, dynamic>>> legacyPurchaseChargesById = {};
  List<Map<String, dynamic>> legacyPaymentsData = [];
  List<Map<String, dynamic>> legacyCustomersData = [];
  List<Map<String, dynamic>> legacySuppliersData = [];
  List<Map<String, dynamic>> legacyEmployeesData = [];
  List<Map<String, dynamic>> legacyWorkentriesData = [];
  final Map<int, List<Map<String, dynamic>>> legacyWorkentryParticularsById = {};
  List<Map<String, dynamic>> legacyPayrollProductsData = [];

  Map<String, dynamic>? lastSavedEmployeePayload;
  Map<String, dynamic>? lastSavedProductionBulkPayload;
  Map<String, dynamic>? lastSavedInvoicePayload;
  Map<String, dynamic>? lastSavedSalesOrderPayload;
  Map<String, dynamic>? lastSavedPurchasePayload;
  Map<String, dynamic>? lastSavedTransferPayload;
  Map<String, dynamic>? lastSavedPayrollPayload;
  int? lastDeletedProductionId;
  bool shouldFailLogin = false;
  String roleToLogin = 'SUPERVISOR';
  Map<String, dynamic> permissionsToLogin = <String, dynamic>{};

  static List<Map<String, dynamic>> _defaultProducts() => [
    {
      'id': 1,
      'code': 'WIP001',
      'name': '12cm Electric Sparklers (WIP)',
      'type': 'WIP',
      'category': 'Sparklers',
      'unit': 'Pcs',
      'boxesPerCase': 10,
      'status': 'Active',
      'rate': null,
    },
    {
      'id': 2,
      'code': 'WIP002',
      'name': 'Ground Chakkar Big (WIP)',
      'type': 'WIP',
      'category': 'Chakkar',
      'unit': 'Pcs',
      'boxesPerCase': 5,
      'status': 'Active',
      'rate': null,
    },
    {
      'id': 3,
      'code': 'FG001',
      'name': 'Finished Sparklers Box',
      'type': 'Finished Goods',
      'category': 'Sparklers',
      'unit': 'Case',
      'boxesPerCase': 10,
      'status': 'Active',
      'rate': 1200,
    },
  ];

  static List<Map<String, dynamic>> _defaultEmployees() => [
    {
      'id': 11,
      'name': 'Mariappan K',
      'mobile': '9876543210',
      'role': 'Rolling',
      'paymentType': 'Contractual',
      'employmentType': 'Regular',
      'unit': 'Unit 1',
      'status': 'Active',
      'advanceBalance': '500.00',
      'salary': null,
    },
    {
      'id': 12,
      'name': 'Selvi R',
      'mobile': '9876500001',
      'role': 'Packing',
      'paymentType': 'Contractual',
      'employmentType': 'Regular',
      'unit': 'Unit 2',
      'status': 'Active',
      'advanceBalance': '0.00',
      'salary': null,
    },
    {
      'id': 13,
      'name': 'Ramesh S',
      'mobile': '9876500002',
      'role': 'Supervisor Asst',
      'paymentType': 'Monthly',
      'employmentType': 'Regular',
      'unit': 'Unit 1',
      'status': 'Active',
      'advanceBalance': '1000.00',
      'salary': null,
    },
  ];

  static List<Map<String, dynamic>> _defaultOrders() => [
    {
      'id': 101,
      'status': 'APPROVED',
      'createdAt': '2026-11-11T08:00:00.000Z',
      'updatedAt': '2026-11-11T09:00:00.000Z',
      'subtotal': null,
      'rep': {'username': 'rep_north'},
      'customer': {
        'name': 'Sri Murugan Agencies',
        'city': 'Madurai',
        'state': 'Tamil Nadu',
      },
      'items': [
        {
          'productId': 1,
          'product': '12cm Electric Box',
          'qty': 10,
          'unit': 'Box',
          'boxesPerCase': 20,
          'rate': null,
          'total': null,
        },
      ],
    },
  ];

  static List<Map<String, dynamic>> _defaultCustomers() => [
    {
      'id': 1,
      'name': 'Sri Murugan Agencies',
      'mobile': '9842100001',
      'address': '12 Anna Salai',
      'city': 'Madurai',
      'district': 'Madurai',
      'state': 'Tamil Nadu',
      'pincode': '625001',
      'gstin': '33AABCU9603R1ZM',
      'status': 'Active',
      'addresses': <Map<String, dynamic>>[],
    },
  ];

  static List<Map<String, dynamic>> _defaultSuppliers() => [
    {
      'id': 1,
      'name': 'Sivakasi Paper & Board Mill',
      'mobile': '9842100010',
      'type': 'Raw Material',
      'address': '44 Bypass Road',
      'city': 'Sivakasi',
      'district': 'Virudhunagar',
      'state': 'Tamil Nadu',
      'pincode': '626123',
      'gstin': '33AABCS1429B1Z5',
      'status': 'Active',
      'addresses': <Map<String, dynamic>>[],
    },
  ];

  static List<Map<String, dynamic>> _defaultVehicles() => [
    {
      'id': 1,
      'no': 'TN67AB1234',
      'name': 'Ashok Leyland Dost',
      'owner_name': 'Senthil',
      'owner_phone': '9876511111',
      'drivers': [
        {'name': 'Karthick', 'phone': '9876522222'},
      ],
    },
  ];

  static List<Map<String, dynamic>> _defaultGodowns() => [
    {'id': 1, 'name': 'Main RM Godown'},
    {'id': 2, 'name': 'Unit 1 Factory'},
  ];

  static List<Map<String, dynamic>> _defaultCompanyProfiles() => [
    {
      'id': 1,
      'name': 'Sri Ganesh Fireworks',
      'gstin': '33AABCS1429B1Z5',
      'address': '101 Sattur Road',
      'city': 'Sivakasi',
      'district': 'Virudhunagar',
      'state': 'Tamil Nadu',
      'pincode': '626123',
      'status': 'Active',
      'addresses': <Map<String, dynamic>>[],
      'billingSeries': [
        {
          'id': 1,
          'companyProfileId': 1,
          'prefix': 'SGFI',
          'name': 'Main Tax Invoice',
          'docType': 'INV',
          'lastNumber': 10,
          'status': 'Active',
        },
        {
          'id': 2,
          'companyProfileId': 1,
          'prefix': 'SGFE',
          'name': 'Main Estimate',
          'docType': 'EST',
          'lastNumber': 4,
          'status': 'Active',
        },
        {
          'id': 3,
          'companyProfileId': 1,
          'prefix': 'SGFP',
          'name': 'Performa Series',
          'docType': 'PRO',
          'lastNumber': 2,
          'status': 'Active',
        },
      ],
    },
  ];

  @override
  Future<void> deleteDailyProduction(int id) async {
    lastDeletedProductionId = id;
    productionsData.removeWhere((p) => p['id'] == id);
  }

  @override
  Future<List<dynamic>> getApprovedFactoryOrders() async => approvedOrdersData;

  @override
  Future<List<dynamic>> getDailyProductions({
    String? date,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    var list = List<Map<String, dynamic>>.from(productionsData);
    if (date != null) {
      list = list
          .where((r) => (r['date'] ?? '').toString().startsWith(date))
          .toList();
    }
    if (limit != null && list.length > limit) {
      return list.take(limit).toList();
    }
    return list;
  }

  @override
  Future<List<dynamic>> getEmployeeAdvances(int employeeId) async {
    return advancesData.where((a) => a['employeeId'] == employeeId).toList();
  }

  @override
  Future<List<dynamic>> getEmployees() async => employeesData;

  @override
  Future<Map<String, dynamic>> getMe() async => {
    'user': {
      'id': 2,
      'username': 'supervisor1',
      'role': roleToLogin,
      'status': 'Active',
      'permissions': permissionsToLogin,
    },
  };

  @override
  Future<List<dynamic>> getProducts() async => productsData;

  @override
  Future<String> getNextProductCode({String type = 'INV'}) async {
    final prefix = type.toUpperCase();
    return '${prefix}00${productsData.length + 1}';
  }

  @override
  Future<Map<String, dynamic>> saveProduct(Map<String, dynamic> payload) async {
    final id = payload['id'] as int?;
    if (id != null && id > 0) {
      final idx = productsData.indexWhere((p) => p['id'] == id);
      if (idx >= 0) {
        final updated = {...productsData[idx], ...payload};
        productsData[idx] = updated;
        return updated;
      }
    }
    final created = {
      'id': productsData.length + 10,
      ...payload,
      'status': payload['status'] ?? 'Active',
    };
    productsData.add(created);
    return created;
  }

  @override
  Future<List<dynamic>> getRecentAdvances({int limit = 50}) async {
    return advancesData.take(limit).toList();
  }

  @override
  Future<Map<String, dynamic>> giveAdvance({
    required int employeeId,
    required String date,
    required double amount,
    String? description,
  }) async {
    final newId = advancesData.length + 1;
    final emp = employeesData.firstWhere((e) => e['id'] == employeeId);
    final prevBal = double.tryParse('${emp['advanceBalance']}') ?? 0;
    emp['advanceBalance'] = (prevBal + amount).toStringAsFixed(2);

    final record = <String, dynamic>{
      'id': newId,
      'employeeId': employeeId,
      'date': '${date}T00:00:00.000Z',
      'type': 'GIVEN',
      'amount': amount.toStringAsFixed(2),
      'description': description ?? 'Advance Given',
      'employee': {
        'id': emp['id'],
        'name': emp['name'],
        'role': emp['role'],
        'advanceBalance': emp['advanceBalance'],
        'status': emp['status'],
      },
    };
    advancesData.insert(0, record);
    return record;
  }

  @override
  Future<Map<String, dynamic>> login(String username, String pin) async {
    if (shouldFailLogin) {
      throw const ApiException('Invalid username or PIN', statusCode: 401);
    }
    return {
      'token': 'fake-jwt-token',
      'user': {
        'id': 2,
        'username': username,
        'role': roleToLogin,
        'status': 'Active',
        'permissions': permissionsToLogin,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> saveDailyProduction(
    Map<String, dynamic> payload,
  ) async {
    final res = await saveDailyProductionBulk(
      date: (payload['date'] ?? '').toString(),
      entries: [payload],
    );
    final records = res['records'] as List<dynamic>;
    return records.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(records.first as Map);
  }

  @override
  Future<Map<String, dynamic>> saveDailyProductionBulk({
    required String date,
    required List<Map<String, dynamic>> entries,
  }) async {
    lastSavedProductionBulkPayload = {'date': date, 'entries': entries};

    final savedRecords = <Map<String, dynamic>>[];
    for (final entry in entries) {
      final empId = entry['employeeId'] as int;
      final items = (entry['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      productionsData.removeWhere(
        (r) =>
            r['employeeId'] == empId &&
            (r['date'] ?? '').toString().startsWith(date),
      );
      if (items.isEmpty) continue;

      final emp = employeesData.firstWhere(
        (e) => e['id'] == empId,
        orElse: () => {'id': empId, 'name': 'Worker #$empId', 'role': null},
      );
      final rec = <String, dynamic>{
        'id': productionsData.length + 100,
        'date': '${date}T00:00:00.000Z',
        'employeeId': empId,
        'totalAmount': null,
        'employee': emp,
        'items': items
            .map(
              (i) => {
                'itemName': i['itemName'],
                'quantity': i['quantity'],
                'pieceRate': null,
                'total': null,
              },
            )
            .toList(),
      };
      productionsData.insert(0, rec);
      savedRecords.add(rec);
    }

    return {'savedCount': savedRecords.length, 'records': savedRecords};
  }

  @override
  Future<Map<String, dynamic>> saveEmployee(Map<String, dynamic> payload) async {
    lastSavedEmployeePayload = Map<String, dynamic>.from(payload);
    final id = payload['id'] as int?;
    if (id != null && id > 0) {
      final idx = employeesData.indexWhere((e) => e['id'] == id);
      final updated = <String, dynamic>{
        ...employeesData[idx],
        ...payload,
      };
      employeesData[idx] = updated;
      return updated;
    }

    final created = <String, dynamic>{
      'id': employeesData.length + 50,
      'employmentType': 'Regular',
      ...payload,
      'advanceBalance': '0.00',
      'salary': payload['salary'],
    };
    employeesData.add(created);
    return created;
  }

  @override
  Future<Map<String, dynamic>> convertEmployeeToRegular(
    int id, {
    String? paymentType,
    double? salary,
  }) async {
    if (roleToLogin != 'ADMIN') {
      throw const ApiException(
        'Only Admin can convert a Temporary worker to Regular.',
        statusCode: 403,
      );
    }
    final idx = employeesData.indexWhere((e) => e['id'] == id);
    final updated = <String, dynamic>{
      ...employeesData[idx],
      'employmentType': 'Regular',
      'regularizedAt': '2026-11-12T09:30:00.000Z',
      'paymentType': ?paymentType,
      'salary': ?salary,
    };
    employeesData[idx] = updated;
    return updated;
  }

  @override
  Future<void> deleteEmployee(int id) async {
    employeesData.removeWhere((e) => e['id'] == id);
  }

  @override
  Future<List<String>> getTamilTransliterations(String text) async {
    return TamilTransliteration.getSuggestions(text);
  }

  @override
  Future<List<dynamic>> getUsers() async => usersData;

  @override
  Future<Map<String, dynamic>> saveUser(Map<String, dynamic> payload) async {
    final id = payload['id'] as int?;
    if (id != null && id > 0) {
      final idx = usersData.indexWhere((u) => u['id'] == id);
      if (idx >= 0) {
        final updated = {...usersData[idx], ...payload};
        usersData[idx] = updated;
        return {'user': updated};
      }
    }
    final created = {
      'id': usersData.length + 10,
      ...payload,
    };
    usersData.add(created);
    return {'user': created};
  }

  @override
  Future<void> deleteUser(int id) async {
    usersData.removeWhere((u) => u['id'] == id);
  }

  @override
  Future<List<dynamic>> getReps() async =>
      usersData.where((u) => u['role'] == 'REP').toList();

  @override
  Future<List<dynamic>> getCustomers() async => customersData;

  @override
  Future<Map<String, dynamic>> saveCustomer(Map<String, dynamic> payload) async {
    final id = payload['id'] as int?;
    if (id != null && id > 0) {
      final idx = customersData.indexWhere((c) => c['id'] == id);
      if (idx >= 0) {
        final updated = {...customersData[idx], ...payload};
        customersData[idx] = updated;
        return updated;
      }
    }
    final created = {'id': customersData.length + 10, ...payload};
    customersData.add(created);
    return created;
  }

  @override
  Future<List<dynamic>> getCustomerPrices(int customerId) async =>
      customerPricesData[customerId] ?? <Map<String, dynamic>>[];

  @override
  Future<Map<String, dynamic>> saveCustomerPrices(
    int customerId,
    List<Map<String, dynamic>> prices,
  ) async {
    customerPricesData[customerId] = prices
        .asMap()
        .entries
        .map(
          (e) => {
            'id': e.key + 1,
            'customerId': customerId,
            'productId': e.value['productId'],
            'rate': e.value['rate'],
          },
        )
        .toList();
    return {'message': 'Prices updated successfully'};
  }

  @override
  Future<List<dynamic>> getSuppliers() async => suppliersData;

  @override
  Future<Map<String, dynamic>> saveSupplier(Map<String, dynamic> payload) async {
    final id = payload['id'] as int?;
    if (id != null && id > 0) {
      final idx = suppliersData.indexWhere((s) => s['id'] == id);
      if (idx >= 0) {
        final updated = {...suppliersData[idx], ...payload};
        suppliersData[idx] = updated;
        return updated;
      }
    }
    final created = {'id': suppliersData.length + 10, ...payload};
    suppliersData.add(created);
    return created;
  }

  @override
  Future<List<dynamic>> getTransporters() async => transportersData;

  @override
  Future<Map<String, dynamic>> saveTransporter(
    Map<String, dynamic> payload,
  ) async {
    final created = {'id': transportersData.length + 1, ...payload};
    transportersData.add(created);
    return created;
  }

  @override
  Future<List<dynamic>> getVehicles() async => vehiclesData;

  @override
  Future<Map<String, dynamic>> saveVehicle(Map<String, dynamic> payload) async {
    final existingIdx = vehiclesData.indexWhere(
      (v) => v['no'] == payload['no'],
    );
    if (existingIdx >= 0) {
      final updated = {...vehiclesData[existingIdx], ...payload};
      vehiclesData[existingIdx] = updated;
      return updated;
    }
    final created = {'id': vehiclesData.length + 10, ...payload};
    vehiclesData.add(created);
    return created;
  }

  @override
  Future<List<dynamic>> getGodowns() async => godownsData;

  @override
  Future<Map<String, dynamic>> saveGodown(Map<String, dynamic> payload) async {
    final created = {'id': godownsData.length + 10, ...payload};
    godownsData.add(created);
    return created;
  }

  @override
  Future<List<dynamic>> getCompanyProfiles() async => companyProfilesData;

  @override
  Future<Map<String, dynamic>> saveCompanyProfile(
    Map<String, dynamic> payload,
  ) async {
    final id = payload['id'] as int?;
    if (id != null && id > 0) {
      final idx = companyProfilesData.indexWhere((p) => p['id'] == id);
      if (idx >= 0) {
        final updated = {...companyProfilesData[idx], ...payload};
        companyProfilesData[idx] = updated;
        return updated;
      }
    }
    final created = {
      'id': companyProfilesData.length + 10,
      ...payload,
      'billingSeries': <Map<String, dynamic>>[],
    };
    companyProfilesData.add(created);
    return created;
  }

  @override
  Future<void> deleteCompanyProfile(int id) async {
    companyProfilesData.removeWhere((p) => p['id'] == id);
  }

  @override
  Future<Map<String, dynamic>> saveBillingSeries(
    Map<String, dynamic> payload,
  ) async {
    final profileId = payload['companyProfileId'] as int?;
    final created = {'id': 99 + DateTime.now().microsecondsSinceEpoch % 1000, ...payload};
    if (profileId != null) {
      final idx = companyProfilesData.indexWhere((p) => p['id'] == profileId);
      if (idx >= 0) {
        final existing = List<Map<String, dynamic>>.from(
          (companyProfilesData[idx]['billingSeries'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>(),
        );
        existing.add(created);
        companyProfilesData[idx]['billingSeries'] = existing;
      }
    }
    return created;
  }

  @override
  Future<void> deleteBillingSeries(int id) async {
    for (final prof in companyProfilesData) {
      final list = prof['billingSeries'];
      if (list is List) {
        prof['billingSeries'] = list
            .whereType<Map<String, dynamic>>()
            .where((s) => s['id'] != id)
            .toList();
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getSystemCredentials() async => {
    'WHITEBOOKS_USERNAME': 'wb_demo',
    'WHITEBOOKS_PASSWORD': 'secret',
    'WHITEBOOKS_GSTIN': '33AABCS1429B1Z5',
    'WHITEBOOKS_CLIENT_ID': 'client_123',
    'WHITEBOOKS_EMAIL': 'erp@example.com',
  };

  final List<Map<String, dynamic>> auditLogsData = [];

  @override
  Future<Map<String, dynamic>> getAuditLogs({
    String module = 'all',
    String action = 'all',
    String username = 'all',
    String search = '',
    bool onlyFlagged = false,
    int limit = 100,
  }) async {
    final filtered = auditLogsData.where((log) {
      if (module != 'all' && log['module'] != module) return false;
      if (action != 'all' && log['action'] != action) return false;
      if (username != 'all' && log['username'] != username) return false;
      if (onlyFlagged &&
          log['isBackdated'] != true &&
          log['action'] != 'DELETE') {
        return false;
      }
      if (search.isNotEmpty) {
        final q = search.toLowerCase();
        final hay =
            '${log['employeeName'] ?? ''} ${log['username'] ?? ''} ${log['summary'] ?? ''} ${log['targetDate'] ?? ''}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
    final users = auditLogsData
        .map((l) => (l['username'] ?? '').toString())
        .where((u) => u.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return {'logs': filtered.take(limit).toList(), 'users': users};
  }

  @override
  Future<Map<String, dynamic>> getInvoice(String number) async {
    return invoicesData.firstWhere(
      (i) => i['number'] == number,
      orElse: () => throw const ApiException('Invoice not found', statusCode: 404),
    );
  }

  @override
  Future<Map<String, dynamic>> saveInvoice(Map<String, dynamic> payload) async {
    lastSavedInvoicePayload = Map<String, dynamic>.from(payload);
    final idx = invoicesData.indexWhere((i) => i['number'] == payload['number']);
    final saved = {
      'id': idx >= 0 ? invoicesData[idx]['id'] : invoicesData.length + 1,
      ...payload,
    };
    if (idx >= 0) {
      invoicesData[idx] = saved;
    } else {
      invoicesData.insert(0, saved);
    }
    return saved;
  }

  @override
  Future<Map<String, dynamic>> generateEwayBill(
    String number,
    String mode,
  ) async {
    throw const ApiException(
      'E-Way Bill generation via Whitebooks API is pending implementation.',
      statusCode: 501,
    );
  }

  @override
  Future<Map<String, dynamic>> getRecentEwayBills({int days = 7}) async {
    lastEwayBillDaysRequested = days;
    return ewayBillReportOverride ??
        {
          'message': 'Success',
          'totalDaysSuccess': 1,
          'totalDaysFailed': 0,
          'data': <Map<String, dynamic>>[],
          'errors': <Map<String, dynamic>>[],
        };
  }

  @override
  Future<List<dynamic>> getInvoiceHistory() async => invoicesData;

  @override
  Future<Map<String, dynamic>> verifyGstin(String gstin) async => {
    'gstin': gstin,
    'legalName': 'Sample Legal Name Pvt Ltd',
    'tradeName': 'Sample Trade Co',
    'address': '10 Market St',
    'city': 'Sivakasi',
    'district': 'Virudhunagar',
    'state': 'Tamil Nadu',
    'pincode': '626123',
    'status': 'Active',
    'addresses': <Map<String, dynamic>>[],
  };

  @override
  Future<Map<String, dynamic>?> lookupPincode(String pincode) async {
    if (pincode == '626123') {
      return {
        'city': 'Sivakasi',
        'district': 'Virudhunagar',
        'state': 'Tamil Nadu',
      };
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>> getRepDashboard() async => {
    'totalSales': 25000,
    'pendingOrdersCount': pendingOrdersData.length,
    'totalCustomers': customersData.length,
    'recentOrders': pendingOrdersData.map((o) {
      final cust = o['customer'] as Map<String, dynamic>?;
      final lead = o['newCustomerData'] as Map<String, dynamic>?;
      return {
        'id': o['id'],
        'customerName': cust?['name'] ?? lead?['name'] ?? 'New Customer',
        'status': o['status'] ?? 'PENDING',
        'subtotal': o['subtotal'] ?? 0,
        'date': o['createdAt'] ?? DateTime.now().toIso8601String(),
      };
    }).toList(),
  };

  @override
  Future<List<dynamic>> getPendingSalesOrders() async => pendingOrdersData;

  @override
  Future<List<dynamic>> getApprovedSalesOrders({bool factoryView = false}) async =>
      approvedOrdersData;

  @override
  Future<Map<String, dynamic>> getSalesOrderFactoryView(int id) async {
    return approvedOrdersData.firstWhere(
      (o) => o['id'] == id,
      orElse: () => approvedOrdersData.first,
    );
  }

  @override
  Future<Map<String, dynamic>> createSalesOrder(
    Map<String, dynamic> payload,
  ) async {
    lastSavedSalesOrderPayload = Map<String, dynamic>.from(payload);
    final created = {
      'id': pendingOrdersData.length + 200,
      'repId': 2,
      'status': 'PENDING',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
      ...payload,
    };
    pendingOrdersData.insert(0, created);
    return created;
  }

  @override
  Future<Map<String, dynamic>> approveSalesOrderCustomer(int id) async {
    final idx = pendingOrdersData.indexWhere((o) => o['id'] == id);
    final order = idx >= 0 ? pendingOrdersData[idx] : <String, dynamic>{};
    final lead = (order['newCustomerData'] as Map<String, dynamic>?) ?? {};
    final createdCustomer = {
      'id': customersData.length + 100,
      'name': lead['name'] ?? 'Lead Customer',
      'gstin': (lead['gstin'] ?? '').toString().isEmpty ? 'URP' : lead['gstin'],
      'status': 'Active',
    };
    customersData.add(createdCustomer);
    return {'message': 'Customer approved', 'customer': createdCustomer, 'order': order};
  }

  @override
  Future<Map<String, dynamic>> linkCustomerToOrder(
    int orderId,
    int customerId,
  ) async {
    final idx = pendingOrdersData.indexWhere((o) => o['id'] == orderId);
    if (idx >= 0) {
      pendingOrdersData[idx]['customerId'] = customerId;
      pendingOrdersData[idx]['newCustomerData'] = null;
      return {'order': pendingOrdersData[idx]};
    }
    return {'order': <String, dynamic>{'id': orderId, 'customerId': customerId}};
  }

  @override
  Future<Map<String, dynamic>> updateSalesOrderStatus(
    int id,
    String status,
  ) async {
    final idx = pendingOrdersData.indexWhere((o) => o['id'] == id);
    if (idx >= 0) {
      final order = pendingOrdersData.removeAt(idx);
      order['status'] = status;
      if (status == 'APPROVED') {
        approvedOrdersData.insert(0, order);
      }
      return order;
    }
    return {'id': id, 'status': status};
  }

  @override
  Future<Map<String, dynamic>> savePurchase(Map<String, dynamic> payload) async {
    lastSavedPurchasePayload = Map<String, dynamic>.from(payload);
    final created = {
      'id': purchasesData.length + 1,
      ...payload,
      'status': payload['status'] ?? 'Active',
    };
    purchasesData.insert(0, created);
    return created;
  }

  @override
  Future<List<dynamic>> getPurchaseHistory() async => purchasesData;

  @override
  Future<Map<String, dynamic>> togglePurchaseStatus(
    int id,
    String status,
  ) async {
    final idx = purchasesData.indexWhere((p) => p['id'] == id);
    if (idx >= 0) {
      purchasesData[idx]['status'] = status;
      return purchasesData[idx];
    }
    return {'id': id, 'status': status};
  }

  @override
  Future<List<dynamic>> getStockLedger() async => stockLedgerData;

  @override
  Future<Map<String, dynamic>> saveTransfer(Map<String, dynamic> payload) async {
    lastSavedTransferPayload = Map<String, dynamic>.from(payload);
    final created = {'id': transfersData.length + 1, ...payload};
    transfersData.insert(0, created);
    return created;
  }

  @override
  Future<List<dynamic>> getTransferHistory() async => transfersData;

  @override
  Future<List<dynamic>> getPayrolls() async => payrollsData;

  @override
  Future<Map<String, dynamic>> savePayroll(Map<String, dynamic> payload) async {
    lastSavedPayrollPayload = Map<String, dynamic>.from(payload);
    final created = {'id': payrollsData.length + 1, ...payload};
    payrollsData.insert(0, created);
    return created;
  }

  @override
  Future<Map<String, dynamic>> getAggregateProduction({
    required int employeeId,
    required String startDate,
    required String endDate,
  }) async {
    return aggregateProductionByEmployee[employeeId] ??
        {'totalAmount': 0, 'details': <Map<String, dynamic>>[]};
  }

  @override
  Future<Map<String, dynamic>> getLegacyAnalytics() async =>
      legacyAnalyticsData;

  @override
  Future<List<dynamic>> getLegacyAnalyticsProducts() async =>
      legacyTrendProductsData;

  @override
  Future<List<dynamic>> getLegacyAnalyticsPriceTrends(String product) async =>
      legacyPriceTrendsByProduct[product] ?? <Map<String, dynamic>>[];

  @override
  Future<List<dynamic>> getLegacyEstimates() async => legacyEstimatesData;

  @override
  Future<Map<String, dynamic>> getLegacyEstimateDetails(int salesId) async =>
      legacyEstimateDetailsById[salesId] ??
      {
        'particulars': <dynamic>[],
        'charges': <dynamic>[],
      };

  @override
  Future<List<dynamic>> getLegacyPurchases() async => legacyPurchasesData;

  @override
  Future<List<dynamic>> getLegacyPurchaseParticulars(int purchaseId) async =>
      legacyPurchaseParticularsById[purchaseId] ?? <Map<String, dynamic>>[];

  @override
  Future<List<dynamic>> getLegacyPurchaseCharges(int purchaseId) async =>
      legacyPurchaseChargesById[purchaseId] ?? <Map<String, dynamic>>[];

  @override
  Future<List<dynamic>> getLegacyPayments() async => legacyPaymentsData;

  @override
  Future<List<dynamic>> getLegacyCustomers() async => legacyCustomersData;

  @override
  Future<List<dynamic>> getLegacySuppliers() async => legacySuppliersData;

  @override
  Future<List<dynamic>> getLegacyEmployees() async => legacyEmployeesData;

  @override
  Future<List<dynamic>> getLegacyWorkentries() async => legacyWorkentriesData;

  @override
  Future<List<dynamic>> getLegacyWorkentryParticulars(int workId) async =>
      legacyWorkentryParticularsById[workId] ?? <Map<String, dynamic>>[];

  @override
  Future<List<dynamic>> getLegacyPayrollProducts() async =>
      legacyPayrollProductsData;

  Map<String, dynamic> _ensureFakeFactoryGodown() {
    final existing = godownsData.where(
      (g) => (g['name'] ?? '').toString().trim().toLowerCase() ==
          'factory ready stock',
    );
    if (existing.isNotEmpty) return existing.first;
    final created = {'id': godownsData.length + 101, 'name': 'Factory Ready Stock'};
    godownsData.insert(0, created);
    return created;
  }

  Map<int, Map<String, int>> _computeFakeTapeWipStats() {
    final tapeWips = productsData
        .where(
          (p) =>
              (p['type'] ?? '').toString().toUpperCase() == 'WIP' &&
              (p['category'] ?? '').toString().toUpperCase() == 'TAPE',
        )
        .toList();
    final stats = <int, Map<String, int>>{};
    final wipByName = <String, Map<String, dynamic>>{};
    for (final w in tapeWips) {
      final wid = w['id'] as int;
      stats[wid] = {'produced': 0, 'packedGood': 0, 'damaged': 0, 'unpacked': 0};
      wipByName[(w['name'] ?? '').toString().trim().toLowerCase()] = w;
    }

    // Sum saved DailyProduction quantities strictly for Tape employees
    for (final rec in productionsData) {
      final empId = (rec['employeeId'] as num?)?.toInt();
      final empObj = rec['employee'] is Map
          ? Map<String, dynamic>.from(rec['employee'] as Map)
          : employeesData.where((e) => e['id'] == empId).firstOrNull;
      final role = (empObj?['role'] ?? '').toString().toLowerCase();
      if (!role.contains('tape')) continue;

      final items = rec['items'] is List
          ? rec['items'] as List<dynamic>
          : const <dynamic>[];
      for (final rawItem in items) {
        if (rawItem is! Map) continue;
        final name = (rawItem['itemName'] ?? '').toString().trim().toLowerCase();
        final wip = wipByName[name];
        if (wip == null) continue;
        final wid = wip['id'] as int;
        stats[wid]!['produced'] =
            stats[wid]!['produced']! + ((rawItem['quantity'] as num?)?.toInt() ?? 0);
      }
    }

    // Subtract INNER_BOX entries linked via factoryAliasId
    for (final entry in packingEntriesData) {
      if ((entry['entryType'] ?? '').toString() != 'INNER_BOX') continue;
      final pid = (entry['productId'] as num?)?.toInt();
      final prod = productsData.where((p) => p['id'] == pid).firstOrNull;
      final aliasId = (prod?['factoryAliasId'] as num?)?.toInt();
      if (aliasId == null || !stats.containsKey(aliasId)) continue;
      stats[aliasId]!['packedGood'] =
          stats[aliasId]!['packedGood']! +
          ((entry['innerBoxesPacked'] as num?)?.toInt() ?? 0);
      stats[aliasId]!['damaged'] =
          stats[aliasId]!['damaged']! +
          ((entry['damagedBoxes'] as num?)?.toInt() ?? 0);
    }

    stats.forEach((wid, st) {
      final rem = st['produced']! - (st['packedGood']! + st['damaged']!);
      st['unpacked'] = rem > 0 ? rem : 0;
    });
    return stats;
  }

  @override
  Future<Map<String, dynamic>> getPackingSummary() async {
    final factoryG = _ensureFakeFactoryGodown();
    final factoryId = factoryG['id'] as int;
    final invProducts = productsData
        .where((p) => (p['type'] ?? 'INV').toString().toUpperCase() == 'INV')
        .toList();
    final tapeWips = productsData
        .where(
          (p) =>
              (p['type'] ?? '').toString().toUpperCase() == 'WIP' &&
              (p['category'] ?? '').toString().toUpperCase() == 'TAPE',
        )
        .toList();
    final wipById = {for (final w in tapeWips) w['id'] as int: w};
    final tapeStats = _computeFakeTapeWipStats();

    final summaryProducts = invProducts.map((p) {
      final pid = p['id'] as int;
      final bpc = ((p['boxesPerCase'] as num?)?.toInt() ?? 1).clamp(1, 999999);
      final loose = packingLooseBoxesByProduct[pid] ?? 0;
      final aliasId = (p['factoryAliasId'] as num?)?.toInt();
      final wip = aliasId != null ? wipById[aliasId] : null;
      final godownCartons = <String, int>{};
      var totalCartons = 0;
      for (final g in godownsData) {
        final gid = g['id'] as int;
        final qty = godownCartonsByGodownAndProduct[gid]?[pid] ?? 0;
        if (qty > 0) {
          godownCartons[g['name'].toString()] = qty;
          totalCartons += qty;
        }
      }
      final factoryCartons =
          godownCartonsByGodownAndProduct[factoryId]?[pid] ?? 0;
      final ready = loose ~/ bpc;
      final rem = loose % bpc;
      return {
        'id': pid,
        'code': p['code'] ?? 'GAR$pid',
        'name': p['name'] ?? 'Product $pid',
        'category': p['category'] ?? 'Garlands',
        'subCategory': p['subCategory'],
        'boxesPerCase': bpc,
        'unit': p['unit'] ?? 'Case',
        'packUnit': p['pack_unit'] ?? 'Box',
        'wipProductId': aliasId,
        'wipCode': wip?['code'],
        'wipName': wip?['name'],
        'looseInnerBoxes': loose,
        'factoryCartons': factoryCartons,
        'godownCartons': godownCartons,
        'totalCartons': totalCartons,
        'readyToSealCartons': ready,
        'neededForNextCarton': rem == 0 ? bpc : bpc - rem,
      };
    }).toList();

    final tapeQueue = tapeWips.map((w) {
      final wid = w['id'] as int;
      final st = tapeStats[wid] ??
          const {'produced': 0, 'packedGood': 0, 'damaged': 0, 'unpacked': 0};
      final styles = summaryProducts
          .where((sp) => sp['wipProductId'] == wid)
          .map(
            (sp) => {
              'id': sp['id'],
              'code': sp['code'],
              'name': sp['name'],
              'subCategory': sp['subCategory'],
              'boxesPerCase': sp['boxesPerCase'],
              'looseInnerBoxes': sp['looseInnerBoxes'],
              'factoryCartons': sp['factoryCartons'],
            },
          )
          .toList();
      return {
        'wipId': wid,
        'wipCode': w['code'],
        'wipName': w['name'],
        'subCategory': w['subCategory'],
        'totalProducedUnits': st['produced']!,
        'totalPackedUnits': st['packedGood']!,
        'totalDamagedUnits': st['damaged']!,
        'unpackedUnits': st['unpacked']!,
        'styleOptions': styles,
      };
    }).toList();

    return {
      'factoryGodownId': factoryId,
      'godowns': godownsData
          .map((g) => {'id': g['id'], 'name': g['name']})
          .toList(),
      'tapeQueue': tapeQueue,
      'products': summaryProducts,
      'recentEntries': List<Map<String, dynamic>>.from(packingEntriesData),
    };
  }

  @override
  Future<Map<String, dynamic>> recordInnerBoxPacking(
    Map<String, dynamic> payload,
  ) async {
    final pid = (payload['productId'] as num).toInt();
    final packed = (payload['innerBoxesPacked'] as num).toInt();
    final damaged = (payload['damagedBoxes'] as num?)?.toInt() ?? 0;
    final autoSeal = payload['autoSealCartons'] == true;
    final prod = productsData.firstWhere((p) => p['id'] == pid);
    final bpc = ((prod['boxesPerCase'] as num?)?.toInt() ?? 1).clamp(1, 999999);
    final date = (payload['date'] ?? DateTime.now().toIso8601String()).toString();

    final aliasId = (prod['factoryAliasId'] as num?)?.toInt();
    String? wipName;
    if (aliasId != null) {
      final stats = _computeFakeTapeWipStats();
      final st = stats[aliasId];
      final wip = productsData.where((p) => p['id'] == aliasId).firstOrNull;
      wipName = wip?['name']?.toString();
      if (st != null && packed + damaged > st['unpacked']!) {
        throw ApiException(
          'Cannot pack ${packed + damaged} units of Tape item "$wipName". Only ${st['unpacked']} unpacked units available.',
          statusCode: 400,
        );
      }
    }

    final prevLoose = packingLooseBoxesByProduct[pid] ?? 0;
    final looseAfterInner = prevLoose + packed;
    packingLooseBoxesByProduct[pid] = looseAfterInner;

    final innerEntry = {
      'id': packingEntriesData.length + 1,
      'date': date,
      'entryType': 'INNER_BOX',
      'productId': pid,
      'productCode': prod['code'] ?? '',
      'productName': prod['name'] ?? '',
      'wipName': wipName,
      'subCategory': prod['subCategory'],
      'innerBoxesPacked': packed,
      'damagedBoxes': damaged,
      'masterCartonsSealed': 0,
      'boxesPerCase': bpc,
      'innerBoxesConsumed': 0,
      'looseRemainingAfter': looseAfterInner,
      'targetGodownName': null,
      'remarks': payload['remarks'],
      'createdBy': 'supervisor',
      'createdAt': DateTime.now().toIso8601String(),
    };
    packingEntriesData.insert(0, innerEntry);

    var sealedCartons = 0;
    var consumed = 0;
    var finalLoose = looseAfterInner;
    String? targetGodownName;

    if (autoSeal && looseAfterInner >= bpc) {
      sealedCartons = looseAfterInner ~/ bpc;
      consumed = sealedCartons * bpc;
      finalLoose = looseAfterInner - consumed;
      packingLooseBoxesByProduct[pid] = finalLoose;

      final factoryG = _ensureFakeFactoryGodown();
      final factoryId = factoryG['id'] as int;
      targetGodownName = factoryG['name'].toString();
      final map = godownCartonsByGodownAndProduct.putIfAbsent(
        factoryId,
        () => <int, int>{},
      );
      map[pid] = (map[pid] ?? 0) + sealedCartons;

      packingEntriesData.insert(0, {
        'id': packingEntriesData.length + 1,
        'date': date,
        'entryType': 'MASTER_CARTON',
        'productId': pid,
        'productCode': prod['code'] ?? '',
        'productName': prod['name'] ?? '',
        'subCategory': prod['subCategory'],
        'innerBoxesPacked': 0,
        'damagedBoxes': 0,
        'masterCartonsSealed': sealedCartons,
        'boxesPerCase': bpc,
        'innerBoxesConsumed': consumed,
        'looseRemainingAfter': finalLoose,
        'targetGodownName': targetGodownName,
        'remarks': payload['remarks'] ?? 'Auto-sealed',
        'createdBy': 'supervisor',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }

    return {
      'innerEntry': innerEntry,
      'productName': prod['name'],
      'boxesPerCase': bpc,
      'sealedCartons': sealedCartons,
      'consumedBoxes': consumed,
      'looseRemainingAfter': finalLoose,
      'targetGodownName': targetGodownName,
    };
  }

  @override
  Future<Map<String, dynamic>> sealMasterCartons(
    Map<String, dynamic> payload,
  ) async {
    final pid = (payload['productId'] as num).toInt();
    final cartons = (payload['masterCartonsSealed'] as num).toInt();
    final prod = productsData.firstWhere((p) => p['id'] == pid);
    final bpc = ((prod['boxesPerCase'] as num?)?.toInt() ?? 1).clamp(1, 999999);
    final prevLoose = packingLooseBoxesByProduct[pid] ?? 0;
    final consumed = cartons * bpc;
    if (consumed > prevLoose) {
      throw ApiException('Not enough loose inner boxes.', statusCode: 400);
    }
    final remaining = prevLoose - consumed;
    packingLooseBoxesByProduct[pid] = remaining;

    final factoryG = _ensureFakeFactoryGodown();
    final targetGId =
        (payload['targetGodownId'] as num?)?.toInt() ?? (factoryG['id'] as int);
    final targetG = godownsData.firstWhere((g) => g['id'] == targetGId);
    final map = godownCartonsByGodownAndProduct.putIfAbsent(
      targetGId,
      () => <int, int>{},
    );
    map[pid] = (map[pid] ?? 0) + cartons;

    final entry = {
      'id': packingEntriesData.length + 1,
      'date': (payload['date'] ?? DateTime.now().toIso8601String()).toString(),
      'entryType': 'MASTER_CARTON',
      'productId': pid,
      'productCode': prod['code'] ?? '',
      'productName': prod['name'] ?? '',
      'subCategory': prod['subCategory'],
      'innerBoxesPacked': 0,
      'damagedBoxes': 0,
      'masterCartonsSealed': cartons,
      'boxesPerCase': bpc,
      'innerBoxesConsumed': consumed,
      'looseRemainingAfter': remaining,
      'targetGodownName': targetG['name'],
      'remarks': payload['remarks'],
      'createdBy': 'supervisor',
      'createdAt': DateTime.now().toIso8601String(),
    };
    packingEntriesData.insert(0, entry);

    return {
      'entry': entry,
      'productName': prod['name'],
      'boxesPerCase': bpc,
      'sealedCartons': cartons,
      'consumedBoxes': consumed,
      'looseRemainingAfter': remaining,
      'targetGodownName': targetG['name'],
    };
  }

  @override
  Future<Map<String, dynamic>> getFactoryDispatches() async {
    _ensureFakeFactoryGodown();
    final stockByGodown = <String, List<Map<String, dynamic>>>{};
    for (final g in godownsData) {
      final gid = g['id'] as int;
      final list = <Map<String, dynamic>>[];
      final byProd = godownCartonsByGodownAndProduct[gid] ?? const {};
      byProd.forEach((pid, qty) {
        if (qty <= 0) return;
        final matches = productsData.where((p) => p['id'] == pid);
        if (matches.isEmpty) return;
        final prod = matches.first;
        list.add({
          'productId': pid,
          'code': prod['code'] ?? '',
          'name': prod['name'] ?? '',
          'subCategory': prod['subCategory'],
          'boxesPerCase': (prod['boxesPerCase'] as num?)?.toInt() ?? 1,
          'availableCartons': qty,
        });
      });
      stockByGodown['$gid'] = list;
    }

    return {
      'dispatches': List<Map<String, dynamic>>.from(factoryDispatchesData),
      'godowns': godownsData
          .map((g) => {'id': g['id'], 'name': g['name']})
          .toList(),
      'transporters': transportersData
          .map((t) => {'id': t['id'], 'name': t['name'], 'city': t['city']})
          .toList(),
      'vehicles': vehiclesData
          .map(
            (v) => {
              'id': v['id'],
              'no': v['no'],
              'name': v['name'],
              'drivers': v['drivers'] ?? <dynamic>[],
            },
          )
          .toList(),
      'stockByGodown': stockByGodown,
    };
  }

  @override
  Future<Map<String, dynamic>> createFactoryDispatch(
    Map<String, dynamic> payload,
  ) async {
    final destType = (payload['destinationType'] ?? 'GODOWN').toString();
    final fromId = (payload['fromGodownId'] as num).toInt();
    final toId = (payload['toGodownId'] as num?)?.toInt();
    final fromG = godownsData.firstWhere((g) => g['id'] == fromId);
    final toG = toId != null
        ? godownsData.firstWhere((g) => g['id'] == toId)
        : null;

    final rawItems = payload['items'] as List<dynamic>;
    final resolvedItems = <Map<String, dynamic>>[];
    var totalCartons = 0;
    var totalBoxes = 0;

    final srcMap = godownCartonsByGodownAndProduct.putIfAbsent(
      fromId,
      () => <int, int>{},
    );

    for (final raw in rawItems) {
      final m = Map<String, dynamic>.from(raw as Map);
      final pid = (m['productId'] as num).toInt();
      final cartons = (m['cartons'] as num).toInt();
      final avail = srcMap[pid] ?? 0;
      if (cartons > avail) {
        throw ApiException('Insufficient stock.', statusCode: 400);
      }
      final prod = productsData.firstWhere((p) => p['id'] == pid);
      final bpc = ((prod['boxesPerCase'] as num?)?.toInt() ?? 1).clamp(1, 999999);
      srcMap[pid] = avail - cartons;
      if (destType == 'GODOWN' && toId != null) {
        final dstMap = godownCartonsByGodownAndProduct.putIfAbsent(
          toId,
          () => <int, int>{},
        );
        dstMap[pid] = (dstMap[pid] ?? 0) + cartons;
      }
      totalCartons += cartons;
      totalBoxes += cartons * bpc;
      resolvedItems.add({
        'id': resolvedItems.length + 1,
        'productId': pid,
        'productName': prod['name'],
        'subCategory': prod['subCategory'],
        'cartons': cartons,
        'boxesPerCase': bpc,
        'totalBoxes': cartons * bpc,
      });
    }

    String? transporterName = payload['transporterName']?.toString();
    if (payload['transporterId'] != null) {
      final tid = (payload['transporterId'] as num).toInt();
      final found = transportersData.where((t) => t['id'] == tid);
      if (found.isNotEmpty) transporterName = found.first['name'].toString();
    }

    final nextId = factoryDispatchesData.length + 1;
    final challanNo = 'DC-${nextId.toString().padLeft(4, '0')}';
    final record = {
      'id': nextId,
      'challanNo': challanNo,
      'date': (payload['date'] ?? DateTime.now().toIso8601String()).toString(),
      'destinationType': destType,
      'fromGodownId': fromId,
      'fromGodownName': fromG['name'],
      'toGodownId': toG?['id'],
      'toGodownName': toG?['name'],
      'transporterId': payload['transporterId'],
      'transporterName': transporterName,
      'customerName': payload['customerName'],
      'lrNumber': payload['lrNumber'],
      'vehicleNo': payload['vehicleNo'],
      'driverName': payload['driverName'],
      'remarks': payload['remarks'],
      'totalCartons': totalCartons,
      'totalBoxes': totalBoxes,
      'createdBy': 'supervisor',
      'createdAt': DateTime.now().toIso8601String(),
      'items': resolvedItems,
    };
    factoryDispatchesData.insert(0, record);
    return record;
  }
}
