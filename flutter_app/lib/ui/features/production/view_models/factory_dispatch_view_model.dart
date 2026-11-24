import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/packing_dispatch_repository.dart';
import 'package:crackers_erp/domain/models/packing_dispatch.dart';

class FactoryDispatchViewModel extends ChangeNotifier {
  FactoryDispatchViewModel({required PackingDispatchRepository repository})
    : _repository = repository;

  final PackingDispatchRepository _repository;

  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  String? successMessage;

  FactoryDispatchOverview? overview;
  FactoryDispatchRecord? lastCreatedDispatch;

  // Draft dispatch form state
  DateTime selectedDate = DateTime.now();
  String destinationType = 'GODOWN'; // GODOWN | TRANSPORTER
  int? fromGodownId;
  int? toGodownId;
  int? selectedTransporterId;
  String customTransporterName = '';
  String customerName = '';
  String lrNumber = '';
  String vehicleNo = '';
  String driverName = '';
  String remarks = '';

  /// Selected cartons by productId
  final Map<int, int> selectedCartonsByProduct = <int, int>{};

  List<FactoryDispatchRecord> get dispatches =>
      overview?.dispatches ?? const [];
  List<PackingGodownRef> get godowns => overview?.godowns ?? const [];
  List<DispatchTransporterRef> get transporters =>
      overview?.transporters ?? const [];
  List<DispatchVehicleRef> get vehicles => overview?.vehicles ?? const [];

  List<DispatchStockItem> get availableStockForSource =>
      overview?.stockForGodown(fromGodownId) ?? const [];

  List<PackingGodownRef> get destinationGodowns =>
      godowns.where((g) => g.id != fromGodownId).toList();

  int get totalSelectedCartons =>
      selectedCartonsByProduct.values.fold(0, (a, b) => a + b);

  int get totalSelectedBoxes {
    final stock = availableStockForSource;
    var sum = 0;
    for (final item in stock) {
      final qty = selectedCartonsByProduct[item.productId] ?? 0;
      if (qty > 0) sum += qty * item.boxesPerCase;
    }
    return sum;
  }

  int get selectedItemCount =>
      selectedCartonsByProduct.values.where((q) => q > 0).length;

  Future<void> loadOverview({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      overview = await _repository.fetchFactoryDispatches();
      _ensureDefaultGodowns();
      errorMessage = null;
    } catch (err) {
      errorMessage = err is ApiException
          ? err.message
          : 'Failed to load dispatch data: $err';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _ensureDefaultGodowns() {
    if (godowns.isEmpty) return;
    if (fromGodownId == null ||
        !godowns.any((g) => g.id == fromGodownId)) {
      final factoryG = godowns.where(
        (g) => g.name.trim().toLowerCase() == 'factory ready stock',
      );
      fromGodownId =
          factoryG.isNotEmpty ? factoryG.first.id : godowns.first.id;
    }
    if (toGodownId == null ||
        toGodownId == fromGodownId ||
        !godowns.any((g) => g.id == toGodownId)) {
      final others = destinationGodowns;
      toGodownId = others.isNotEmpty ? others.first.id : null;
    }
  }

  void setDate(DateTime date) {
    selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setDestinationType(String type) {
    if (destinationType == type) return;
    destinationType = type;
    errorMessage = null;
    notifyListeners();
  }

  void setFromGodownId(int? id) {
    if (fromGodownId == id) return;
    fromGodownId = id;
    selectedCartonsByProduct.clear();
    if (toGodownId == fromGodownId) {
      final others = destinationGodowns;
      toGodownId = others.isNotEmpty ? others.first.id : null;
    }
    notifyListeners();
  }

  void setToGodownId(int? id) {
    toGodownId = id;
    notifyListeners();
  }

  void setSelectedTransporterId(int? id) {
    selectedTransporterId = id;
    if (id != null) {
      customTransporterName = '';
    }
    notifyListeners();
  }

  void setCustomTransporterName(String value) {
    customTransporterName = value;
    if (value.trim().isNotEmpty) {
      selectedTransporterId = null;
    }
    notifyListeners();
  }

  void setCartonsForProduct(int productId, int cartons, int maxAvailable) {
    final clamped = cartons.clamp(0, maxAvailable);
    if (clamped <= 0) {
      selectedCartonsByProduct.remove(productId);
    } else {
      selectedCartonsByProduct[productId] = clamped;
    }
    notifyListeners();
  }

  void clearSelection() {
    selectedCartonsByProduct.clear();
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  Future<FactoryDispatchRecord?> submitDispatch({
    required String vehicleNoInput,
    required String driverNameInput,
    required String customerNameInput,
    required String lrNumberInput,
    required String remarksInput,
    String? customTransporterInput,
  }) async {
    if (fromGodownId == null) {
      errorMessage = 'Please select a source godown.';
      notifyListeners();
      return null;
    }

    final items = <Map<String, dynamic>>[];
    for (final stockItem in availableStockForSource) {
      final qty = selectedCartonsByProduct[stockItem.productId] ?? 0;
      if (qty > 0) {
        items.add({'productId': stockItem.productId, 'cartons': qty});
      }
    }
    if (items.isEmpty) {
      errorMessage = 'Select at least 1 Master Carton to dispatch.';
      notifyListeners();
      return null;
    }

    if (destinationType == 'GODOWN') {
      if (toGodownId == null || toGodownId == fromGodownId) {
        errorMessage = 'Please select a destination godown.';
        notifyListeners();
        return null;
      }
    } else {
      final typedTransporter =
          (customTransporterInput ?? customTransporterName).trim();
      if (selectedTransporterId == null && typedTransporter.isEmpty) {
        errorMessage = 'Select or enter a Transporter name.';
        notifyListeners();
        return null;
      }
    }

    isSubmitting = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final typedTransporter =
          (customTransporterInput ?? customTransporterName).trim();
      final created = await _repository.createFactoryDispatch(
        date: selectedDate,
        destinationType: destinationType,
        fromGodownId: fromGodownId!,
        toGodownId: destinationType == 'GODOWN' ? toGodownId : null,
        transporterId:
            destinationType == 'TRANSPORTER' ? selectedTransporterId : null,
        transporterName:
            destinationType == 'TRANSPORTER' && selectedTransporterId == null
            ? typedTransporter
            : null,
        customerName:
            destinationType == 'TRANSPORTER' ? customerNameInput : null,
        lrNumber: destinationType == 'TRANSPORTER' ? lrNumberInput : null,
        vehicleNo: vehicleNoInput,
        driverName: driverNameInput,
        remarks: remarksInput,
        items: items,
      );
      lastCreatedDispatch = created;
      selectedCartonsByProduct.clear();
      successMessage =
          '${created.challanNo} created: ${created.totalCartons} Master Cartons (${created.totalBoxes} boxes) dispatched to ${created.destinationDisplay}.';
      await loadOverview(silent: true);
      return created;
    } catch (err) {
      errorMessage = err is ApiException
          ? err.message
          : 'Failed to create factory dispatch: $err';
      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  void reset() {
    isLoading = false;
    isSubmitting = false;
    errorMessage = null;
    successMessage = null;
    overview = null;
    lastCreatedDispatch = null;
    selectedDate = DateTime.now();
    destinationType = 'GODOWN';
    fromGodownId = null;
    toGodownId = null;
    selectedTransporterId = null;
    customTransporterName = '';
    customerName = '';
    lrNumber = '';
    vehicleNo = '';
    driverName = '';
    remarks = '';
    selectedCartonsByProduct.clear();
    notifyListeners();
  }
}

