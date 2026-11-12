import 'package:flutter/foundation.dart';

import 'package:crackers_erp/core/constants/indian_states.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/domain/models/transporter.dart';

class TransporterMasterViewModel extends ChangeNotifier {
  TransporterMasterViewModel({required MasterRepository masterRepository})
    : _masterRepo = masterRepository;

  final MasterRepository _masterRepo;

  List<Transporter> _transporters = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLookingUpGstin = false;
  bool _isLookingUpPincode = false;
  String? _errorMessage;
  String? _successMessage;
  String _searchQuery = '';

  int? _editingId;
  String _gstin = '';
  String _name = '';
  String _address = '';
  String _state = '';
  String _pincode = '';
  String _city = '';
  String _district = '';
  String _status = 'Active';

  List<Transporter> get transporters => _transporters;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLookingUpGstin => _isLookingUpGstin;
  bool get isLookingUpPincode => _isLookingUpPincode;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get searchQuery => _searchQuery;

  int? get editingId => _editingId;
  String get gstin => _gstin;
  String get name => _name;
  String get address => _address;
  String get state => _state;
  String get pincode => _pincode;
  String get city => _city;
  String get district => _district;
  String get status => _status;

  List<Transporter> get filteredTransporters {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _transporters;
    return _transporters.where((t) {
      return t.name.toLowerCase().contains(q) ||
          t.gstin.toLowerCase().contains(q) ||
          (t.city ?? '').toLowerCase().contains(q) ||
          (t.district ?? '').toLowerCase().contains(q);
    }).toList();
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _transporters = await _masterRepo.fetchTransporters();
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateField({
    String? gstin,
    String? name,
    String? address,
    String? state,
    String? pincode,
    String? city,
    String? district,
  }) {
    if (gstin != null) _gstin = gstin.toUpperCase();
    if (name != null) _name = name;
    if (address != null) _address = address;
    if (state != null) _state = state;
    if (pincode != null) _pincode = pincode;
    if (city != null) _city = city;
    if (district != null) _district = district;
    notifyListeners();

    if (gstin != null && _gstin.trim().length == 15) {
      verifyGstin(_gstin.trim());
    }
    if (pincode != null && _pincode.trim().length == 6) {
      lookupPincode(_pincode.trim());
    }
  }

  Future<void> verifyGstin(String gstinCode) async {
    final clean = gstinCode.trim().toUpperCase();
    if (clean.length != 15) return;
    _isLookingUpGstin = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final details = await _masterRepo.verifyGstin(clean);
      final primary =
          details.addresses.isNotEmpty ? details.addresses.first : null;
      if (details.preferredName.isNotEmpty) _name = details.preferredName;
      final addrText = (primary?.address ?? details.address).trim();
      final cityText = (primary?.city ?? details.city).trim();
      final distText =
          (primary?.district ?? details.district).trim().isNotEmpty
          ? (primary?.district ?? details.district).trim()
          : cityText;
      final stateText = (primary?.state ?? details.state).trim();
      final pinText = (primary?.pincode ?? details.pincode).trim();

      if (addrText.isNotEmpty) _address = addrText;
      if (cityText.isNotEmpty) _city = cityText;
      if (distText.isNotEmpty) _district = distText;
      if (stateText.isNotEmpty) {
        _state = normalizeIndianState(stateText, fallback: '');
      }
      if (pinText.isNotEmpty) _pincode = pinText;
    } catch (e) {
      _errorMessage = e is ApiException
          ? 'GSTIN Lookup failed: ${e.message}'
          : 'GSTIN Lookup failed: $e';
    } finally {
      _isLookingUpGstin = false;
      notifyListeners();
    }
  }

  Future<void> lookupPincode(String pin) async {
    final clean = pin.trim();
    if (clean.length != 6) return;
    _isLookingUpPincode = true;
    notifyListeners();
    try {
      final loc = await _masterRepo.lookupPincode(clean);
      if (loc != null) {
        if (loc.city.trim().isNotEmpty) _city = loc.city.trim();
        if (loc.district.trim().isNotEmpty) _district = loc.district.trim();
        if (loc.state.trim().isNotEmpty) {
          _state = normalizeIndianState(loc.state, fallback: '');
        }
      }
    } catch (_) {
      // Non-fatal
    } finally {
      _isLookingUpPincode = false;
      notifyListeners();
    }
  }

  void editTransporter(Transporter t) {
    _editingId = t.id;
    _gstin = t.gstin;
    _name = t.name;
    _address = t.address ?? '';
    _state = normalizeIndianState(t.state, fallback: '');
    _pincode = t.pincode ?? '';
    _city = t.city ?? '';
    _district = t.district ?? '';
    _status = t.status;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearForm() {
    _editingId = null;
    _gstin = '';
    _name = '';
    _address = '';
    _state = '';
    _pincode = '';
    _city = '';
    _district = '';
    _status = 'Active';
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> saveTransporter() async {
    if (_gstin.trim().isEmpty) {
      _errorMessage = 'GSTIN is required for Transporter.';
      notifyListeners();
      return false;
    }
    if (_name.trim().isEmpty) {
      _errorMessage = 'Transporter Name is required.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final saved = await _masterRepo.saveTransporter(
        Transporter(
          id: _editingId ?? 0,
          gstin: _gstin.trim().toUpperCase(),
          name: _name.trim(),
          address: _address.trim(),
          city: _city.trim(),
          district: _district.trim(),
          state: _state.trim(),
          pincode: _pincode.trim(),
          status: _status,
        ),
      );
      clearForm();
      _transporters = await _masterRepo.fetchTransporters();
      _successMessage = 'Transporter "${saved.name}" saved successfully!';
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatus(Transporter t) async {
    final nextStatus = t.isActive ? 'Inactive' : 'Active';
    _errorMessage = null;
    try {
      await _masterRepo.saveTransporter(
        Transporter(
          id: t.id,
          gstin: t.gstin,
          name: t.name,
          address: t.address,
          city: t.city,
          district: t.district,
          state: t.state,
          pincode: t.pincode,
          status: nextStatus,
        ),
      );
      _transporters = await _masterRepo.fetchTransporters();
      _successMessage = '${t.name} marked as $nextStatus!';
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    }
    notifyListeners();
  }

  void reset() {
    _transporters = const [];
    _searchQuery = '';
    clearForm();
  }
}
