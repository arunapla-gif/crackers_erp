import 'package:crackers_erp/core/config/app_config.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/services/api_client.dart';
import 'package:crackers_erp/data/services/local_storage_service.dart';

class InMemoryLocalStorageService implements LocalStorageService {
  String? _token;
  Map<String, dynamic>? _userJson;
  String _apiUrl = AppConfig.defaultApiBaseUrl;
  List<String> _pinnedItems = <String>[];
  final Map<String, Map<int, Map<String, int>>> _drafts =
      <String, Map<int, Map<String, int>>>{};

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
}

class FakeApiClient implements ApiClient {
  FakeApiClient({
    List<Map<String, dynamic>>? products,
    List<Map<String, dynamic>>? employees,
    List<Map<String, dynamic>>? advances,
    List<Map<String, dynamic>>? productions,
    List<Map<String, dynamic>>? approvedOrders,
  }) : productsData = products ?? _defaultProducts(),
       employeesData = employees ?? _defaultEmployees(),
       advancesData = advances ?? <Map<String, dynamic>>[],
       productionsData = productions ?? <Map<String, dynamic>>[],
       approvedOrdersData = approvedOrders ?? _defaultOrders();

  List<Map<String, dynamic>> productsData;
  List<Map<String, dynamic>> employeesData;
  List<Map<String, dynamic>> advancesData;
  List<Map<String, dynamic>> productionsData;
  List<Map<String, dynamic>> approvedOrdersData;

  Map<String, dynamic>? lastSavedEmployeePayload;
  Map<String, dynamic>? lastSavedProductionBulkPayload;
  int? lastDeletedProductionId;
  bool shouldFailLogin = false;
  String roleToLogin = 'SUPERVISOR';

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
      'permissions': <String, dynamic>{},
    },
  };

  @override
  Future<List<dynamic>> getProducts() async => productsData;

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
        'permissions': <String, dynamic>{},
      },
    };
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
      ...payload,
      'advanceBalance': '0.00',
      'salary': null,
    };
    employeesData.add(created);
    return created;
  }
}

