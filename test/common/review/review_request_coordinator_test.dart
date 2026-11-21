import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/common/review/review_request_policy.dart';
import 'package:mola_gemini_flutter_template/common/review/review_request_coordinator.dart';

void main() {
  late SharedPreferences prefs;
  late BuildContext screen;
  late String owner;
  late int requests;
  final now = DateTime(2026, 11, 22, 12);
  Future<void> seed() async {
    final p = ReviewRequestPolicy(prefs);
    await p.recordSuccess(
      'guest',
      'record:1',
      now.subtract(const Duration(days: 1)),
    );
    await p.recordSuccess('guest', 'record:2', now);
  }

  ReviewRequestCoordinator coordinator({
    bool available = true,
    bool enabled = true,
    bool fail = false,
  }) => ReviewRequestCoordinator(
    enabled: enabled,
    preferences: () async => prefs,
    owner: () => owner,
    now: () => now,
    version: () async => '5.0.60',
    available: () async => available,
    request: () async {
      requests++;
      if (fail) throw StateError('provider failed');
    },
    quietPeriod: const Duration(seconds: 3),
  );
  Future<void> home(WidgetTester tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            screen = context;
            return Scaffold(
              body: TextButton(onPressed: () {}, child: const Text('Continue')),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester, Future<void> pending) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 4));
    await pending;
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    owner = 'guest';
    requests = 0;
    await seed();
  });
  testWidgets(
    'quiet completed task requests the OS once and persists the attempt, not a rating',
    (tester) async {
      await home(tester);
      final c = coordinator();
      final pending = c.afterSuccessfulRecord(
        screen,
        recordKey: 'record:3',
        owner: 'guest',
      );
      await finish(tester, pending);
      expect(requests, 1);
      await finish(
        tester,
        c.afterSuccessfulRecord(screen, recordKey: 'record:4', owner: 'guest'),
      );
      expect(requests, 1);
      expect(
        prefs.getString(ReviewRequestPolicy.historyKey),
        contains('5.0.60'),
      );
    },
  );
  testWidgets(
    'touches during the quiet period cancel without consuming the attempt',
    (tester) async {
      await home(tester);
      final pending = coordinator().afterSuccessfulRecord(
        screen,
        recordKey: 'record:3',
        owner: 'guest',
      );
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await finish(tester, pending);
      expect(requests, 0);
      expect(prefs.getString(ReviewRequestPolicy.historyKey), isNull);
    },
  );
  testWidgets('another dialog and busy state do not interrupt a task', (
    tester,
  ) async {
    await home(tester);
    final pending = coordinator().afterSuccessfulRecord(
      screen,
      recordKey: 'record:3',
      owner: 'guest',
    );
    await tester.pump();
    unawaited(
      showDialog<void>(
        context: screen,
        builder: (_) => const AlertDialog(title: Text('Working')),
      ),
    );
    await finish(tester, pending);
    expect(requests, 0);
    Navigator.of(screen).pop();
    await tester.pumpAndSettle();
    await finish(
      tester,
      coordinator().afterSuccessfulRecord(
        screen,
        recordKey: 'record:4',
        owner: 'guest',
        isIdle: () => false,
      ),
    );
    expect(requests, 0);
  });
  testWidgets('background and resume during the delay cancels this prompt', (
    tester,
  ) async {
    await home(tester);
    final pending = coordinator().afterSuccessfulRecord(
      screen,
      recordKey: 'record:3',
      owner: 'guest',
    );
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await finish(tester, pending);
    expect(requests, 0);
  });
  testWidgets('account changes cancel pending requests', (tester) async {
    await home(tester);
    final pending = coordinator().afterSuccessfulRecord(
      screen,
      recordKey: 'record:3',
      owner: 'guest',
    );
    await tester.pump();
    owner = 'different-account';
    await finish(tester, pending);
    expect(requests, 0);
  });
  testWidgets(
    'unavailable OS and debug-disabled requests do not consume quota',
    (tester) async {
      await home(tester);
      await finish(
        tester,
        coordinator(
          available: false,
        ).afterSuccessfulRecord(screen, recordKey: 'record:3', owner: 'guest'),
      );
      await finish(
        tester,
        coordinator(
          enabled: false,
        ).afterSuccessfulRecord(screen, recordKey: 'record:4', owner: 'guest'),
      );
      expect(requests, 0);
      expect(prefs.getString(ReviewRequestPolicy.historyKey), isNull);
    },
  );
  testWidgets(
    'manual review during a pending automatic request suppresses the automatic request',
    (tester) async {
      await home(tester);
      final c = coordinator();
      final pending = c.afterSuccessfulRecord(
        screen,
        recordKey: 'record:3',
        owner: 'guest',
      );
      await tester.pump();
      await c.recordManualRequest();
      await finish(tester, pending);
      expect(requests, 0);
    },
  );
  testWidgets(
    'concurrent completions and an ambiguous provider error do not repeatedly prompt',
    (tester) async {
      await home(tester);
      final c = coordinator(fail: true);
      final one = c.afterSuccessfulRecord(
        screen,
        recordKey: 'record:3',
        owner: 'guest',
      );
      final two = c.afterSuccessfulRecord(
        screen,
        recordKey: 'record:4',
        owner: 'guest',
      );
      await finish(tester, two);
      await one;
      expect(requests, 1);
      await finish(
        tester,
        c.afterSuccessfulRecord(screen, recordKey: 'record:5', owner: 'guest'),
      );
      expect(requests, 1);
    },
  );
}
