import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../analytics/app_analytics.dart';

const favoriteDiagnosisMinimum = 2;

enum JourneyStep { preference, like, diagnosis, scan }

enum JourneyAction {
  preference,
  firstLike,
  moreLikes,
  diagnosis,
  scan,
  complete,
}

class JourneySnapshot {
  const JourneySnapshot({
    this.steps = const {},
    this.until,
    this.hidden = false,
    this.completionSeen = false,
    this.diagnosedMonth,
  });
  final Set<JourneyStep> steps;
  final DateTime? until;
  final bool hidden, completionSeen;
  final String? diagnosedMonth;
  JourneySnapshot copy({
    Set<JourneyStep>? steps,
    DateTime? until,
    bool? hidden,
    bool? completionSeen,
    String? diagnosedMonth,
  }) => JourneySnapshot(
    steps: steps ?? this.steps,
    until: until ?? this.until,
    hidden: hidden ?? this.hidden,
    completionSeen: completionSeen ?? this.completionSeen,
    diagnosedMonth: diagnosedMonth ?? this.diagnosedMonth,
  );
  bool visible(DateTime now) =>
      !hidden &&
      !(until?.isAfter(now) ?? false) &&
      !(steps.length == 4 && completionSeen);
  JourneyAction action(int favorites) {
    if (!steps.contains(JourneyStep.preference))
      return JourneyAction.preference;
    if (!steps.contains(JourneyStep.diagnosis)) {
      if (favorites == 0 && !steps.contains(JourneyStep.like))
        return JourneyAction.firstLike;
      if (favorites > 0 && favorites < favoriteDiagnosisMinimum)
        return JourneyAction.moreLikes;
      if (favorites >= favoriteDiagnosisMinimum) return JourneyAction.diagnosis;
    }
    if (!steps.contains(JourneyStep.scan)) return JourneyAction.scan;
    if (!steps.contains(JourneyStep.like)) return JourneyAction.firstLike;
    return JourneyAction.complete;
  }

  Map<String, dynamic> toJson() => {
    'steps': steps.map((s) => s.name).toList(),
    'until': until?.toIso8601String(),
    'hidden': hidden,
    'completionSeen': completionSeen,
    'diagnosedMonth': diagnosedMonth,
  };
  factory JourneySnapshot.fromJson(Map<String, dynamic> json) =>
      JourneySnapshot(
        steps: JourneyStep.values
            .where((s) => (json['steps'] as List? ?? []).contains(s.name))
            .toSet(),
        until: DateTime.tryParse(json['until'] as String? ?? ''),
        hidden: json['hidden'] == true,
        completionSeen: json['completionSeen'] == true,
        diagnosedMonth: json['diagnosedMonth'] as String?,
      );
}

/// Initial guide state is per account; no images or personal text are stored.
class SakeJourneyStore {
  SakeJourneyStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;
  static final instance = SakeJourneyStore();
  final Future<SharedPreferences> Function() _preferences;
  final revision = ValueNotifier<int>(0);
  Future<void> _writes = Future.value();
  String key(String owner) =>
      'sake_journey_v1_${sha256.convert(utf8.encode(owner))}';
  Future<JourneySnapshot> load(String owner) async {
    await _writes;
    return _read(await _preferences(), owner);
  }

  JourneySnapshot _read(SharedPreferences prefs, String owner) {
    try {
      return JourneySnapshot.fromJson(
        jsonDecode(prefs.getString(key(owner)) ?? '{}') as Map<String, dynamic>,
      );
    } catch (_) {
      return const JourneySnapshot();
    }
  }

  Future<void> _update(
    String owner,
    JourneySnapshot Function(JourneySnapshot) update,
  ) {
    final job = _writes.then((_) async {
      final prefs = await _preferences();
      final previous = _read(prefs, owner);
      final next = update(previous);
      if (jsonEncode(previous.toJson()) == jsonEncode(next.toJson())) return;
      if (!await prefs.setString(key(owner), jsonEncode(next.toJson()))) return;
      for (final step in next.steps.difference(previous.steps)) {
        track(step.name, 'success');
      }
      revision.value++;
    });
    _writes = job.catchError((Object _) {});
    return _writes;
  }

  Future<void> reconcile(
    String owner, {
    required bool preference,
    required int likes,
    required bool scan,
    bool diagnosed = false,
  }) => _update(owner, (s) {
    final steps = {
      ...s.steps,
      if (preference) JourneyStep.preference,
      if (likes > 0) JourneyStep.like,
      if (scan) JourneyStep.scan,
      if (diagnosed) JourneyStep.diagnosis,
    };
    return s.copy(steps: steps);
  });
  Future<void> complete(String owner, JourneyStep step, {DateTime? now}) =>
      _update(owner, (s) {
        final time = now ?? DateTime.now();
        return s.copy(
          steps: {...s.steps, step},
          diagnosedMonth: step == JourneyStep.diagnosis
              ? '${time.year}-${time.month}'
              : null,
        );
      });
  Future<void> dismiss(String owner, {bool forever = false, DateTime? now}) =>
      _update(
        owner,
        (s) => s.copy(
          hidden: forever,
          until: (now ?? DateTime.now()).add(const Duration(days: 7)),
        ),
      );
  Future<void> acknowledgeCompletion(String owner) =>
      _update(owner, (s) => s.copy(completionSeen: true));
  static String target(String step) => switch (step) {
    'preference' => 'profile_edit',
    'like' || 'firstLike' || 'moreLikes' => 'favorite',
    'scan' => 'scan',
    _ => 'profile',
  };
  static void track(String step, String kind) => AppAnalytics.instance.event(
    'home',
    target(step),
    kind: kind,
    source: 'profile',
    labelVariant: 'journey_$step',
  );
}
