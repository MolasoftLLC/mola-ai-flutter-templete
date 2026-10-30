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
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/recorded_sake_seal.dart';

class _Catalog extends PlaceMapRepository {
  _Catalog({this.failOrigins = false}) : super(ApiClient.create());
  final bool failOrigins;
  int productRequests = 0;
  @override
  Future<List<SakeProductOrigin>> fetchSakeOrigins(List<int> ids) async {
    if (failOrigins) throw StateError('offline');
    return [
      for (final id in ids)
        SakeProductOrigin(
          sakeId: id,
          canonicalSakeId: id == 103 ? 3 : id,
          brandId: 11,
          prefectureCode: 5,
        ),
    ];
  }

  @override
  Future<SakeCatalogPage<SakeMapSearchResult>> fetchBrandProducts(
    int brandId, {
    int? beforeId,
  }) async {
    productRequests++;
    return const SakeCatalogPage(
      items: [
        SakeMapSearchResult(
          isMaster: true,
          sakeId: 1,
          name: '雪の茅舎 山廃純米 生酒',
          brewery: '株式会社齋彌酒造店',
          type: '純米酒',
        ),
        SakeMapSearchResult(
          isMaster: true,
          sakeId: 2,
          name: '雪の茅舎 秘伝山廃 山廃純米吟醸 生酒',
          brewery: '株式会社齋彌酒造店',
          type: '純米吟醸',
        ),
        SakeMapSearchResult(
          isMaster: true,
          sakeId: 3,
          name: '雪の茅舎 山廃本醸造',
          brewery: '株式会社齋彌酒造店',
          type: '本醸造',
        ),
        SakeMapSearchResult(
          isMaster: true,
          sakeId: 4,
          name: '雪の茅舎 大吟醸',
          brewery: '株式会社齋彌酒造店',
          type: '大吟醸',
        ),
      ],
    );
  }
}

class _PagedCatalog extends _Catalog {
  bool failMore = false;
  @override
  Future<SakeCatalogPage<SakeMapSearchResult>> fetchBrandProducts(
    int brandId, {
    int? beforeId,
  }) async {
    if (beforeId != null && failMore) {
      productRequests++;
      throw StateError('offline');
    }
    final all = await super.fetchBrandProducts(brandId, beforeId: beforeId);
    return SakeCatalogPage(
      items: all.items
          .where(
            (sake) => beforeId == null ? sake.sakeId! <= 2 : sake.sakeId! > 2,
          )
          .toList(),
      nextCursor: beforeId == null ? 2 : null,
    );
  }

  @override
  Future<List<SakeProductOrigin>> fetchSakeOrigins(List<int> ids) async => [
    for (final id in ids)
      SakeProductOrigin(
        sakeId: id,
        canonicalSakeId: id,
        brandId: id == 9 ? 99 : 11,
        prefectureCode: 5,
      ),
  ];
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'SakeSeal',
    )..addFont(rootBundle.load('assets/fonts/YujiSyuku-Regular.ttf'))).load();
    const font = String.fromEnvironment('JAPAN_UI_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('SealPreview')..addFont(
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
    _Catalog repo,
    ValueNotifier<SavedSakeState> saved, {
    double scale = 1,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Provider<PlaceMapRepository>.value(
        value: repo,
        child: ValueListenableBuilder<SavedSakeState>(
          valueListenable: saved,
          builder: (_, value, child) =>
              Provider<SavedSakeState>.value(value: value, child: child),
          child: RepaintBoundary(
            key: const ValueKey('seal-preview'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('ja'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: ThemeData(
                fontFamily:
                    const String.fromEnvironment('JAPAN_UI_FONT').isEmpty
                    ? null
                    : 'SealPreview',
              ),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: const JapanSakeBrandProductsPage(
                brand: SakeBrandSummary(
                  brandId: 11,
                  name: '雪の茅舎',
                  brewery: '株式会社齋彌酒造店',
                  productCount: 4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder seal(int id) => find.descendant(
    of: find.byKey(ValueKey('japan-product-$id')),
    matching: find.byType(RecordedSakeSeal),
  );
  Future<void> preview(WidgetTester tester, String name) async {
    const output = String.fromEnvironment('JAPAN_UI_OUTPUT');
    if (output.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('seal-preview')),
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
    'stamps only recorded products, resolves verified merged IDs, and follows edits/account changes without reloading catalog',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = _Catalog();
      final saved = ValueNotifier(
        const SavedSakeState(
          savedSakeList: [
            Sake(sakeId: 1, impression: '飲んだ'),
            Sake(sakeId: 1, place: '店'),
            Sake(sakeId: 2, isBookmarked: true),
            Sake(sakeId: 103, impression: '統合前の商品の記録'),
          ],
        ),
      );
      addTearDown(saved.dispose);
      await open(tester, repo, saved);
      expect(seal(1), findsOneWidget);
      expect(seal(2), findsNothing);
      expect(seal(3), findsOneWidget);
      expect(seal(4), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('japan-product-3'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('japan-product-2'))).dy,
        ),
      );
      expect(find.bySemanticsLabel(RegExp('飲んだ記録あり')), findsNWidgets(2));
      await preview(tester, 'recorded-sake-seal');
      saved.value = const SavedSakeState(
        savedSakeList: [Sake(sakeId: 1, isBookmarked: true)],
      );
      await tester.pumpAndSettle();
      expect(find.byType(RecordedSakeSeal), findsNothing);
      saved.value = const SavedSakeState(
        savedSakeList: [Sake(sakeId: 2, impression: '別アカウント')],
      );
      await tester.pumpAndSettle();
      expect(seal(1), findsNothing);
      expect(seal(2), findsOneWidget);
      expect(seal(3), findsNothing);
      expect(repo.productRequests, 1);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('japan-product-2'))).dy,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('japan-product-1'))).dy,
        ),
      );
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('記録済みは未取得のページ分も先頭に表示し、追加取得・再試行・アカウント変更で重複しない', (tester) async {
    final repo = _PagedCatalog();
    const records = SavedSakeState(
      savedSakeList: [
        Sake(sakeId: 4, name: '記録した大吟醸', impression: '飲んだ'),
        Sake(sakeId: 9, name: '別の銘柄', impression: '飲んだ'),
        Sake(sakeId: 2, name: '保存だけ', isBookmarked: true),
      ],
    );
    final saved = ValueNotifier(records);
    addTearDown(saved.dispose);
    await open(tester, repo, saved);
    expect(repo.productRequests, 1);
    expect(seal(4), findsOneWidget);
    expect(find.byKey(const ValueKey('japan-product-9')), findsNothing);
    expect(find.text('保存だけ'), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('japan-product-4'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('japan-product-1'))).dy,
      ),
    );
    saved.value = const SavedSakeState();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('japan-product-4')), findsNothing);
    saved.value = records;
    await tester.pumpAndSettle();
    expect(seal(4), findsOneWidget);
    expect(repo.productRequests, 1);
    repo.failMore = true;
    await tester.tap(find.text('もっと見る'));
    await tester.pumpAndSettle();
    expect(find.text('一覧を取得できませんでした。'), findsOneWidget);
    expect(seal(4), findsOneWidget);
    repo.failMore = false;
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    expect(repo.productRequests, 3);
    expect(find.byKey(const ValueKey('japan-product-4')), findsOneWidget);
    expect(find.text('記録した大吟醸'), findsNothing);
    expect(find.text('雪の茅舎 大吟醸'), findsOneWidget);
    expect(seal(4), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('japan-product-4'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('japan-product-1'))).dy,
      ),
    );
    await preview(tester, 'recorded-first-products');
    saved.value = const SavedSakeState();
    await tester.pumpAndSettle();
    expect(find.byType(RecordedSakeSeal), findsNothing);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('japan-product-1'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const ValueKey('japan-product-4'))).dy,
      ),
    );
    expect(repo.productRequests, 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failed origin lookup keeps exact ID stamps without guessing aliases; small screen and enlarged text fit',
    (tester) async {
      final saved = ValueNotifier(
        const SavedSakeState(
          savedSakeList: [
            Sake(sakeId: 1, impression: '飲んだ'),
            Sake(sakeId: 103, impression: '統合前'),
          ],
        ),
      );
      addTearDown(saved.dispose);
      await open(
        tester,
        _Catalog(failOrigins: true),
        saved,
        scale: 1.5,
        size: const Size(320, 568),
      );
      expect(seal(1), findsOneWidget);
      expect(seal(3), findsNothing);
      expect(seal(2), findsNothing);
      final card = tester.getRect(
        find.byKey(const ValueKey('japan-product-1')),
      );
      final stamp = tester.getRect(seal(1));
      expect(card.contains(stamp.topLeft), isTrue);
      expect(card.contains(stamp.bottomRight), isTrue);
      expect(stamp.center.dx, greaterThan(card.center.dx));
      expect(stamp.top - card.top, lessThan(16));
      await preview(tester, 'recorded-sake-seal-small');
      expect(tester.takeException(), isNull);
    },
  );
}
