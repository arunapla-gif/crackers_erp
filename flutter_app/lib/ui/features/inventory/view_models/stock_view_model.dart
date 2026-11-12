import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/inventory_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/domain/models/godown.dart';
import 'package:crackers_erp/domain/models/purchase.dart';

class StockViewModel extends ChangeNotifier {
  StockViewModel({
    required InventoryRepository inventoryRepository,
    required MasterRepository masterRepository,
  }) : _inventoryRepository = inventoryRepository,
       _masterRepository = masterRepository;

  final InventoryRepository _inventoryRepository;
  final MasterRepository _masterRepository;

  List<StockLedgerEntry> _entries = const [];
  List<Godown> _godowns = const [];
  int? _selectedGodownId;
  String _searchQuery = '';

  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  List<StockLedgerEntry> get entries => _entries;
  List<Godown> get godowns => _godowns;
  int? get selectedGodownId => _selectedGodownId;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<StockLedgerEntry> get filteredEntries {
    final q = _searchQuery.trim().toLowerCase();
    return _entries.where((entry) {
      if (_selectedGodownId != null && entry.godownId != _selectedGodownId) {
        return false;
      }
      if (q.isEmpty) return true;
      final gName = entry.godown?.name.toLowerCase() ?? '';
      return entry.product.toLowerCase().contains(q) || gName.contains(q);
    }).toList();
  }

  double get totalStockValue =>
      filteredEntries.fold(0.0, (sum, item) => sum + item.value);

  int get totalStockQty =>
      filteredEntries.fold(0, (sum, item) => sum + item.qty);

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final results = await Future.wait<dynamic>([
        _inventoryRepository.fetchStockLedger(),
        _masterRepository.fetchGodowns(),
      ]);
      _entries = results[0] as List<StockLedgerEntry>;
      _godowns = results[1] as List<Godown>;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load godown stock ledger.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void setGodownFilter(int? godownId) {
    _selectedGodownId = godownId;
    _safeNotify();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _safeNotify();
  }

  void reset() {
    _entries = const [];
    _godowns = const [];
    _selectedGodownId = null;
    _searchQuery = '';
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

