import 'customer.dart';
import 'json_helpers.dart';

class BillingSeries {
  const BillingSeries({
    required this.id,
    required this.companyProfileId,
    required this.prefix,
    required this.name,
    required this.docType,
    required this.lastNumber,
    required this.status,
  });

  final int id;
  final int companyProfileId;
  final String prefix;
  final String name;
  final String docType; // 'INV' | 'EST' | 'PRO'
  final int lastNumber;
  final String status;

  String get formattedNextNumber => (lastNumber + 1).toString().padLeft(4, '0');

  factory BillingSeries.fromJson(Map<String, dynamic> json) {
    return BillingSeries(
      id: parseInt(json['id']),
      companyProfileId: parseInt(json['companyProfileId']),
      prefix: (json['prefix'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
      docType: (json['docType'] ?? 'INV').toString().trim(),
      lastNumber: parseInt(json['lastNumber']),
      status: parseOptionalString(json['status']) ?? 'Active',
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'id': id,
      'companyProfileId': companyProfileId,
      'prefix': prefix.trim().toUpperCase(),
      'name': name.trim(),
      'docType': docType,
      'lastNumber': lastNumber,
      'status': status,
    };
  }
}

class CompanyProfile {
  const CompanyProfile({
    required this.id,
    required this.name,
    required this.gstin,
    this.address,
    this.city,
    this.district,
    required this.state,
    this.pincode,
    this.addresses = const [],
    required this.status,
    this.billingSeries = const [],
  });

  final int id;
  final String name;
  final String gstin;
  final String? address;
  final String? city;
  final String? district;
  final String state;
  final String? pincode;
  final List<PartyAddress> addresses;
  final String status;
  final List<BillingSeries> billingSeries;

  bool get isActive => status.toLowerCase() != 'inactive';

  String get fullDispatchAddress {
    final parts = [
      address ?? '',
      city ?? '',
      district ?? '',
      state,
      pincode ?? '',
    ].where((s) => s.trim().isNotEmpty).toList();
    if (parts.isEmpty) return state;
    if ((pincode ?? '').trim().isNotEmpty && parts.length >= 2) {
      final withoutPin = parts.sublist(0, parts.length - 1).join(', ');
      return '$withoutPin - ${pincode!.trim()}';
    }
    return parts.join(', ');
  }

  List<BillingSeries> seriesForDocType(String docType) =>
      billingSeries.where((s) => s.docType == docType).toList();

  factory CompanyProfile.fromJson(Map<String, dynamic> json) {
    final rawAddrs = json['addresses'];
    final addrs = rawAddrs is List
        ? rawAddrs
              .whereType<Map<String, dynamic>>()
              .map(PartyAddress.fromJson)
              .toList()
        : const <PartyAddress>[];

    final rawSeries = json['billingSeries'];
    final series = rawSeries is List
        ? rawSeries
              .whereType<Map<String, dynamic>>()
              .map(BillingSeries.fromJson)
              .toList()
        : const <BillingSeries>[];

    return CompanyProfile(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      gstin: (json['gstin'] ?? '').toString().trim(),
      address: parseOptionalString(json['address']),
      city: parseOptionalString(json['city']),
      district: parseOptionalString(json['district']),
      state: parseOptionalString(json['state']) ?? 'Tamil Nadu',
      pincode: parseOptionalString(json['pincode']),
      addresses: addrs,
      status: parseOptionalString(json['status']) ?? 'Active',
      billingSeries: series,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'id': id,
      'name': name.trim(),
      'gstin': gstin.trim().toUpperCase(),
      'address': parseOptionalString(address),
      'city': parseOptionalString(city),
      'district': parseOptionalString(district),
      'state': state.trim(),
      'pincode': parseOptionalString(pincode),
      'status': status,
      'addresses': addresses.map((a) => a.toJson()).toList(),
    };
  }
}

class SystemCredentials {
  const SystemCredentials({
    this.whitebooksUsername,
    this.whitebooksPassword,
    this.whitebooksGstin,
    this.whitebooksClientId,
    this.whitebooksEmail,
  });

  final String? whitebooksUsername;
  final String? whitebooksPassword;
  final String? whitebooksGstin;
  final String? whitebooksClientId;
  final String? whitebooksEmail;

  factory SystemCredentials.fromJson(Map<String, dynamic> json) {
    return SystemCredentials(
      whitebooksUsername: parseOptionalString(json['WHITEBOOKS_USERNAME']),
      whitebooksPassword: parseOptionalString(json['WHITEBOOKS_PASSWORD']),
      whitebooksGstin: parseOptionalString(json['WHITEBOOKS_GSTIN']),
      whitebooksClientId: parseOptionalString(json['WHITEBOOKS_CLIENT_ID']),
      whitebooksEmail: parseOptionalString(json['WHITEBOOKS_EMAIL']),
    );
  }
}

