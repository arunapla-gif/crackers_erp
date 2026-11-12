import 'json_helpers.dart';

class VehicleDriver {
  const VehicleDriver({
    required this.name,
    this.phone = '',
  });

  final String name;
  final String phone;

  factory VehicleDriver.fromJson(Map<String, dynamic> json) {
    return VehicleDriver(
      name: (json['name'] ?? '').toString().trim(),
      phone: (json['phone'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name.trim(), 'phone': phone.trim()};
  }
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.no,
    this.name,
    this.ownerName,
    this.ownerPhone,
    this.drivers = const [],
  });

  final int id;
  final String no;
  final String? name;
  final String? ownerName;
  final String? ownerPhone;
  final List<VehicleDriver> drivers;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final rawDrivers = json['drivers'];
    final drivers = rawDrivers is List
        ? rawDrivers
              .whereType<Map<String, dynamic>>()
              .map(VehicleDriver.fromJson)
              .where((d) => d.name.isNotEmpty)
              .toList()
        : const <VehicleDriver>[];

    return Vehicle(
      id: parseInt(json['id']),
      no: (json['no'] ?? '').toString().trim(),
      name: parseOptionalString(json['name']),
      ownerName: parseOptionalString(json['owner_name']),
      ownerPhone: parseOptionalString(json['owner_phone']),
      drivers: drivers,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'id': id,
      'no': no.trim().toUpperCase(),
      'name': parseOptionalString(name),
      'owner_name': parseOptionalString(ownerName),
      'owner_phone': parseOptionalString(ownerPhone),
      'drivers': drivers.map((d) => d.toJson()).toList(),
    };
  }
}

