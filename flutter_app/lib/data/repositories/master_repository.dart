import 'package:flutter/foundation.dart';

import '../../domain/models/billing.dart';
import '../../domain/models/customer.dart';
import '../../domain/models/godown.dart';
import '../../domain/models/product.dart';
import '../../domain/models/supplier.dart';
import '../../domain/models/transporter.dart';
import '../../domain/models/vehicle.dart';
import '../services/api_client.dart';

List<Product> _parseProducts(List<dynamic> rawList) {
  return rawList
      .whereType<Map<String, dynamic>>()
      .map(Product.fromJson)
      .toList();
}

List<Customer> _parseCustomers(List<dynamic> rawList) {
  final list = rawList
      .whereType<Map<String, dynamic>>()
      .map(Customer.fromJson)
      .toList();
  list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

List<Supplier> _parseSuppliers(List<dynamic> rawList) {
  final list = rawList
      .whereType<Map<String, dynamic>>()
      .map(Supplier.fromJson)
      .toList();
  list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

List<Transporter> _parseTransporters(List<dynamic> rawList) {
  final list = rawList
      .whereType<Map<String, dynamic>>()
      .map(Transporter.fromJson)
      .toList();
  list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

List<Vehicle> _parseVehicles(List<dynamic> rawList) {
  final list = rawList
      .whereType<Map<String, dynamic>>()
      .map(Vehicle.fromJson)
      .toList();
  list.sort((a, b) => a.no.toLowerCase().compareTo(b.no.toLowerCase()));
  return list;
}

List<Godown> _parseGodowns(List<dynamic> rawList) {
  final list = rawList
      .whereType<Map<String, dynamic>>()
      .map(Godown.fromJson)
      .toList();
  list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return list;
}

class MasterRepository {
  MasterRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Product>> fetchProducts() async {
    final raw = await _apiClient.getProducts();
    if (raw.length < 80) return _parseProducts(raw);
    return compute(_parseProducts, raw);
  }

  Future<String> fetchNextProductCode({String type = 'INV'}) {
    return _apiClient.getNextProductCode(type: type);
  }

  Future<Product> saveProduct(Product product) async {
    final raw = await _apiClient.saveProduct(product.toPayload());
    return Product.fromJson(raw);
  }

  Future<List<Customer>> fetchCustomers() async {
    final raw = await _apiClient.getCustomers();
    if (raw.length < 80) return _parseCustomers(raw);
    return compute(_parseCustomers, raw);
  }

  Future<Customer> saveCustomer(Customer customer) async {
    final raw = await _apiClient.saveCustomer(customer.toPayload());
    return Customer.fromJson(raw);
  }

  Future<List<CustomerPrice>> fetchCustomerPrices(int customerId) async {
    final raw = await _apiClient.getCustomerPrices(customerId);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(CustomerPrice.fromJson)
        .toList();
  }

  Future<Map<String, dynamic>> saveCustomerPrices(
    int customerId,
    List<Map<String, dynamic>> prices,
  ) {
    return _apiClient.saveCustomerPrices(customerId, prices);
  }

  Future<List<Supplier>> fetchSuppliers() async {
    final raw = await _apiClient.getSuppliers();
    if (raw.length < 80) return _parseSuppliers(raw);
    return compute(_parseSuppliers, raw);
  }

  Future<Supplier> saveSupplier(Supplier supplier) async {
    final raw = await _apiClient.saveSupplier(supplier.toPayload());
    return Supplier.fromJson(raw);
  }

  Future<List<Transporter>> fetchTransporters() async {
    final raw = await _apiClient.getTransporters();
    if (raw.length < 80) return _parseTransporters(raw);
    return compute(_parseTransporters, raw);
  }

  Future<Transporter> saveTransporter(Transporter transporter) async {
    final raw = await _apiClient.saveTransporter(transporter.toPayload());
    return Transporter.fromJson(raw);
  }

  Future<List<Vehicle>> fetchVehicles() async {
    final raw = await _apiClient.getVehicles();
    if (raw.length < 80) return _parseVehicles(raw);
    return compute(_parseVehicles, raw);
  }

  Future<Vehicle> saveVehicle(Vehicle vehicle) async {
    final raw = await _apiClient.saveVehicle(vehicle.toPayload());
    return Vehicle.fromJson(raw);
  }

  Future<List<Godown>> fetchGodowns() async {
    final raw = await _apiClient.getGodowns();
    if (raw.length < 80) return _parseGodowns(raw);
    return compute(_parseGodowns, raw);
  }

  Future<Godown> saveGodown(Godown godown) async {
    final raw = await _apiClient.saveGodown(godown.toPayload());
    return Godown.fromJson(raw);
  }

  Future<GstinDetails> verifyGstin(String gstin) async {
    final raw = await _apiClient.verifyGstin(gstin);
    return GstinDetails.fromJson(raw);
  }

  Future<PincodeLocation?> lookupPincode(String pincode) async {
    final raw = await _apiClient.lookupPincode(pincode);
    if (raw == null) return null;
    return PincodeLocation(
      city: (raw['city'] ?? '').toString(),
      district: (raw['district'] ?? '').toString(),
      state: (raw['state'] ?? '').toString(),
    );
  }
}

