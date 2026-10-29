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
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/japan_sake_page.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/japan_sake_map.dart';

class _Repository extends PlaceMapRepository {
  _Repository() : super(ApiClient.create());
  final requests = <String>[];
  Future<List<SakeMapSearchResult>> Function(String) loader = (_) async =>
      const [];
  @override
  Future<List<SakeMapSearchResult>> discoverSakeMasters({
    String? prefecture,
    List<String>? flavors,
    List<String>? tastes,
    List<String>? designs,
  }) {
    requests.add(prefecture!);
    return loader(prefecture);
  }
}

void main() {
  late List<JapanSakePrefecture> data;
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    data = await JapanSakeMapData.load();
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
    await tester.pump();
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
      repository.loader = (name) async => [
        SakeMapSearchResult(
          sakeId: 123,
          name: '$nameの日本酒',
          brewery: '蔵元',
          isMaster: true,
        ),
      ];
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
      expect(find.text('北海道の日本酒'), findsOneWidget);
      await preview(tester, 'hokkaido');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'switching prefectures ignores late results and reuses loaded catalogs',
    (tester) async {
      final repository = _Repository();
      final niigata = Completer<List<SakeMapSearchResult>>();
      final hokkaido = Completer<List<SakeMapSearchResult>>();
      repository.loader = (name) =>
          name == '新潟県' ? niigata.future : hokkaido.future;
      await open(tester, repository, const JapanSakePage());
      await tapPrefecture(tester, 15);
      await tapPrefecture(tester, 1);
      niigata.complete([
        const SakeMapSearchResult(sakeId: 15, name: '新潟のお酒', isMaster: true),
      ]);
      await tester.pump();
      expect(find.text('新潟のお酒'), findsNothing);
      hokkaido.complete([
        const SakeMapSearchResult(sakeId: 1, name: '北海道のテスト商品', isMaster: true),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('北海道のテスト商品'), findsOneWidget);
      await tapPrefecture(tester, 15);
      await tester.pumpAndSettle();
      expect(find.text('新潟のお酒'), findsOneWidget);
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
      repository.loader = (_) async => const [];
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
      await tester.ensureVisible(
        find.byKey(const ValueKey('choose-japan-prefecture')),
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
      expect(find.text('沖縄県のお酒'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await preview(tester, 'small');
    },
  );
}
