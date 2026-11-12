import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/inventory_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/domain/models/godown.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/domain/models/purchase.dart';
import 'package:crackers_erp/domain/models/supplier.dart';

class PurchaseLineDraft {
  PurchaseLineDraft({
    required this.localId,
    this.godownId,
    this.godownName = '',
    this.productId,
    this.productCode = '',
    this.productName = '',
    this.packs = 1,
    this.qtyPerPack = 1,
    this.packUnit = 'Pack',
    this.pricingUnit = 'Kg',
    this.qty = 1,
    this.rate = 0,
    this.amount = 0,
    this.discount = 0,
    this.taxRate = 18,
    this.taxAmt = 0,
    this.netAmt = 0,
  });

  final int localId;
  int? godownId;
  String godownName;
  int? productId;
  String productCode;
  String productName;
  int packs;
  int qtyPerPack;
  String packUnit;
  String pricingUnit;
  int qty;
  double rate;
  double amount;
  double discount;
  double taxRate;
  double taxAmt;
  double netAmt;

  void recalculate() {
    final safePacks = packs < 0 ? 0 : packs;
    final safePerPack = qtyPerPack < 1 ? 1 : qtyPerPack;
    qty = safePacks * safePerPack;
    amount = double.parse((qty * rate).toStringAsFixed(2));
    final taxable = math.max(0.0, amount - discount);
    taxAmt = double.parse((taxable * taxRate / 100.0).toStringAsFixed(2));
    netAmt = double.parse((taxable + taxAmt).toStringAsFixed(2));
  }

  Map<String, dynamic> toPayload() {
    return {
      'godownId': godownId,
      'productId': productId,
      'product': productName.trim(),
      'packs': packs,
      'qtyPerPack': qtyPerPack,
      'pack_unit': packUnit,
      'pricing_unit': pricingUnit,
      'qty': qty,
      'rate': rate,
      'amount': amount,
      'discount': discount,
      'tax_rate': taxRate,
      'tax_amt': taxAmt,
      'net_amount': netAmt,
    };
  }
}

class PurchaseViewModel extends ChangeNotifier {
  PurchaseViewModel({
    required InventoryRepository inventoryRepository,
    required MasterRepository masterRepository,
  }) : _inventoryRepository = inventoryRepository,
       _masterRepository = masterRepository;

  static const String companyState = 'Tamil Nadu';

  final InventoryRepository _inventoryRepository;
  final MasterRepository _masterRepository;

  List<Product> _rawMaterials = const [];
  List<Godown> _godowns = const [];
  List<Supplier> _suppliers = const [];
  List<PurchaseRecord> _history = const [];

  int? _editingId;
  String _purchaseNumber = _generateNumber();
  DateTime _date = DateTime.now();
  String _supplierName = '';
  String _supplierState = companyState;
  String _billNo = '';

  int _nextLocalRowId = 1;
  late List<PurchaseLineDraft> _rows = [_createDefaultRow()];

  bool _isLoading = false;
  bool _isSaving = false;
  int? _togglingPurchaseId;
  String? _errorMessage;
  String? _statusMessage;
  bool _disposed = false;

  List<Product> get rawMaterials => _rawMaterials;
  List<Godown> get godowns => _godowns;
  List<Supplier> get suppliers => _suppliers;
  List<PurchaseRecord> get history => _history;

  int? get editingId => _editingId;
  bool get isEditing => _editingId != null;
  String get purchaseNumber => _purchaseNumber;
  DateTime get date => _date;
  String get isoDate => toIsoCalendarDate(_date);
  String get supplierName => _supplierName;
  String get supplierState => _supplierState;
  String get billNo => _billNo;
  List<PurchaseLineDraft> get rows => List.unmodifiable(_rows);

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  int? get togglingPurchaseId => _togglingPurchaseId;
  String? get errorMessage => _errorMessage;
  String? get statusMessage => _statusMessage;

  int get totalQty => _rows.fold(0, (sum, r) => sum + r.qty);
  double get subtotal => _rows.fold(0.0, (sum, r) => sum + r.amount);
  double get totalDiscount => _rows.fold(0.0, (sum, r) => sum + r.discount);
  double get totalTax => _rows.fold(0.0, (sum, r) => sum + r.taxAmt);
  double get grandTotal => _rows.fold(0.0, (sum, r) => sum + r.netAmt);

  bool get isIntraState =>
      _supplierState.trim().isEmpty ||
      _supplierState.trim().toLowerCase() == companyState.toLowerCase();

  double get cgst => isIntraState ? totalTax / 2.0 : 0.0;
  double get sgst => isIntraState ? totalTax / 2.0 : 0.0;
  double get igst => isIntraState ? 0.0 : totalTax;

  static String _generateNumber() {
    final millis = DateTime.now().millisecondsSinceEpoch.toString();
    return 'PUR-${millis.substring(millis.length - 4)}';
  }

  PurchaseLineDraft _createDefaultRow() {
    final row = PurchaseLineDraft(localId: _nextLocalRowId++);
    row.recalculate();
    return row;
  }

  Future<void> loadAll() async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final results = await Future.wait<dynamic>([
        _masterRepository.fetchProducts(),
        _masterRepository.fetchGodowns(),
        _masterRepository.fetchSuppliers(),
        _inventoryRepository.fetchPurchaseHistory(),
      ]);

      final allProducts = results[0] as List<Product>;
      _rawMaterials = allProducts.where((p) => p.isRm).toList();
      _godowns = results[1] as List<Godown>;
      _suppliers = results[2] as List<Supplier>;
      _history = results[3] as List<PurchaseRecord>;
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'Failed to load purchase entry data.';
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }

  void setDate(DateTime value) {
    _date = DateTime(value.year, value.month, value.day);
    _safeNotify();
  }

  void setBillNo(String value) {
    _billNo = value;
    _safeNotify();
  }

  void selectSupplier(Supplier supplier) {
    _supplierName = supplier.name;
    final state = supplier.state?.trim() ?? '';
    _supplierState = state.isNotEmpty ? state : companyState;
    _safeNotify();
  }

  void setCustomSupplierName(String name) {
    _supplierName = name.trim();
    Supplier? matched;
    for (final s in _suppliers) {
      if (s.name.toLowerCase() == _supplierName.toLowerCase()) {
        matched = s;
        break;
      }
    }
    _supplierState = (matched?.state?.trim().isNotEmpty ?? false)
        ? matched!.state!.trim()
        : companyState;
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

  void selectRowGodown(int localId, Godown godown) {
    final row = _findRow(localId);
    if (row == null) return;
    row.godownId = godown.id;
    row.godownName = godown.name;
    _safeNotify();
  }

  void selectRowProduct(int localId, Product product) {
    final row = _findRow(localId);
    if (row == null) return;
    row.productId = product.id;
    row.productCode = product.code;
    row.productName = product.name;
    row.qtyPerPack = product.unitQty > 0 ? product.unitQty : 1;
    row.packUnit = (product.packUnit?.trim().isNotEmpty ?? false)
        ? product.packUnit!.trim()
        : 'Pack';
    row.pricingUnit = product.unit.trim().isNotEmpty ? product.unit.trim() : 'Kg';
    row.rate = product.rate;
    row.taxRate = product.tax;
    row.recalculate();
    _safeNotify();
  }

  void updateRowNumbers(
    int localId, {
    int? packs,
    int? qtyPerPack,
    double? rate,
    double? discount,
    double? taxRate,
  }) {
    final row = _findRow(localId);
    if (row == null) return;
    if (packs != null) row.packs = packs < 0 ? 0 : packs;
    if (qtyPerPack != null) row.qtyPerPack = qtyPerPack < 1 ? 1 : qtyPerPack;
    if (rate != null) row.rate = rate < 0 ? 0 : rate;
    if (discount != null) row.discount = discount < 0 ? 0 : discount;
    if (taxRate != null) row.taxRate = taxRate < 0 ? 0 : taxRate;
    row.recalculate();
    _safeNotify();
  }

  void editPurchase(PurchaseRecord purchase) {
    _editingId = purchase.id;
    _purchaseNumber = purchase.number;
    _date = purchase.date;
    _supplierName = purchase.supplier;
    _billNo = purchase.billNo;

    Supplier? matched;
    for (final s in _suppliers) {
      if (s.name.toLowerCase() == purchase.supplier.toLowerCase()) {
        matched = s;
        break;
      }
    }
    _supplierState = (matched?.state?.trim().isNotEmpty ?? false)
        ? matched!.state!.trim()
        : companyState;

    if (purchase.items.isNotEmpty) {
      _rows = purchase.items.map((item) {
        final inferredQtyPerPack = item.packs > 0
            ? math.max(1, (item.qty / item.packs).round())
            : 1;
        final line = PurchaseLineDraft(
          localId: _nextLocalRowId++,
          godownId: item.godownId > 0 ? item.godownId : null,
          godownName: item.godownName ?? _godownNameById(item.godownId),
          productId: item.productId,
          productName: item.product,
          packs: item.packs > 0 ? item.packs : item.qty,
          qtyPerPack: inferredQtyPerPack,
          packUnit: item.packUnit ?? 'Pack',
          pricingUnit: item.pricingUnit ?? 'Kg',
          qty: item.qty,
          rate: item.rate,
          amount: item.amount,
          discount: item.discount,
          taxRate: item.taxRate,
          taxAmt: item.taxAmt,
          netAmt: item.netAmount > 0 ? item.netAmount : item.amount,
        );
        return line;
      }).toList();
    } else {
      _rows = [_createDefaultRow()];
    }

    _errorMessage = null;
    _statusMessage = 'Editing purchase ${purchase.number}.';
    _safeNotify();
  }

  void cancelEdit() {
    _editingId = null;
    _purchaseNumber = _generateNumber();
    _date = DateTime.now();
    _supplierName = '';
    _supplierState = companyState;
    _billNo = '';
    _rows = [_createDefaultRow()];
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();
  }

  Future<bool> savePurchase() async {
    final cleanSupplier = _supplierName.trim();
    if (cleanSupplier.isEmpty) {
      _errorMessage = 'Supplier name is required.';
      _safeNotify();
      return false;
    }

    for (final row in _rows) {
      if (row.productName.trim().isEmpty) {
        _errorMessage = 'Raw material product is required for all rows.';
        _safeNotify();
        return false;
      }
      if (row.godownId == null || row.godownId! <= 0) {
        _errorMessage =
            'Please select a valid Destination Godown for ${row.productName}.';
        _safeNotify();
        return false;
      }
      if (row.qty <= 0) {
        _errorMessage = 'Quantity must be greater than 0 for ${row.productName}.';
        _safeNotify();
        return false;
      }
    }

    _isSaving = true;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    final wasEditing = isEditing;
    final savedNum = _purchaseNumber;

    try {
      final payload = <String, dynamic>{
        if (_editingId != null) 'id': _editingId,
        'number': _purchaseNumber,
        'date': isoDate,
        'supplier': cleanSupplier,
        'billNo': _billNo.trim(),
        'qty': totalQty,
        'subtotal': double.parse(subtotal.toStringAsFixed(2)),
        'discount': double.parse(totalDiscount.toStringAsFixed(2)),
        'tax': double.parse(totalTax.toStringAsFixed(2)),
        'cgst': double.parse(cgst.toStringAsFixed(2)),
        'sgst': double.parse(sgst.toStringAsFixed(2)),
        'igst': double.parse(igst.toStringAsFixed(2)),
        'value': double.parse(grandTotal.toStringAsFixed(2)),
        'items': _rows.map((r) => r.toPayload()).toList(),
      };

      await _inventoryRepository.savePurchase(payload);
      cancelEdit();
      _history = await _inventoryRepository.fetchPurchaseHistory();
      _statusMessage =
          'Purchase $savedNum ${wasEditing ? 'updated' : 'saved'}! Stock balances updated.';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to save purchase entry.';
      return false;
    } finally {
      _isSaving = false;
      _safeNotify();
    }
  }

  Future<bool> togglePurchaseStatus(PurchaseRecord purchase) async {
    final nextStatus = purchase.isActive ? 'Inactive' : 'Active';
    _togglingPurchaseId = purchase.id;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();

    try {
      await _inventoryRepository.togglePurchaseStatus(purchase.id, nextStatus);
      _history = await _inventoryRepository.fetchPurchaseHistory();
      _statusMessage =
          'Purchase ${purchase.number} marked $nextStatus. Godown stock adjusted.';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'Failed to update purchase status.';
      return false;
    } finally {
      _togglingPurchaseId = null;
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
    _rawMaterials = const [];
    _godowns = const [];
    _suppliers = const [];
    _history = const [];
    _editingId = null;
    _purchaseNumber = _generateNumber();
    _date = DateTime.now();
    _supplierName = '';
    _supplierState = companyState;
    _billNo = '';
    _rows = [_createDefaultRow()];
    _isLoading = false;
    _isSaving = false;
    _togglingPurchaseId = null;
    _errorMessage = null;
    _statusMessage = null;
    _safeNotify();
  }

  PurchaseLineDraft? _findRow(int localId) {
    for (final r in _rows) {
      if (r.localId == localId) return r;
    }
    return null;
  }

  String _godownNameById(int id) {
    for (final g in _godowns) {
      if (g.id == id) return g.name;
    }
    return '';
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

