import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/repository/place_map_repository.dart';

/// Only printed text is sent to the existing catalog search. No image/AI path.
List<String> liveSakeQueries(String text) {
  final lines = text
      .split(RegExp(r'[\r\n]+'))
      .map(
        (line) => line
            .replaceAll(
              RegExp(
                r'[¥￥]\s*\d[\d,]*\s*円?|\d[\d,]*\s*(?:円|[mM][lL]|合)(?:税込|税別)?',
              ),
              ' ',
            )
            .replaceAll(RegExp(r'[・|｜：:]'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
      )
      .where(
        (line) =>
            line.isNotEmpty &&
            line.length <= 64 &&
            RegExp(r'[A-Za-zぁ-んァ-ヶ一-龥]').hasMatch(line),
      )
      .toList();
  final generic = RegExp(
    r'^(?:日本酒|お品書き|メニュー|純米|純米酒|純米吟醸|純米大吟醸|吟醸|大吟醸|本醸造|特純|特別純米|生酒|辛口|甘口|価格|おすすめ|グラス|ボトル)$',
  );
  final result = <String>[];
  void add(String value) {
    if (value.isNotEmpty &&
        !generic.hasMatch(value) &&
        !result.contains(value)) {
      result.add(value);
    }
  }

  for (var i = 0; i < lines.length && result.length < 4; i++) {
    final line = lines[i];
    if (generic.hasMatch(line)) continue;
    if (i + 1 < lines.length && generic.hasMatch(lines[i + 1])) {
      add('$line ${lines[i + 1]}');
    }
    add(line);
    // Printed classification is useful evidence, but must not hide the brand.
    final name = line
        .split(RegExp(r'\s*(?=純米|特純|特別純米|本醸造|吟醸|大吟醸|生酒|山廃|生酛)'))
        .first;
    if (name != line) add(name);
  }
  return result.take(4).toList();
}

class LiveSakeSearch extends ChangeNotifier {
  LiveSakeSearch({required this.search, required this.loadProfiles});
  final Future<List<SakeMapSearchResult>> Function(String) search;
  final Future<Map<int, SakeTasteProfileDetails>> Function(List<int>)
  loadProfiles;
  final _cache = <String, List<SakeMapSearchResult>>{};
  final _pendingProfiles = <int>{};
  final _profileCache = <int, SakeTasteProfileDetails>{};
  List<SakeMapSearchResult> candidates = [];
  Map<int, SakeTasteProfileDetails> get profiles => _profileCache;
  String text = '';
  String? error;
  bool searching = false;
  bool _disposed = false;
  int _generation = 0;
  String _previous = '', _accepted = '';
  String? _failed;
  DateTime _retryAfter = DateTime.fromMillisecondsSinceEpoch(0);

  void observe(String reading) {
    final key = liveSakeQueries(reading).join('\n');
    if (key.isEmpty) {
      _previous = '';
      return;
    }
    if (key != _previous) {
      _previous = key;
      return;
    }
    if (key == _accepted &&
        (key != _failed || DateTime.now().isBefore(_retryAfter))) {
      return;
    }
    unawaited(find(reading));
  }

  Future<void> find(String reading) async {
    final queries = liveSakeQueries(reading);
    final key = queries.join('\n');
    final generation = ++_generation;
    _accepted = key;
    text = reading;
    error = null;
    searching = queries.isNotEmpty;
    candidates = [];
    notifyListeners();
    var failures = 0;
    final found = <int, SakeMapSearchResult>{};
    final byQuery = <String, List<SakeMapSearchResult>>{};
    await Future.wait(
      queries.map((query) async {
        try {
          final results =
              _cache[query] ??
              await search(query).timeout(const Duration(seconds: 6));
          if (!_cache.containsKey(query)) {
            if (_cache.length >= 80) _cache.remove(_cache.keys.first);
            _cache[query] = results;
          }
          if (_disposed || generation != _generation) return;
          byQuery[query] = results;
          found.clear();
          // Specific name/classification queries stay ahead of broad brand
          // matches regardless of which network response arrived first.
          for (final q in queries) {
            for (final result in byQuery[q] ?? <SakeMapSearchResult>[]) {
              if ((result.sakeId ?? 0) > 0 && result.isMaster) {
                found.putIfAbsent(result.sakeId!, () => result);
              }
            }
          }
          candidates = found.values.take(20).toList();
          notifyListeners(); // Show the first catalog response immediately.
          unawaited(_loadTasteProfiles(found.keys.toList(), generation));
        } catch (_) {
          failures++;
        }
      }),
    );
    if (_disposed || generation != _generation) return;
    searching = false;
    if (failures > 0) {
      _failed = key;
      _retryAfter = DateTime.now().add(const Duration(seconds: 4));
      if (found.isEmpty) error = '候補を取得できませんでした。通信を確認してください。';
    } else {
      _failed = null;
    }
    notifyListeners();
  }

  Future<void> _loadTasteProfiles(List<int> allIds, int generation) async {
    final ids = allIds
        .where(
          (id) =>
              !_profileCache.containsKey(id) && !_pendingProfiles.contains(id),
        )
        .toList();
    if (ids.isEmpty) return;
    _pendingProfiles.addAll(ids);
    try {
      final loaded = await loadProfiles(
        ids,
      ).timeout(const Duration(seconds: 6));
      if (_disposed) return;
      _profileCache.addAll(loaded);
      if (candidates.any((candidate) => loaded.containsKey(candidate.sakeId))) {
        notifyListeners();
      }
    } catch (_) {
      /* Names and selection remain usable without taste data. */
    } finally {
      _pendingProfiles.removeAll(ids);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
