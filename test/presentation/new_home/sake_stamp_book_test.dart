import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_catalog_browse.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/saved_sake/saved_sake_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/japan_sake_page.dart';
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
  bool failMore = false;
  @override
  Future<SakeCatalogPage<SakeBrandSummary>> fetchPrefectureBrands(
    int code, {
    int? afterId,
  }) async {
    cursors.add(afterId);
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

void main() {
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
    ValueNotifier<SavedSakeState>? saved,
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Provider<PlaceMapRepository>.value(
        value: repo ?? _Catalog(),
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
    await tester.pumpAndSettle();
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
