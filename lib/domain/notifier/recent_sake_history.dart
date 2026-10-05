import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

/// 詳細の閲覧履歴。飲酒記録や公開投稿とは別に端末へ保存する。
class RecentSakeHistory extends ChangeNotifier {
  static const _key = 'recent_viewed_sakes_v1';
  final Map<int, ({Sake sake, int viewedAt})> _entries = {};
  SharedPreferences? _prefs;

  Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      for (final source in _prefs!.getStringList(_key) ?? <String>[]) {
        try {
          final json = jsonDecode(source) as Map<String, dynamic>;
          final sake = Sake.fromJson(json['sake'] as Map<String, dynamic>);
          if ((sake.sakeId ?? 0) > 0) {
            _entries[sake.sakeId!] = (
              sake: sake,
              viewedAt: (json['viewedAt'] as num).toInt(),
            );
          }
        } catch (_) {
          // 壊れた一件だけを読み飛ばす。
        }
      }
    } catch (_) {
      // 保存が利用できなくても詳細の閲覧は継続できる。
    }
  }

  void record(Sake sake) {
    if ((sake.sakeId ?? 0) <= 0) return;
    _entries[sake.sakeId!] = (
      sake: Sake(
        sakeId: sake.sakeId,
        name: sake.name,
        brewery: sake.brewery,
        type: sake.type,
        description: sake.description,
        primaryImageUrl: sake.primaryImageUrl,
        thumbnailImageUrl: sake.thumbnailImageUrl,
      ),
      viewedAt: DateTime.now().millisecondsSinceEpoch,
    );
    final sorted = _entries.entries.toList()
      ..sort((a, b) => b.value.viewedAt.compareTo(a.value.viewedAt));
    _entries.removeWhere((id, _) => !sorted.take(200).any((e) => e.key == id));
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    try {
      await _prefs?.setStringList(
        _key,
        _entries.values
            .map(
              (entry) => jsonEncode({
                'sake': entry.sake.toJson(),
                'viewedAt': entry.viewedAt,
              }),
            )
            .toList(),
      );
    } catch (_) {
      // 保存に失敗してもこの起動中の履歴は保持する。
    }
  }

  List<Sake> merge(List<Sake> saved) {
    final savedIds = saved.map((sake) => sake.sakeId).toSet();
    final rows = [
      ...saved,
      ..._entries.values
          .where((entry) => !savedIds.contains(entry.sake.sakeId))
          .map((entry) => entry.sake),
    ];
    int timestamp(Sake sake) {
      final parts = sake.savedId?.split('_');
      final savedAt = parts != null && parts.length >= 3
          ? int.tryParse(parts[1]) ?? 0
          : 0;
      final viewedAt = _entries[sake.sakeId]?.viewedAt ?? 0;
      return savedAt > viewedAt ? savedAt : viewedAt;
    }

    rows.sort((a, b) => timestamp(b).compareTo(timestamp(a)));
    return rows;
  }
}
