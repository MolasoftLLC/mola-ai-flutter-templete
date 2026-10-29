import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/common/prefecture.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_catalog_browse.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_catalog_thumbnail.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/japan_sake_page.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/japan_sake_map.dart';

class _Repository extends PlaceMapRepository {
  _Repository() : super(ApiClient.create());
  final requests = <String>[];
  Future<SakeCatalogPage<SakeBrandSummary>> Function(String) loader =
      (_) async => const SakeCatalogPage(items: []);
  Future<SakeCatalogPage<SakeMapSearchResult>> Function(int, int?)
  productsLoader = (_, __) async => const SakeCatalogPage(items: []);
  final productRequests = <(int, int?)>[];
  final brandCursors = <int?>[];
  @override
  Future<SakeCatalogPage<SakeBrandSummary>> fetchPrefectureBrands(
    int code, {
    int? afterId,
  }) {
    final name = prefectures[code];
    requests.add(name);
    brandCursors.add(afterId);
    return loader(name);
  }

  @override
  Future<SakeCatalogPage<SakeMapSearchResult>> fetchBrandProducts(
    int brandId, {
    int? beforeId,
  }) {
    productRequests.add((brandId, beforeId));
    return productsLoader(brandId, beforeId);
  }
}

void main() {
  late List<JapanSakePrefecture> data;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    data = await JapanSakeMapData.load();
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
    const font = String.fromEnvironment('JAPAN_UI_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('JapanPreview')..addFont(
            Future.value(ByteData.sublistView(await File(font).readAsBytes())),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  Future<void> open(
    WidgetTester tester,
    _Repository repository,
    Widget home, {
    Size size = const Size(390, 844),
    double scale = 1,
    Locale locale = const Locale('ja'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Provider<PlaceMapRepository>.value(
        value: repository,
        child: RepaintBoundary(
          key: const ValueKey('japan-preview'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData(
              fontFamily: const String.fromEnvironment('JAPAN_UI_FONT').isEmpty
                  ? null
                  : 'JapanPreview',
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: home,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> tapPrefecture(WidgetTester tester, int code) async {
    final finder = find.byType(JapanSakeMap).last;
    final size = tester.getSize(finder);
    final scale = math.min(size.width / 720, size.height / 760);
    final offset = Offset(
      (size.width - 720 * scale) / 2,
      (size.height - 760 * scale) / 2,
    );
    final prefecture = data.firstWhere((p) => p.code == code);
    expect(prefecture.dots, isNotEmpty);
    await tester.tapAt(
      tester.getTopLeft(finder) +
          offset +
          prefecture.dots[prefecture.dots.length ~/ 2] * scale,
    );
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
  }

  Future<void> preview(WidgetTester tester, String name) async {
    const output = String.fromEnvironment('JAPAN_UI_OUTPUT');
    if (output.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('japan-preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  test('offline map covers all 47 correct prefectures including Okinawa', () {
    expect(data.map((p) => p.code), List.generate(47, (i) => i + 1));
    expect(data.map((p) => p.name), prefectures.skip(1));
    expect(data.every((p) => !p.bounds.isEmpty && p.dots.isNotEmpty), isTrue);
  });

  testWidgets(
    'home map opens the tapped prefecture without loading catalogs on home',
    (tester) async {
      final repository = _Repository();
      repository.loader = (name) async => SakeCatalogPage(
        items: [
          SakeBrandSummary(
            brandId: 123,
            name: '$nameのテスト銘柄',
            brewery: '蔵元',
            productCount: 3,
          ),
        ],
      );
      await open(
        tester,
        repository,
        const Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(child: JapanSakeSection()),
        ),
      );
      expect(repository.requests, isEmpty);
      await preview(tester, 'home-section');
      await tapPrefecture(tester, 1);
      await tester.pumpAndSettle();
      expect(repository.requests, ['北海道']);
      expect(find.byKey(const ValueKey('japan-brand-123')), findsOneWidget);
      await preview(tester, 'hokkaido');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'switching prefectures ignores late results and reuses loaded catalogs',
    (tester) async {
      final repository = _Repository();
      final niigata = Completer<SakeCatalogPage<SakeBrandSummary>>();
      final hokkaido = Completer<SakeCatalogPage<SakeBrandSummary>>();
      repository.loader = (name) =>
          name == '新潟県' ? niigata.future : hokkaido.future;
      await open(tester, repository, const JapanSakePage());
      await tapPrefecture(tester, 15);
      await tapPrefecture(tester, 1);
      niigata.complete(
        const SakeCatalogPage(
          items: [
            SakeBrandSummary(
              brandId: 15,
              name: '新潟の銘柄',
              brewery: '蔵元',
              productCount: 1,
            ),
          ],
        ),
      );
      await tester.pump();
      expect(find.text('新潟の銘柄'), findsNothing);
      hokkaido.complete(
        const SakeCatalogPage(
          items: [
            SakeBrandSummary(
              brandId: 1,
              name: '北海道のテスト銘柄',
              brewery: '蔵元',
              productCount: 1,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('japan-brand-1')), findsOneWidget);
      await tapPrefecture(tester, 15);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('japan-brand-15')), findsOneWidget);
      expect(repository.requests, ['新潟県', '北海道']);
    },
  );

  testWidgets(
    'failed catalog can retry and distinguishes missing data from an error',
    (tester) async {
      final repository = _Repository();
      repository.loader = (_) async => throw StateError('offline');
      await open(
        tester,
        repository,
        const JapanSakePage(initialPrefectureCode: 15),
      );
      await tester.pumpAndSettle();
      expect(find.text('再読み込み'), findsOneWidget);
      repository.loader = (_) async => const SakeCatalogPage(items: []);
      await tester.tap(find.text('再読み込み'));
      await tester.pumpAndSettle();
      expect(find.textContaining('カタログに見つかりません'), findsOneWidget);
      expect(repository.requests, ['新潟県', '新潟県']);
    },
  );

  testWidgets(
    'all prefectures remain selectable on a small screen with large text',
    (tester) async {
      final repository = _Repository();
      await open(
        tester,
        repository,
        const JapanSakePage(),
        size: const Size(320, 568),
        scale: 1.5,
      );
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('choose-japan-prefecture')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const ValueKey('choose-japan-prefecture')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('prefecture-47')),
        450,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const ValueKey('prefecture-47')));
      await tester.pumpAndSettle();
      expect(repository.requests, ['沖縄県']);
      expect(find.text('沖縄県の銘柄'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await preview(tester, 'small');
    },
  );

  testWidgets(
    'a brand opens its own products with the same illustration fallback',
    (tester) async {
      final repository = _Repository();
      repository.loader = (_) async => const SakeCatalogPage(
        items: [
          SakeBrandSummary(
            brandId: 11,
            name: 'テスト銘柄',
            brewery: 'テスト酒造',
            productCount: 2,
          ),
          SakeBrandSummary(
            brandId: 12,
            name: 'テスト銘柄',
            brewery: '別の酒造',
            productCount: 1,
          ),
        ],
      );
      repository.productsLoader = (id, cursor) async => SakeCatalogPage(
        items: [
          SakeMapSearchResult(
            sakeId: cursor == null ? 500 : 499,
            name: cursor == null ? 'テスト銘柄 純米吟醸' : 'テスト銘柄 純米',
            type: '純米酒',
            isMaster: true,
          ),
        ],
        nextCursor: cursor == null ? 500 : null,
      );
      await open(
        tester,
        repository,
        const JapanSakePage(initialPrefectureCode: 15),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('japan-brand-11')), findsOneWidget);
      expect(find.byKey(const ValueKey('japan-brand-12')), findsOneWidget);
      expect(find.byKey(const ValueKey('brand-stamp-11')), findsOneWidget);
      expect(find.byKey(const ValueKey('brand-stamp-12')), findsOneWidget);
      expect(find.byType(SakeCatalogThumbnail), findsNWidgets(2));
      await tester.ensureVisible(find.byKey(const ValueKey('japan-brand-11')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('japan-brand-11')));
      await tester.pumpAndSettle();
      expect(repository.productRequests, [(11, null)]);
      expect(find.text('テスト銘柄 純米吟醸'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('sake-catalog-illustration')),
        findsOneWidget,
      );
      await preview(tester, 'brand-products');
      await tester.tap(find.text('もっと見る'));
      await tester.pumpAndSettle();
      expect(repository.productRequests, [(11, null), (11, 500)]);
      expect(find.text('テスト銘柄 純米'), findsOneWidget);
    },
  );

  testWidgets(
    'zoomed map selects the prefecture under the transformed tap and resets',
    (tester) async {
      JapanSakePrefecture? selected;
      await open(
        tester,
        _Repository(),
        Scaffold(
          body: SizedBox(
            height: 500,
            child: ZoomableJapanSakeMap(
              prefectures: data,
              onSelected: (p) => selected = p,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('japan-map-zoom-in')));
      await tester.pumpAndSettle();
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      final matrix = viewer.transformationController!.value;
      expect(matrix.getMaxScaleOnAxis(), closeTo(1.6, .01));
      final map = find.byType(JapanSakeMap);
      final size = tester.getSize(map);
      final scale = math.min(size.width / 720, size.height / 760);
      final offset = Offset(
        (size.width - 720 * scale) / 2,
        (size.height - 760 * scale) / 2,
      );
      final viewport = tester.getTopLeft(
        find.byKey(const ValueKey('japan-map-viewer')),
      );
      final target = data.firstWhere((p) => p.code == 20);
      final point = MatrixUtils.transformPoint(
        matrix,
        offset + target.dots[target.dots.length ~/ 2] * scale,
      );
      expect((Offset.zero & size).contains(point), isTrue);
      await tester.tapAt(viewport + point);
      await tester.pump(const Duration(milliseconds: 350));
      expect(selected?.code, 20);
      await preview(tester, 'map-zoomed');
      await tester.tap(find.byKey(const ValueKey('japan-map-reset')));
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
    },
  );

  testWidgets('full screen map returns its chosen prefecture', (tester) async {
    final repository = _Repository();
    await open(tester, repository, const JapanSakePage());
    await tester.tap(find.byKey(const ValueKey('japan-map-expand')));
    await tester.pumpAndSettle();
    expect(find.text('産地を選ぶ'), findsOneWidget);
    await preview(tester, 'fullscreen-map');
    await tapPrefecture(tester, 1);
    await tester.pumpAndSettle();
    expect(repository.requests, ['北海道']);
    expect(find.text('北海道の銘柄'), findsOneWidget);
  });

  testWidgets(
    'pinching zooms without selecting a prefecture and permits panning',
    (tester) async {
      JapanSakePrefecture? selected;
      await open(
        tester,
        _Repository(),
        Scaffold(
          body: SizedBox(
            height: 500,
            child: ZoomableJapanSakeMap(
              prefectures: data,
              onSelected: (p) => selected = p,
            ),
          ),
        ),
      );
      final center = tester.getCenter(
        find.byKey(const ValueKey('japan-map-viewer')),
      );
      final a = await tester.startGesture(
        center - const Offset(30, 0),
        pointer: 1,
      );
      final b = await tester.startGesture(
        center + const Offset(30, 0),
        pointer: 2,
      );
      await a.moveBy(const Offset(-30, 0));
      await b.moveBy(const Offset(30, 0));
      await tester.pump();
      await a.up();
      await b.up();
      await tester.pumpAndSettle();
      final viewer = tester.widget<InteractiveViewer>(
        find.byType(InteractiveViewer),
      );
      expect(
        viewer.transformationController!.value.getMaxScaleOnAxis(),
        greaterThan(1.1),
      );
      expect(viewer.panEnabled, isTrue);
      expect(selected, isNull);
      final before = viewer.transformationController!.value.clone();
      await tester.dragFrom(center, const Offset(30, 20));
      await tester.pumpAndSettle();
      expect(viewer.transformationController!.value, isNot(before));
      expect(selected, isNull);
    },
  );

  testWidgets(
    'placeholder URLs use the local illustration and broken photos fall back safely',
    (tester) async {
      await open(
        tester,
        _Repository(),
        const Scaffold(
          body: SakeCatalogThumbnail(
            thumbnailImageUrl:
                'https://molasoft-ai-central.com/assets/noimage.png',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sake-catalog-illustration')),
        findsOneWidget,
      );
      await tester.pumpWidget(const SizedBox());
      await open(
        tester,
        _Repository(),
        const Scaffold(
          body: SakeCatalogThumbnail(
            thumbnailImageUrl: 'https://example.com/broken-thumb.jpg',
            primaryImageUrl: 'https://example.com/broken-primary.jpg',
          ),
        ),
      );
      // Widget-test HTTP returns 400, exercising both photo error handlers.
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
      });
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('sake-catalog-illustration')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
