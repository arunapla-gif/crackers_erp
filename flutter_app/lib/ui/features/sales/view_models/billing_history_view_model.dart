import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/repositories/billing_repository.dart';
import 'package:crackers_erp/domain/models/billing.dart';

class BillingHistoryViewModel extends ChangeNotifier {
  BillingHistoryViewModel({required BillingRepository billingRepository})
    : _billingRepo = billingRepository;

  final BillingRepository _billingRepo;

  List<InvoiceRecord> _records = const [];
  String _searchQuery = '';
  bool _isLoading = false;
  String? _errorMessage;

  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<InvoiceRecord> get filteredRecords {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return List.unmodifiable(_records);
    return _records
        .where(
          (r) =>
              r.number.toLowerCase().contains(q) ||
              (r.customer ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _records = await _billingRepo.fetchInvoiceHistory();
    } catch (e) {
      _errorMessage = 'Failed to load billing history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _records = const [];
    _searchQuery = '';
    _errorMessage = null;
    notifyListeners();
  }
}

