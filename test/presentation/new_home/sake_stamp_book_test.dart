import 'dart:async';
import 'package:mola_gemini_flutter_template/domain/notifier/sake_stamp_store.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_stamp_preferences.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_catalog_browse.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/saved_sake/saved_sake_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/japan_sake_page.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/sake_stamp_book_page.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/prefecture_stamp_catalog.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/nationwide_stamp_catalog.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_stamp_collection_label.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_stamp_book.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/japan_sake_map.dart';

const _names = [
  '出羽桜',
  'くどき上手',
  '朝日鷹',
  '秀鳳',
  '栄光冨士',
  '上喜元',
  '十四代',
  '楯野川',
  '東光',
  '同名の銘柄',
  '同名の銘柄',
];
List<SakeBrandSummary> _brands(int start, int end) => [
  for (var i = start; i <= end; i++)
    SakeBrandSummary(
      brandId: i,
      name: _names[i - 1],
      brewery: i == 10 ? '酒造A' : '酒造B',
      productCount: 3,
    ),
];

class _Catalog extends PlaceMapRepository {
  _Catalog() : super(ApiClient.create());
  final cursors = <int?>[];
  final codes = <int>[];
  bool failMore = false;
  bool failFirst = false;
  @override
  Future<SakeCatalogPage<SakeBrandSummary>> fetchPrefectureBrands(
    int code, {
    int? afterId,
  }) async {
    cursors.add(afterId);
    codes.add(code);
    if (afterId == null && failFirst) throw StateError('offline');
    if (afterId != null && failMore) throw StateError('offline');
    return SakeCatalogPage(
      items: afterId == null ? _brands(1, 9) : _brands(10, 11),
      nextCursor: afterId == null ? 9 : null,
    );
  }

  @override
  Future<List<SakeProductOrigin>> fetchSakeOrigins(List<int> ids) async => [
    for (final id in ids)
      SakeProductOrigin(
        sakeId: id,
        canonicalSakeId: id == 100 ? 1 : id,
        brandId: id == 100 ? 1 : id,
        prefectureCode: 6,
      ),
  ];
  @override
  Future<SakeCatalogPage<SakeMapSearchResult>> fetchBrandProducts(
    int brandId, {
    int? beforeId,
  }) async => const SakeCatalogPage(items: []);
}

class _TwoPrefecturesCatalog extends _Catalog {
  @override
  Future<List<SakeProductOrigin>> fetchSakeOrigins(List<int> ids) async => [
    for (final id in ids)
      SakeProductOrigin(
        sakeId: id,
        canonicalSakeId: id == 100 ? 1 : id,
        brandId: id == 100 ? 1 : id,
        prefectureCode: id == 10 ? 3 : 6,
      ),
  ];
}

class _PreviewCatalog extends _Catalog {
  @override
  Future<SakeCatalogPage<SakeBrandSummary>> fetchPrefectureBrands(
    int code, {
    int? afterId,
  }) async {
    codes.add(code);
    cursors.add(afterId);
    final start = code == 35 ? 21 : (afterId == null ? 1 : 13);
    final end = code == 35 ? 43 : (afterId == null ? 12 : 20);
    return SakeCatalogPage(
      items: [
        for (var id = start; id <= end; id++)
          SakeBrandSummary(
            brandId: id,
            name: _names[(id - 1) % _names.length],
            brewery: '酒造',
            productCount: 1,
          ),
      ],
      nextCursor: code == 6 && afterId == null ? 12 : null,
    );
  }

  @override
  Future<List<SakeProductOrigin>> fetchSakeOrigins(List<int> ids) async => [
    for (final id in ids)
      SakeProductOrigin(
        sakeId: id,
        canonicalSakeId: id == 100 ? 1 : id,
        brandId: id == 100 ? 1 : id,
        prefectureCode: id <= 20 || id == 100 ? 6 : 35,
      ),
  ];
}

class _PartialNationalCatalog extends _TwoPrefecturesCatalog {
  bool failYamagata = true;
  @override
  Future<SakeCatalogPage<SakeBrandSummary>> fetchPrefectureBrands(
    int code, {
    int? afterId,
  }) async {
    if (code == 6 && failYamagata) {
      codes.add(code);
      cursors.add(afterId);
      throw StateError('offline');
    }
    return super.fetchPrefectureBrands(code, afterId: afterId);
  }
}

class _DelayedCatalog extends _Catalog {
  final first = Completer<SakeCatalogPage<SakeBrandSummary>>();
  @override
  Future<SakeCatalogPage<SakeBrandSummary>> fetchPrefectureBrands(
    int code, {
    int? afterId,
  }) async =>
      code == 1 ? first.future : SakeCatalogPage(items: _brands(10, 11));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await JapanSakeMapData.load();
    await (FontLoader(
      'SakeSeal',
    )..addFont(rootBundle.load('assets/fonts/YujiSyuku-Regular.ttf'))).load();
    const font = String.fromEnvironment('JAPAN_UI_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('BookPreview')..addFont(
            Future.value(ByteData.sublistView(await File(font).readAsBytes())),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
    final loaded = Completer<void>();
    final stream = const ResizeImage(
      AssetImage('assets/images/sake_catalog_illustration.png'),
      width: 256,
    ).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener((_, __) {
      if (!loaded.isCompleted) loaded.complete();
    });
    stream.addListener(listener);
    await loaded.future;
    stream.removeListener(listener);
  });
  Future<void> open(
    WidgetTester tester,
    Widget child, {
    _Catalog? repo,
    SakeStampStore? stamps,
    ValueNotifier<SavedSakeState>? saved,
    Size size = const Size(390, 844),
    double scale = 1,
    bool settle = true,
    bool openCover = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<PlaceMapRepository>.value(value: repo ?? _Catalog()),
          if (stamps != null) ChangeNotifierProvider.value(value: stamps),
        ],
        child: ValueListenableBuilder<SavedSakeState>(
          valueListenable: saved ?? ValueNotifier(const SavedSakeState()),
          builder: (_, value, child) =>
              Provider<SavedSakeState>.value(value: value, child: child),
          child: RepaintBoundary(
            key: const ValueKey('book-preview'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('ja'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: ThemeData(
                fontFamily:
                    const String.fromEnvironment('JAPAN_UI_FONT').isEmpty
                    ? null
                    : 'BookPreview',
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: child,
            ),
          ),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
      if (openCover &&
          find
              .byKey(const ValueKey('stamp-book-cover'))
              .evaluate()
              .isNotEmpty) {
        await tester.ensureVisible(
          find.byKey(const ValueKey('stamp-book-cover')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('stamp-book-cover')));
        await tester.pumpAndSettle();
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
      }
    } else {
      await tester.pump();
    }
  }

  Future<void> preview(WidgetTester tester, String name) async {
    const output = String.fromEnvironment('JAPAN_UI_OUTPUT');
    if (output.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('book-preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('詳細閲覧で取得した酒印はホーム・専用帳・旅するの帳に反映し飲酒件数は増やさない', (tester) async {
    final store = SakeStampStore();
    await store.ready;
    addTearDown(store.dispose);
    await store.acquire(
      CollectedSakeStamp(
        brandId: 1,
        prefectureCode: 6,
        sakeId: 1,
        source: 'analyzed_detail',
        observedAt: DateTime.now(),
      ),
      isCurrent: () => true,
    );
    await open(
      tester,
      const Scaffold(body: SakeStampBookSection()),
      stamps: store,
    );
    expect(find.text('全国 酒印帳'), findsOneWidget);
    expect(
      tester.widget<SakeStampBook>(find.byType(SakeStampBook)).recordedBrandIds,
      {1},
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await open(
      tester,
      const SakeStampBookPage(initialPrefectureCode: 6),
      stamps: store,
    );
    expect(find.text('山形県で集めた酒印 1銘柄'), findsOneWidget);
    expect(
      tester.widget<SakeStampBook>(find.byType(SakeStampBook)).recordedBrandIds,
      {1},
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await open(
      tester,
      const JapanSakePage(initialPrefectureCode: 6),
      stamps: store,
    );
    await tester.scrollUntilVisible(
      find.byType(SakeStampBook),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<SakeStampBook>(find.byType(SakeStampBook)).recordedBrandIds,
      {1},
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('ホームは記録ゼロ・保存だけなら山口、記録追加で全国、削除で山口に戻る', (tester) async {
    SharedPreferences.setMockInitialValues({
      SakeStampPreferences.prefectureKey: 6,
    });
    final repo = _Catalog();
    final saved = ValueNotifier(
      const SavedSakeState(savedSakeList: [Sake(sakeId: 1)]),
    );
    addTearDown(saved.dispose);
    await open(
      tester,
      const Scaffold(body: SakeStampBookSection()),
      repo: repo,
      saved: saved,
    );
    expect(find.text('山口県 酒印帳'), findsOneWidget);
    expect(find.text('現在0銘柄'), findsOneWidget);
    expect(find.byKey(const ValueKey('stamp-page-number')), findsNothing);
    expect(repo.codes, [35]);
    await preview(tester, 'home-yamaguchi');
    saved.value = const SavedSakeState(
      savedSakeList: [Sake(sakeId: 1, impression: '飲んだ')],
    );
    await tester.pumpAndSettle();
    expect(find.text('全国 酒印帳'), findsOneWidget);
    expect(
      tester
          .widget<SakeStampBook>(find.byType(SakeStampBook))
          .brands
          .map((b) => b.brandId),
      [1],
    );
    await preview(tester, 'home-nationwide');
    saved.value = const SavedSakeState();
    await tester.pumpAndSettle();
    expect(find.text('山口県 酒印帳'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('open-sake-stamp-book')));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<FormFieldState<int>>(
            find.byKey(const ValueKey('stamp-prefecture-picker')),
          )
          .value,
      35,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('全国を選ぶと押印済みのみを県順に集め、再試行・記録変更・ホーム復元に対応する', (tester) async {
    final repo = _PartialNationalCatalog();
    final saved = ValueNotifier(
      const SavedSakeState(
        savedSakeList: [
          Sake(sakeId: 1, impression: '記録'),
          Sake(sakeId: 100, impression: '同商品'),
          Sake(sakeId: 10, impression: '岩手'),
          Sake(sakeId: 2),
        ],
      ),
    );
    addTearDown(saved.dispose);
    await open(
      tester,
      const SakeStampBookPage(initialPrefectureCode: 3),
      repo: repo,
      saved: saved,
    );
    final label = find.byType(SakeStampCollectionLabel);
    expect(
      find.descendant(of: label, matching: find.text('全国で集めた酒印 2銘柄')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: label, matching: find.text('岩手県で集めた酒印 1銘柄')),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('全国で集めた酒印 2銘柄')).dy,
      lessThan(tester.getTopLeft(find.text('岩手県で集めた酒印 1銘柄')).dy),
    );
    await preview(tester, 'prefecture-summary');
    await tester.tap(find.byKey(const ValueKey('stamp-prefecture-picker')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('全国'),
      -100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('全国').last);
    await tester.pumpAndSettle();
    expect(await SakeStampPreferences.lastPrefecture(), 0);
    expect(find.byKey(const ValueKey('stamp-earned-only')), findsNothing);
    expect(find.byKey(const ValueKey('stamp-next-prefecture')), findsOneWidget);
    expect(find.byKey(const ValueKey('brand-stamp-10')), findsOneWidget);
    expect(find.byKey(const ValueKey('national-stamp-retry')), findsOneWidget);
    repo.failYamagata = false;
    await tester.tap(find.byKey(const ValueKey('national-stamp-retry')));
    await tester.pumpAndSettle();
    final book = tester.widget<SakeStampBook>(find.byType(SakeStampBook));
    expect(book.brands.map((b) => b.brandId), [10, 1]);
    expect(book.recordedBrandIds, {1, 10});
    expect(find.byKey(const ValueKey('brand-stamp-2')), findsNothing);
    expect(repo.codes.toSet(), {3, 6});
    await preview(tester, 'national-earned-stamps');
    await tester.tap(find.byKey(const ValueKey('brand-stamp-10')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<JapanSakeBrandProductsPage>(
            find.byType(JapanSakeBrandProductsPage),
          )
          .brand
          .brandId,
      10,
    );
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await open(
      tester,
      const SakeStampBookPage(),
      repo: repo,
      saved: saved,
      size: const Size(320, 568),
      scale: 1.5,
    );
    expect(find.text('全国 酒印帳'), findsOneWidget);
    expect(find.text('全国で集めた酒印 2銘柄'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await preview(tester, 'national-small');
    saved.value = const SavedSakeState(
      savedSakeList: [Sake(sakeId: 2, impression: '別アカウント')],
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('brand-stamp-1')), findsNothing);
    expect(find.byKey(const ValueKey('brand-stamp-10')), findsNothing);
    expect(find.byKey(const ValueKey('brand-stamp-2')), findsOneWidget);
    saved.value = const SavedSakeState();
    await tester.pumpAndSettle();
    expect(find.text('押印済みの酒印がまだありません。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await open(
      tester,
      const Scaffold(body: SakeStampBookSection()),
      repo: repo,
      saved: saved,
    );
    await tester.tap(find.byKey(const ValueKey('open-sake-stamp-book')));
    await tester.pumpAndSettle();
    expect(
      tester
          .state<FormFieldState<int>>(
            find.byKey(const ValueKey('stamp-prefecture-picker')),
          )
          .value,
      35,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('全国の未確認記録は取得せず、古い県の遅延応答も混入しない', (tester) async {
    final repo = _DelayedCatalog();
    Widget catalog(Map<int, Set<int>> records, bool ready) => Scaffold(
      body: NationwideStampCatalog(
        recordedBrands: records,
        recordsReady: ready,
        onBrandTap: (_) {},
      ),
    );
    await open(
      tester,
      catalog({
        1: {1},
      }, false),
      repo: repo,
    );
    expect(find.text('記録未確認'), findsOneWidget);
    await open(
      tester,
      catalog({
        1: {1},
      }, true),
      repo: repo,
      settle: false,
    );
    await tester.pump();
    await open(
      tester,
      catalog({
        6: {10},
      }, true),
      repo: repo,
    );
    expect(find.byKey(const ValueKey('brand-stamp-10')), findsOneWidget);
    repo.first.complete(SakeCatalogPage(items: _brands(1, 9)));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('brand-stamp-1')), findsNothing);
    expect(find.byKey(const ValueKey('brand-stamp-10')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ホームは最初の9銘柄で取得を止め、全国の総数だけを帳面に表示する', (tester) async {
    final repo = _PreviewCatalog();
    final saved = ValueNotifier(
      SavedSakeState(
        savedSakeList: [
          for (var id = 1; id <= 43; id++) Sake(sakeId: id, impression: '記録'),
          const Sake(sakeId: 100, impression: '同じ銘柄'),
        ],
      ),
    );
    addTearDown(saved.dispose);
    await open(
      tester,
      const Scaffold(body: SakeStampBookSection()),
      repo: repo,
      saved: saved,
    );
    final book = tester.widget<SakeStampBook>(find.byType(SakeStampBook));
    expect(book.preview, isTrue);
    expect(book.brands.map((b) => b.brandId), List.generate(9, (i) => i + 1));
    expect(book.recordedBrandIds.length, 43);
    expect(repo.codes, [6]);
    expect(repo.cursors, [null]);
    expect(find.text('現在43銘柄'), findsOneWidget);
    expect(find.textContaining('全国で集めた'), findsNothing);
    expect(find.text('9 / 9'), findsNothing);
    expect(find.byKey(const ValueKey('stamp-page-number')), findsNothing);
    expect(find.byKey(const ValueKey('stamp-next')), findsNothing);
    expect(find.byKey(const ValueKey('stamp-previous')), findsNothing);
    expect(find.textContaining('取得できませんでした'), findsNothing);
    await preview(tester, 'home-first-nine');
    await tester.tap(find.byKey(const ValueKey('open-sake-stamp-book')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stamp-book-cover')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SakeStampBook>(find.byType(SakeStampBook)).brands.length,
      43,
    );
    expect(repo.codes, [6, 6, 6, 35]);
    expect(repo.cursors, [null, null, 12, null]);
    expect(find.text('全国で集めた酒印 43銘柄'), findsOneWidget);
    expect(find.byKey(const ValueKey('stamp-next')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('stamp-next-prefecture')),
    );
    await tester.pumpAndSettle();
    await preview(tester, 'national-prefecture-buttons');
    expect(tester.takeException(), isNull);
  });

  testWidgets('同じ全国カタログでもプレビューから全件表示への変更を再取得する', (tester) async {
    final repo = _PreviewCatalog();
    final isPreview = ValueNotifier(true);
    addTearDown(isPreview.dispose);
    await open(
      tester,
      Scaffold(
        body: ValueListenableBuilder<bool>(
          valueListenable: isPreview,
          builder: (_, preview, __) => NationwideStampCatalog(
            recordedBrands: {
              6: {for (var id = 1; id <= 20; id++) id},
              35: {for (var id = 21; id <= 43; id++) id},
            },
            recordsReady: true,
            preview: preview,
            onBrandTap: (_) {},
          ),
        ),
      ),
      repo: repo,
    );
    expect(
      tester.widget<SakeStampBook>(find.byType(SakeStampBook)).brands.length,
      9,
    );
    isPreview.value = false;
    await tester.pumpAndSettle();
    expect(
      tester.widget<SakeStampBook>(find.byType(SakeStampBook)).brands.length,
      43,
    );
    expect(repo.codes, [6, 6, 6, 35]);
    isPreview.value = true;
    await tester.pumpAndSettle();
    expect(
      tester.widget<SakeStampBook>(find.byType(SakeStampBook)).brands.length,
      9,
    );
    expect(repo.codes, [6, 6, 6, 35, 6]);
    expect(find.text('現在43銘柄'), findsOneWidget);
    expect(find.textContaining('取得できませんでした'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('全国も9銘柄ずつページ送りし、銘柄はIDで重複除外する', (tester) async {
    final repo = _Catalog();
    final saved = ValueNotifier(
      SavedSakeState(
        savedSakeList: [
          for (var id = 1; id <= 11; id++) Sake(sakeId: id, impression: '記録'),
          const Sake(sakeId: 100, impression: '同商品'),
        ],
      ),
    );
    addTearDown(saved.dispose);
    await open(
      tester,
      const SakeStampBookPage(initialPrefectureCode: 0),
      repo: repo,
      saved: saved,
    );
    expect(find.text('全国で集めた酒印 11銘柄'), findsOneWidget);
    expect(repo.codes, [6, 6]);
    expect(repo.cursors, [null, 9]);
    expect(
      tester.widget<SakeStampBook>(find.byType(SakeStampBook)).brands.length,
      11,
    );
    await tester.tap(find.byKey(const ValueKey('stamp-next')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('stamp-book-cover')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 80));
    await preview(tester, 'stamp-arrow-reopening');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stamp-book-cover')), findsNothing);
    expect(find.text('2 / 2'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('brand-stamp-10')), findsOneWidget);
    expect(find.byKey(const ValueKey('brand-stamp-11')), findsOneWidget);
    await tester.fling(
      find.byKey(const ValueKey('sake-stamp-pages')),
      const Offset(250, 0),
      1000,
    );
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const ValueKey('stamp-book-cover')), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('stamp-book-cover')), findsNothing);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.byKey(const ValueKey('brand-stamp-1')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('全国数は銘柄を重複除外し、専用ページは最後の県を復元・ホームは常に全国にする', (tester) async {
    SharedPreferences.setMockInitialValues({
      SakeStampPreferences.prefectureKey: 3,
    });
    final repo = _TwoPrefecturesCatalog();
    final saved = ValueNotifier(
      const SavedSakeState(
        savedSakeList: [
          Sake(sakeId: 1, impression: '飲んだ'),
          Sake(sakeId: 100, impression: '同商品'),
          Sake(sakeId: 2, impression: '飲んだ'),
          Sake(sakeId: 10, impression: '岩手'),
          Sake(sakeId: 3),
        ],
      ),
    );
    addTearDown(saved.dispose);
    await open(tester, const SakeStampBookPage(), repo: repo, saved: saved);
    expect(find.text('全国で集めた酒印 3銘柄'), findsOneWidget);
    expect(find.text('岩手県で集めた酒印 1銘柄'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('stamp-prefecture-picker')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('山形県').last);
    await tester.pumpAndSettle();
    expect(find.text('山形県で集めた酒印 2銘柄'), findsOneWidget);
    expect(await SakeStampPreferences.lastPrefecture(), 6);
    expect(find.text('全国で集めた酒印 3銘柄'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await open(tester, const SakeStampBookPage(), repo: repo, saved: saved);
    expect(find.text('山形県で集めた酒印 2銘柄'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await open(
      tester,
      const Scaffold(body: SakeStampBookSection()),
      repo: repo,
      saved: saved,
    );
    expect(find.text('全国 酒印帳'), findsOneWidget);
    expect(find.text('現在3銘柄'), findsOneWidget);
    expect(find.text('全国で集めた酒印 3銘柄'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('open-sake-stamp-book')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('stamp-prefecture-picker')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('岩手県'),
      -100,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('岩手県').last);
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(find.text('全国 酒印帳'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('押印済みのみは次ページも取得し、取得失敗から再試行して記録削除にも追従する', (tester) async {
    final repo = _Catalog()..failMore = true;
    final saved = ValueNotifier(
      const SavedSakeState(savedSakeList: [Sake(sakeId: 10, impression: '記録')]),
    );
    addTearDown(saved.dispose);
    await open(
      tester,
      const SakeStampBookPage(initialPrefectureCode: 6),
      repo: repo,
      saved: saved,
    );
    await tester.tap(find.byKey(const ValueKey('stamp-earned-only')));
    await tester.pumpAndSettle();
    expect(repo.cursors, [null, 9]);
    expect(find.text('酒印帳を読み込めませんでした。'), findsOneWidget);
    repo.failMore = false;
    await tester.ensureVisible(
      find.byKey(const ValueKey('stamp-catalog-retry')),
    );
    await tester.tap(find.byKey(const ValueKey('stamp-catalog-retry')));
    await tester.pumpAndSettle();
    expect(repo.cursors, [null, 9, 9]);
    expect(find.text('1 / 1'), findsNWidgets(2));
    expect(find.byKey(const ValueKey('brand-stamp-10')), findsOneWidget);
    expect(find.byKey(const ValueKey('brand-stamp-1')), findsNothing);
    await preview(tester, 'earned-stamps-only');
    await tester.ensureVisible(find.byKey(const ValueKey('brand-stamp-10')));
    await tester.tap(find.byKey(const ValueKey('brand-stamp-10')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<JapanSakeBrandProductsPage>(
            find.byType(JapanSakeBrandProductsPage),
          )
          .brand
          .brandId,
      10,
    );
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    saved.value = const SavedSakeState();
    await tester.pumpAndSettle();
    expect(find.text('この県には押印済みの酒印がまだありません。'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('stamp-earned-only')));
    await tester.tap(find.byKey(const ValueKey('stamp-earned-only')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('brand-stamp-1')), findsOneWidget);
    expect(repo.cursors, [null, 9, 9]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('下の左右ボタンで県ID順に移動し、選択欄・記憶と同期する', (tester) async {
    final repo = _Catalog();
    await open(
      tester,
      const SakeStampBookPage(initialPrefectureCode: 6),
      repo: repo,
      size: const Size(320, 568),
      scale: 1.5,
    );
    final previous = find.byKey(const ValueKey('stamp-previous-prefecture'));
    final next = find.byKey(const ValueKey('stamp-next-prefecture'));
    await tester.scrollUntilVisible(
      previous,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(previous);
    await tester.pumpAndSettle();
    expect(repo.codes.last, 5);
    expect(find.text('秋田県 酒印帳'), findsOneWidget);
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    expect(
      tester
          .state<FormFieldState<int>>(
            find.byKey(const ValueKey('stamp-prefecture-picker')),
          )
          .value,
      5,
    );
    await tester.scrollUntilVisible(
      next,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(repo.codes.last, 7);
    expect(await SakeStampPreferences.lastPrefecture(), 7);
    expect(tester.takeException(), isNull);
    await preview(tester, 'prefecture-arrows-small');

    expect(tester.takeException(), isNull);
  });

  testWidgets('全国・北海道・沖縄の左右ボタンは両方向にループし選択と記憶を更新する', (tester) async {
    final repo = _Catalog();
    await open(
      tester,
      const SakeStampBookPage(initialPrefectureCode: 0),
      repo: repo,
      size: const Size(320, 568),
      scale: 1.5,
    );
    final previous = find.byKey(const ValueKey('stamp-previous-prefecture'));
    final next = find.byKey(const ValueKey('stamp-next-prefecture'));
    Future<void> step(Finder button, int code, String title) async {
      await tester.scrollUntilVisible(
        button,
        160,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pump();
      expect(find.byKey(const ValueKey('stamp-book-cover')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('stamp-book-cover')), findsNothing);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      expect(await SakeStampPreferences.lastPrefecture(), code);
      expect(
        tester
            .state<FormFieldState<int>>(
              find.byKey(const ValueKey('stamp-prefecture-picker')),
            )
            .value,
        code,
      );
      if (code != 0) {
        expect(repo.codes.last, code);
        expect(find.text('$title 酒印帳'), findsOneWidget);
      } else {
        expect(find.text('押印済みの酒印がまだありません。'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    }

    await tester.scrollUntilVisible(
      previous,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: previous, matching: find.text('沖縄県')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: next, matching: find.text('北海道')),
      findsOneWidget,
    );
    await tester.ensureVisible(next);
    await tester.pumpAndSettle();
    await preview(tester, 'national-prefecture-loop');
    await step(previous, 47, '沖縄県');
    await tester.scrollUntilVisible(
      next,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(of: next, matching: find.text('全国')),
      findsOneWidget,
    );
    await step(next, 0, '全国');
    await step(next, 1, '北海道');
    await tester.scrollUntilVisible(
      previous,
      160,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.descendant(of: previous, matching: find.text('全国')),
      findsOneWidget,
    );
    await step(previous, 0, '全国');
    await step(next, 1, '北海道');
    await step(next, 2, '青森県');
    await step(previous, 1, '北海道');
    await step(previous, 0, '全国');
    await step(previous, 47, '沖縄県');
    await step(previous, 46, '鹿児島県');
    await step(next, 47, '沖縄県');
    await step(next, 0, '全国');
  });

  testWidgets('都道府県メニューは高さを抑えて全国と遠い県も選べる', (tester) async {
    for (final size in [const Size(390, 844), const Size(320, 568)]) {
      await tester.pumpWidget(const SizedBox.shrink());
      await open(
        tester,
        const SakeStampBookPage(initialPrefectureCode: 0),
        size: size,
        scale: size.width == 320 ? 1.5 : 1,
      );
      final picker = find.byKey(const ValueKey('stamp-prefecture-picker'));
      await tester.tap(picker);
      await tester.pumpAndSettle();
      final menu = find.byType(Scrollable).last;
      expect(tester.getSize(menu).height, lessThanOrEqualTo(size.height * .4));
      if (size.width == 390) await preview(tester, 'compact-prefecture-menu');
      final okinawa = find.descendant(of: menu, matching: find.text('沖縄県'));
      await tester.scrollUntilVisible(okinawa, 180, scrollable: menu);
      await tester.pumpAndSettle();
      await tester.tap(okinawa);
      await tester.pumpAndSettle();
      expect(tester.state<FormFieldState<int>>(picker).value, 47);
      expect(await SakeStampPreferences.lastPrefecture(), 47);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(picker);
      await tester.pumpAndSettle();
      final reopenedMenu = find.byType(Scrollable).last;
      final nationwide = find.descendant(
        of: reopenedMenu,
        matching: find.text('全国'),
      );
      await tester.scrollUntilVisible(
        nationwide,
        -180,
        scrollable: reopenedMenu,
      );
      await tester.pumpAndSettle();
      await tester.tap(nationwide);
      await tester.pumpAndSettle();
      expect(tester.state<FormFieldState<int>>(picker).value, 0);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('不正な記憶値は無視し、明示した県は前回の県より優先する', (tester) async {
    SharedPreferences.setMockInitialValues({
      SakeStampPreferences.prefectureKey: 999,
    });
    expect(await SakeStampPreferences.lastPrefecture(), isNull);
    await open(tester, const SakeStampBookPage(initialPrefectureCode: 6));
    expect(find.text('山形県 酒印帳'), findsOneWidget);
    expect(await SakeStampPreferences.lastPrefecture(), 6);
    await tester.pumpWidget(const SizedBox.shrink());
    await open(tester, const SakeStampBookPage(initialPrefectureCode: 3));
    expect(find.text('岩手県 酒印帳'), findsOneWidget);
    expect(await SakeStampPreferences.lastPrefecture(), 3);
  });

  testWidgets(
    'home book appears above the journey and tapping the paper opens a dedicated book, then brand products',
    (tester) async {
      final repo = _Catalog();
      await open(
        tester,
        Scaffold(
          body: ListView(
            children: const [SakeStampBookSection(), JapanSakeSection()],
          ),
        ),
        repo: repo,
        saved: ValueNotifier(
          const SavedSakeState(
            savedSakeList: [Sake(sakeId: 1, impression: '飲んだ')],
          ),
        ),
      );
      expect(
        tester.getTopLeft(find.text('日本酒ご酒印帳')).dy,
        lessThan(tester.getTopLeft(find.text('日本酒を旅する')).dy),
      );
      expect(repo.codes.last, 6);
      expect(repo.codes.toSet().difference({1, 6}), isEmpty);
      expect(find.text('1 / 1'), findsNothing);
      expect(find.text('現在1銘柄'), findsOneWidget);
      final homeBookSize = tester.getSize(
        find.byKey(const ValueKey('sake-stamp-book')),
      );
      await preview(tester, 'home-stamp-book');
      await tester.tap(find.byKey(const ValueKey('sake-stamp-demo-button')));
      await tester.pumpAndSettle();
      expect(find.text('新しい酒印を獲得！'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('close-stamp-demo')));
      await tester.pumpAndSettle();
      expect(find.text('1 / 1'), findsNothing);
      expect(find.text('現在1銘柄'), findsOneWidget);
      expect(repo.codes.last, 6);
      await tester.tapAt(
        tester.getCenter(find.byKey(const ValueKey('sake-stamp-book'))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SakeStampBookPage), findsOneWidget);
      expect(find.text('全国で集めた酒印 1銘柄'), findsOneWidget);
      expect(find.byKey(const ValueKey('stamp-book-cover')), findsOneWidget);
      await preview(tester, 'stamp-book-cover');
      await tester.tap(find.byKey(const ValueKey('stamp-book-cover')));
      await tester.pump();
      if (const String.fromEnvironment('JAPAN_UI_OUTPUT').isNotEmpty) {
        for (var frame = 1; frame <= 10; frame++) {
          await tester.pump(const Duration(milliseconds: 30));
          await preview(
            tester,
            'stamp-open-${frame.toString().padLeft(2, '0')}',
          );
        }
      }
      await tester.pumpAndSettle();
      expect(find.byType(JapanSakeMap), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('sake-stamp-book'))),
        homeBookSize,
      );
      expect(find.textContaining('お酒の記録をつけると'), findsNothing);
      expect(find.textContaining('保存だけでは押印'), findsNothing);
      expect(find.text('記録した商品数'), findsNothing);
      await preview(tester, 'dedicated-stamp-book');
      await tester.tap(find.byKey(const ValueKey('brand-stamp-1')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<JapanSakeBrandProductsPage>(
              find.byType(JapanSakeBrandProductsPage),
            )
            .brand
            .brandId,
        1,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dedicated book retries, paginates, switches prefectures, and updates records on a small screen',
    (tester) async {
      final repo = _Catalog()..failFirst = true;
      final saved = ValueNotifier(
        const SavedSakeState(
          savedSakeList: [Sake(sakeId: 1, impression: '記録')],
        ),
      );
      addTearDown(saved.dispose);
      await open(
        tester,
        const SakeStampBookPage(initialPrefectureCode: 6),
        repo: repo,
        saved: saved,
        size: const Size(320, 568),
        scale: 1.5,
      );
      expect(find.text('酒印帳を読み込めませんでした。'), findsOneWidget);
      repo.failFirst = false;
      await tester.ensureVisible(
        find.byKey(const ValueKey('stamp-catalog-retry')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stamp-catalog-retry')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const ValueKey('stamp-next')));
      await tester.pumpAndSettle();
      repo.failMore = true;
      await tester.tap(find.byKey(const ValueKey('stamp-next')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('stamp-book-cover')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('stamp-book-cover')), findsNothing);
      expect(find.byKey(const ValueKey('stamp-retry')), findsOneWidget);
      expect(
        tester.widget<SakeStampBook>(find.byType(SakeStampBook)).brands.length,
        9,
      );
      repo.failMore = false;
      await tester.tap(find.byKey(const ValueKey('stamp-retry')));
      await tester.pumpAndSettle();
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('brand-stamp-10')), findsOneWidget);
      saved.value = const SavedSakeState();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SakeStampBook>(find.byType(SakeStampBook))
            .recordedBrandIds,
        isEmpty,
      );
      expect(find.text('2 / 2'), findsOneWidget);
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('stamp-prefecture-picker')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('岩手県').last,
        -100,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('岩手県').last);
      await tester.pumpAndSettle();
      expect(repo.codes.last, 3);
      expect(find.text('岩手県で集めた酒印 0銘柄'), findsOneWidget);
      expect(find.text('1 / …'), findsOneWidget);
      await preview(tester, 'dedicated-stamp-book-small');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late catalog responses cannot replace a newly selected prefecture',
    (tester) async {
      final repo = _DelayedCatalog();
      final prefectures = await JapanSakeMapData.load();
      var selected = prefectures.first;
      late StateSetter update;
      await open(
        tester,
        Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return PrefectureStampCatalog(
                prefecture: selected,
                recordedBrandIds: const {},
                recordsReady: true,
                onBrandTap: (_) {},
              );
            },
          ),
        ),
        repo: repo,
        settle: false,
      );
      update(() => selected = prefectures[2]);
      await tester.pumpAndSettle();
      repo.first.complete(SakeCatalogPage(items: _brands(1, 9)));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('brand-stamp-10')), findsOneWidget);
      expect(find.byKey(const ValueKey('brand-stamp-1')), findsNothing);
      expect(find.text('岩手県 酒印帳'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'nine real brands per page share list pagination, retain rows after retry, and open the correct brand',
    (tester) async {
      final repo = _Catalog();
      final saved = ValueNotifier(
        SavedSakeState(
          savedSakeList: [
            for (var id = 1; id <= 7; id++) Sake(sakeId: id, impression: '記録'),
            const Sake(sakeId: 100, impression: '統合前'),
            const Sake(sakeId: 9, name: '保存だけ'),
          ],
        ),
      );
      addTearDown(saved.dispose);
      await open(
        tester,
        const JapanSakePage(initialPrefectureCode: 6),
        repo: repo,
        saved: saved,
      );
      final book = find.byKey(const ValueKey('sake-stamp-book'));
      await Scrollable.ensureVisible(
        tester.element(find.text('山形県の銘柄')),
        alignment: 0,
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(book).height, 236); // 212pt paper + 24pt margins.
      expect(find.text('7 / 9'), findsOneWidget);
      expect(repo.cursors, [null]);
      expect(find.byKey(const ValueKey('brand-stamp-9')), findsOneWidget);
      expect(find.byKey(const ValueKey('brand-stamp-10')), findsNothing);
      await preview(tester, 'stamp-book');
      repo.failMore = true;
      await tester.tap(find.byKey(const ValueKey('stamp-next')));
      await tester.pumpAndSettle();
      expect(repo.cursors, [null, 9]);
      expect(find.byKey(const ValueKey('stamp-retry')), findsOneWidget);
      expect(find.text('0 / 0'), findsNothing);
      expect(find.byKey(const ValueKey('japan-brand-1')), findsOneWidget);
      repo.failMore = false;
      await tester.tap(find.byKey(const ValueKey('stamp-retry')));
      await tester.pumpAndSettle();
      expect(repo.cursors, [null, 9, 9]);
      expect(find.text('2 / 2'), findsOneWidget);
      expect(find.text('0 / 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('japan-brand-10')), findsOneWidget);
      expect(find.byKey(const ValueKey('brand-stamp-10')), findsOneWidget);
      expect(find.byKey(const ValueKey('brand-stamp-11')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('brand-stamp-11')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<JapanSakeBrandProductsPage>(
              find.byType(JapanSakeBrandProductsPage),
            )
            .brand
            .brandId,
        11,
      );
      expect(find.text('酒造B'), findsOneWidget);
      expect(saved.value.savedSakeList.length, 9);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'record edits and account changes update stamp state without manual stamping',
    (tester) async {
      final saved = ValueNotifier(
        const SavedSakeState(
          savedSakeList: [Sake(sakeId: 1, impression: '記録')],
        ),
      );
      addTearDown(saved.dispose);
      await open(
        tester,
        const JapanSakePage(initialPrefectureCode: 6),
        saved: saved,
      );
      final book = find.byType(SakeStampBook);
      await tester.ensureVisible(book);
      await tester.pumpAndSettle();
      expect(tester.widget<SakeStampBook>(book).recordedBrandIds, {1});
      expect(find.text('1 / 9'), findsOneWidget);
      saved.value = const SavedSakeState();
      await tester.pumpAndSettle();
      expect(tester.widget<SakeStampBook>(book).recordedBrandIds, isEmpty);
      expect(find.text('0 / 9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'small screens and long brand names stay compact and unconfirmed origins are not stamped',
    (tester) async {
      final names = [
        ..._brands(1, 8),
        const SakeBrandSummary(
          brandId: 99,
          name: '栄光冨士 GRAVITY 仕込乃壱 長い銘柄名',
          brewery: '蔵',
          productCount: 1,
        ),
      ];
      await open(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SakeStampBook(
              prefectureName: '山形県',
              brands: names,
              recordedBrandIds: const {1},
              recordsReady: false,
              onBrandTap: (_) {},
              hasMore: false,
              loading: false,
              failed: false,
              loadMore: () {},
            ),
          ),
        ),
        size: const Size(320, 568),
        scale: 1.5,
      );
      expect(find.text('記録未確認'), findsOneWidget);
      expect(find.text('1 / 9'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey('sake-stamp-book'))).height,
        236,
      );
      await preview(tester, 'stamp-book-small');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'a fifty-brand API page fills the partial sixth stamp page on demand',
    (tester) async {
      var brands = List.generate(
        50,
        (i) => SakeBrandSummary(
          brandId: i + 1,
          name: '銘柄${i + 1}',
          brewery: '蔵',
          productCount: 1,
        ),
      );
      var hasMore = true;
      var loads = 0;
      int? opened;
      await open(
        tester,
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: StatefulBuilder(
              builder: (context, setState) => SakeStampBook(
                prefectureName: '山形県',
                brands: brands,
                recordedBrandIds: const {},
                recordsReady: true,
                onBrandTap: (brand) => opened = brand.brandId,
                hasMore: hasMore,
                loading: false,
                failed: false,
                loadMore: () {
                  loads++;
                  setState(() {
                    brands = [
                      ...brands,
                      for (var id = 51; id <= 54; id++)
                        SakeBrandSummary(
                          brandId: id,
                          name: '銘柄$id',
                          brewery: '蔵',
                          productCount: 1,
                        ),
                    ];
                    hasMore = false;
                  });
                },
              ),
            ),
          ),
        ),
      );
      expect(loads, 0);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const ValueKey('stamp-next')));
        await tester.pumpAndSettle();
      }
      expect(loads, 1);
      expect(find.text('6 / 6'), findsOneWidget);
      expect(find.byKey(const ValueKey('brand-stamp-54')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('brand-stamp-54')));
      expect(opened, 54);
      expect(tester.takeException(), isNull);
    },
  );
}
