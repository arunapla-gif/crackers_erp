import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../models/api_exceptions.dart';

abstract class ApiClient {
  Future<Map<String, dynamic>> login(String username, String pin);
  Future<Map<String, dynamic>> getMe();
  Future<List<dynamic>> getProducts();
  Future<List<dynamic>> getEmployees();
  Future<Map<String, dynamic>> saveEmployee(Map<String, dynamic> payload);
  Future<List<dynamic>> getRecentAdvances({int limit = 50});
  Future<List<dynamic>> getEmployeeAdvances(int employeeId);
  Future<Map<String, dynamic>> giveAdvance({
    required int employeeId,
    required String date,
    required double amount,
    String? description,
  });
  Future<List<dynamic>> getDailyProductions({
    String? date,
    String? startDate,
    String? endDate,
    int? limit,
  });
  Future<Map<String, dynamic>> saveDailyProductionBulk({
    required String date,
    required List<Map<String, dynamic>> entries,
  });
  Future<void> deleteDailyProduction(int id);
  Future<List<dynamic>> getApprovedFactoryOrders();
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
  Future<List<dynamic>> getProducts() async {
    final res = await _send(method: 'GET', path: '/products');
    return _asList(res);
  }

  @override
  Future<List<dynamic>> getEmployees() async {
    final res = await _send(method: 'GET', path: '/employees');
    return _asList(res);
  }

  @override
  Future<Map<String, dynamic>> saveEmployee(Map<String, dynamic> payload) async {
    final res = await _send(
      method: 'POST',
      path: '/employees',
      body: payload,
    );
    return _asMap(res);
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
  Future<Map<String, dynamic>> saveDailyProductionBulk({
    required String date,
    required List<Map<String, dynamic>> entries,
  }) async {
    final res = await _send(
      method: 'POST',
      path: '/production/daily/bulk',
      body: {
        'date': date,
        'entries': entries,
      },
    );
    return _asMap(res);
  }

  @override
  Future<void> deleteDailyProduction(int id) async {
    await _send(method: 'DELETE', path: '/production/daily/$id');
  }

  @override
  Future<List<dynamic>> getApprovedFactoryOrders() async {
    final res = await _send(
      method: 'GET',
      path: '/sales-orders/approved',
      queryParameters: {'factoryView': '1'},
    );
    return _asList(res);
  }
}

