import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/packing_dispatch_repository.dart';
import 'package:crackers_erp/domain/models/packing_dispatch.dart';

class PackingViewModel extends ChangeNotifier {
  PackingViewModel({required PackingDispatchRepository repository})
    : _repository = repository;

  final PackingDispatchRepository _repository;

  bool isLoading = false;
  bool isSubmitting = false;
  String? errorMessage;
  String? successMessage;

  PackingSummary? summary;
  String selectedSubCategory = 'All';
  String searchQuery = '';
  bool showOnlyReadyToSeal = false;
  DateTime selectedDate = DateTime.now();

  List<PackingProductStatus> get allProducts => summary?.products ?? const [];
  List<PackingEntryRecord> get recentEntries =>
      summary?.recentEntries ?? const [];
  List<PackingGodownRef> get godowns => summary?.godowns ?? const [];
  int? get factoryGodownId => summary?.factoryGodownId;

  int get totalFactoryCartons => summary?.totalFactoryCartons ?? 0;
  int get totalLooseInnerBoxes => summary?.totalLooseInnerBoxes ?? 0;
  int get totalReadyToSealCartons => summary?.totalReadyToSealCartons ?? 0;

  static int _naturalSubCatRank(String value) {
    final m = RegExp(r'(\d+)').firstMatch(value);
    final numVal = m != null ? int.tryParse(m.group(1)!) ?? 99999 : 99999;
    final hasCore = value.toLowerCase().contains('core') ? 1 : 0;
    return numVal * 10 + hasCore;
  }

  List<String> get subCategories {
    final set = <String>{};
    for (final p in allProducts) {
      final sub = (p.subCategory ?? '').trim();
      if (sub.isNotEmpty) set.add(sub);
    }
    final list = set.toList()
      ..sort((a, b) {
        final cmp = _naturalSubCatRank(a).compareTo(_naturalSubCatRank(b));
        return cmp != 0 ? cmp : a.compareTo(b);
      });
    return ['All', ...list];
  }

  List<PackingProductStatus> get filteredProducts {
    final q = searchQuery.trim().toLowerCase();
    return allProducts.where((p) {
      if (selectedSubCategory != 'All' &&
          (p.subCategory ?? '').trim() != selectedSubCategory) {
        return false;
      }
      if (showOnlyReadyToSeal && p.readyToSealCartons <= 0) {
        return false;
      }
      if (q.isNotEmpty) {
        final hay =
            '${p.name} ${p.code} ${p.subCategory ?? ''} ${p.wipName ?? ''}'
                .toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();
  }

  Future<void> loadSummary({bool silent = false}) async {
    if (!silent) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }
    try {
      summary = await _repository.fetchPackingSummary();
      errorMessage = null;
    } catch (err) {
      errorMessage = err is ApiException
          ? err.message
          : 'Failed to load packing status: $err';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSubCategory(String sub) {
    if (selectedSubCategory == sub) return;
    selectedSubCategory = sub;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  void toggleReadyToSealOnly(bool value) {
    showOnlyReadyToSeal = value;
    notifyListeners();
  }

  void setSelectedDate(DateTime date) {
    selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
    notifyListeners();
  }

  Future<bool> recordInnerBoxPacking({
    required PackingProductStatus product,
    required int innerBoxesPacked,
    int damagedBoxes = 0,
    bool autoSealCartons = false,
    String? remarks,
    DateTime? date,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final res = await _repository.recordInnerBoxPacking(
        date: date ?? selectedDate,
        productId: product.id,
        innerBoxesPacked: innerBoxesPacked,
        damagedBoxes: damagedBoxes,
        autoSealCartons: autoSealCartons,
        remarks: remarks,
      );
      final sealed = (res['sealedCartons'] as num?)?.toInt() ?? 0;
      final remaining = (res['looseRemainingAfter'] as num?)?.toInt() ?? 0;
      if (sealed > 0) {
        successMessage =
            'Packed $innerBoxesPacked boxes of ${product.name} → Sealed $sealed Master Cartons ($remaining loose boxes carried forward).';
      } else {
        successMessage =
            'Packed $innerBoxesPacked inner boxes of ${product.name}. Loose balance: $remaining boxes.';
      }
      await loadSummary(silent: true);
      return true;
    } catch (err) {
      errorMessage = err is ApiException
          ? err.message
          : 'Failed to save inner box packing: $err';
      return false;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> sealMasterCartons({
    required PackingProductStatus product,
    required int masterCartonsSealed,
    int? targetGodownId,
    String? remarks,
    DateTime? date,
  }) async {
    isSubmitting = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    try {
      final res = await _repository.sealMasterCartons(
        date: date ?? selectedDate,
        productId: product.id,
        masterCartonsSealed: masterCartonsSealed,
        targetGodownId: targetGodownId ?? factoryGodownId,
        remarks: remarks,
      );
      final remaining = (res['looseRemainingAfter'] as num?)?.toInt() ?? 0;
      final godownName =
          (res['targetGodownName'] ?? 'Factory Ready Stock').toString();
      successMessage =
          'Sealed $masterCartonsSealed Master Cartons of ${product.name} into $godownName ($remaining loose boxes left).';
      await loadSummary(silent: true);
      return true;
    } catch (err) {
      errorMessage = err is ApiException
          ? err.message
          : 'Failed to seal Master Cartons: $err';
      return false;
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
    summary = null;
    selectedSubCategory = 'All';
    searchQuery = '';
    showOnlyReadyToSeal = false;
    selectedDate = DateTime.now();
    notifyListeners();
  }
}

