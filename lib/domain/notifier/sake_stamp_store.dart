import 'dart:async';
import 'dart:convert';
import 'package:flutter/widgets.dart';
import '../eintities/collected_sake_stamp.dart';
import '../repository/sake_stamp_repository.dart';
export '../eintities/collected_sake_stamp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../eintities/sake_catalog_browse.dart';
import '../eintities/sake_label_scan.dart';

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

/// Durable local collection with additive account backup and restoration.
/// Writes are serialized so simultaneous detail/record events award once.
class SakeStampStore extends ChangeNotifier with WidgetsBindingObserver {
  SakeStampStore({
    this.accountId,
    this.remote,
    Future<SharedPreferences> Function()? preferences,
  }) : _preferences = preferences ?? SharedPreferences.getInstance {
    ready = _load();
    if (accountId != null && remote != null) {
      WidgetsBinding.instance.addObserver(this);
      unawaited(ready.then((_) => sync()));
    }
  }
  final String? accountId;
  final SakeStampRemote? remote;
  Future<void>? _syncing;
  bool _syncAgain = false;
  bool syncFailed = false;
  bool _syncDisabled = false;
  bool _foreground = true;
  int _retryAttempt = 0;
  Timer? _retry;
  final _uploaded = <String>{};
  String _fingerprint(CollectedSakeStamp stamp) => jsonEncode(stamp.toJson());
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
      unawaited(sync());
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
      unawaited(sync());
    } catch (_) {
      /* The records themselves remain authoritative. */
    }
  });

  /// Pull first, then upload the durable local union in bounded batches. Restores
  /// are silent; only a new local successful action can show the award animation.
  Future<void> sync() {
    if (_disposed || _syncDisabled || accountId == null || remote == null) {
      return Future.value();
    }
    if (_syncing != null) {
      _syncAgain = true;
      return _syncing!;
    }
    _retry?.cancel();
    final work = _sync();
    _syncing = work;
    return work.whenComplete(() {
      _syncing = null;
      if (_syncAgain && !_disposed && !syncFailed) {
        _syncAgain = false;
        unawaited(sync());
      }
    });
  }

  Future<void> _mergeRemote(List<CollectedSakeStamp> stamps) =>
      _serialize(() async {
        if (_disposed || _syncDisabled || !_canWrite) return;
        final next = {..._entries};
        for (final s in stamps) {
          if (!s.valid) throw const FormatException('Invalid cloud stamp');
          if (s.originalBrandId != null && s.originalBrandId != s.brandId) {
            next.remove(s.originalBrandId);
          }
          next.putIfAbsent(s.brandId, () => s);
        }
        final prefs = await _preferences();
        if (_disposed) return;
        if (!await prefs.setStringList(
          storageKey,
          next.values.map((s) => jsonEncode(s.toJson())).toList(),
        )) {
          throw StateError('Could not persist cloud stamps');
        }
        if (_disposed) return;
        _entries
          ..clear()
          ..addAll(next);
        for (final s in stamps) {
          final local = _entries[s.brandId];
          if (local != null) _uploaded.add(_fingerprint(local));
        }
        notifyListeners();
      });

  Future<void> _sync() async {
    try {
      await ready;
      if (_disposed || _syncDisabled || !_canWrite) return;
      final restored = await remote!.fetch(accountId!);
      if (_disposed) return;
      await _mergeRemote(restored);
      final pending = _entries.values
          .where((s) => !_uploaded.contains(_fingerprint(s)))
          .toList();
      for (var start = 0; start < pending.length; start += 100) {
        if (_disposed) return;
        final end = (start + 100).clamp(0, pending.length);
        final sent = pending.sublist(start, end);
        final accepted = await remote!.upload(accountId!, sent);
        if (_disposed) return;
        await _mergeRemote(accepted);
        // Unresolved catalog entries stay local and are retried, never erased.
        if (accepted.length != sent.length) {
          throw StateError('Unresolved stamp origins');
        }
      }
      syncFailed = false;
      _retryAttempt = 0;
    } catch (_) {
      if (!_disposed && !_syncDisabled) {
        syncFailed = true;
        _retryAttempt = (_retryAttempt + 1).clamp(1, 4);
        if (_foreground) {
          _retry = Timer(
            Duration(minutes: 1 << (_retryAttempt - 1)),
            () => unawaited(sync()),
          );
        }
      }
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground) {
      unawaited(sync());
    } else {
      _retry?.cancel();
    }
  }

  /// Called only after the server has confirmed deletion of this account.
  Future<void> clearDeletedAccount(String uid) async {
    if (uid != accountId || _disposed) return;
    _syncDisabled = true;
    _retry?.cancel();
    await _serialize(() async {
      await ready;
      _canWrite = false;
      _entries.clear();
      _uploaded.clear();
      try {
        await (await _preferences()).remove(storageKey);
      } catch (_) {}
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _retry?.cancel();
    if (remote != null && accountId != null) {
      WidgetsBinding.instance.removeObserver(this);
    }
    super.dispose();
  }
}
