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
  Future<List<SakeProductOrigin>> fetchSakeOrigins(List<int> ids) {
    requests.add(List.of(ids));
    return loader(ids);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await JapanSakeMapData.load();
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
    'the full screen map has the same record colors and errors can retry without changing records',
    (tester) async {
      final repo = _Origins();
      final saved = ValueNotifier(SavedSakeState(savedSakeList: records(10)));
      addTearDown(saved.dispose);
      await open(tester, repo, saved, home: const JapanSakePage());
      await tester.tap(find.byKey(const ValueKey('japan-map-expand')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<JapanSakeMap>(find.byType(JapanSakeMap).last)
            .productCounts,
        {15: 10},
      );
      await preview(tester, 'journey-fullscreen');
      Navigator.of(tester.element(find.byType(JapanSakeMap).last)).pop();
      await tester.pumpAndSettle();
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
