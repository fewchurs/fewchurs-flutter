import 'dart:async';
import 'dart:math';

/// Persists the generated device ID between launches.
abstract class DeviceIdStore {
  /// Returns the saved ID, or `null` if there is none.
  Future<String?> read();

  /// Saves [id].
  Future<void> write(String id);
}

/// A [DeviceIdStore] that forgets the ID when the process ends.
class InMemoryDeviceIdStore implements DeviceIdStore {
  String? _id;

  @override
  Future<String?> read() async => _id;

  @override
  Future<void> write(String id) async => _id = id;
}

/// Returns your own device or user ID, or `null` to use the generated one.
typedef DeviceIdResolver = FutureOr<String?> Function();

/// Resolves the `X-Device-Id` for requests: a custom [resolver] first, then a
/// random UUID persisted in [store].
class DeviceIdentity {
  DeviceIdentity({DeviceIdStore? store, this.resolver})
      : store = store ?? InMemoryDeviceIdStore();

  /// Where the generated ID is saved.
  final DeviceIdStore store;

  /// Optional custom ID, tried before the generated one.
  final DeviceIdResolver? resolver;
  Future<String>? _generated;

  /// The ID sent as `X-Device-Id`.
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

/// A random RFC 4122 version 4 UUID.
String generateUuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
