import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/sake_stamp_store.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_catalog_browse.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

const profile = SakeTasteProfileDetails(
  fruity: .5,
  sweetness: .5,
  acidity: .5,
  umami: .5,
  kire: .5,
  dryness: .5,
  aroma: .5,
);
CollectedSakeStamp stamp(int brand, {String source = 'analyzed_detail'}) =>
    CollectedSakeStamp(
      brandId: brand,
      prefectureCode: 6,
      sakeId: 100 + brand,
      source: source,
      observedAt: DateTime.utc(2026, 10, 30),
    );

class _FailedWrites implements SharedPreferences {
  @override
  List<String>? getStringList(String key) => [];
  @override
  Future<bool> setStringList(String key, List<String> value) async => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('同銘柄の詳細・記録が同時に完了しても1回だけ取得し、再起動後にも残る', () async {
    final store = SakeStampStore(accountId: 'A');
    addTearDown(store.dispose);
    final acquired = await Future.wait([
      store.acquire(stamp(1), isCurrent: () => true),
      store.acquire(stamp(1, source: 'personal_record'), isCurrent: () => true),
    ]);
    expect(acquired, [true, false]);
    expect(store.brandIdsByPrefecture, {
      6: {1},
    });
    final restored = SakeStampStore(accountId: 'A');
    addTearDown(restored.dispose);
    await restored.ready;
    expect(restored.contains(1), true);
    expect(await restored.acquire(stamp(1), isCurrent: () => true), false);
  });
  test('ゲストと各アカウントの取得履歴を混ぜない', () async {
    final a = SakeStampStore(accountId: 'A'),
        b = SakeStampStore(accountId: 'B'),
        guest = SakeStampStore();
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    addTearDown(guest.dispose);
    await a.acquire(stamp(1), isCurrent: () => true);
    await b.ready;
    await guest.ready;
    expect(b.contains(1), false);
    expect(guest.contains(1), false);
    expect({a.storageKey, b.storageKey, guest.storageKey}.length, 3);
  });
  test('既存記録を静かに継承し、異なる商品でも同銘柄なら重複しない', () async {
    final s = SakeStampStore();
    addTearDown(s.dispose);
    await s.inheritRecords(const [
      SakeProductOrigin(
        sakeId: 1,
        canonicalSakeId: 1,
        brandId: 10,
        prefectureCode: 6,
      ),
      SakeProductOrigin(
        sakeId: 2,
        canonicalSakeId: 2,
        brandId: 10,
        prefectureCode: 6,
      ),
    ], isCurrent: () => true);
    expect(s.brandIdsByPrefecture, {
      6: {10},
    });
    expect(await s.acquire(stamp(10), isCurrent: () => true), false);
  });
  test('保存失敗では取得を確定せず、失効した画面・不明産地も付与しない', () async {
    final s = SakeStampStore(preferences: () async => _FailedWrites());
    addTearDown(s.dispose);
    expect(await s.acquire(stamp(1), isCurrent: () => true), false);
    expect(s.contains(1), false);
    final other = SakeStampStore();
    addTearDown(other.dispose);
    expect(await other.acquire(stamp(2), isCurrent: () => false), false);
    expect(
      await other.acquire(
        CollectedSakeStamp(
          brandId: 1,
          prefectureCode: 0,
          sakeId: 1,
          source: 'analyzed_detail',
          observedAt: DateTime.now(),
        ),
        isCurrent: () => true,
      ),
      false,
    );
  });
  test('読み込み失敗では未知の保存履歴を上書きしない', () async {
    final s = SakeStampStore(
      preferences: () => Future.error(StateError('unavailable')),
    );
    addTearDown(s.dispose);
    await s.ready;
    expect(await s.acquire(stamp(1), isCurrent: () => true), false);
    expect(s.brandIdsByPrefecture, isEmpty);
  });
  test('壊れた行を飛ばし有効な取得履歴を保つ', () async {
    final key = SakeStampStore().storageKey;
    SharedPreferences.setMockInitialValues({
      key: ['broken', jsonEncode(stamp(7).toJson())],
    });
    final s = SakeStampStore();
    addTearDown(s.dispose);
    await s.ready;
    expect(s.contains(7), true);
  });
  test('ロード中の破棄は通知・取得を発生させない', () async {
    final loading = Completer<SharedPreferences>();
    final s = SakeStampStore(preferences: () => loading.future);
    s.dispose();
    loading.complete(await SharedPreferences.getInstance());
    await s.ready;
    expect(await s.acquire(stamp(1), isCurrent: () => true), false);
  });
  test('詳細成功は説明・有効プロフィールが必要で、partial・failed・idle・runningは対象外', () {
    SakeOverview overview({
      String? status,
      bool pending = false,
      bool analyzed = true,
      bool description = true,
      bool taste = true,
    }) => SakeOverview(
      sake: Sake(sakeId: 1, description: description ? '商品説明' : null),
      analysisCompleted: analyzed,
      lensDetailAnalysisStatus: status,
      masterEnrichmentPending: pending,
      master: SakeMasterDetails(tasteProfile: taste ? profile : null),
    );
    expect(isStampEligibleOverview(overview()), true);
    expect(isStampEligibleOverview(overview(status: 'completed')), true);
    for (final status in ['partial', 'failed', 'idle', 'running']) {
      expect(isStampEligibleOverview(overview(status: status)), false);
    }
    expect(isStampEligibleOverview(overview(pending: true)), false);
    expect(isStampEligibleOverview(overview(analyzed: false)), false);
    expect(isStampEligibleOverview(overview(description: false)), false);
    expect(isStampEligibleOverview(overview(taste: false)), false);
  });
}
