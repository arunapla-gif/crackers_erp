import 'json_helpers.dart';

class PartyAddress {
  const PartyAddress({
    this.type = 'Principal Place',
    required this.address,
    this.city = '',
    this.district = '',
    this.state = '',
    this.pincode = '',
  });

  final String type;
  final String address;
  final String city;
  final String district;
  final String state;
  final String pincode;

  String get formattedSummary {
    return [address, city, district, state, pincode]
        .where((s) => s.trim().isNotEmpty)
        .join(', ');
  }

  factory PartyAddress.fromJson(Map<String, dynamic> json) {
    return PartyAddress(
      type: (json['type'] ?? 'Address').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'address': address,
      'city': city,
      'district': district,
      'state': state,
      'pincode': pincode,
    };
  }
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.mobile,
    this.reference,
    this.address,
    this.city,
    this.district,
    this.state,
    this.pincode,
    this.idNumber,
    this.gstin,
    required this.status,
    this.addresses = const [],
    this.repId,
    this.repUsername,
  });

  final int id;
  final String name;
  final String? mobile;
  final String? reference;
  final String? address;
  final String? city;
  final String? district;
  final String? state;
  final String? pincode;
  final String? idNumber;
  final String? gstin;
  final String status;
  final List<PartyAddress> addresses;
  final int? repId;
  final String? repUsername;

  bool get isActive => status.toLowerCase() != 'inactive';
  bool get isUrp =>
      gstin == null || gstin!.trim().isEmpty || gstin!.toUpperCase() == 'URP';

  String get primaryAddressText {
    if (addresses.isNotEmpty && addresses.first.address.trim().isNotEmpty) {
      return addresses.first.address;
    }
    return address ?? '';
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    final rawAddrs = json['addresses'];
    final parsedAddrs = rawAddrs is List
        ? rawAddrs
              .whereType<Map<String, dynamic>>()
              .map(PartyAddress.fromJson)
              .toList()
        : const <PartyAddress>[];
    final repRaw = json['rep'];

    return Customer(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
      mobile: parseOptionalString(json['mobile']),
      reference: parseOptionalString(json['reference']),
      address: parseOptionalString(json['address']),
      city: parseOptionalString(json['city']),
      district: parseOptionalString(json['district']),
      state: parseOptionalString(json['state']),
      pincode: parseOptionalString(json['pincode']),
      idNumber: parseOptionalString(json['id_number']),
      gstin: parseOptionalString(json['gstin']),
      status: parseOptionalString(json['status']) ?? 'Active',
      addresses: parsedAddrs,
      repId: json['repId'] == null ? null : parseInt(json['repId']),
      repUsername: repRaw is Map<String, dynamic>
          ? parseOptionalString(repRaw['username'])
          : null,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'id': id,
      'name': name.trim(),
      'mobile': parseOptionalString(mobile),
      'reference': parseOptionalString(reference),
      'address': parseOptionalString(address),
      'city': parseOptionalString(city),
      'district': parseOptionalString(district),
      'state': parseOptionalString(state),
      'pincode': parseOptionalString(pincode),
      'id_number': parseOptionalString(idNumber),
      'gstin': parseOptionalString(gstin),
      'status': status,
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'repId': repId,
    };
  }
}

class GstinDetails {
  const GstinDetails({
    required this.gstin,
    required this.legalName,
    required this.tradeName,
    required this.address,
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    required this.status,
    required this.addresses,
  });

  final String gstin;
  final String legalName;
  final String tradeName;
  final String address;
  final String city;
  final String district;
  final String state;
  final String pincode;
  final String status;
  final List<PartyAddress> addresses;

  String get preferredName =>
      tradeName.trim().isNotEmpty ? tradeName.trim() : legalName.trim();

  factory GstinDetails.fromJson(Map<String, dynamic> json) {
    final rawAddrs = json['addresses'];
    final addrs = rawAddrs is List
        ? rawAddrs
              .whereType<Map<String, dynamic>>()
              .map(PartyAddress.fromJson)
              .toList()
        : const <PartyAddress>[];
    return GstinDetails(
      gstin: (json['gstin'] ?? '').toString(),
      legalName: (json['legalName'] ?? '').toString(),
      tradeName: (json['tradeName'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      district: (json['district'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      status: (json['status'] ?? 'Active').toString(),
      addresses: addrs,
    );
  }
}

class PincodeLocation {
  const PincodeLocation({
    required this.city,
    required this.district,
    required this.state,
  });

  final String city;
  final String district;
  final String state;
}
