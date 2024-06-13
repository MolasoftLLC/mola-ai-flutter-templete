import 'package:shared_preferences/shared_preferences.dart';

class SharedPreference {
  Future<void> setStringList({
    required String key,
    required List<String> list,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, list);
  }

  Future<List<String>> getStringList({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }
}
