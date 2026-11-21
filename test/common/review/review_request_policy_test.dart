import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/common/review/review_request_policy.dart';

void main() {
  late SharedPreferences prefs;
  late ReviewRequestPolicy policy;
  final start = DateTime(2026, 11, 21, 12);
  Future<void> qualify(String owner) async {
    await policy.recordSuccess(owner, 'record:1', start);
    await policy.recordSuccess(owner, 'record:2', start);
    await policy.recordSuccess(
      owner,
      'record:3',
      start.add(const Duration(days: 1)),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    policy = ReviewRequestPolicy(prefs);
  });
  test(
    'three distinct saved records and two active days are required',
    () async {
      expect(policy.canRequest('guest', '5.0.60', start), false);
      for (var i = 0; i < 3; i++) {
        await policy.recordSuccess('guest', 'record:$i', start);
      }
      expect(policy.canRequest('guest', '5.0.60', start), false);
      await policy.recordSuccess(
        'guest',
        'record:3',
        start.add(const Duration(days: 1)),
      );
      expect(
        policy.canRequest(
          'guest',
          '5.0.60',
          start.add(const Duration(days: 1)),
        ),
        true,
      );
    },
  );
  test(
    'crossing midnight alone does not count as sufficient experience',
    () async {
      final late = DateTime(2026, 11, 21, 23, 59);
      await policy.recordSuccess('guest', 'record:1', late);
      await policy.recordSuccess('guest', 'record:2', late);
      await policy.recordSuccess(
        'guest',
        'record:3',
        late.add(const Duration(minutes: 2)),
      );
      expect(
        policy.canRequest(
          'guest',
          '5.0.60',
          late.add(const Duration(minutes: 2)),
        ),
        false,
      );
      expect(
        policy.canRequest('guest', '5.0.60', late.add(const Duration(days: 1))),
        true,
      );
    },
  );
  test('repeated edits cannot create new milestones or active days', () async {
    for (var i = 0; i < 5; i++) {
      await policy.recordSuccess(
        'guest',
        'record:1',
        start.add(Duration(days: i)),
      );
    }
    expect(
      policy.canRequest('guest', '5.0.60', start.add(const Duration(days: 5))),
      false,
    );
  });
  test(
    'progress persists across restarts and does not cross accounts',
    () async {
      await qualify('account-A');
      policy = ReviewRequestPolicy(prefs);
      expect(
        policy.canRequest(
          'account-A',
          '5.0.60',
          start.add(const Duration(days: 1)),
        ),
        true,
      );
      expect(
        policy.canRequest(
          'account-B',
          '5.0.60',
          start.add(const Duration(days: 1)),
        ),
        false,
      );
      expect(prefs.getKeys().any((key) => key.contains('account-A')), false);
      expect(
        prefs.getKeys().any(
          (key) => (prefs.getString(key) ?? '').contains('record:1'),
        ),
        false,
      );
    },
  );
  test(
    '90 day cooldown, one per version, and device-wide suppression after manual review',
    () async {
      await qualify('guest');
      final attempt = start.add(const Duration(days: 1));
      await policy.recordRequest('5.0.60', attempt);
      expect(
        policy.canRequest(
          'guest',
          '5.0.61',
          attempt.add(const Duration(days: 89)),
        ),
        false,
      );
      expect(
        policy.canRequest(
          'guest',
          '5.0.60',
          attempt.add(const Duration(days: 100)),
        ),
        false,
      );
      expect(
        policy.canRequest(
          'guest',
          '5.0.61',
          attempt.add(const Duration(days: 90)),
        ),
        true,
      );
      await qualify('another-account');
      expect(
        policy.canRequest(
          'another-account',
          '5.0.61',
          attempt.add(const Duration(days: 2)),
        ),
        false,
      );
    },
  );
  test(
    'at most three attempts in a rolling year and backwards clock suppresses requests',
    () async {
      await qualify('guest');
      for (var i = 0; i < 3; i++) {
        await policy.recordRequest('v$i', start.add(Duration(days: i * 91)));
      }
      expect(
        policy.canRequest('guest', 'v3', start.add(const Duration(days: 273))),
        false,
      );
      expect(
        policy.canRequest('guest', 'v3', start.add(const Duration(days: 366))),
        true,
      );
      expect(
        policy.canRequest(
          'guest',
          'v3',
          start.subtract(const Duration(days: 1)),
        ),
        false,
      );
    },
  );
  test(
    'corrupt request history fails closed instead of silently resetting quota',
    () async {
      await qualify('guest');
      await prefs.setString(
        ReviewRequestPolicy.historyKey,
        jsonEncode([
          {'version': 'old', 'at': 'bad-date'},
        ]),
      );
      expect(
        () => policy.canRequest(
          'guest',
          'v3',
          start.add(const Duration(days: 1)),
        ),
        throwsFormatException,
      );
    },
  );
}
