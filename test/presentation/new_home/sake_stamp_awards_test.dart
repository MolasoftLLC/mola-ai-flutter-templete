import 'dart:async';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/domain/repository/auth_repository.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/auth/auth_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/sake_master_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_catalog_browse.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/sake_stamp_store.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/saved_sake/saved_sake_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_stamp_awards.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_stamp_acquisition_demo.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_journey_progress.dart';

class _Catalog extends PlaceMapRepository {
  _Catalog() : super(ApiClient.create());
  Completer<List<SakeProductOrigin>>? pending;
  @override
  Future<List<SakeProductOrigin>> fetchSakeOrigins(List<int> ids) async =>
      pending?.future ??
      [
        for (final id in ids)
          SakeProductOrigin(
            sakeId: id,
            canonicalSakeId: id,
            brandId: 11,
            prefectureCode: 6,
          ),
      ];
  @override
  Future<SakeCatalogPage<SakeBrandSummary>> fetchPrefectureBrands(
    int code, {
    int? afterId,
  }) async => const SakeCatalogPage(
    items: [
      SakeBrandSummary(
        brandId: 11,
        name: '出羽桜',
        brewery: '出羽桜酒造',
        productCount: 2,
      ),
    ],
  );
}

SakeOverview overview({String? status}) => SakeOverview(
  sake: const Sake(sakeId: 123, brandId: 11, description: '商品固有の説明'),
  analysisCompleted: true,
  lensDetailAnalysisStatus: status,
  brand: const SakeBrandDetails(id: 11, name: '出羽桜'),
  brewery: const SakeBreweryDetails(prefectureCode: '06'),
  master: const SakeMasterDetails(
    tasteProfile: SakeTasteProfileDetails(
      fruity: .5,
      sweetness: .5,
      acidity: .5,
      umami: .5,
      kire: .5,
      dryness: .5,
      aroma: .5,
    ),
  ),
);
void main() {
  setUpAll(loggerConfigure);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  late BuildContext screen;
  Future<void> open(
    WidgetTester tester,
    SakeStampStore store, {
    _Catalog? repo,
    List<Sake> records = const [],
  }) async {
    await store.ready;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: store),
          Provider<PlaceMapRepository>.value(value: repo ?? _Catalog()),
          Provider<SavedSakeState>.value(
            value: SavedSakeState(savedSakeList: records),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) {
              screen = context;
              return const Scaffold(body: Text('detail'));
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final scanId in <int?>[null, 0, 999]) {
    testWidgets('閲覧のみ・別商品では解析済みでも付与しない: $scanId', (tester) async {
      final store = SakeStampStore();
      addTearDown(store.dispose);
      await open(tester, store);
      await SakeStampAwardSession.detail(
        screen,
        overview(),
        scannedSakeId: scanId,
      );
      await tester.pumpAndSettle();
      expect(store.contains(11), isFalse);
      expect(find.byType(SakeStampAcquisitionDemo), findsNothing);
    });
  }

  testWidgets('解析済み詳細から実際の銘柄・県の酒印を1回だけ付与し、飲んだ件数は増えない', (tester) async {
    final s = SakeStampStore(accountId: 'A');
    addTearDown(s.dispose);
    await open(tester, s);
    final award = SakeStampAwardSession.detail(
      screen,
      overview(),
      scannedSakeId: 123,
    );
    await tester.pumpAndSettle();
    expect(s.contains(11), true);
    expect(find.byType(SakeStampAcquisitionDemo), findsOneWidget);
    expect(find.text('出羽桜  ·  山形県'), findsOneWidget);
    expect(find.text('一杯の出会いを、日々の思い出に'), findsOneWidget);
    expect(find.textContaining('デモのため'), findsNothing);
    expect(find.byKey(const ValueKey('replay-stamp-demo')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('close-stamp-demo')));
    await tester.pumpAndSettle();
    await award;
    await SakeStampAwardSession.detail(screen, overview(), scannedSakeId: 123);
    await tester.pumpAndSettle();
    expect(find.byType(SakeStampAcquisitionDemo), findsNothing);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: s,
        child: Provider<PlaceMapRepository>.value(
          value: _Catalog(),
          child: const MaterialApp(home: Scaffold(body: _Progress())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('drink:0 stamp:1'), findsOneWidget);
  });
  testWidgets('解析の失敗・途中状態、保存だけでは付与しない', (tester) async {
    final s = SakeStampStore();
    addTearDown(s.dispose);
    await open(tester, s, records: [const Sake(sakeId: 123)]);
    for (final status in ['partial', 'failed', 'idle', 'running']) {
      await SakeStampAwardSession.detail(
        screen,
        overview(status: status),
        scannedSakeId: 123,
      );
    }
    final session = await SakeStampAwardSession.prepare(screen);
    await session!.record(screen, const Sake(sakeId: 123));
    await tester.pumpAndSettle();
    expect(s.contains(11), false);
    expect(find.byType(SakeStampAcquisitionDemo), findsNothing);
  });
  testWidgets('既存の飲んだ記録は演出せず引き継ぎ、別商品でも重複しない', (tester) async {
    final s = SakeStampStore();
    addTearDown(s.dispose);
    await open(
      tester,
      s,
      records: [const Sake(sakeId: 124, impression: '以前の記録')],
    );
    await SakeStampAwardSession.detail(screen, overview(), scannedSakeId: 123);
    await tester.pumpAndSettle();
    expect(s.contains(11), true);
    expect(find.byType(SakeStampAcquisitionDemo), findsNothing);
  });
  testWidgets('保存成功後の記録は未解析でも付与する。キャンセルは付与しない', (tester) async {
    final s = SakeStampStore();
    addTearDown(s.dispose);
    await open(tester, s);
    final session = await SakeStampAwardSession.prepare(screen);
    expect(s.contains(11), false);
    final award = session!.record(
      screen,
      const Sake(sakeId: 123, impression: '飲んだ記録'),
    );
    await tester.pumpAndSettle();
    expect(s.contains(11), true);
    expect(find.byType(SakeStampAcquisitionDemo), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-stamp-demo')));
    await tester.pumpAndSettle();
    await award;
  });
  for (final fail in [false, true]) {
    testWidgets('記録編集シートの${fail ? '保存失敗では付与しない' : '保存成功後に酒印を付与する'}', (
      tester,
    ) async {
      final store = SakeStampStore();
      await store.ready;
      addTearDown(store.dispose);
      final saved = _RecordNotifier()..read = (<T>() => _Guest() as T);
      addTearDown(saved.dispose);
      await tester.pump();
      const record = Sake(
        savedId: 'record-1',
        sakeId: 123,
        name: '出羽桜',
        isBookmarked: false,
      );
      await saved.addSavedSake(record);
      saved.fail = fail;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: store),
            Provider<SavedSakeState>.value(value: saved.state),
            Provider<PlaceMapRepository>.value(value: _Catalog()),
            Provider<AuthState>.value(value: const AuthState()),
          ],
          child: MaterialApp(
            locale: const Locale('ja'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => showSakeRecordEditorSheet(
                    context,
                    notifier: saved,
                    sake: record,
                  ),
                  child: const Text('edit'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('edit'));
      await tester.pumpAndSettle();
      final memo = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.hintText == '香りや味、食事との相性を残す',
      );
      await tester.ensureVisible(memo);
      await tester.pumpAndSettle();
      await tester.enterText(memo, 'すっきりした味わい');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final save = find.text('記録を保存');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(store.contains(11), !fail);
      expect(
        find.byType(SakeStampAcquisitionDemo),
        fail ? findsNothing : findsOneWidget,
      );
      if (fail) {
        expect(find.textContaining('保存に失敗しました。'), findsOneWidget);
        expect(saved.savedSakes.single.impression, isNull);
      } else {
        expect(saved.savedSakes.single.impression, 'すっきりした味わい');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('演出中にアカウントが変わったら閉じ、別アカウントへ取得履歴を混ぜない', (tester) async {
    final first = SakeStampStore(accountId: 'A'),
        second = SakeStampStore(accountId: 'B');
    await first.ready;
    await second.ready;
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final scope = ValueNotifier(first);
    addTearDown(scope.dispose);
    await tester.pumpWidget(
      ValueListenableBuilder<SakeStampStore>(
        valueListenable: scope,
        builder: (_, store, __) => ChangeNotifierProvider.value(
          value: store,
          child: Provider<PlaceMapRepository>.value(
            value: _Catalog(),
            child: MaterialApp(
              locale: const Locale('ja'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Builder(
                builder: (context) {
                  screen = context;
                  return const Scaffold(body: Text('detail'));
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final award = SakeStampAwardSession.detail(
      screen,
      overview(),
      scannedSakeId: 123,
    );
    await tester.pumpAndSettle();
    expect(find.byType(SakeStampAcquisitionDemo), findsOneWidget);
    scope.value = second;
    await tester.pumpAndSettle();
    await award;
    expect(find.byType(SakeStampAcquisitionDemo), findsNothing);
    expect(first.contains(11), true);
    expect(second.contains(11), false);
    expect(tester.takeException(), isNull);
  });

  testWidgets('処理中に画面を離れた結果は付与しない', (tester) async {
    final s = SakeStampStore();
    addTearDown(s.dispose);
    final repo = _Catalog()..pending = Completer();
    await open(tester, s, repo: repo);
    final session = await SakeStampAwardSession.prepare(screen);
    final award = session!.record(
      screen,
      const Sake(sakeId: 123, impression: '記録'),
    );
    Navigator.of(screen).push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('other')),
      ),
    );
    await tester.pumpAndSettle();
    repo.pending!.complete(const [
      SakeProductOrigin(
        sakeId: 123,
        canonicalSakeId: 123,
        brandId: 11,
        prefectureCode: 6,
      ),
    ]);
    await award;
    await tester.pumpAndSettle();
    expect(s.contains(11), false);
  });
}

class _Progress extends StatelessWidget {
  const _Progress();
  @override
  Widget build(BuildContext context) => SakeJourneyProgressBuilder(
    includeEncounterStamps: true,
    builder: (_, p, __, ___) => Text(
      'drink:${p.counts.values.fold<int>(0, (a, b) => a + b)} stamp:${p.brandIdsByPrefecture.values.expand((ids) => ids).toSet().length}',
    ),
  );
}

class _Guest implements AuthRepository {
  @override
  get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordNotifier extends SavedSakeNotifier {
  bool fail = false;
  @override
  Future<void> updateSavedSake(Sake sake) async {
    if (fail) throw StateError('save failed');
    await super.updateSavedSake(sake);
  }
}
