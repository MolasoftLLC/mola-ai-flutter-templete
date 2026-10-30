import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/sake_stamp_store.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_stamp_repository.dart';

CollectedSakeStamp stamp(int id) => CollectedSakeStamp(
  brandId: id,
  sakeId: id + 100,
  prefectureCode: 6,
  source: 'analyzed_detail',
  observedAt: DateTime.utc(2026, 10, 30),
);

class Cloud implements SakeStampRemote {
  final accounts = <String, Map<int, CollectedSakeStamp>>{};
  bool offline = false;
  Completer<void>? pause;
  int uploads = 0;
  @override
  Future<List<CollectedSakeStamp>> fetch(String uid) async {
    if (offline) throw StateError('offline');
    if (pause != null) await pause!.future;
    return (accounts[uid] ?? {}).values.toList();
  }

  @override
  Future<List<CollectedSakeStamp>> upload(
    String uid,
    List<CollectedSakeStamp> stamps,
  ) async {
    if (offline) throw StateError('offline');
    uploads++;
    expect(stamps.length, lessThanOrEqualTo(100));
    final collection = accounts.putIfAbsent(uid, () => {});
    for (final s in stamps) {
      collection.putIfAbsent(s.brandId, () => s);
    }
    return stamps;
  }
}

Future<void> settle(SakeStampStore s) async {
  await s.ready;
  await s.sync();
  await Future<void>.delayed(Duration.zero);
  await s.sync();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'legacy local stamps migrate; another empty device restores the union silently',
    () async {
      final old = SakeStampStore(accountId: 'A');
      await old.acquire(stamp(1), isCurrent: () => true);
      old.dispose();
      final cloud = Cloud()..accounts['A'] = {2: stamp(2)};
      final first = SakeStampStore(accountId: 'A', remote: cloud);
      await settle(first);
      expect(first.brandIdsByPrefecture[6], {1, 2});
      expect(cloud.accounts['A']!.keys.toSet(), {1, 2});
      first.dispose();
      SharedPreferences.setMockInitialValues({}); // new device / reinstall
      final second = SakeStampStore(accountId: 'A', remote: cloud);
      addTearDown(second.dispose);
      await settle(second);
      expect(second.brandIdsByPrefecture[6], {1, 2});
      expect(second.presenting, false);
      expect(await second.acquire(stamp(1), isCurrent: () => true), false);
    },
  );
  test(
    'offline awards survive restart and retry without erasing cloud awards',
    () async {
      final cloud = Cloud()..offline = true;
      final s = SakeStampStore(accountId: 'A', remote: cloud);
      expect(await s.acquire(stamp(3), isCurrent: () => true), true);
      await settle(s);
      expect(s.syncFailed, true);
      s.dispose();
      cloud.offline = false;
      final restarted = SakeStampStore(accountId: 'A', remote: cloud);
      addTearDown(restarted.dispose);
      await settle(restarted);
      expect(restarted.syncFailed, false);
      expect(cloud.accounts['A']!.containsKey(3), true);
    },
  );
  test(
    'guest and account B never receive account A; disposed requests cannot notify',
    () async {
      final cloud = Cloud()
        ..accounts['A'] = {4: stamp(4)}
        ..pause = Completer<void>();
      final a = SakeStampStore(accountId: 'A', remote: cloud);
      await a.ready;
      await Future<void>.delayed(Duration.zero);
      a.dispose();
      cloud.pause!.complete();
      cloud.pause = null;
      final b = SakeStampStore(accountId: 'B', remote: cloud);
      final guest = SakeStampStore(remote: cloud);
      addTearDown(b.dispose);
      addTearDown(guest.dispose);
      await settle(b);
      await settle(guest);
      expect(b.contains(4), false);
      expect(guest.contains(4), false);
    },
  );
  test(
    'more than 100 existing awards are uploaded in bounded batches',
    () async {
      final local = SakeStampStore(accountId: 'A');
      await local.ready;
      final key = local.storageKey;
      local.dispose();
      SharedPreferences.setMockInitialValues({
        key: List.generate(205, (i) => jsonEncode(stamp(i + 1).toJson())),
      });
      final cloud = Cloud();
      final s = SakeStampStore(accountId: 'A', remote: cloud);
      addTearDown(s.dispose);
      await settle(s);
      expect(cloud.accounts['A']!.length, 205);
      expect(cloud.uploads, 3);
    },
  );
  test(
    'account deletion clears only its local cache and stops future uploads',
    () async {
      final cloud = Cloud();
      final s = SakeStampStore(accountId: 'A', remote: cloud);
      addTearDown(s.dispose);
      await s.acquire(stamp(3), isCurrent: () => true);
      await settle(s);
      final key = s.storageKey;
      await s.clearDeletedAccount('B');
      expect(s.contains(3), true);
      await s.clearDeletedAccount('A');
      expect(s.contains(3), false);
      expect(
        (await SharedPreferences.getInstance()).getStringList(key),
        isNull,
      );
      final count = cloud.uploads;
      await s.sync();
      expect(cloud.uploads, count);
      expect(await s.acquire(stamp(4), isCurrent: () => true), false);
    },
  );
  test('a new award during restore is retained and uploaded', () async {
    final cloud = Cloud()..pause = Completer<void>();
    final s = SakeStampStore(accountId: 'A', remote: cloud);
    addTearDown(s.dispose);
    await s.ready;
    expect(await s.acquire(stamp(8), isCurrent: () => true), true);
    cloud.pause!.complete();
    cloud.pause = null;
    await settle(s);
    expect(cloud.accounts['A']!.containsKey(8), true);
  });
}
