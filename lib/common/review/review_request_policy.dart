import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Eligibility uses completed tasks, never a person's ratings, sentiment or taste match.
class ReviewRequestPolicy {
  ReviewRequestPolicy(this.prefs);
  final SharedPreferences prefs;
  static const historyKey = 'review-request-history-v1';
  String _progressKey(String owner) =>
      'review-progress-v1-${sha256.convert(utf8.encode(owner))}';
  Map<String, dynamic> _progress(String owner) {
    final raw = prefs.getString(_progressKey(owner));
    return raw == null
        ? <String, dynamic>{}
        : jsonDecode(raw) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _history() {
    final raw = prefs.getString(historyKey);
    return raw == null
        ? []
        : (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  Future<void> recordSuccess(
    String owner,
    String recordKey,
    DateTime now,
  ) async {
    final progress = _progress(owner);
    final records = Set<String>.from(progress['records'] as List? ?? []);
    final days = Set<String>.from(progress['days'] as List? ?? []);
    final hash = sha256.convert(utf8.encode(recordKey)).toString();
    if (!records.add(hash)) return;
    days.add('${now.year}-${now.month}-${now.day}');
    if (!await prefs.setString(
      _progressKey(owner),
      jsonEncode({
        'firstAt': progress['firstAt'] ?? now.toUtc().toIso8601String(),
        'records': records.toList(),
        'days': days.toList(),
      }),
    )) {
      throw StateError('Review progress could not be stored');
    }
  }

  bool canRequest(String owner, String version, DateTime now) {
    final progress = _progress(owner);
    if ((progress['records'] as List? ?? []).length < 3 ||
        (progress['days'] as List? ?? []).length < 2)
      return false;
    final firstAt = progress['firstAt'];
    if (firstAt is! String ||
        now.difference(DateTime.parse(firstAt)) < const Duration(days: 1)) {
      return false;
    }
    final history = _history();
    if (history.any((row) => row['version'] == version)) return false;
    final dates = history
        .map((row) => DateTime.parse(row['at'] as String))
        .toList();
    // Also suppress if the device clock has moved backwards.
    if (dates.any((at) => now.difference(at) < const Duration(days: 90)))
      return false;
    return dates
            .where((at) => now.difference(at) < const Duration(days: 365))
            .length <
        3;
  }

  Future<void> recordRequest(String version, DateTime now) async {
    final history = _history()
      ..add({'version': version, 'at': now.toUtc().toIso8601String()});
    // Preserve the version history so an app downgrade does not request again.
    if (!await prefs.setString(historyKey, jsonEncode(history)))
      throw StateError('Review attempt could not be stored');
  }
}
