import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/billing_repository.dart';
import 'package:crackers_erp/domain/models/eway_bill.dart';

class EwayBillReportViewModel extends ChangeNotifier {
  EwayBillReportViewModel({required BillingRepository billingRepository})
    : _billingRepository = billingRepository;

  final BillingRepository _billingRepository;

  static const List<int> availableDayRanges = [3, 5, 7, 15];

  int _days = 7;
  EwayBillReportResponse? _report;
  bool _initialized = false;
  bool _isLoading = false;
  String? _errorMessage;

  int get days => _days;
  EwayBillReportResponse? get report => _report;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await fetchReport();
  }

  Future<void> setDays(int days) async {
    if (_days == days) return;
    _days = days;
    notifyListeners();
    await fetchReport();
  }

  Future<void> fetchReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _report = await _billingRepository.fetchRecentEwayBills(days: _days);
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : 'Failed to fetch from government portal: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _days = 7;
    _report = null;
    _initialized = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}

