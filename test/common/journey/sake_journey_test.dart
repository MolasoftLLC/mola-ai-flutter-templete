import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/common/journey/sake_journey.dart';

void main() {
  test('guide uses existing server-accepted analytics targets', () {
    expect(SakeJourneyStore.target('preference'), 'profile_edit');
    expect(SakeJourneyStore.target('like'), 'favorite');
    expect(SakeJourneyStore.target('diagnosis'), 'profile');
    expect(SakeJourneyStore.target('scan'), 'scan');
    expect(SakeJourneyStore.target('complete'), 'home_recommendations');
  });

  test(
    'next action reflects unset, zero, one, eligible, diagnosed and completed states',
    () {
      expect(const JourneySnapshot().action(0), JourneyAction.preference);
      expect(
        const JourneySnapshot(steps: {JourneyStep.preference}).action(0),
        JourneyAction.firstLike,
      );
      expect(
        const JourneySnapshot(
          steps: {JourneyStep.preference, JourneyStep.like},
        ).action(1),
        JourneyAction.moreLikes,
      );
      expect(
        const JourneySnapshot(
          steps: {JourneyStep.preference, JourneyStep.like},
        ).action(favoriteDiagnosisMinimum),
        JourneyAction.diagnosis,
      );
      expect(
        const JourneySnapshot(
          steps: {
            JourneyStep.preference,
            JourneyStep.like,
            JourneyStep.diagnosis,
          },
        ).action(2),
        JourneyAction.scan,
      );
      expect(
        JourneySnapshot(steps: JourneyStep.values.toSet()).action(2),
        JourneyAction.complete,
      );
    },
  );
  test('snooze persists for seven days and is isolated per account', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime(2026, 11, 7);
    final store = SakeJourneyStore();
    await store.dismiss('one', now: now);
    final restored = await SakeJourneyStore().load('one');
    expect(restored.visible(now.add(const Duration(days: 6))), isFalse);
    expect(restored.visible(now.add(const Duration(days: 7))), isTrue);
    expect((await store.load('two')).visible(now), isTrue);
    expect((await store.load('guest')).visible(now), isTrue);
  });
  test('permanent hide survives new milestones and expiry', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SakeJourneyStore();
    await store.dismiss('one', forever: true);
    await store.complete('one', JourneyStep.scan);
    expect((await store.load('one')).visible(DateTime(2040)), isFalse);
  });
  test(
    'existing achievements and out-of-order steps merge without losing concurrent writes',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = SakeJourneyStore();
      await Future.wait([
        store.complete('one', JourneyStep.scan),
        store.complete('one', JourneyStep.diagnosis),
        store.reconcile('one', preference: true, likes: 2, scan: false),
      ]);
      expect(
        (await SakeJourneyStore().load('one')).steps,
        JourneyStep.values.toSet(),
      );
      await store.reconcile('one', preference: false, likes: 0, scan: false);
      expect((await store.load('one')).steps.length, 4);
    },
  );
  test(
    'completion is shown only once after acknowledgement; other accounts are not affected',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = SakeJourneyStore();
      for (final step in JourneyStep.values) {
        await store.complete('one', step);
      }
      expect((await store.load('one')).visible(DateTime.now()), isTrue);
      await store.acknowledgeCompletion('one');
      expect(
        (await SakeJourneyStore().load('one')).visible(DateTime.now()),
        isFalse,
      );
      expect((await store.load('two')).completionSeen, isFalse);
    },
  );
  test(
    'corrupted state recovers and repairs independently for each account',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = SakeJourneyStore();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(store.key('one'), 'broken');
      expect((await store.load('one')).steps, isEmpty);
      await store.complete('one', JourneyStep.preference);
      expect((await store.load('one')).steps, {JourneyStep.preference});
    },
  );
}
