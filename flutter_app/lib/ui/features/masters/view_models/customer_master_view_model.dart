import 'package:flutter/foundation.dart';

import 'package:crackers_erp/core/constants/indian_states.dart';
import 'package:crackers_erp/data/repositories/admin_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/data/repositories/sales_order_repository.dart';
import 'package:crackers_erp/data/models/api_exceptions.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/domain/models/erp_user.dart';
import 'package:crackers_erp/domain/models/sales_order.dart';

class CustomerMasterViewModel extends ChangeNotifier {
  CustomerMasterViewModel({
    required MasterRepository masterRepository,
    required AdminRepository adminRepository,
    required SalesOrderRepository salesOrderRepository,
  }) : _masterRepo = masterRepository,
       _adminRepo = adminRepository,
       _salesOrderRepo = salesOrderRepository;

  final MasterRepository _masterRepo;
  final AdminRepository _adminRepo;
  final SalesOrderRepository _salesOrderRepo;

  List<Customer> _customers = const [];
  List<ErpUser> _reps = const [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isLookingUpGstin = false;
  bool _isLookingUpPincode = false;
  String? _errorMessage;
  String? _successMessage;
  String _searchQuery = '';

  // Form state
  int? _editingId;
  bool _isUnregistered = false;
  String _gstin = '';
  String _name = '';
  String _mobile = '';
  String _reference = '';
  String _address = '';
  String _state = '';
  String _pincode = '';
  String _city = '';
  String _district = '';
  String _idNumber = '';
  String _status = 'Active';
  List<PartyAddress> _addresses = const [];
  int? _repId;

  // Lead verification state
  int? _pendingOrderId;
  bool _isLeadVerificationMode = false;

  List<Customer> get customers => _customers;
  List<ErpUser> get reps => _reps;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isLookingUpGstin => _isLookingUpGstin;
  bool get isLookingUpPincode => _isLookingUpPincode;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get searchQuery => _searchQuery;

  int? get editingId => _editingId;
  bool get isUnregistered => _isUnregistered;
  String get gstin => _gstin;
  String get name => _name;
  String get mobile => _mobile;
  String get reference => _reference;
  String get address => _address;
  String get state => _state;
  String get pincode => _pincode;
  String get city => _city;
  String get district => _district;
  String get idNumber => _idNumber;
  String get status => _status;
  List<PartyAddress> get addresses => _addresses;
  int? get repId => _repId;
  int? get pendingOrderId => _pendingOrderId;
  bool get isLeadVerificationMode => _isLeadVerificationMode;

  List<Customer> get filteredCustomers {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _customers;
    return _customers.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.mobile ?? '').toLowerCase().contains(q) ||
          (c.city ?? '').toLowerCase().contains(q) ||
          (c.district ?? '').toLowerCase().contains(q) ||
          (c.gstin ?? '').toLowerCase().contains(q);
    }).toList();
  }

  String repNameFor(Customer c) {
    if (c.repUsername != null && c.repUsername!.isNotEmpty) {
      return c.repUsername!;
    }
    if (c.repId != null) {
      for (final r in _reps) {
        if (r.id == c.repId) return r.username;
      }
    }
    return '-';
  }

  Future<void> initialize({VerifyCustomerLeadArgs? leadArgs}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _masterRepo.fetchCustomers(),
        _adminRepo.fetchReps().catchError((_) => const <ErpUser>[]),
      ]);
      _customers = results[0] as List<Customer>;
      _reps = results[1] as List<ErpUser>;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    if (leadArgs != null) {
      await beginLeadVerification(leadArgs);
    }
  }

  Future<void> beginLeadVerification(VerifyCustomerLeadArgs args) async {
    clearForm(keepLeadState: false);
    final lead = args.leadData;
    final hasGst =
        lead.gstin.trim().isNotEmpty || lead.type.toUpperCase() == 'GST';
    final cleanGstin = hasGst ? lead.gstin.trim().toUpperCase() : 'URP';

    _isLeadVerificationMode = true;
    _pendingOrderId = args.orderId;
    _isUnregistered = !hasGst;
    _gstin = cleanGstin;
    _name = lead.name.trim();
    _city = lead.city.trim();
    _mobile = lead.mobile.trim();
    _pincode = lead.pincode.trim();
    _idNumber = lead.idNumber.trim();
    _successMessage =
        'LEAD VERIFICATION MODE: Please verify all details and save to approve Order #${args.orderId}.';
    notifyListeners();

    if (!_isUnregistered && cleanGstin.length == 15) {
      await verifyGstin(cleanGstin);
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setRegistrationType(bool unregistered) {
    _isUnregistered = unregistered;
    _gstin = unregistered ? 'URP' : (_gstin == 'URP' ? '' : _gstin);
    notifyListeners();
  }

  void updateField({
    String? gstin,
    String? name,
    String? mobile,
    String? reference,
    String? address,
    String? state,
    String? pincode,
    String? city,
    String? district,
    String? idNumber,
    int? repId,
    bool clearRep = false,
  }) {
    if (gstin != null) _gstin = gstin.toUpperCase();
    if (name != null) _name = name;
    if (mobile != null) _mobile = mobile;
    if (reference != null) _reference = reference;
    if (address != null) _address = address;
    if (state != null) _state = state;
    if (pincode != null) _pincode = pincode;
    if (city != null) _city = city;
    if (district != null) _district = district;
    if (idNumber != null) _idNumber = idNumber;
    if (clearRep) {
      _repId = null;
    } else if (repId != null) {
      _repId = repId;
    }
    notifyListeners();

    if (gstin != null &&
        !_isUnregistered &&
        _gstin.trim().length == 15) {
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
      if (details.preferredName.isNotEmpty) {
        _name = details.preferredName;
      }
      if (details.address.trim().isNotEmpty) {
        _address = details.address.trim();
      }
      if (details.city.trim().isNotEmpty) {
        _city = details.city.trim();
      }
      if (details.district.trim().isNotEmpty) {
        _district = details.district.trim();
      }
      if (details.state.trim().isNotEmpty) {
        _state = normalizeIndianState(details.state, fallback: '');
      }
      if (details.pincode.trim().isNotEmpty) {
        _pincode = details.pincode.trim();
      }
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
      // Non-fatal pincode lookup error
    } finally {
      _isLookingUpPincode = false;
      notifyListeners();
    }
  }

  void editCustomer(Customer customer) {
    _editingId = customer.id;
    _isUnregistered =
        (customer.gstin ?? '').trim().toUpperCase() == 'URP';
    _gstin = customer.gstin ?? '';
    _name = customer.name;
    _mobile = customer.mobile ?? '';
    _reference = customer.reference ?? '';
    _address = customer.address ?? '';
    _state = normalizeIndianState(customer.state, fallback: '');
    _pincode = customer.pincode ?? '';
    _city = customer.city ?? '';
    _district = customer.district ?? '';
    _idNumber = customer.idNumber ?? '';
    _status = customer.status;
    _addresses = customer.addresses;
    _repId = customer.repId;
    _isLeadVerificationMode = false;
    _pendingOrderId = null;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void clearForm({bool keepLeadState = false}) {
    _editingId = null;
    _isUnregistered = false;
    _gstin = '';
    _name = '';
    _mobile = '';
    _reference = '';
    _address = '';
    _state = '';
    _pincode = '';
    _city = '';
    _district = '';
    _idNumber = '';
    _status = 'Active';
    _addresses = const [];
    _repId = null;
    _errorMessage = null;
    _successMessage = null;
    if (!keepLeadState) {
      _isLeadVerificationMode = false;
      _pendingOrderId = null;
    }
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<bool> saveCustomer() async {
    if (_name.trim().isEmpty) {
      _errorMessage = 'Customer Name is required.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final finalGstin = _isUnregistered ? 'URP' : _gstin.trim().toUpperCase();
      final payload = Customer(
        id: _editingId ?? 0,
        name: _name.trim(),
        mobile: _mobile.trim(),
        reference: _reference.trim(),
        address: _address.trim(),
        city: _city.trim(),
        district: _district.trim(),
        state: _state.trim(),
        pincode: _pincode.trim(),
        idNumber: _idNumber.trim(),
        gstin: finalGstin,
        status: _status,
        addresses: _addresses,
        repId: _repId,
      );

      final saved = await _masterRepo.saveCustomer(payload);

      if (_isLeadVerificationMode &&
          _pendingOrderId != null &&
          saved.id > 0) {
        await _salesOrderRepo.linkCustomerToOrder(_pendingOrderId!, saved.id);
        final orderId = _pendingOrderId!;
        clearForm();
        _customers = await _masterRepo.fetchCustomers();
        _successMessage =
            'Customer "${saved.name}" linked to Order #$orderId!';
        _isSaving = false;
        notifyListeners();
        return true;
      }

      clearForm();
      _customers = await _masterRepo.fetchCustomers();
      _successMessage = 'Customer "${saved.name}" saved successfully!';
      return true;
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> toggleStatus(Customer customer) async {
    final nextStatus = customer.isActive ? 'Inactive' : 'Active';
    _errorMessage = null;
    try {
      final updated = Customer(
        id: customer.id,
        name: customer.name,
        mobile: customer.mobile,
        reference: customer.reference,
        address: customer.address,
        city: customer.city,
        district: customer.district,
        state: customer.state,
        pincode: customer.pincode,
        idNumber: customer.idNumber,
        gstin: customer.gstin,
        status: nextStatus,
        addresses: customer.addresses,
        repId: customer.repId,
      );
      await _masterRepo.saveCustomer(updated);
      _customers = await _masterRepo.fetchCustomers();
      _successMessage = '${customer.name} marked as $nextStatus!';
    } catch (e) {
      _errorMessage = e is ApiException ? e.message : e.toString();
    }
    notifyListeners();
  }

  void reset() {
    _customers = const [];
    _reps = const [];
    _searchQuery = '';
    clearForm();
  }
}
