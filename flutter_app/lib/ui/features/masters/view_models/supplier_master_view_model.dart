import 'package:flutter/foundation.dart';

import 'package:crackers_erp/core/constants/indian_states.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/domain/models/supplier.dart';

class SupplierMasterViewModel extends ChangeNotifier {
  SupplierMasterViewModel({required MasterRepository masterRepository})
    : _masterRepo = masterRepository;

  final MasterRepository _masterRepo;

  List<Supplier> _suppliers = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLookingUpGstin = false;
  bool _isLookingUpPincode = false;
  String? _errorMessage;
  String? _successMessage;
  String _searchQuery = '';

  // Form state
  int? _editingId;
  String _gstin = '';
  String _name = '';
  String _mobile = '';
  String _type = 'Raw Material';
  String _address = '';
  String _state = '';
  String _pincode = '';
  String _city = '';
  String _district = '';
  String _idNumber = '';
  String _status = 'Active';
  List<PartyAddress> _addresses = const [];

  List<Supplier> get suppliers => _suppliers;
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
  String get mobile => _mobile;
  String get type => _type;
  String get address => _address;
  String get state => _state;
  String get pincode => _pincode;
  String get city => _city;
  String get district => _district;
  String get idNumber => _idNumber;
  String get status => _status;
  List<PartyAddress> get addresses => _addresses;

  List<Supplier> get filteredSuppliers {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _suppliers;
    return _suppliers.where((s) {
      return s.name.toLowerCase().contains(q) ||
          (s.mobile ?? '').toLowerCase().contains(q) ||
          (s.city ?? '').toLowerCase().contains(q) ||
          (s.gstin ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<Supplier> get rawMaterialSuppliers =>
      filteredSuppliers.where((s) => s.type == 'Raw Material').toList();

  List<Supplier> get finishedGoodsSuppliers =>
      filteredSuppliers.where((s) => s.type == 'Finished Goods').toList();

  List<Supplier> get otherSuppliers => filteredSuppliers
      .where((s) => s.type != 'Raw Material' && s.type != 'Finished Goods')
      .toList();

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _suppliers = await _masterRepo.fetchSuppliers();
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
    String? mobile,
    String? type,
    String? address,
    String? state,
    String? pincode,
    String? city,
    String? district,
    String? idNumber,
  }) {
    if (gstin != null) _gstin = gstin.toUpperCase();
    if (name != null) _name = name;
    if (mobile != null) _mobile = mobile;
    if (type != null) _type = type;
    if (address != null) _address = address;
    if (state != null) _state = state;
    if (pincode != null) _pincode = pincode;
    if (city != null) _city = city;
    if (district != null) _district = district;
    if (idNumber != null) _idNumber = idNumber;
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
      if (details.preferredName.isNotEmpty) {
        _name = details.preferredName;
      }
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

      if (details.addresses.isNotEmpty) {
        _addresses = details.addresses;
      } else if (_address.isNotEmpty || _city.isNotEmpty) {
        _addresses = [
          PartyAddress(
            type: 'Principal Place',
            address: _address,
            city: _city,
            district: _district,
            state: _state,
            pincode: _pincode,
          ),
        ];
      }
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

  void editSupplier(Supplier supplier) {
    _editingId = supplier.id;
    _gstin = supplier.gstin ?? '';
    _name = supplier.name;
    _mobile = supplier.mobile ?? '';
    _type = supplier.type.isEmpty ? 'Raw Material' : supplier.type;
    _address = supplier.address ?? '';
    _state = normalizeIndianState(supplier.state, fallback: '');
    _pincode = supplier.pincode ?? '';
    _city = supplier.city ?? '';
    _district = supplier.district ?? '';
    _idNumber = supplier.idNumber ?? '';
    _status = supplier.status;
    _addresses = supplier.addresses;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearForm() {
    _editingId = null;
    _gstin = '';
    _name = '';
    _mobile = '';
    _type = 'Raw Material';
    _address = '';
    _state = '';
    _pincode = '';
    _city = '';
    _district = '';
    _idNumber = '';
    _status = 'Active';
    _addresses = const [];
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> saveSupplier() async {
    if (_name.trim().isEmpty) {
      _errorMessage = 'Supplier Name is required.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
    try {
      final saved = await _masterRepo.saveSupplier(
        Supplier(
          id: _editingId ?? 0,
          name: _name.trim(),
          mobile: _mobile.trim(),
          type: _type,
          address: _address.trim(),
          city: _city.trim(),
          district: _district.trim(),
          state: _state.trim(),
          pincode: _pincode.trim(),
          idNumber: _idNumber.trim(),
          gstin: _gstin.trim().toUpperCase(),
          status: _status,
          addresses: _addresses,
        ),
      );
      clearForm();
      _suppliers = await _masterRepo.fetchSuppliers();
      _successMessage = 'Supplier "${saved.name}" saved successfully!';
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatus(Supplier supplier) async {
    final nextStatus = supplier.isActive ? 'Inactive' : 'Active';
    _errorMessage = null;
    try {
      await _masterRepo.saveSupplier(
        Supplier(
          id: supplier.id,
          name: supplier.name,
          mobile: supplier.mobile,
          type: supplier.type,
          address: supplier.address,
          city: supplier.city,
          district: supplier.district,
          state: supplier.state,
          pincode: supplier.pincode,
          idNumber: supplier.idNumber,
          gstin: supplier.gstin,
          status: nextStatus,
          addresses: supplier.addresses,
        ),
      );
      _suppliers = await _masterRepo.fetchSuppliers();
      _successMessage = '${supplier.name} marked as $nextStatus!';
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    }
    notifyListeners();
  }

  void reset() {
    _suppliers = const [];
    _searchQuery = '';
    clearForm();
  }
}
