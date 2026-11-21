import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'review_request_policy.dart';

class ReviewRequestCoordinator {
  ReviewRequestCoordinator({
    this.enabled = kReleaseMode,
    Future<SharedPreferences> Function()? preferences,
    Future<String> Function()? version,
    Future<bool> Function()? available,
    Future<void> Function()? request,
    String Function()? owner,
    DateTime Function()? now,
    this.quietPeriod = const Duration(seconds: 3),
  }) : _preferences = preferences ?? SharedPreferences.getInstance,
       _version =
           version ?? (() async => (await PackageInfo.fromPlatform()).version),
       _available = available ?? (() => InAppReview.instance.isAvailable()),
       _request = request ?? (() => InAppReview.instance.requestReview()),
       _owner = owner ?? _firebaseOwner,
       _now = now ?? DateTime.now;
  static final instance = ReviewRequestCoordinator();
  final bool enabled;
  final Duration quietPeriod;
  final Future<SharedPreferences> Function() _preferences;
  final Future<String> Function() _version;
  final Future<bool> Function() _available;
  final Future<void> Function() _request;
  final String Function() _owner;
  final DateTime Function() _now;
  Future<void> _tail = Future.value();
  int _generation = 0;
  String get owner => _owner();
  static String _firebaseOwner() {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? 'guest';
    } catch (_) {
      return 'guest';
    }
  }

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  /// Call after persistence, success messages and stamp dialogs have completed.
  /// A new touch, route change, account change or backgrounding cancels this attempt.
  Future<void> afterSuccessfulRecord(
    BuildContext context, {
    required String recordKey,
    required String owner,
    bool Function()? isIdle,
  }) async {
    if (!enabled || recordKey.isEmpty || !context.mounted || _owner() != owner)
      return;
    final route = ModalRoute.of(context);
    if (route == null) return;
    final generation = ++_generation;
    var interacted = false;
    final lifecycleGuard = _ReviewLifecycleGuard();
    WidgetsBinding.instance.addObserver(lifecycleGuard);
    void onPointer(PointerEvent event) {
      if (event is PointerDownEvent) interacted = true;
    }

    bool ready() =>
        context.mounted &&
        route.isCurrent &&
        (route.animation?.isCompleted ?? true) &&
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
        generation == _generation &&
        !lifecycleGuard.interrupted &&
        !interacted &&
        _owner() == owner &&
        (isIdle?.call() ?? true) &&
        MediaQuery.viewInsetsOf(context).bottom == 0;
    GestureBinding.instance.pointerRouter.addGlobalRoute(onPointer);
    try {
      await _serial(() async {
        final policy = ReviewRequestPolicy(await _preferences());
        await policy.recordSuccess(owner, recordKey, _now());
      });
      if (!ready()) return;
      await Future<void>.delayed(quietPeriod);
      if (!ready()) return;
      await _serial(() async {
        if (!ready()) return;
        final version = await _version();
        final policy = ReviewRequestPolicy(await _preferences());
        if (!policy.canRequest(owner, version, _now()) ||
            !await _available() ||
            !ready())
          return;
        // Persist before invoking the OS. The API cannot tell us whether a prompt
        // appeared, was dismissed, or led to a rating; never record a completed review.
        await policy.recordRequest(version, _now());
        if (ready()) await _request();
      });
    } catch (_) {
      // Optional feedback must not affect the saved record or show a new error.
    } finally {
      GestureBinding.instance.pointerRouter.removeGlobalRoute(onPointer);
      WidgetsBinding.instance.removeObserver(lifecycleGuard);
    }
  }

  Future<void> recordManualRequest() async {
    ++_generation;
    try {
      await _serial(
        () async => ReviewRequestPolicy(
          await _preferences(),
        ).recordRequest(await _version(), _now()),
      );
    } catch (_) {}
  }
}

class _ReviewLifecycleGuard extends WidgetsBindingObserver {
  bool interrupted = false;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) interrupted = true;
  }
}
