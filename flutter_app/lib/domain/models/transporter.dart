import 'json_helpers.dart';

class Transporter {
  const Transporter({
    required this.id,
    required this.gstin,
    required this.name,
    this.address,
    this.city,
    this.district,
    this.state,
    this.pincode,
    required this.status,
  });

  final int id;
  final String gstin;
  final String name;
  final String? address;
  final String? city;
  final String? district;
  final String? state;
  final String? pincode;
  final String status;

  bool get isActive => status.toLowerCase() != 'inactive';

  factory Transporter.fromJson(Map<String, dynamic> json) {
    return Transporter(
      id: parseInt(json['id']),
      gstin: (json['gstin'] ?? '').toString().trim(),
      name: (json['name'] ?? '').toString().trim(),
      address: parseOptionalString(json['address']),
      city: parseOptionalString(json['city']),
      district: parseOptionalString(json['district']),
      state: parseOptionalString(json['state']),
      pincode: parseOptionalString(json['pincode']),
      status: parseOptionalString(json['status']) ?? 'Active',
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'id': id,
      'gstin': gstin.trim().toUpperCase(),
      'name': name.trim(),
      'address': parseOptionalString(address),
      'city': parseOptionalString(city),
      'district': parseOptionalString(district),
      'state': parseOptionalString(state),
      'pincode': parseOptionalString(pincode),
      'status': status,
    };
  }
}

