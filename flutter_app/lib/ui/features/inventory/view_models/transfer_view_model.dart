import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/inventory_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/domain/models/godown.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/domain/models/purchase.dart';
import 'package:crackers_erp/domain/models/vehicle.dart';

class TransferLineDraft {
  TransferLineDraft({
    required this.localId,
    this.fromGodownId,
    this.fromGodownName = '',
    this.toGodownId,
    this.toGodownName = '',
    this.productId,
    this.productCode = '',
    this.productName = '',
    this.qty = 1,
    this.rate = 0,
    this.value = 0,
  });

  final int localId;
  int? fromGodownId;
  String fromGodownName;
  int? toGodownId;
  String toGodownName;
  int? productId;
  String productCode;
  String productName;
  int qty;
  double rate;
  double value;

  void recalculateValue() {
    value = double.parse((qty * rate).toStringAsFixed(2));
  }

  Map<String, dynamic> toPayload() {
    return {
      'fromGodownId': fromGodownId,
      'toGodownId': toGodownId,
      'productId': productId,
      'product': productName.trim(),
      'qty': qty,
      'rate': rate,
      'value': value,
    };
  }
}

class TransferViewModel extends ChangeNotifier {
  TransferViewModel({
    required InventoryRepository inventoryRepository,
    required MasterRepository masterRepository,
  }) : _inventoryRepository = inventoryRepository,
       _masterRepository = masterRepository;

  final InventoryRepository _inventoryRepository;
  final MasterRepository _masterRepository;

  List<Product> _products = const [];
  List<Godown> _godowns = const [];
  List<Vehicle> _vehicles = const [];
  List<StockLedgerEntry> _stockLedger = const [];

  String _transferNumber = _generateNumber();
  DateTime _date = DateTime.now();
  Vehicle? _selectedVehicle;
  String _driverName = '';
  String _remarks = '';

  int _nextLocalId = 1;
  late List<TransferLineDraft> _rows = [_createDefaultRow()];

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _statusMessage;
  bool _disposed = false;

  List<Product> get products => _products;
  List<Godown> get godowns => _godowns;
  List<Vehicle> get vehicles => _vehicles;
  List<StockLedgerEntry> get stockLedger => _stockLedger;

  String get transferNumber => _transferNumber;
  DateTime get date => _date;
  String get isoDate => toIsoCalendarDate(_date);
  Vehicle? get selectedVehicle => _selectedVehicle;
  String get driverName => _driverName;
  String get remarks => _remarks;
  List<VehicleDriver> get availableDrivers =>
      _selectedVehicle?.drivers ?? const [];
  List<TransferLineDraft> get rows => List.unmodifiable(_rows);

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  int get totalQty => _rows.fold(0, (sum, r) => sum + r.qty);
  double get totalValue => _rows.fold(0.0, (sum, r) => sum + r.value);

  static String _generateNumber() {
    final millis = DateTime.now().millisecondsSinceEpoch.toString();
    return 'TRF-${millis.substring(millis.length - 4)}';
  }

  TransferLineDraft _createDefaultRow() {
    return TransferLineDraft(localId: _nextLocalId++);
  }

  StockLedgerEntry? sourceStockForRow(TransferLineDraft row) {
    if (row.fromGodownId == null || row.productName.trim().isEmpty) {
      return null;
    }
    final lowerName = row.productName.trim().toLowerCase();
    for (final s in _stockLedger) {
      if (s.godownId == row.fromGodownId &&
          s.product.trim().toLowerCase() == lowerName) {
        return s;
      }
    }
    return null;
  }

  int availableQtyForRow(TransferLineDraft row) =>
      sourceStockForRow(row)?.qty ?? 0;

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final results = await Future.wait<dynamic>([
        _masterRepository.fetchProducts(),
        _masterRepository.fetchGodowns(),
        _masterRepository.fetchVehicles(),
        _inventoryRepository.fetchStockLedger(),
      ]);
      _products = results[0] as List<Product>;
      _godowns = results[1] as List<Godown>;
      _vehicles = results[2] as List<Vehicle>;
      _stockLedger = results[3] as List<StockLedgerEntry>;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load stock transfer resources.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void setDate(DateTime value) {
    _date = DateTime(value.year, value.month, value.day);
    _safeNotify();
  }

  void selectVehicle(Vehicle? vehicle) {
    _selectedVehicle = vehicle;
    final drivers = vehicle?.drivers ?? const <VehicleDriver>[];
    if (!drivers.any((d) => d.name == _driverName)) {
      _driverName = drivers.length == 1 ? drivers.first.name : '';
    }
    _safeNotify();
  }

  void setDriverName(String value) {
    _driverName = value;
    _safeNotify();
  }

  void setRemarks(String value) {
    _remarks = value;
    _safeNotify();
  }

  void addRow() {
    _rows.add(_createDefaultRow());
    _safeNotify();
  }

  void removeRow(int localId) {
    _rows.removeWhere((r) => r.localId == localId);
    if (_rows.isEmpty) {
      _rows.add(_createDefaultRow());
    }
    _safeNotify();
  }

  void selectFromGodown(int localId, Godown godown) {
    final row = _findRow(localId);
    if (row == null) return;
    row.fromGodownId = godown.id;
    row.fromGodownName = godown.name;
    _syncRowStockRate(row);
    _safeNotify();
  }

  void selectToGodown(int localId, Godown godown) {
    final row = _findRow(localId);
    if (row == null) return;
    row.toGodownId = godown.id;
    row.toGodownName = godown.name;
    _safeNotify();
  }

  void selectProduct(int localId, Product product) {
    final row = _findRow(localId);
    if (row == null) return;
    row.productId = product.id;
    row.productCode = product.code;
    row.productName = product.name;
    _syncRowStockRate(row);
    _safeNotify();
  }

  void updateRowQty(int localId, int qty) {
    final row = _findRow(localId);
    if (row == null) return;
    row.qty = qty < 0 ? 0 : qty;
    row.recalculateValue();
    _safeNotify();
  }

  void _syncRowStockRate(TransferLineDraft row) {
    final stock = sourceStockForRow(row);
    if (stock != null) {
      row.rate = stock.avgRate;
    } else {
      row.rate = 0;
    }
    row.recalculateValue();
  }

  Future<bool> saveTransfer() async {
    if (_selectedVehicle == null) {
      _errorMessage = 'Please select a vehicle.';
      _safeNotify();
      return false;
    }

    for (final row in _rows) {
      if (row.fromGodownId == null || row.toGodownId == null) {
        _errorMessage =
            'Select both From and To Godowns for ${row.productName.isEmpty ? 'every line' : row.productName}.';
        _safeNotify();
        return false;
      }
      if (row.fromGodownId == row.toGodownId) {
        _errorMessage =
            'Source and Destination godowns cannot be the same for ${row.productName}.';
        _safeNotify();
        return false;
      }
      if (row.productName.trim().isEmpty || row.qty <= 0) {
        _errorMessage = 'Enter a valid product and positive quantity.';
        _safeNotify();
        return false;
      }
      final available = availableQtyForRow(row);
      if (available < row.qty) {
        _errorMessage =
            'Insufficient stock for ${row.productName} in ${row.fromGodownName}. Available: $available.';
        _safeNotify();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    final savedNum = _transferNumber;

    try {
      await _inventoryRepository.saveTransfer({
        'number': _transferNumber,
        'date': isoDate,
        'vehicleId': _selectedVehicle!.id,
        'driverName': _driverName.trim(),
        'remarks': _remarks.trim(),
        'qty': totalQty,
        'items': _rows.map((r) => r.toPayload()).toList(),
      });

      _transferNumber = _generateNumber();
      _remarks = '';
      _rows = [_createDefaultRow()];
      _stockLedger = await _inventoryRepository.fetchStockLedger();
      _statusMessage = 'Transfer $savedNum completed! Stock ledger updated.';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to complete stock transfer.';
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
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
    _products = const [];
    _godowns = const [];
    _vehicles = const [];
    _stockLedger = const [];
    _transferNumber = _generateNumber();
    _date = DateTime.now();
    _selectedVehicle = null;
    _driverName = '';
    _remarks = '';
    _rows = [_createDefaultRow()];
    _isLoading = false;
    _isSaving = false;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();
  }

  TransferLineDraft? _findRow(int localId) {
    for (final r in _rows) {
      if (r.localId == localId) return r;
    }
    return null;
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

