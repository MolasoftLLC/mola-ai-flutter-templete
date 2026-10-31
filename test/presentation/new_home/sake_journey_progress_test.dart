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
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/japan_sake_map.dart';

class _Origins extends PlaceMapRepository {
  _Origins() : super(ApiClient.create());
  final requests = <List<int>>[];
  Future<List<SakeProductOrigin>> Function(List<int>) loader = (ids) async => [
    for (final id in ids)
      SakeProductOrigin(
        sakeId: id,
        canonicalSakeId: id,
        brandId: 11,
        prefectureCode: id <= 10
            ? 15
            : id <= 15
            ? 26
            : 1,
      ),
  ];
  @override
  Future<SakeCatalogPage<SakeBrandSummary>> fetchPrefectureBrands(
    int code, {
    int? afterId,
  }) async => const SakeCatalogPage(items: []);
  @override
  Future<List<SakeProductOrigin>> fetchSakeOrigins(List<int> ids) {
    requests.add(List.of(ids));
    return loader(ids);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await JapanSakeMapData.load();
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
      await (FontLoader('JourneyPreview')..addFont(
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
    _Origins repo,
    ValueNotifier<SavedSakeState> saved, {
    Widget? home,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
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
            key: const ValueKey('journey-preview'),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('ja'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              theme: ThemeData(
                fontFamily:
                    const String.fromEnvironment('JAPAN_UI_FONT').isEmpty
                    ? null
                    : 'JourneyPreview',
              ),
              home:
                  home ??
                  const Scaffold(
                    body: SingleChildScrollView(child: JapanSakeSection()),
                  ),
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
      find.byKey(const ValueKey('journey-preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(data!.buffer.asUint8List());
      image.dispose();
    });
  }

  List<Sake> records(int n) =>
      List.generate(n, (i) => Sake(sakeId: i + 1, impression: '飲んだ記録'));

  testWidgets(
    'prefecture record button opens the counted products only and reacts to history changes',
    (tester) async {
      final repo = _Origins();
      repo.loader = (_) async => [
        for (final id in [1, 100, 2, 3, 4])
          SakeProductOrigin(
            sakeId: id,
            canonicalSakeId: id == 100 ? 1 : id,
            brandId: 11,
            prefectureCode: id == 3 ? 26 : 15,
          ),
      ];
      final saved = ValueNotifier(
        const SavedSakeState(
          savedSakeList: [
            Sake(sakeId: 1, name: '記録した新潟のお酒', impression: '好き', place: '京都'),
            Sake(sakeId: 1, name: '同商品の別記録', impression: '2回目'),
            Sake(sakeId: 100, name: '統合前の商品', impression: '統合元'),
            Sake(sakeId: 2, name: '新潟の別商品', impression: '飲んだ'),
            Sake(sakeId: 3, name: '京都の商品', impression: '飲んだ', place: '新潟'),
            Sake(sakeId: 4, name: '保存だけの商品'),
            Sake(name: '産地不明', impression: '飲んだ'),
          ],
        ),
      );
      addTearDown(saved.dispose);
      await open(
        tester,
        repo,
        saved,
        home: const JapanSakePage(initialPrefectureCode: 15),
      );
      final button = find.byKey(const ValueKey('open-prefecture-records'));
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      expect(find.text('新潟県：記録したお酒 2商品'), findsOneWidget);
      expect(
        find.descendant(of: button, matching: find.byIcon(Icons.arrow_forward)),
        findsOneWidget,
      );
      await preview(tester, 'prefecture-record-button');
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byType(JapanSakeRecordsPage), findsOneWidget);
      expect(find.text('新潟県のお酒の記録'), findsOneWidget);
      expect(find.text('2商品・蔵元の所在地で集計'), findsOneWidget);
      expect(find.text('記録した新潟のお酒'), findsOneWidget);
      expect(find.text('新潟の別商品'), findsOneWidget);
      for (final name in ['同商品の別記録', '統合前の商品', '京都の商品', '保存だけの商品', '産地不明']) {
        expect(find.text(name), findsNothing);
      }
      await preview(tester, 'prefecture-record-list');
      saved.value = const SavedSakeState();
      await tester.pumpAndSettle();
      expect(find.text('この県のお酒の記録はまだありません。'), findsOneWidget);
      expect(find.text('記録した新潟のお酒'), findsNothing);
      Navigator.of(tester.element(find.byType(JapanSakeRecordsPage))).pop();
      await tester.pumpAndSettle();
      expect(find.text('新潟県：記録したお酒 0商品'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'record list retries failed origin lookup without showing a false empty list',
    (tester) async {
      final repo = _Origins();
      repo.loader = (_) async => throw StateError('offline');
      final saved = ValueNotifier(SavedSakeState(savedSakeList: records(1)));
      addTearDown(saved.dispose);
      final prefecture = (await JapanSakeMapData.load()).firstWhere(
        (p) => p.code == 15,
      );
      await open(
        tester,
        repo,
        saved,
        home: JapanSakeRecordsPage(prefecture: prefecture),
      );
      expect(find.text('この県のお酒の記録はまだありません。'), findsNothing);
      final retry = find.text('産地を確認できませんでした。再試行');
      expect(retry, findsOneWidget);
      repo.loader = (_) async => [
        const SakeProductOrigin(
          sakeId: 1,
          canonicalSakeId: 1,
          brandId: 11,
          prefectureCode: 15,
        ),
      ];
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(find.text('1商品・蔵元の所在地で集計'), findsOneWidget);
      expect(find.byKey(const ValueKey('japan-record-1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'record edits, deletion and account changes recompute the map without carrying over another history',
    (tester) async {
      final repo = _Origins();
      final saved = ValueNotifier(SavedSakeState(savedSakeList: records(16)));
      addTearDown(saved.dispose);
      await open(tester, repo, saved);
      JapanSakeMap map() =>
          tester.widget<JapanSakeMap>(find.byType(JapanSakeMap).last);
      expect(map().productCounts, {15: 10, 26: 5, 1: 1});
      expect(find.text('記録した商品数'), findsOneWidget);
      await preview(tester, 'journey-home');
      saved.value = SavedSakeState(
        savedSakeList: records(16).where((r) => r.sakeId != 10).toList(),
      );
      await tester.pumpAndSettle();
      expect(map().productCounts, {15: 9, 26: 5, 1: 1});
      saved.value = const SavedSakeState();
      await tester.pumpAndSettle();
      expect(map().productCounts, isEmpty);
      final nextAccount = Completer<List<SakeProductOrigin>>();
      repo.loader = (_) => nextAccount.future;
      saved.value = const SavedSakeState(
        savedSakeList: [Sake(sakeId: 99, impression: '別アカウント')],
      );
      await tester.pump();
      await tester.pump();
      expect(map().productCounts, isEmpty);
      nextAccount.complete([
        const SakeProductOrigin(
          sakeId: 99,
          canonicalSakeId: 99,
          brandId: 22,
          prefectureCode: 1,
        ),
      ]);
      await tester.pumpAndSettle();
      expect(map().productCounts, {1: 1});
    },
  );

  testWidgets(
    'the journey map has record colors and errors can retry without changing records',
    (tester) async {
      final repo = _Origins();
      final saved = ValueNotifier(SavedSakeState(savedSakeList: records(10)));
      addTearDown(saved.dispose);
      await open(tester, repo, saved, home: const JapanSakePage());
      expect(
        tester
            .widget<JapanSakeMap>(find.byType(JapanSakeMap).last)
            .productCounts,
        {15: 10},
      );
      await preview(tester, 'journey-fullscreen');
      repo.loader = (_) async => throw StateError('offline');
      saved.value = SavedSakeState(savedSakeList: records(9));
      await tester.pumpAndSettle();
      final retry = find.text('産地を確認できませんでした。再試行');
      expect(retry, findsOneWidget);
      repo.loader = (ids) async => [
        for (final id in ids)
          SakeProductOrigin(
            sakeId: id,
            canonicalSakeId: id,
            brandId: 11,
            prefectureCode: 15,
          ),
      ];
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<JapanSakeMap>(find.byType(JapanSakeMap).last)
            .productCounts,
        {15: 9},
      );
      expect(saved.value.savedSakeList.length, 9);
      expect(tester.takeException(), isNull);
    },
  );
}
