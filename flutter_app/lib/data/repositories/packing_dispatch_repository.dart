import '../../domain/models/json_helpers.dart';
import '../../domain/models/packing_dispatch.dart';
import '../services/api_client.dart';

class PackingDispatchRepository {
  PackingDispatchRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PackingSummary> fetchPackingSummary() async {
    final json = await _apiClient.getPackingSummary();
    return PackingSummary.fromJson(json);
  }

  Future<Map<String, dynamic>> recordInnerBoxPacking({
    required DateTime date,
    required int productId,
    required int innerBoxesPacked,
    int damagedBoxes = 0,
    bool autoSealCartons = false,
    String? remarks,
  }) async {
    return _apiClient.recordInnerBoxPacking({
      'date': toIsoCalendarDate(date),
      'productId': productId,
      'innerBoxesPacked': innerBoxesPacked,
      'damagedBoxes': damagedBoxes,
      'autoSealCartons': autoSealCartons,
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    });
  }

  Future<Map<String, dynamic>> sealMasterCartons({
    required DateTime date,
    required int productId,
    required int masterCartonsSealed,
    int? targetGodownId,
    String? remarks,
  }) async {
    return _apiClient.sealMasterCartons({
      'date': toIsoCalendarDate(date),
      'productId': productId,
      'masterCartonsSealed': masterCartonsSealed,
      'targetGodownId': ?targetGodownId,
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
    });
  }

  Future<FactoryDispatchOverview> fetchFactoryDispatches() async {
    final json = await _apiClient.getFactoryDispatches();
    return FactoryDispatchOverview.fromJson(json);
  }

  Future<FactoryDispatchRecord> createFactoryDispatch({
    required DateTime date,
    required String destinationType,
    required int fromGodownId,
    int? toGodownId,
    int? transporterId,
    String? transporterName,
    String? customerName,
    String? lrNumber,
    String? vehicleNo,
    String? driverName,
    String? remarks,
    required List<Map<String, dynamic>> items,
  }) async {
    final json = await _apiClient.createFactoryDispatch({
      'date': toIsoCalendarDate(date),
      'destinationType': destinationType,
      'fromGodownId': fromGodownId,
      'toGodownId': ?toGodownId,
      'transporterId': ?transporterId,
      if (transporterName != null && transporterName.trim().isNotEmpty)
        'transporterName': transporterName.trim(),
      if (customerName != null && customerName.trim().isNotEmpty)
        'customerName': customerName.trim(),
      if (lrNumber != null && lrNumber.trim().isNotEmpty)
        'lrNumber': lrNumber.trim(),
      if (vehicleNo != null && vehicleNo.trim().isNotEmpty)
        'vehicleNo': vehicleNo.trim(),
      if (driverName != null && driverName.trim().isNotEmpty)
        'driverName': driverName.trim(),
      if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
      'items': items,
    });
    return FactoryDispatchRecord.fromJson(json);
  }
}
