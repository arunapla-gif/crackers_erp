import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/domain/models/vehicle.dart';

class VehicleMasterViewModel extends ChangeNotifier {
  VehicleMasterViewModel({required MasterRepository masterRepository})
    : _masterRepo = masterRepository;

  final MasterRepository _masterRepo;

  List<Vehicle> _vehicles = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  int? _editingId;
  String _no = '';
  String _name = '';
  String _ownerName = '';
  String _ownerPhone = '';
  List<VehicleDriver> _drivers = const [];
  String _driverDraftName = '';
  String _driverDraftPhone = '';

  List<Vehicle> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  int? get editingId => _editingId;
  String get no => _no;
  String get name => _name;
  String get ownerName => _ownerName;
  String get ownerPhone => _ownerPhone;
  List<VehicleDriver> get drivers => _drivers;
  String get driverDraftName => _driverDraftName;
  String get driverDraftPhone => _driverDraftPhone;

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _vehicles = await _masterRepo.fetchVehicles();
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateField({
    String? no,
    String? name,
    String? ownerName,
    String? ownerPhone,
    String? driverDraftName,
    String? driverDraftPhone,
  }) {
    if (no != null) _no = no.toUpperCase();
    if (name != null) _name = name;
    if (ownerName != null) _ownerName = ownerName;
    if (ownerPhone != null) _ownerPhone = ownerPhone;
    if (driverDraftName != null) _driverDraftName = driverDraftName;
    if (driverDraftPhone != null) _driverDraftPhone = driverDraftPhone;
    notifyListeners();
  }

  bool addDriver() {
    if (_driverDraftName.trim().isEmpty) {
      _errorMessage = 'Driver Name is required before adding.';
      notifyListeners();
      return false;
    }
    _drivers = [
      ..._drivers,
      VehicleDriver(
        name: _driverDraftName.trim(),
        phone: _driverDraftPhone.trim(),
      ),
    ];
    _driverDraftName = '';
    _driverDraftPhone = '';
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void removeDriver(int index) {
    if (index < 0 || index >= _drivers.length) return;
    final next = List<VehicleDriver>.from(_drivers)..removeAt(index);
    _drivers = next;
    notifyListeners();
  }

  void editVehicle(Vehicle v) {
    _editingId = v.id;
    _no = v.no;
    _name = v.name ?? '';
    _ownerName = v.ownerName ?? '';
    _ownerPhone = v.ownerPhone ?? '';
    _drivers = List<VehicleDriver>.from(v.drivers);
    _driverDraftName = '';
    _driverDraftPhone = '';
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearForm() {
    _editingId = null;
    _no = '';
    _name = '';
    _ownerName = '';
    _ownerPhone = '';
    _drivers = const [];
    _driverDraftName = '';
    _driverDraftPhone = '';
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> saveVehicle() async {
    if (_no.trim().isEmpty) {
      _errorMessage = 'Vehicle Number is required.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final saved = await _masterRepo.saveVehicle(
        Vehicle(
          id: _editingId ?? 0,
          no: _no.trim().toUpperCase(),
          name: _name.trim(),
          ownerName: _ownerName.trim(),
          ownerPhone: _ownerPhone.trim(),
          drivers: _drivers,
        ),
      );
      clearForm();
      _vehicles = await _masterRepo.fetchVehicles();
      _successMessage = 'Vehicle ${saved.no} saved successfully!';
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void reset() {
    _vehicles = const [];
    clearForm();
  }
}
