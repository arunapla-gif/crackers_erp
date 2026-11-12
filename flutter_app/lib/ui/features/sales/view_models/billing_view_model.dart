import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:crackers_erp/data/repositories/admin_repository.dart';
import 'package:crackers_erp/data/repositories/billing_repository.dart';
import 'package:crackers_erp/data/repositories/master_repository.dart';
import 'package:crackers_erp/domain/models/billing.dart';
import 'package:crackers_erp/domain/models/company_profile.dart';
import 'package:crackers_erp/domain/models/customer.dart';
import 'package:crackers_erp/domain/models/json_helpers.dart';
import 'package:crackers_erp/domain/models/product.dart';
import 'package:crackers_erp/domain/models/sales_order.dart';
import 'package:crackers_erp/domain/models/transporter.dart';
import 'package:crackers_erp/domain/models/vehicle.dart';

class BillingViewModel extends ChangeNotifier {
  BillingViewModel({
    required BillingRepository billingRepository,
    required MasterRepository masterRepository,
    required AdminRepository adminRepository,
  }) : _billingRepo = billingRepository,
       _masterRepo = masterRepository,
       _adminRepo = adminRepository {
    _loadDraftFromStorage();
    _recalculate();
  }

  final BillingRepository _billingRepo;
  final MasterRepository _masterRepo;
  final AdminRepository _adminRepo;

  String _docType = 'INV'; // 'INV' | 'EST' | 'PRO'
  BillingHeader _header = BillingHeader(
    date: toIsoCalendarDate(DateTime.now()),
    series: '',
    number: '',
  );
  List<BillingRow> _rows = [const BillingRow(id: 1, product: '')];
  List<AdditionalChargeRow> _chargeRows = [const AdditionalChargeRow(id: 1)];
  String _originState = 'Tamil Nadu';
  String _billState = 'Tamil Nadu';
  BillingTotals _totals = const BillingTotals();

  List<Product> _products = const [];
  List<Customer> _customers = const [];
  List<Transporter> _transporters = const [];
  List<Vehicle> _vehicles = const [];
  List<CompanyProfile> _profiles = const [];
  Map<int, double> _customRates = const {};

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isGeneratingEway = false;
  bool _isGatewayOpen = false;
  bool _initializedMasters = false;
  String? _errorMessage;
  String? _successMessage;

  String get docType => _docType;
  BillingHeader get header => _header;
  List<BillingRow> get rows => List.unmodifiable(_rows);
  List<AdditionalChargeRow> get chargeRows => List.unmodifiable(_chargeRows);
  String get originState => _originState;
  String get billState => _billState;
  BillingTotals get totals => _totals;
  List<Product> get products => List.unmodifiable(_products);
  List<Customer> get customers => List.unmodifiable(_customers);
  List<Transporter> get transporters => List.unmodifiable(_transporters);
  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  List<CompanyProfile> get profiles => List.unmodifiable(_profiles);
  Map<int, double> get customRates => Map.unmodifiable(_customRates);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isGeneratingEway => _isGeneratingEway;
  bool get isGatewayOpen => _isGatewayOpen;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  CompanyProfile? get selectedProfile {
    if (_header.companyProfileId == null) return null;
    for (final p in _profiles) {
      if (p.id == _header.companyProfileId) return p;
    }
    return null;
  }

  List<BillingSeries> get availableSeries {
    final prof = selectedProfile;
    if (prof == null) return const [];
    return prof.seriesForDocType(_docType);
  }

  Customer? get selectedCustomer {
    final name = _header.customer.trim();
    if (name.isEmpty) return null;
    for (final c in _customers) {
      if (c.name == name) return c;
    }
    return null;
  }

  int _nextLocalId() => DateTime.now().microsecondsSinceEpoch;

  void _loadDraftFromStorage() {
    final savedCart = _billingRepo.loadDraftCart();
    if (savedCart != null) {
      final type = (savedCart['currentType'] ?? 'INV').toString().toUpperCase();
      if (type == 'INV' || type == 'EST' || type == 'PRO') {
        _docType = type;
      }
      _originState =
          parseOptionalString(savedCart['originState']) ?? 'Tamil Nadu';
      _billState = parseOptionalString(savedCart['billState']) ?? 'Tamil Nadu';
      final rawRows = savedCart['rows'];
      if (rawRows is List && rawRows.isNotEmpty) {
        final parsed = rawRows
            .whereType<Map<String, dynamic>>()
            .map(BillingRow.fromJson)
            .toList();
        if (parsed.isNotEmpty) _rows = parsed;
      }
      final rawCharges = savedCart['chargeRows'];
      if (rawCharges is List && rawCharges.isNotEmpty) {
        final parsed = rawCharges
            .whereType<Map<String, dynamic>>()
            .map(AdditionalChargeRow.fromJson)
            .toList();
        if (parsed.isNotEmpty) _chargeRows = parsed;
      }
    }

    final savedHeader = _billingRepo.loadDraftHeader();
    if (savedHeader != null) {
      _header = savedHeader;
    }
  }

  Future<void> _persistDraft() async {
    await _billingRepo.saveDraftCart({
      'currentType': _docType,
      'originState': _originState,
      'billState': _billState,
      'rows': _rows.map((r) => r.toJson()).toList(),
      'chargeRows': _chargeRows.map((c) => c.toJson()).toList(),
    });
    await _billingRepo.saveDraftHeader(_header);
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_initializedMasters && !forceRefresh) {
      _checkGatewayTrigger();
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _masterRepo.fetchProducts(),
        _masterRepo.fetchCustomers(),
        _masterRepo.fetchTransporters(),
        _masterRepo.fetchVehicles(),
        _adminRepo.fetchCompanyProfiles(),
      ]);
      _products = (results[0] as List<Product>)
          .where((p) => p.isActive)
          .toList();
      _customers = (results[1] as List<Customer>)
          .where((c) => c.isActive)
          .toList();
      _transporters = results[2] as List<Transporter>;
      _vehicles = results[3] as List<Vehicle>;
      _profiles = (results[4] as List<CompanyProfile>)
          .where((p) => p.isActive)
          .toList();
      _initializedMasters = true;

      _checkGatewayTrigger();
      if (_header.customer.isNotEmpty) {
        await _loadCustomRatesForCustomerName(_header.customer);
      }
      _persistDraft().ignore();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _checkGatewayTrigger() {
    if (_profiles.isNotEmpty &&
        _header.companyProfileId == null &&
        !_isGatewayOpen) {
      if (_profiles.length == 1 || _docType == 'PRO') {
        selectGatewayProfile(_profiles.first);
      } else {
        _isGatewayOpen = true;
      }
    }
  }

  String _nextNumberForSeries(CompanyProfile? profile, String seriesPrefix) {
    if (profile == null || seriesPrefix.isEmpty) return '';
    for (final s in profile.billingSeries) {
      if (s.prefix == seriesPrefix) {
        return s.formattedNextNumber;
      }
    }
    return '';
  }

  void setDocType(String type) {
    final normalized = type.toUpperCase();
    if (normalized != 'INV' && normalized != 'EST' && normalized != 'PRO') {
      return;
    }
    if (_docType == normalized) return;
    _docType = normalized;
    final prof = selectedProfile;
    if (prof != null) {
      final seriesList = prof.seriesForDocType(_docType);
      final defaultSeries = seriesList.isNotEmpty ? seriesList.first.prefix : '';
      final nextNo = _nextNumberForSeries(prof, defaultSeries);
      _header = _header.copyWith(series: defaultSeries, number: nextNo);
    }
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  void openGateway() {
    _isGatewayOpen = true;
    notifyListeners();
  }

  void closeGateway() {
    _isGatewayOpen = false;
    notifyListeners();
  }

  void selectGatewayProfile(CompanyProfile? profile) {
    if (profile == null) {
      _header = _header.copyWith(
        clearCompanyProfile: true,
        companyProfileName: '',
        dispatchAddress: '',
        series: '',
        number: '',
      );
      _isGatewayOpen = false;
      _persistDraft();
      notifyListeners();
      return;
    }
    final seriesList = profile.seriesForDocType(_docType);
    final defaultSeries = seriesList.isNotEmpty ? seriesList.first.prefix : '';
    final nextNo = _nextNumberForSeries(profile, defaultSeries);
    _originState = profile.state.trim().isNotEmpty ? profile.state : 'Tamil Nadu';
    _header = _header.copyWith(
      companyProfileId: profile.id,
      companyProfileName: '${profile.name} - ${profile.gstin}',
      dispatchAddress: profile.fullDispatchAddress,
      series: defaultSeries,
      number: nextNo,
    );
    _isGatewayOpen = false;
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  Future<void> selectCustomer(Customer? customer) async {
    if (customer == null) {
      _header = _header.copyWith(customer: '', customerAddress: '');
      _customRates = const {};
      _applyProductRates();
      await _persistDraft();
      notifyListeners();
      return;
    }

    _header = _header.copyWith(
      customer: customer.name,
      customerAddress: customer.primaryAddressText,
    );
    if ((customer.state ?? '').trim().isNotEmpty) {
      _billState = customer.state!.trim();
    }
    _recalculate();
    notifyListeners();
    await _loadCustomRatesForCustomerId(customer.id);
    await _persistDraft();
  }

  Future<void> _loadCustomRatesForCustomerName(String name) async {
    for (final c in _customers) {
      if (c.name == name) {
        await _loadCustomRatesForCustomerId(c.id);
        return;
      }
    }
  }

  Future<void> _loadCustomRatesForCustomerId(int customerId) async {
    try {
      final prices = await _masterRepo.fetchCustomerPrices(customerId);
      final map = <int, double>{};
      for (final p in prices) {
        map[p.productId] = p.rate;
      }
      _customRates = map;
      _applyProductRates();
      notifyListeners();
    } catch (_) {
      // Non-fatal fallback to standard rates
    }
  }

  void _applyProductRates() {
    if (_products.isEmpty) return;
    var changed = false;
    final nextRows = <BillingRow>[];
    for (final row in _rows) {
      if (row.productId == null) {
        nextRows.add(row);
        continue;
      }
      Product? match;
      for (final p in _products) {
        if (p.id == row.productId) {
          match = p;
          break;
        }
      }
      if (match == null) {
        nextRows.add(row);
        continue;
      }
      final rate = _customRates[match.id] ?? match.rate;
      final amount = double.parse((row.qty * rate).toStringAsFixed(2));
      if (row.rate != rate || row.amount != amount) {
        changed = true;
        nextRows.add(row.copyWith(rate: rate, amount: amount));
      } else {
        nextRows.add(row);
      }
    }
    if (changed) {
      _rows = nextRows;
      _recalculate();
    }
  }

  void setBillState(String state) {
    _billState = state;
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  void setOriginState(String state) {
    _originState = state;
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  void updateHeader({
    String? date,
    String? series,
    String? number,
    String? customerAddress,
    String? vehicleNo,
    String? distance,
    String? transporterId,
    String? ewayBillNo,
    String? dispatchAddress,
  }) {
    String? nextNumber = number;
    if (series != null && series != _header.series) {
      nextNumber = _nextNumberForSeries(selectedProfile, series);
    }
    _header = _header.copyWith(
      date: date,
      series: series,
      number: nextNumber,
      customerAddress: customerAddress,
      vehicleNo: vehicleNo,
      distance: distance,
      transporterId: transporterId,
      ewayBillNo: ewayBillNo,
      dispatchAddress: dispatchAddress,
    );
    _persistDraft();
    notifyListeners();
  }

  void addRow() {
    _rows = [..._rows, BillingRow(id: _nextLocalId(), product: '')];
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  void removeRow(int id) {
    final filtered = _rows.where((r) => r.id != id).toList();
    _rows = filtered.isEmpty
        ? [BillingRow(id: _nextLocalId(), product: '')]
        : filtered;
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  void selectProductForRow(int rowId, Product product) {
    final finalRate = _customRates[product.id] ?? product.rate;
    _rows = _rows.map((r) {
      if (r.id != rowId) return r;
      final amount = double.parse((r.qty * finalRate).toStringAsFixed(2));
      return r.copyWith(
        productId: product.id,
        product: product.name,
        hsn: product.hsn,
        tax: product.tax,
        rate: finalRate,
        amount: amount,
      );
    }).toList();
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  void updateRow(
    int rowId, {
    String? product,
    String? hsn,
    int? qty,
    double? rate,
    double? tax,
  }) {
    _rows = _rows.map((r) {
      if (r.id != rowId) return r;
      final nextQty = qty ?? r.qty;
      final nextRate = rate ?? r.rate;
      final nextAmount = double.parse((nextQty * nextRate).toStringAsFixed(2));
      return r.copyWith(
        product: product,
        hsn: hsn,
        qty: nextQty,
        rate: nextRate,
        tax: tax,
        amount: nextAmount,
      );
    }).toList();
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  void addChargeRow() {
    _chargeRows = [..._chargeRows, AdditionalChargeRow(id: _nextLocalId())];
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  void removeChargeRow(int id) {
    final filtered = _chargeRows.where((c) => c.id != id).toList();
    _chargeRows = filtered.isEmpty
        ? [AdditionalChargeRow(id: _nextLocalId())]
        : filtered;
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  void updateChargeRow(
    int rowId, {
    String? name,
    String? source,
    String? mode,
    String? type,
    double? value,
    String? series,
    String? number,
  }) {
    _chargeRows = _chargeRows.map((c) {
      if (c.id != rowId) return c;
      return c.copyWith(
        name: name,
        source: source,
        mode: mode,
        type: type,
        value: value,
        series: series,
        number: number,
      );
    }).toList();
    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  Future<void> fetchInvoiceTaxForChargeRow(int rowId) async {
    AdditionalChargeRow? target;
    for (final c in _chargeRows) {
      if (c.id == rowId) {
        target = c;
        break;
      }
    }
    if (target == null) return;
    final rawNum = target.number.trim();
    if (rawNum.isEmpty) {
      _errorMessage = 'Enter invoice number first.';
      notifyListeners();
      return;
    }
    final lookupNo = (target.series.isNotEmpty &&
            RegExp(r'^\d+$').hasMatch(rawNum))
        ? '${target.series}$rawNum'
        : rawNum;

    _errorMessage = null;
    try {
      InvoiceRecord record;
      try {
        record = await _billingRepo.fetchInvoice(rawNum);
      } catch (_) {
        if (lookupNo == rawNum) rethrow;
        record = await _billingRepo.fetchInvoice(lookupNo);
      }
      updateChargeRow(
        rowId,
        name: 'Invoice Tax ${record.number}',
        source: 'INVOICE_TAX',
        mode: 'ADD',
        type: 'AMOUNT',
        value: record.tax,
      );
    } catch (_) {
      _errorMessage = 'Invoice tax record "$rawNum" not found. Save the invoice first.';
      notifyListeners();
    }
  }

  void _recalculate() {
    var subtotal = 0.0;
    var tax = 0.0;
    for (final row in _rows) {
      subtotal += row.amount;
      if (_docType == 'INV') {
        tax += row.amount * (row.tax / 100);
      }
    }

    var totalCharges = 0.0;
    if (_docType != 'INV') {
      final updatedCharges = <AdditionalChargeRow>[];
      for (final c in _chargeRows) {
        var amt = 0.0;
        if (c.name.trim().isNotEmpty || c.value != 0) {
          amt = c.type == 'PERCENT' ? (subtotal * c.value / 100) : c.value;
          if (c.mode == 'DEDUCT') amt = -amt;
        }
        final roundedAmt = double.parse(amt.toStringAsFixed(2));
        totalCharges += roundedAmt;
        updatedCharges.add(c.copyWith(amount: roundedAmt));
      }
      _chargeRows = updatedCharges;
    }

    final isIntraState =
        _originState.trim().toLowerCase() == _billState.trim().toLowerCase();
    final roundedSub = double.parse(subtotal.toStringAsFixed(2));
    final roundedTax = double.parse(tax.toStringAsFixed(2));
    final roundedCharges = double.parse(totalCharges.toStringAsFixed(2));
    final halfTax = double.parse((tax / 2).toStringAsFixed(2));

    _totals = BillingTotals(
      subtotal: roundedSub,
      tax: roundedTax,
      cgst: (_docType == 'INV' && isIntraState) ? halfTax : 0,
      sgst: (_docType == 'INV' && isIntraState) ? halfTax : 0,
      igst: (_docType == 'INV' && !isIntraState) ? roundedTax : 0,
      charges: roundedCharges,
      grandTotal: double.parse(
        (subtotal + tax + totalCharges).toStringAsFixed(2),
      ),
    );
  }

  Future<String?> saveDocument() async {
    final docNo = _header.number.trim();
    if (docNo.isEmpty) {
      _errorMessage = 'Document number is required.';
      notifyListeners();
      return null;
    }

    final validRows = _rows
        .where((r) => r.product.trim().isNotEmpty && r.qty > 0)
        .toList();
    if (validRows.isEmpty) {
      _errorMessage = 'Add at least one item with quantity greater than 0.';
      notifyListeners();
      return null;
    }

    final fullNumber = '${_header.series}$docNo';
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final payload = <String, dynamic>{
        'series': _header.series,
        'number': fullNumber,
        'date': _header.date,
        'customer': _header.customer,
        'customerAddress': _header.customerAddress,
        'vehicleNo': _header.vehicleNo,
        'distance': _header.distance,
        'transporterId': _header.transporterId,
        'ewayBillNo': _header.ewayBillNo,
        'companyProfileId': _header.companyProfileId,
        'dispatchAddress': _header.dispatchAddress,
        'state': _billState,
        'subtotal': _totals.subtotal,
        'cgst': _totals.cgst,
        'sgst': _totals.sgst,
        'igst': _totals.igst,
        'tax': _totals.tax,
        'grand_total': _totals.grandTotal,
        'items': validRows
            .map(
              (r) => {
                'productId': r.productId,
                'product': r.product.trim(),
                'hsn': r.hsn,
                'qty': r.qty,
                'rate': r.rate,
                'tax': r.tax,
                'total': r.amount,
              },
            )
            .toList(),
        'charges': _docType != 'INV'
            ? _chargeRows
                .where((c) => c.name.trim().isNotEmpty || c.amount != 0)
                .map(
                  (c) => {
                    'name': c.name,
                    'source': c.source,
                    'mode': c.mode,
                    'type': c.type,
                    'value': c.value,
                    'amount': c.amount,
                  },
                )
                .toList()
            : <Map<String, dynamic>>[],
      };

      await _billingRepo.saveInvoice(payload);
      await _billingRepo.clearDraft();

      // Refresh profiles silently so billingSeries.lastNumber increments match server
      try {
        final refreshedProfiles = await _adminRepo.fetchCompanyProfiles();
        _profiles = refreshedProfiles.where((p) => p.isActive).toList();
      } catch (_) {}

      final nextFromProfile = _nextNumberForSeries(
        selectedProfile,
        _header.series,
      );
      final parsedCurrent = int.tryParse(docNo);
      final incrementedCurrent = parsedCurrent != null
          ? (parsedCurrent + 1).toString().padLeft(docNo.length, '0')
          : nextFromProfile;
      final nextFromProfInt = int.tryParse(nextFromProfile) ?? 0;
      final nextNo = (nextFromProfInt > (parsedCurrent ?? 0))
          ? nextFromProfile
          : incrementedCurrent;

      _rows = [BillingRow(id: _nextLocalId(), product: '')];
      _chargeRows = [AdditionalChargeRow(id: _nextLocalId())];
      _customRates = const {};
      _header = _header.copyWith(
        customer: '',
        customerAddress: '',
        vehicleNo: '',
        distance: '',
        transporterId: '',
        ewayBillNo: '',
        number: nextNo,
      );
      _recalculate();
      _successMessage = 'Document $fullNumber saved successfully!';
      return fullNumber;
    } catch (e) {
      _errorMessage = 'Error saving document: $e';
      return null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<bool> generateEwayBill(String mode) async {
    if (_header.number.trim().isEmpty) {
      _errorMessage = 'Enter a document number first.';
      notifyListeners();
      return false;
    }
    final savedNo = await saveDocument();
    if (savedNo == null) return false;

    _isGeneratingEway = true;
    _errorMessage = null;
    _successMessage =
        'Generating ${mode == 'PART_A' ? 'Part-A ' : 'Full '}E-Way Bill via Whitebooks...';
    notifyListeners();

    try {
      final result = await _billingRepo.generateEwayBill(savedNo, mode);
      final ewbNo = (result['ewayBillNo'] ?? '').toString().trim();
      if (ewbNo.isNotEmpty) {
        _header = _header.copyWith(ewayBillNo: ewbNo);
        _successMessage = 'Success! E-Way Bill Generated: $ewbNo';
      } else {
        _successMessage = 'E-Way Bill request processed.';
      }
      return true;
    } catch (e) {
      _errorMessage = 'E-Way Bill error: $e';
      _successMessage = null;
      return false;
    } finally {
      _isGeneratingEway = false;
      notifyListeners();
    }
  }

  Future<void> clearDraft() async {
    await _billingRepo.clearDraft();
    _rows = [BillingRow(id: _nextLocalId(), product: '')];
    _chargeRows = [AdditionalChargeRow(id: _nextLocalId())];
    _customRates = const {};
    _header = BillingHeader(
      date: toIsoCalendarDate(DateTime.now()),
      series: '',
      number: '',
    );
    _billState = 'Tamil Nadu';
    _recalculate();
    if (_profiles.length > 1 && _docType != 'PRO') {
      _isGatewayOpen = true;
    } else if (_profiles.isNotEmpty) {
      selectGatewayProfile(_profiles.first);
    }
    notifyListeners();
  }

  void loadSalesOrder(SalesOrder order) {
    _docType = 'PRO';
    final loadedRows = order.items.asMap().entries.map((entry) {
      final item = entry.value;
      return BillingRow(
        id: _nextLocalId() + entry.key,
        productId: item.productId,
        product: item.product,
        qty: item.qty,
        rate: item.rate,
        tax: 18,
        amount: item.total,
      );
    }).toList();
    _rows = loadedRows.isNotEmpty
        ? loadedRows
        : [BillingRow(id: _nextLocalId(), product: '')];

    final custName = order.displayCustomerName;
    String custAddress = '';
    String? custState;
    if (order.customer != null) {
      custAddress = order.customer!.primaryAddressText;
      custState = order.customer!.state;
    } else {
      for (final c in _customers) {
        if (c.name == custName) {
          custAddress = c.primaryAddressText;
          custState = c.state;
          break;
        }
      }
    }
    if (custState != null && custState.trim().isNotEmpty) {
      _billState = custState.trim();
    }
    _header = _header.copyWith(
      customer: custName,
      customerAddress: custAddress,
    );

    if (_header.companyProfileId == null && _profiles.isNotEmpty) {
      selectGatewayProfile(_profiles.first);
    } else if (selectedProfile != null) {
      final proSeries = selectedProfile!.seriesForDocType('PRO');
      if (proSeries.isNotEmpty) {
        _header = _header.copyWith(
          series: proSeries.first.prefix,
          number: proSeries.first.formattedNextNumber,
        );
      }
    }

    _recalculate();
    _persistDraft();
    notifyListeners();
  }

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  void reset() {
    _docType = 'INV';
    _header = BillingHeader(
      date: toIsoCalendarDate(DateTime.now()),
      series: '',
      number: '',
    );
    _rows = [const BillingRow(id: 1, product: '')];
    _chargeRows = [const AdditionalChargeRow(id: 1)];
    _originState = 'Tamil Nadu';
    _billState = 'Tamil Nadu';
    _customRates = const {};
    _isGatewayOpen = false;
    _initializedMasters = false;
    _errorMessage = null;
    _successMessage = null;
    _recalculate();
    notifyListeners();
  }
}
