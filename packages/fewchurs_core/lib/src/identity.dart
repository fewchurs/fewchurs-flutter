import 'dart:async';
import 'dart:math';

abstract class DeviceIdStore {
  Future<String?> read();

  Future<void> write(String id);
}

class InMemoryDeviceIdStore implements DeviceIdStore {
  String? _id;

  @override
  Future<String?> read() async => _id;

  @override
  Future<void> write(String id) async => _id = id;
}

typedef DeviceIdResolver = FutureOr<String?> Function();

/// Resolves the `X-Device-Id` for requests: a custom [resolver] first, then a
/// random UUID persisted in [store].
class DeviceIdentity {
  DeviceIdentity({DeviceIdStore? store, this.resolver})
      : store = store ?? InMemoryDeviceIdStore();

  final DeviceIdStore store;
  final DeviceIdResolver? resolver;
  Future<String>? _generated;

  Future<String> get id async {
    if (resolver != null) {
      try {
        final custom = await resolver!();
        if (custom != null && custom.trim().isNotEmpty) return custom.trim();
      } catch (_) {}
    }
    return _generated ??= _loadOrCreate();
  }

  Future<String> _loadOrCreate() async {
    try {
      final saved = await store.read();
      if (saved != null && saved.isNotEmpty) return saved;
    } catch (_) {}
    final id = generateUuidV4();
    try {
      await store.write(id);
    } catch (_) {}
    return id;
  }
}

String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
