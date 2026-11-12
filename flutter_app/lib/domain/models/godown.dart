import 'json_helpers.dart';

class Godown {
  const Godown({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  factory Godown.fromJson(Map<String, dynamic> json) {
    return Godown(
      id: parseInt(json['id']),
      name: (json['name'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      if (id > 0) 'id': id,
      'name': name.trim(),
    };
  }
}

