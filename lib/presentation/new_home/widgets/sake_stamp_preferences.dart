import 'package:shared_preferences/shared_preferences.dart';

/// Device-local display preference, separate from accounts and earned stamps.
class SakeStampPreferences {
  static const prefectureKey = 'sake_stamp_last_prefecture_v1';

  /// Zero represents the nationwide earned-stamps view; 1–47 are prefectures.
  static Future<int?> lastPrefecture() async {
    try {
      final code = (await SharedPreferences.getInstance()).getInt(
        prefectureKey,
      );
      return code != null && code >= 0 && code <= 47 ? code : null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> rememberPrefecture(int code) async {
    if (code < 0 || code > 47) return;
    try {
      await (await SharedPreferences.getInstance()).setInt(prefectureKey, code);
    } catch (_) {
      // A storage failure must not prevent browsing the book.
    }
  }
}
