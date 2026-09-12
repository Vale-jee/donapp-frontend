// Shared domain checks used by generated network decoders.
T apiDecode<T>(T Function() decode) {
  try {
    return decode();
  } on FormatException {
    rethrow;
  } on TypeError {
    throw const FormatException('Invalid API field type.');
  } on ArgumentError {
    throw const FormatException('Invalid API field value.');
  }
}

int strictInt(Object? value) {
  if (value is! int) throw const FormatException('Expected integer.');
  return value;
}

String nonEmptyString(Object? value) {
  if (value is! String || value.isEmpty) {
    throw const FormatException('Expected nonempty string.');
  }
  return value;
}

String? nonEmptyNullableString(Object? value) =>
    value == null ? null : nonEmptyString(value);
DateTime serverInstant(Object? value) {
  final hasZone =
      value is String && RegExp(r'(?:Z|[+-]\d{2}:\d{2})$').hasMatch(value);
  final parsed = hasZone ? DateTime.tryParse(value) : null;
  if (parsed == null) {
    throw const FormatException('Expected server timestamp with time zone.');
  }
  return parsed.toUtc();
}

Object? categoryId(Map json, String key) => (json['categoria'] as Map)['id'];
Object? categoryName(Map json, String key) =>
    (json['categoria'] as Map)['nombre'];
