import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/venue_favorites_repository.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/venue_favorites_controller.dart';

const venue = MapVenue(
  venueId: 'v1',
  displayName: '日本酒のお店',
  latitude: 35,
  longitude: 139,
  sakeCount: 3,
  recordCount: 4,
  providerPlaceId: 'google-place',
);
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  test('保存成功後だけ星を更新し連打による重複保存を防ぐ', () async {
    final store = MemoryStore()..pending = Completer<void>();
    final controller = VenueFavoritesController(store: store, accountId: 'a');
    await settle();
    final saving = controller.toggle(venue);
    expect(controller.isSaving, true);
    expect(controller.isFavorite('v1'), false);
    expect(await controller.toggle(venue), false);
    store.pending!.complete();
    expect(await saving, true);
    expect(controller.venues, hasLength(1));
    store.pending = null;
    expect(await controller.toggle(venue), true);
    expect(controller.venues, isEmpty);
    controller.dispose();
  });

  test('保存失敗は星の成功表示にせず既存一覧を保つ', () async {
    final store = MemoryStore()
      ..data['a'] = [venue]
      ..failSave = true;
    final controller = VenueFavoritesController(store: store, accountId: 'a');
    await settle();
    expect(await controller.toggle(venue), false);
    expect(controller.isFavorite('v1'), true);
    expect(controller.isSaving, false);
    controller.dispose();
  });

  test('読込失敗中は空の一覧で保存済みデータを上書きしない', () async {
    final store = MemoryStore()..failLoad = true;
    final controller = VenueFavoritesController(store: store);
    await settle();
    expect(controller.errorMessage, isNotNull);
    expect(await controller.toggle(venue), false);
    expect(store.writes, 0);
    store.failLoad = false;
    await controller.reload();
    expect(controller.errorMessage, isNull);
    expect(await controller.toggle(venue), true);
    controller.dispose();
  });

  test('保存中にアカウントを切り替えても旧一覧が新アカウントに出ない', () async {
    final accounts = StreamController<String?>.broadcast(sync: true);
    final store = MemoryStore()..pending = Completer<void>();
    final controller = VenueFavoritesController(
      store: store,
      accountId: 'a',
      accountChanges: accounts.stream,
    );
    await settle();
    final saving = controller.toggle(venue);
    accounts.add('b');
    expect(controller.venues, isEmpty);
    store.pending!.complete();
    expect(await saving, false);
    await settle();
    expect(controller.venues, isEmpty);
    expect(store.data['a']!.single.venueId, 'v1');
    accounts.add('a');
    await settle();
    expect(controller.venues.single.venueId, 'v1');
    controller.dispose();
    await accounts.close();
  });

  test('読み込み完了前に閉じても破棄後の通知を行わない', () async {
    final store = MemoryStore()..loadPending = Completer<void>();
    final controller = VenueFavoritesController(store: store);
    controller.dispose();
    store.loadPending!.complete();
    await settle();
  });
}

class MemoryStore implements VenueFavoritesStore {
  final data = <String?, List<MapVenue>>{};
  bool failSave = false, failLoad = false;
  int writes = 0;
  Completer<void>? pending, loadPending;
  @override
  Future<List<MapVenue>> load(String? id) async {
    await loadPending?.future;
    if (failLoad) throw StateError('load');
    return List.of(data[id] ?? []);
  }

  @override
  Future<void> save(String? id, List<MapVenue> venues) async {
    writes++;
    await pending?.future;
    if (failSave) throw StateError('save');
    data[id] = List.of(venues);
  }
}
