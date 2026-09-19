String readString(Object? v) => v is String ? v : (v?.toString() ?? '');

String? readOptionalString(Object? v) => v is String && v.isNotEmpty ? v : null;

int readInt(Object? v) => v is num ? v.toInt() : 0;

bool readBool(Object? v) => v == true;

DateTime readDate(Object? v) {
  final parsed = v is String ? DateTime.tryParse(v) : null;
  return (parsed ?? DateTime.fromMillisecondsSinceEpoch(0)).toUtc();
}

List<Map<String, Object?>> readList(Object? v) =>
    v is List ? v.whereType<Map<String, Object?>>().toList() : const [];
