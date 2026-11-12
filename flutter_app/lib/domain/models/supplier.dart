import 'customer.dart';
import 'json_helpers.dart';

class Supplier {
  const Supplier({
    required this.id,
    required this.name,
    this.mobile,
    required this.type,
    this.address,
    this.city,
    this.district,
    this.state,
    this.pincode,
    this.idNumber,
    this.gstin,
    required this.status,
    this.addresses = const [],
  });

  final int id;
  final String name;
  final String? mobile;
  final String type; // 'Raw Material' | 'Finished Goods' | 'Other'
  final String? address;
  final String? city;
  final String? district;
  final String? state;
  final String? pincode;
  final String? idNumber;
  final String? gstin;
  final String status;
  final List<PartyAddress> addresses;

  bool get isActive => status.toLowerCase() != 'inactive';
  bool get isUrp =>
      gstin == null || gstin!.trim().isEmpty || gstin!.toUpperCase() == 'URP';

  factory Supplier.fromJson(Map<String, dynamic> json) {
    final rawAddrs = json['addresses'];
    final addrs = rawAddrs is List
        ? rawAddrs
              .whereType<Map<String, dynamic>>()
              .map(PartyAddress.fromJson)
              .toList()
        : const <PartyAddress>[];
    return Supplier(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      mobile: parseOptionalString(json['mobile']),
      type: parseOptionalString(json['type']) ?? 'Raw Material',
      address: parseOptionalString(json['address']),
      city: parseOptionalString(json['city']),
      district: parseOptionalString(json['district']),
      state: parseOptionalString(json['state']),
      pincode: parseOptionalString(json['pincode']),
      idNumber: parseOptionalString(json['id_number']),
      gstin: parseOptionalString(json['gstin']),
      status: parseOptionalString(json['status']) ?? 'Active',
      addresses: addrs,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'id': id,
      'name': name.trim(),
      'mobile': parseOptionalString(mobile),
      'type': type,
      'address': parseOptionalString(address),
      'city': parseOptionalString(city),
      'district': parseOptionalString(district),
      'state': parseOptionalString(state),
      'pincode': parseOptionalString(pincode),
      'id_number': parseOptionalString(idNumber),
      'gstin': parseOptionalString(gstin),
      'status': status,
      'addresses': addresses.map((a) => a.toJson()).toList(),
    };
  }
}

