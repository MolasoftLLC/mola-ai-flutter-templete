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

  /// 静的に文字列を保存するメソッド
  static Future<void> staticSetString({
    required String key,
    required String value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  /// 静的に文字列を取得するメソッド
  static Future<String> staticGetString({
    required String key,
    String defaultValue = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? defaultValue;
  }

  /// 静的に文字列リストを保存するメソッド
  static Future<void> staticSetStringList({
    required String key,
    required List<String> list,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, list);
  }

  /// 静的に文字列リストを取得するメソッド
  static Future<List<String>> staticGetStringList({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key) ?? [];
  }
}
