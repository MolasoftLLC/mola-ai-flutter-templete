import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../eintities/sake_catalog_browse.dart';
import '../eintities/sake_label_scan.dart';

/// A collected encounter is separate from drinking records and map counts.
class CollectedSakeStamp {
  const CollectedSakeStamp({
    required this.brandId,
    required this.prefectureCode,
    required this.sakeId,
    required this.source,
    required this.observedAt,
  });
  final int brandId, prefectureCode, sakeId;
  final String source;
  final DateTime observedAt;
  bool get valid =>
      brandId > 0 && sakeId > 0 && prefectureCode >= 1 && prefectureCode <= 47;
  Map<String, dynamic> toJson() => {
    'brandId': brandId,
    'prefectureCode': prefectureCode,
    'sakeId': sakeId,
    'source': source,
    'observedAt': observedAt.toIso8601String(),
  };
  factory CollectedSakeStamp.fromJson(Map<String, dynamic> json) =>
      CollectedSakeStamp(
        brandId: json['brandId'] as int,
        prefectureCode: json['prefectureCode'] as int,
        sakeId: json['sakeId'] as int,
        source: json['source'] as String,
        observedAt: DateTime.parse(json['observedAt'] as String),
      );
}

/// A cache payload alone does not establish that detailed analysis succeeded.
bool isStampEligibleOverview(SakeOverview overview) {
  final status = overview.lensDetailAnalysisStatus;
  if (status != null && status != 'completed') return false;
  final profile = overview.master.tasteProfile;
  if (profile == null ||
      ![
        profile.fruity,
        profile.sweetness,
        profile.acidity,
        profile.umami,
        profile.kire,
        profile.dryness,
      ].every((v) => v.isFinite && v >= 0 && v <= 1)) {
    return false;
  }
  return !overview.masterEnrichmentPending &&
      (overview.analysisCompleted || status == 'completed') &&
      overview.sake.description?.trim().isNotEmpty == true &&
      overview.master.tasteProfile != null;
}

/// Device-local collection, isolated by verified account or guest scope.
/// Writes are serialized so simultaneous detail/record events award once.
class SakeStampStore extends ChangeNotifier {
  SakeStampStore({
    this.accountId,
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance {
    ready = _load();
  }
  final String? accountId;
  final Future<SharedPreferences> Function() _preferences;
  late final Future<void> ready;
  final _entries = <int, CollectedSakeStamp>{};
  Future<void> _tail = Future.value();
  bool _disposed = false;
  bool _canWrite = true;
  bool loaded = false;
  bool presenting = false;
  String get storageKey =>
      'sake_encounter_stamps_v1:${base64Url.encode(utf8.encode(accountId == null ? 'guest' : 'account:$accountId'))}';
  Map<int, Set<int>> get brandIdsByPrefecture {
    final result = <int, Set<int>>{};
    for (final stamp in _entries.values) {
      result.putIfAbsent(stamp.prefectureCode, () => {}).add(stamp.brandId);
    }
    return result;
  }

  bool contains(int brandId) => _entries.containsKey(brandId);
  Future<void> _load() async {
    try {
      final prefs = await _preferences();
      if (_disposed) return;
      for (final row in prefs.getStringList(storageKey) ?? <String>[]) {
        try {
          final entry = CollectedSakeStamp.fromJson(
            jsonDecode(row) as Map<String, dynamic>,
          );
          if (entry.valid) _entries.putIfAbsent(entry.brandId, () => entry);
        } catch (_) {
          /* Ignore a corrupt row without discarding the collection. */
        }
      }
    } catch (_) {
      _canWrite = false; // Preserve unread history rather than overwriting it.
    }
    if (!_disposed) {
      loaded = true;
      notifyListeners();
    }
  }

  Future<T> _serialize<T>(Future<T> Function() work) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await work());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<bool> acquire(
    CollectedSakeStamp stamp, {
    required bool Function() isCurrent,
  }) => _serialize(() async {
    await ready;
    if (_disposed ||
        !_canWrite ||
        !isCurrent() ||
        !stamp.valid ||
        contains(stamp.brandId)) {
      return false;
    }
    final next = {..._entries, stamp.brandId: stamp};
    try {
      final prefs = await _preferences();
      if (_disposed || !_canWrite || !isCurrent()) return false;
      final saved = await prefs.setStringList(
        storageKey,
        next.values.map((s) => jsonEncode(s.toJson())).toList(),
      );
      if (!saved || _disposed) return false;
      _entries[stamp.brandId] = stamp;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  });

  /// Existing personal records are inherited silently, without replaying awards.
  Future<void> inheritRecords(
    List<SakeProductOrigin> origins, {
    required bool Function() isCurrent,
  }) => _serialize(() async {
    await ready;
    if (_disposed || !_canWrite || !isCurrent()) return;
    final next = {..._entries};
    for (final origin in origins) {
      final entry = CollectedSakeStamp(
        brandId: origin.brandId,
        prefectureCode: origin.prefectureCode,
        sakeId: origin.canonicalSakeId,
        source: 'prior_record',
        observedAt: DateTime.now(),
      );
      if (entry.valid) next.putIfAbsent(entry.brandId, () => entry);
    }
    if (next.length == _entries.length) return;
    try {
      final prefs = await _preferences();
      if (_disposed || !_canWrite || !isCurrent()) return;
      if (!await prefs.setStringList(
            storageKey,
            next.values.map((s) => jsonEncode(s.toJson())).toList(),
          ) ||
          _disposed) {
        return;
      }
      _entries
        ..clear()
        ..addAll(next);
      notifyListeners();
    } catch (_) {
      /* The records themselves remain authoritative. */
    }
  });
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
