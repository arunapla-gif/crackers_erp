import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/data/repositories/admin_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/domain/models/company_profile.dart';
import 'package:crackers_erp/domain/models/customer.dart';

class CompanyProfileViewModel extends ChangeNotifier {
  CompanyProfileViewModel({
    required AdminRepository adminRepository,
    required MasterRepository masterRepository,
  }) : _adminRepository = adminRepository,
       _masterRepository = masterRepository;

  final AdminRepository _adminRepository;
  final MasterRepository _masterRepository;

  List<CompanyProfile> _profiles = [];
  SystemCredentials? _credentials;
  bool _initialized = false;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSearchingGstin = false;
  bool _isSavingSeries = false;
  String? _errorMessage;
  String? _successMessage;
  String? _seriesErrorMessage;

  // Profile Form State
  int? _editingId;
  String _name = '';
  String _gstin = '';
  String _address = '';
  String _city = '';
  String _district = '';
  String _state = 'Tamil Nadu';
  String _pincode = '';
  List<PartyAddress> _addresses = [];
  String _status = 'Active';
  String _lastVerifiedGstin = '';

  // Selected Profile for Billing Series Modal
  int? _selectedProfileId;
  String _seriesPrefix = '';
  String _seriesName = '';
  String _seriesDocType = 'INV';
  String _seriesLastNumber = '0';

  List<CompanyProfile> get profiles => List.unmodifiable(_profiles);
  SystemCredentials? get credentials => _credentials;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSearchingGstin => _isSearchingGstin;
  bool get isSavingSeries => _isSavingSeries;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String? get seriesErrorMessage => _seriesErrorMessage;

  int? get editingId => _editingId;
  bool get isEditing => _editingId != null;
  String get name => _name;
  String get gstin => _gstin;
  String get address => _address;
  String get city => _city;
  String get district => _district;
  String get state => _state;
  String get pincode => _pincode;
  List<PartyAddress> get addresses => List.unmodifiable(_addresses);
  String get status => _status;

  int? get selectedProfileId => _selectedProfileId;
  CompanyProfile? get selectedProfile {
    final id = _selectedProfileId;
    if (id == null) return null;
    for (final p in _profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  String get seriesPrefix => _seriesPrefix;
  String get seriesName => _seriesName;
  String get seriesDocType => _seriesDocType;
  String get seriesLastNumber => _seriesLastNumber;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final fetchedProfiles = await _adminRepository.fetchCompanyProfiles();
      _profiles = fetchedProfiles;
      try {
        _credentials = await _adminRepository.fetchSystemCredentials();
      } catch (_) {
        // Non-fatal if credentials endpoint fails
      }
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : 'Failed to load company profiles: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setName(String value) {
    _name = value;
  }

  Future<void> setGstin(String value) async {
    final normalized = value.toUpperCase();
    _gstin = normalized;
    if (normalized.length == 15 && normalized != _lastVerifiedGstin) {
      _lastVerifiedGstin = normalized;
      await _lookupGstin(normalized);
    } else if (normalized.length < 15) {
      _lastVerifiedGstin = '';
    }
  }

  Future<void> _lookupGstin(String gstinValue) async {
    _isSearchingGstin = true;
    notifyListeners();
    try {
      final details = await _masterRepository.verifyGstin(gstinValue);
      final additional = details.addresses.length > 1
          ? details.addresses.sublist(1)
          : <PartyAddress>[];
      final primary = details.addresses.isNotEmpty
          ? details.addresses.first
          : null;

      if (details.preferredName.isNotEmpty) {
        _name = details.preferredName;
      }
      if ((primary?.address ?? details.address).trim().isNotEmpty) {
        _address = (primary?.address ?? details.address).trim();
      }
      if ((primary?.city ?? details.city).trim().isNotEmpty) {
        _city = (primary?.city ?? details.city).trim();
      }
      final nextDist = (primary?.district ?? '').trim().isNotEmpty
          ? primary!.district.trim()
          : (details.district.trim().isNotEmpty
                ? details.district.trim()
                : details.city.trim());
      if (nextDist.isNotEmpty) {
        _district = nextDist;
      }
      if ((primary?.state ?? details.state).trim().isNotEmpty) {
        _state = (primary?.state ?? details.state).trim();
      }
      if ((primary?.pincode ?? details.pincode).trim().isNotEmpty) {
        _pincode = (primary?.pincode ?? details.pincode).trim();
      }
      if (additional.isNotEmpty) {
        _addresses = additional;
      }
    } catch (_) {
      // Allow manual entry if GSTIN lookup fails
    } finally {
      _isSearchingGstin = false;
      notifyListeners();
    }
  }

  void setStateName(String value) {
    _state = value.isEmpty ? 'Tamil Nadu' : value;
    notifyListeners();
  }

  void setAddress(String value) {
    _address = value;
  }

  void setCity(String value) {
    _city = value;
  }

  void setDistrict(String value) {
    _district = value;
  }

  Future<void> setPincode(String value) async {
    _pincode = value;
    if (value.trim().length == 6 && int.tryParse(value.trim()) != null) {
      try {
        final loc = await _masterRepository.lookupPincode(value.trim());
        if (loc != null) {
          if (loc.city.isNotEmpty) _city = loc.city;
          if (loc.district.isNotEmpty) _district = loc.district;
          if (loc.state.isNotEmpty) _state = loc.state;
          notifyListeners();
        }
      } catch (_) {}
    }
  }

  void editProfile(CompanyProfile profile) {
    _editingId = profile.id;
    _name = profile.name;
    _gstin = profile.gstin;
    _lastVerifiedGstin = profile.gstin;
    _address = profile.address ?? '';
    _city = profile.city ?? '';
    _district = profile.district ?? '';
    _state = profile.state;
    _pincode = profile.pincode ?? '';
    _addresses = List<PartyAddress>.from(profile.addresses);
    _status = profile.status;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearForm() {
    _editingId = null;
    _name = '';
    _gstin = '';
    _lastVerifiedGstin = '';
    _address = '';
    _city = '';
    _district = '';
    _state = 'Tamil Nadu';
    _pincode = '';
    _addresses = [];
    _status = 'Active';
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> saveProfile() async {
    if (_name.trim().isEmpty || _gstin.trim().isEmpty) {
      _errorMessage = 'Branch Name and GSTIN are required.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final wasEditing = _editingId != null;
      final profile = CompanyProfile(
        id: _editingId ?? 0,
        name: _name.trim(),
        gstin: _gstin.trim().toUpperCase(),
        address: _address.trim().isEmpty ? null : _address.trim(),
        city: _city.trim().isEmpty ? null : _city.trim(),
        district: _district.trim().isEmpty ? null : _district.trim(),
        state: _state.trim().isEmpty ? 'Tamil Nadu' : _state.trim(),
        pincode: _pincode.trim().isEmpty ? null : _pincode.trim(),
        addresses: _addresses,
        status: _status,
      );
      await _adminRepository.saveCompanyProfile(profile);
      _profiles = await _adminRepository.fetchCompanyProfiles();
      clearForm();
      _successMessage = wasEditing ? 'Profile Updated!' : 'Profile Saved!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : 'Error saving company profile: $e';
      notifyListeners();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> toggleStatus(CompanyProfile profile) async {
    _errorMessage = null;
    _successMessage = null;
    try {
      final newStatus = profile.isActive ? 'Inactive' : 'Active';
      final updated = CompanyProfile(
        id: profile.id,
        name: profile.name,
        gstin: profile.gstin,
        address: profile.address,
        city: profile.city,
        district: profile.district,
        state: profile.state,
        pincode: profile.pincode,
        addresses: profile.addresses,
        status: newStatus,
      );
      await _adminRepository.saveCompanyProfile(updated);
      _profiles = await _adminRepository.fetchCompanyProfiles();
      _successMessage = '${profile.name} marked $newStatus.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e is ApiException
          ? e.message
          : 'Error updating status: $e';
      notifyListeners();
      return false;
    }
  }

  void selectProfileForSeries(CompanyProfile? profile) {
    _selectedProfileId = profile?.id;
    _seriesPrefix = '';
    _seriesName = '';
    _seriesDocType = 'INV';
    _seriesLastNumber = '0';
    _seriesErrorMessage = null;
    notifyListeners();
  }

  void setSeriesPrefix(String value) {
    _seriesPrefix = value.toUpperCase();
  }

  void setSeriesName(String value) {
    _seriesName = value;
  }

  void setSeriesDocType(String value) {
    _seriesDocType = value;
    notifyListeners();
  }

  void setSeriesLastNumber(String value) {
    _seriesLastNumber = value;
  }

  Future<bool> saveBillingSeries() async {
    final profileId = _selectedProfileId;
    if (profileId == null) return false;
    if (_seriesPrefix.trim().isEmpty || _seriesName.trim().isEmpty) {
      _seriesErrorMessage = 'Prefix and Series Name are required.';
      notifyListeners();
      return false;
    }

    _isSavingSeries = true;
    _seriesErrorMessage = null;
    notifyListeners();

    try {
      final series = BillingSeries(
        id: 0,
        companyProfileId: profileId,
        prefix: _seriesPrefix.trim().toUpperCase(),
        name: _seriesName.trim(),
        docType: _seriesDocType,
        lastNumber: int.tryParse(_seriesLastNumber.trim()) ?? 0,
        status: 'Active',
      );
      await _adminRepository.saveBillingSeries(series);
      _profiles = await _adminRepository.fetchCompanyProfiles();
      _seriesPrefix = '';
      _seriesName = '';
      _seriesDocType = 'INV';
      _seriesLastNumber = '0';
      notifyListeners();
      return true;
    } catch (e) {
      _seriesErrorMessage = e is ApiException
          ? e.message
          : 'Error saving billing series: $e';
      notifyListeners();
      return false;
    } finally {
      _isSavingSeries = false;
      notifyListeners();
    }
  }

  Future<bool> deleteBillingSeries(int seriesId) async {
    _isSavingSeries = true;
    _seriesErrorMessage = null;
    notifyListeners();

    try {
      await _adminRepository.deleteBillingSeries(seriesId);
      _profiles = await _adminRepository.fetchCompanyProfiles();
      notifyListeners();
      return true;
    } catch (e) {
      _seriesErrorMessage = e is ApiException
          ? e.message
          : 'Error deleting billing series: $e';
      notifyListeners();
      return false;
    } finally {
      _isSavingSeries = false;
      notifyListeners();
    }
  }

  void dismissMessages() {
    _errorMessage = null;
    _successMessage = null;
    _seriesErrorMessage = null;
    notifyListeners();
  }

  void reset() {
    _profiles = [];
    _credentials = null;
    _initialized = false;
    _isLoading = false;
    _isSaving = false;
    _isSearchingGstin = false;
    _isSavingSeries = false;
    _errorMessage = null;
    _successMessage = null;
    _seriesErrorMessage = null;
    _selectedProfileId = null;
    clearForm();
  }
}

