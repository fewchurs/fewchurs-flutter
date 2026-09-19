import 'package:fewchurs_core/fewchurs_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsDeviceIdStore implements DeviceIdStore {
  const PrefsDeviceIdStore({this.key = 'fewchurs.device_id'});

  final String key;

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(key);

  @override
  Future<void> write(String id) async =>
      (await SharedPreferences.getInstance()).setString(key, id);
}

class FewchursPrefs {
  const FewchursPrefs();

  static const emailKey = 'fewchurs.email';
  static const authorNameKey = 'fewchurs.author_name';

  Future<String?> get(String key) async {
    try {
      return (await SharedPreferences.getInstance()).getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> set(String key, String? value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null || value.isEmpty) {
        await prefs.remove(key);
      } else {
        await prefs.setString(key, value);
      }
    } catch (_) {}
  }
}
