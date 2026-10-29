import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/menu_analysis_history_repository.dart';

Response page(List<MenuAnalysisHistoryItem> items, {String? cursor}) =>
    Response(http.Response('', 200), {
      'histories': items
          .map(
            (item) => {'id': item.id, 'deleted': false, 'item': item.toJson()},
          )
          .toList(),
      'nextCursor': cursor,
    });

class PageApi implements ApiClient {
  PageApi(this.fetch);
  Future<Response> Function(String, String?) fetch;
  List<MenuAnalysisHistoryItem> serverItems = [];
  @override
  Future<Response> fetchMenuAnalysisHistory(String ownerUid) async =>
      page(serverItems);
  @override
  Future<Response> saveMenuAnalysisHistoryItem(
    String id,
    Map<String, dynamic> body,
  ) async {
    serverItems.removeWhere((item) => item.id == id);
    if (body['deleted'] != true) {
      serverItems.add(
        MenuAnalysisHistoryItem.fromJson(
          Map<String, dynamic>.from(body['item'] as Map),
        ),
      );
    }
    return Response(http.Response('', 200), const <String, dynamic>{});
  }

  @override
  Future<Response> fetchMenuAnalysisHistoryPage(
    String ownerUid, {
    String? cursor,
  }) => fetch(ownerUid, cursor);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory temp;
  late MenuAnalysisHistoryRepository store;
  MenuAnalysisHistoryItem item(String id) => MenuAnalysisHistoryItem(
    id: id,
    date: DateTime.utc(2026, 10, 29),
    base64Image: base64Encode([1, 2, 3]),
    sakes: [SavedSake(name: '正雪', sakeId: 42, matchPercent: 80)],
  );
  setUp(() async {
    temp = await Directory.systemTemp.createTemp('menu-page-');
    store = MenuAnalysisHistoryRepository(
      directoryProvider: () async => temp,
      legacyReader: () async => null,
      legacyClearer: () async {},
      ownerId: 'owner',
    );
  });
  tearDown(() => temp.delete(recursive: true));

  test(
    'default retention keeps all 45 histories across restart and replacement, including dates/photos',
    () async {
      for (var i = 0; i < 45; i++) {
        await store.upsert(item('item-$i'));
      }
      expect(await store.load(), hasLength(45));
      await store.replaceAll(await store.load());
      final restarted = MenuAnalysisHistoryRepository(
        directoryProvider: () async => temp,
        legacyReader: () async => null,
        legacyClearer: () async {},
        ownerId: 'owner',
      );
      expect(await restarted.load(), hasLength(45));
    },
  );

  test(
    'pages beyond 20, merges duplicates by ID and restores cloud images without queuing uploads',
    () async {
      var calls = 0;
      final api = PageApi((owner, cursor) async {
        expect(owner, 'owner');
        calls++;
        if (cursor == null) {
          return page(List.generate(20, (i) => item('a-$i')), cursor: 'next');
        }
        expect(cursor, 'next');
        return page([item('a-0'), ...List.generate(25, (i) => item('b-$i'))]);
      });
      expect(await store.fetchPage(api, () => true), 'next');
      expect(await store.fetchPage(api, () => true, cursor: 'next'), isNull);
      final all = await store.load();
      expect(all, hasLength(45));
      expect(calls, 2);
      expect(
        all.every(
          (i) => i.base64Image == null && File(i.imagePath!).existsSync(),
        ),
        isTrue,
      );
      expect(
        File(
          '${temp.path}/menu_analysis_history_v2/accounts/owner/.cloud_outbox.json',
        ).existsSync(),
        isFalse,
      );
    },
  );

  test(
    'a page in flight cannot undo a local place edit/deletion; coordinates and other fields persist',
    () async {
      final originals = [item('edit'), item('delete')];
      await store.fetchPage(
        PageApi((_, __) async => page(originals)),
        () => true,
      );
      final previous = (await store.load()).firstWhere((i) => i.id == 'edit');
      final response = Completer<Response>();
      final requested = Completer<void>();
      final inFlight = store.fetchPage(
        PageApi((_, __) {
          requested.complete();
          return response.future;
        }),
        () => true,
      );
      await requested.future;
      const place = DrinkingPlace(
        displayName: '変更後の店舗',
        providerPlaceId: 'google-2',
        latitude: 35.1,
        longitude: 135.2,
        formattedAddress: '京都府',
      );
      await store.upsert(
        previous.copyWith(storeName: place.displayName, drinkingPlace: place),
      );
      await store.delete('delete');
      response.complete(page(originals));
      await inFlight;
      final saved = (await store.load()).single;
      expect(saved.id, 'edit');
      expect(saved.date, previous.date);
      expect(saved.imagePath, previous.imagePath);
      expect(saved.sakes.single.toJson(), previous.sakes.single.toJson());
      expect(saved.drinkingPlace, place);
      final outbox =
          jsonDecode(
                await File(
                  '${temp.path}/menu_analysis_history_v2/accounts/owner/.cloud_outbox.json',
                ).readAsString(),
              )
              as Map;
      expect(outbox['edit']['item']['drinkingPlace']['latitude'], 35.1);
      expect(outbox['delete']['deleted'], true);
    },
  );

  test(
    'a stale page cannot undo an edit after its outbox has already uploaded',
    () async {
      final old = item('edited');
      await store.fetchPage(PageApi((_, __) async => page([old])), () => true);
      final response = Completer<Response>();
      final requested = Completer<void>();
      final reading = store.fetchPage(
        PageApi((_, __) {
          requested.complete();
          return response.future;
        }),
        () => true,
      );
      await requested.future;
      const place = DrinkingPlace(
        displayName: '同期済み店舗',
        latitude: 35,
        longitude: 135,
      );
      final previous = (await store.load()).single;
      // Avoid image compression in this test; photo persistence is covered above.
      await store.upsert(
        previous.copyWith(
          clearImagePath: true,
          drinkingPlace: place,
          storeName: place.displayName,
        ),
      );
      final sync = PageApi((_, __) async => page([]))..serverItems = [old];
      await store.synchronize(sync, () => true);
      final outbox =
          jsonDecode(
                await File(
                  '${temp.path}/menu_analysis_history_v2/accounts/owner/.cloud_outbox.json',
                ).readAsString(),
              )
              as Map;
      expect(outbox, isEmpty);
      response.complete(page([old]));
      await reading;
      expect((await store.load()).single.drinkingPlace, place);
    },
  );

  test(
    'owner changes discard responses and request failures remain retryable',
    () async {
      var owner = true;
      final response = Completer<Response>();
      final requested = Completer<void>();
      final inFlight = store.fetchPage(
        PageApi((_, __) {
          requested.complete();
          return response.future;
        }),
        () => owner,
      );
      await requested.future;
      owner = false;
      response.complete(page([item('private')]));
      await inFlight;
      expect(await store.load(), isEmpty);
      await expectLater(
        store.fetchPage(
          PageApi((_, __) async => Response(http.Response('', 503), null)),
          () => true,
        ),
        throwsStateError,
      );
      expect(
        await store.fetchPage(
          PageApi((_, __) async => page([item('retried')])),
          () => true,
        ),
        isNull,
      );
      expect((await store.load()).single.id, 'retried');
      await expectLater(
        store.fetchPage(
          PageApi((_, __) async => page([], cursor: 'same')),
          () => true,
          cursor: 'same',
        ),
        throwsStateError,
      );
    },
  );
}
