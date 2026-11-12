import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../models/api_exceptions.dart';

abstract class ApiClient {
  // Auth
  Future<Map<String, dynamic>> login(String username, String pin);
  Future<Map<String, dynamic>> getMe();

  // Users & Reps
  Future<List<dynamic>> getUsers();
  Future<Map<String, dynamic>> saveUser(Map<String, dynamic> payload);
  Future<void> deleteUser(int id);
  Future<List<dynamic>> getReps();

  // Customers & Prices
  Future<List<dynamic>> getCustomers();
  Future<Map<String, dynamic>> saveCustomer(Map<String, dynamic> payload);
  Future<List<dynamic>> getCustomerPrices(int customerId);
  Future<Map<String, dynamic>> saveCustomerPrices(
    int customerId,
    List<Map<String, dynamic>> prices,
  );

  // Suppliers, Transporters, Vehicles, Godowns
  Future<List<dynamic>> getSuppliers();
  Future<Map<String, dynamic>> saveSupplier(Map<String, dynamic> payload);
  Future<List<dynamic>> getTransporters();
  Future<Map<String, dynamic>> saveTransporter(Map<String, dynamic> payload);
  Future<List<dynamic>> getVehicles();
  Future<Map<String, dynamic>> saveVehicle(Map<String, dynamic> payload);
  Future<List<dynamic>> getGodowns();
  Future<Map<String, dynamic>> saveGodown(Map<String, dynamic> payload);

  // Products
  Future<List<dynamic>> getProducts();
  Future<String> getNextProductCode({String type = 'INV'});
  Future<Map<String, dynamic>> saveProduct(Map<String, dynamic> payload);

  // Company Profiles, Series, Credentials
  Future<List<dynamic>> getCompanyProfiles();
  Future<Map<String, dynamic>> saveCompanyProfile(Map<String, dynamic> payload);
  Future<void> deleteCompanyProfile(int id);
  Future<Map<String, dynamic>> saveBillingSeries(Map<String, dynamic> payload);
  Future<void> deleteBillingSeries(int id);
  Future<Map<String, dynamic>> getSystemCredentials();

  // Invoices & Billing & E-Way Bills
  Future<Map<String, dynamic>> getInvoice(String number);
  Future<Map<String, dynamic>> saveInvoice(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> generateEwayBill(String number, String mode);
  Future<Map<String, dynamic>> getRecentEwayBills({int days = 7});
  Future<List<dynamic>> getInvoiceHistory();

  // GSTIN & Pincode Lookups
  Future<Map<String, dynamic>> verifyGstin(String gstin);
  Future<Map<String, dynamic>?> lookupPincode(String pincode);

  // Sales Orders
  Future<Map<String, dynamic>> getRepDashboard();
  Future<List<dynamic>> getPendingSalesOrders();
  Future<List<dynamic>> getApprovedSalesOrders({bool factoryView = false});
  Future<List<dynamic>> getApprovedFactoryOrders();
  Future<Map<String, dynamic>> getSalesOrderFactoryView(int id);
  Future<Map<String, dynamic>> createSalesOrder(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> approveSalesOrderCustomer(int id);
  Future<Map<String, dynamic>> linkCustomerToOrder(int orderId, int customerId);
  Future<Map<String, dynamic>> updateSalesOrderStatus(int id, String status);

  // Purchases, Stock, Transfers
  Future<Map<String, dynamic>> savePurchase(Map<String, dynamic> payload);
  Future<List<dynamic>> getPurchaseHistory();
  Future<Map<String, dynamic>> togglePurchaseStatus(int id, String status);
  Future<List<dynamic>> getStockLedger();
  Future<Map<String, dynamic>> saveTransfer(Map<String, dynamic> payload);
  Future<List<dynamic>> getTransferHistory();

  // Employees & Advances & Payroll
  Future<List<dynamic>> getEmployees();
  Future<Map<String, dynamic>> saveEmployee(Map<String, dynamic> payload);
  Future<void> deleteEmployee(int id);
  Future<List<dynamic>> getRecentAdvances({int limit = 50});
  Future<List<dynamic>> getEmployeeAdvances(int employeeId);
  Future<Map<String, dynamic>> giveAdvance({
    required int employeeId,
    required String date,
    required double amount,
    String? description,
  });
  Future<List<dynamic>> getPayrolls();
  Future<Map<String, dynamic>> savePayroll(Map<String, dynamic> payload);

  // Daily Production
  Future<List<dynamic>> getDailyProductions({
    String? date,
    String? startDate,
    String? endDate,
    int? limit,
  });
  Future<Map<String, dynamic>> saveDailyProduction(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> saveDailyProductionBulk({
    required String date,
    required List<Map<String, dynamic>> entries,
  });
  Future<void> deleteDailyProduction(int id);
  Future<Map<String, dynamic>> getAggregateProduction({
    required int employeeId,
    required String startDate,
    required String endDate,
  });

  // Legacy Archive APIs
  Future<Map<String, dynamic>> getLegacyAnalytics();
  Future<List<dynamic>> getLegacyAnalyticsProducts();
  Future<List<dynamic>> getLegacyAnalyticsPriceTrends(String product);
  Future<List<dynamic>> getLegacyEstimates();
  Future<Map<String, dynamic>> getLegacyEstimateDetails(int salesId);
  Future<List<dynamic>> getLegacyPurchases();
  Future<List<dynamic>> getLegacyPurchaseParticulars(int purchaseId);
  Future<List<dynamic>> getLegacyPurchaseCharges(int purchaseId);
  Future<List<dynamic>> getLegacyPayments();
  Future<List<dynamic>> getLegacyCustomers();
  Future<List<dynamic>> getLegacySuppliers();
  Future<List<dynamic>> getLegacyEmployees();
  Future<List<dynamic>> getLegacyWorkentries();
  Future<List<dynamic>> getLegacyWorkentryParticulars(int workId);
  Future<List<dynamic>> getLegacyPayrollProducts();
}

class HttpApiClient implements ApiClient {
  HttpApiClient({
    required String Function() baseUrlProvider,
    required String? Function() tokenProvider,
    void Function()? onUnauthorized,
    http.Client? client,
  }) : _baseUrlProvider = baseUrlProvider,
       _tokenProvider = tokenProvider,
       _onUnauthorized = onUnauthorized,
       _client = client ?? http.Client();

  final String Function() _baseUrlProvider;
  final String? Function() _tokenProvider;
  final void Function()? _onUnauthorized;
  final http.Client _client;

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final base = _baseUrlProvider();
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$base$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) return uri;
    return uri.replace(queryParameters: queryParameters);
  }

  Map<String, String> _headers({required bool authenticated}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (authenticated) {
      final token = _tokenProvider();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    Map<String, String>? queryParameters,
    Object? body,
    bool authenticated = true,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = _headers(authenticated: authenticated);
    final encodedBody = body != null ? jsonEncode(body) : null;

    http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(AppConfig.requestTimeout);
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(AppConfig.requestTimeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers)
              .timeout(AppConfig.requestTimeout);
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }
    } on TimeoutException {
      throw const NetworkUnavailableException(
        'Server request timed out. Please try again.',
      );
    } on http.ClientException {
      throw const NetworkUnavailableException();
    }

    dynamic decoded;
    if (response.body.trim().isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.body;
        }
        throw ApiException(
          'Unexpected server response (${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final errorMessage = _extractErrorMessage(decoded, response.statusCode);
    final isExpiredToken =
        response.statusCode == 401 ||
        (response.statusCode == 403 &&
            errorMessage.toLowerCase().contains('token'));

    if (authenticated && isExpiredToken) {
      _onUnauthorized?.call();
    }

    throw ApiException(errorMessage, statusCode: response.statusCode);
  }

  String _extractErrorMessage(dynamic decoded, int statusCode) {
    if (decoded is Map<String, dynamic>) {
      final err = decoded['error'] ?? decoded['message'];
      if (err != null && err.toString().trim().isNotEmpty) {
        return err.toString().trim();
      }
    }
    return 'Request failed with status $statusCode.';
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw const ApiException('Expected JSON object from server.');
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List<dynamic>) return data;
    throw const ApiException('Expected JSON array from server.');
  }

  @override
  Future<Map<String, dynamic>> login(String username, String pin) async {
    final res = await _send(
      method: 'POST',
      path: '/login',
      authenticated: false,
      body: {'username': username.trim(), 'pin': pin.trim()},
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> getMe() async {
    final res = await _send(method: 'GET', path: '/me');
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getUsers() async {
    final res = await _send(method: 'GET', path: '/users');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveUser(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/users', body: payload);
    return _asMap(res);
  }

  @override
  Future<void> deleteUser(int id) async {
    await _send(method: 'DELETE', path: '/users/$id');
  }

  @override
  Future<List<dynamic>> getReps() async {
    final res = await _send(method: 'GET', path: '/reps');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getCustomers() async {
    final res = await _send(method: 'GET', path: '/customers');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveCustomer(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/customers', body: payload);
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getCustomerPrices(int customerId) async {
    final res = await _send(
      method: 'GET',
      path: '/customers/$customerId/prices',
    );
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveCustomerPrices(
    int customerId,
    List<Map<String, dynamic>> prices,
  ) async {
    final res = await _send(
      method: 'POST',
      path: '/customers/$customerId/prices',
      body: {'prices': prices},
    );
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getSuppliers() async {
    final res = await _send(method: 'GET', path: '/suppliers');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveSupplier(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/suppliers', body: payload);
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getTransporters() async {
    final res = await _send(method: 'GET', path: '/transporters');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveTransporter(
    Map<String, dynamic> payload,
  ) async {
    final res = await _send(
      method: 'POST',
      path: '/transporters',
      body: payload,
    );
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getVehicles() async {
    final res = await _send(method: 'GET', path: '/vehicles');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveVehicle(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/vehicles', body: payload);
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getGodowns() async {
    final res = await _send(method: 'GET', path: '/godowns');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveGodown(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/godowns', body: payload);
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getProducts() async {
    final res = await _send(method: 'GET', path: '/products');
    return _asList(res);
  }

  @override
  Future<String> getNextProductCode({String type = 'INV'}) async {
    try {
      final res = await _send(
        method: 'GET',
        path: '/products/next-code',
        queryParameters: {'type': type},
      );
      final map = _asMap(res);
      final code = (map['code'] ?? '').toString().trim();
      if (code.isNotEmpty) return code;
    } catch (_) {}
    return '${type}001';
  }

  @override
  Future<Map<String, dynamic>> saveProduct(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/products', body: payload);
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getCompanyProfiles() async {
    final res = await _send(method: 'GET', path: '/company-profiles');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveCompanyProfile(
    Map<String, dynamic> payload,
  ) async {
    final res = await _send(
      method: 'POST',
      path: '/company-profiles',
      body: payload,
    );
    return _asMap(res);
  }

  @override
  Future<void> deleteCompanyProfile(int id) async {
    await _send(method: 'DELETE', path: '/company-profiles/$id');
  }

  @override
  Future<Map<String, dynamic>> saveBillingSeries(
    Map<String, dynamic> payload,
  ) async {
    final res = await _send(
      method: 'POST',
      path: '/billing-series',
      body: payload,
    );
    return _asMap(res);
  }

  @override
  Future<void> deleteBillingSeries(int id) async {
    await _send(method: 'DELETE', path: '/billing-series/$id');
  }

  @override
  Future<Map<String, dynamic>> getSystemCredentials() async {
    final res = await _send(method: 'GET', path: '/system-credentials');
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> getInvoice(String number) async {
    final res = await _send(
      method: 'GET',
      path: '/invoices/${Uri.encodeComponent(number.trim())}',
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> saveInvoice(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/invoices', body: payload);
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> generateEwayBill(
    String number,
    String mode,
  ) async {
    final res = await _send(
      method: 'POST',
      path: '/invoices/${Uri.encodeComponent(number.trim())}/ewaybill',
      body: {'mode': mode},
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> getRecentEwayBills({int days = 7}) async {
    final res = await _send(
      method: 'GET',
      path: '/ewaybill/reports/recent',
      queryParameters: {'days': '$days'},
    );
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getInvoiceHistory() async {
    final res = await _send(method: 'GET', path: '/history/invoices');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> verifyGstin(String gstin) async {
    final res = await _send(
      method: 'GET',
      path: '/gstin/${Uri.encodeComponent(gstin.trim().toUpperCase())}',
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>?> lookupPincode(String pincode) async {
    final clean = pincode.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(clean)) return null;
    try {
      final response = await _client
          .get(Uri.parse('https://api.postalpincode.in/pincode/$clean'))
          .timeout(AppConfig.requestTimeout);
      if (response.statusCode != 200) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is List && decoded.isNotEmpty) {
        final first = decoded.first;
        if (first is Map<String, dynamic> &&
            first['Status'] == 'Success' &&
            first['PostOffice'] is List &&
            (first['PostOffice'] as List).isNotEmpty) {
          final po = (first['PostOffice'] as List).first;
          if (po is Map<String, dynamic>) {
            return {
              'city': (po['Block'] ?? po['Name'] ?? po['District'] ?? '')
                  .toString(),
              'district': (po['District'] ?? '').toString(),
              'state': (po['State'] ?? '').toString(),
            };
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<Map<String, dynamic>> getRepDashboard() async {
    final res = await _send(method: 'GET', path: '/rep/dashboard');
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getPendingSalesOrders() async {
    final res = await _send(method: 'GET', path: '/sales-orders/pending');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getApprovedSalesOrders({bool factoryView = false}) async {
    final res = await _send(
      method: 'GET',
      path: '/sales-orders/approved',
      queryParameters: factoryView ? {'factoryView': '1'} : null,
    );
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getApprovedFactoryOrders() =>
      getApprovedSalesOrders(factoryView: true);

  @override
  Future<Map<String, dynamic>> getSalesOrderFactoryView(int id) async {
    final res = await _send(
      method: 'GET',
      path: '/sales-orders/$id/factory-view',
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> createSalesOrder(
    Map<String, dynamic> payload,
  ) async {
    final res = await _send(
      method: 'POST',
      path: '/sales-orders',
      body: payload,
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> approveSalesOrderCustomer(int id) async {
    final res = await _send(
      method: 'POST',
      path: '/sales-orders/$id/approve-customer',
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> linkCustomerToOrder(
    int orderId,
    int customerId,
  ) async {
    final res = await _send(
      method: 'POST',
      path: '/sales-orders/$orderId/link-customer',
      body: {'customerId': customerId},
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> updateSalesOrderStatus(
    int id,
    String status,
  ) async {
    final res = await _send(
      method: 'POST',
      path: '/sales-orders/$id/status',
      body: {'status': status},
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> savePurchase(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/purchases', body: payload);
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getPurchaseHistory() async {
    final res = await _send(method: 'GET', path: '/history/purchases');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> togglePurchaseStatus(
    int id,
    String status,
  ) async {
    final res = await _send(
      method: 'POST',
      path: '/purchases/$id/status',
      body: {'status': status},
    );
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getStockLedger() async {
    final res = await _send(method: 'GET', path: '/stock');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveTransfer(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/transfers', body: payload);
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getTransferHistory() async {
    final res = await _send(method: 'GET', path: '/history/transfers');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getEmployees() async {
    final res = await _send(method: 'GET', path: '/employees');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveEmployee(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/employees', body: payload);
    return _asMap(res);
  }

  @override
  Future<void> deleteEmployee(int id) async {
    await _send(method: 'DELETE', path: '/employees/$id');
  }

  @override
  Future<List<dynamic>> getRecentAdvances({int limit = 50}) async {
    final res = await _send(
      method: 'GET',
      path: '/advances',
      queryParameters: {'limit': '$limit'},
    );
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getEmployeeAdvances(int employeeId) async {
    final res = await _send(method: 'GET', path: '/advances/$employeeId');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> giveAdvance({
    required int employeeId,
    required String date,
    required double amount,
    String? description,
  }) async {
    final res = await _send(
      method: 'POST',
      path: '/advances',
      body: {
        'employeeId': employeeId,
        'date': date,
        'amount': amount,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
    );
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getPayrolls() async {
    final res = await _send(method: 'GET', path: '/payrolls');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> savePayroll(Map<String, dynamic> payload) async {
    final res = await _send(method: 'POST', path: '/payrolls', body: payload);
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getDailyProductions({
    String? date,
    String? startDate,
    String? endDate,
    int? limit,
  }) async {
    final query = <String, String>{};
    if (date != null && date.isNotEmpty) query['date'] = date;
    if (startDate != null && startDate.isNotEmpty) query['startDate'] = startDate;
    if (endDate != null && endDate.isNotEmpty) query['endDate'] = endDate;
    if (limit != null) query['limit'] = '$limit';

    final res = await _send(
      method: 'GET',
      path: '/production/daily',
      queryParameters: query.isEmpty ? null : query,
    );
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveDailyProduction(
    Map<String, dynamic> payload,
  ) async {
    final res = await _send(
      method: 'POST',
      path: '/production/daily',
      body: payload,
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> saveDailyProductionBulk({
    required String date,
    required List<Map<String, dynamic>> entries,
  }) async {
    final res = await _send(
      method: 'POST',
      path: '/production/daily/bulk',
      body: {'date': date, 'entries': entries},
    );
    return _asMap(res);
  }

  @override
  Future<void> deleteDailyProduction(int id) async {
    await _send(method: 'DELETE', path: '/production/daily/$id');
  }

  @override
  Future<Map<String, dynamic>> getAggregateProduction({
    required int employeeId,
    required String startDate,
    required String endDate,
  }) async {
    final res = await _send(
      method: 'GET',
      path: '/production/aggregate',
      queryParameters: {
        'employeeId': '$employeeId',
        'startDate': startDate,
        'endDate': endDate,
      },
    );
    return _asMap(res);
  }

  @override
  Future<Map<String, dynamic>> getLegacyAnalytics() async {
    final res = await _send(method: 'GET', path: '/legacy/analytics');
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getLegacyAnalyticsProducts() async {
    final res = await _send(method: 'GET', path: '/legacy/analytics/products');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacyAnalyticsPriceTrends(String product) async {
    final res = await _send(
      method: 'GET',
      path: '/legacy/analytics/price-trends',
      queryParameters: {'product': product},
    );
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacyEstimates() async {
    final res = await _send(method: 'GET', path: '/legacy/estimates');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> getLegacyEstimateDetails(int salesId) async {
    final res = await _send(
      method: 'GET',
      path: '/legacy/estimates/$salesId/details',
    );
    return _asMap(res);
  }

  @override
  Future<List<dynamic>> getLegacyPurchases() async {
    final res = await _send(method: 'GET', path: '/legacy/purchases');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacyPurchaseParticulars(int purchaseId) async {
    final res = await _send(
      method: 'GET',
      path: '/legacy/purchases/$purchaseId/particulars',
    );
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacyPurchaseCharges(int purchaseId) async {
    final res = await _send(
      method: 'GET',
      path: '/legacy/purchases/$purchaseId/charges',
    );
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacyPayments() async {
    final res = await _send(method: 'GET', path: '/legacy/payments');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacyCustomers() async {
    final res = await _send(method: 'GET', path: '/legacy/customers');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacySuppliers() async {
    final res = await _send(method: 'GET', path: '/legacy/suppliers');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacyEmployees() async {
    final res = await _send(method: 'GET', path: '/legacy/employees');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacyWorkentries() async {
    final res = await _send(method: 'GET', path: '/legacy/workentries');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacyWorkentryParticulars(int workId) async {
    final res = await _send(
      method: 'GET',
      path: '/legacy/workentries/$workId/particulars',
    );
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getLegacyPayrollProducts() async {
    final res = await _send(method: 'GET', path: '/legacy/payroll-products');
    return _asList(res);
  }
}
