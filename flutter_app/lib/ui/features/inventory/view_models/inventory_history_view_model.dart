import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/inventory_repository.dart';
import 'package:crackers_erp/domain/models/purchase.dart';

enum InventoryHistoryTab { purchases, transfers }

class InventoryHistoryViewModel extends ChangeNotifier {
  InventoryHistoryViewModel({required InventoryRepository inventoryRepository})
    : _inventoryRepository = inventoryRepository;

  final InventoryRepository _inventoryRepository;

  InventoryHistoryTab _activeTab = InventoryHistoryTab.purchases;
  String _searchQuery = '';
  List<PurchaseRecord> _purchases = const [];
  List<StockTransferRecord> _transfers = const [];

  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  InventoryHistoryTab get activeTab => _activeTab;
  String get searchQuery => _searchQuery;
  List<PurchaseRecord> get purchases => _purchases;
  List<StockTransferRecord> get transfers => _transfers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<PurchaseRecord> get filteredPurchases {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _purchases;
    return _purchases.where((p) {
      return p.number.toLowerCase().contains(q) ||
          p.supplier.toLowerCase().contains(q) ||
          p.billNo.toLowerCase().contains(q);
    }).toList();
  }

  List<StockTransferRecord> get filteredTransfers {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _transfers;
    return _transfers.where((t) {
      return t.number.toLowerCase().contains(q) ||
          (t.driverName ?? '').toLowerCase().contains(q) ||
          (t.vehicle?.no ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final results = await Future.wait<dynamic>([
        _inventoryRepository.fetchPurchaseHistory(),
        _inventoryRepository.fetchTransferHistory(),
      ]);
      _purchases = results[0] as List<PurchaseRecord>;
      _transfers = results[1] as List<StockTransferRecord>;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load inventory history.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void setTab(InventoryHistoryTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _searchQuery = '';
    _safeNotify();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _safeNotify();
  }

  void reset() {
    _activeTab = InventoryHistoryTab.purchases;
    _searchQuery = '';
    _purchases = const [];
    _transfers = const [];
    _isLoading = false;
    _errorMessage = null;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

