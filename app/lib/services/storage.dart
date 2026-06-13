import 'package:shared_preferences/shared_preferences.dart';

/// Thin async wrapper over SharedPreferences. Initialise once at startup via
/// [Storage.init], then use the synchronous getters/setters.
class Storage {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? getString(String key) => _prefs.getString(key);
  static Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);
  static Future<void> remove(String key) => _prefs.remove(key);
  static Set<String> getKeys() => _prefs.getKeys();
}
