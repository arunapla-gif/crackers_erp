double parseDouble(Object? value, {double fallback = 0.0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return double.tryParse(trimmed) ?? fallback;
  }
  return fallback;
}

int parseInt(Object? value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return fallback;
    return int.tryParse(trimmed) ?? double.tryParse(trimmed)?.toInt() ?? fallback;
  }
  return fallback;
}

String? parseOptionalString(Object? value) {
  if (value == null) return null;
  final str = value.toString().trim();
  return str.isEmpty ? null : str;
}

DateTime parseDateTime(Object? value, {DateTime? fallback}) {
  if (value is String && value.trim().isNotEmpty) {
    final parsed = DateTime.tryParse(value.trim());
    if (parsed != null) return parsed;
  }
  return fallback ?? DateTime.now();
}

String toIsoCalendarDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

