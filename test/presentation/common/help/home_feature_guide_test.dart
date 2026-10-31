import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/common/help/home_feature_guide.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/japan_sake_page.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/japan_sake_map.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await JapanSakeMapData.load();
    const font = String.fromEnvironment('JAPAN_UI_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('GuidePreview')..addFont(
            Future.value(ByteData.sublistView(await File(font).readAsBytes())),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  Future<void> open(WidgetTester tester, HomeFeatureGuide guide) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      guide.dispose();
    });
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('guide-preview'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ja'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ThemeData(
            fontFamily: const String.fromEnvironment('JAPAN_UI_FONT').isEmpty
                ? null
                : 'GuidePreview',
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  Row(
                    children: [
                      for (final key in [guide.headerScanKey, guide.searchKey])
                        SizedBox(key: key, width: 60, height: 50),
                      TextButton(
                        onPressed: () =>
                            unawaited(guide.showIfNeeded(context, () => true)),
                        child: const Text('案内'),
                      ),
                      TextButton(
                        onPressed: () => unawaited(
                          guide.showIfNeeded(context, () => true, force: true),
                        ),
                        child: const Text('もう一度'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: ListView(
                      controller: guide.homeScrollController,
                      children: [
                        const SizedBox(height: 900),
                        SizedBox(
                          key: guide.recommendationsKey,
                          height: 250,
                          child: const Text('あなたが好きそうな日本酒'),
                        ),
                        const SizedBox(height: 500),
                        SizedBox(
                          key: guide.timelineKey,
                          height: 250,
                          child: const Text('タイムライン'),
                        ),
                        const SizedBox(height: 500),
                        JapanSakeSection(key: guide.japanSakeKey),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      for (final key in [
                        guide.bottomScanKey,
                        guide.menuAnalysisKey,
                        guide.mapKey,
                        guide.myPageKey,
                      ])
                        SizedBox(key: key, width: 60, height: 60),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'home tutorial scrolls to the new final sake journey step and can be replayed',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final guide = HomeFeatureGuide();
      await open(tester, guide);
      // It starts outside the lazily built portion of the home list.
      expect(guide.japanSakeKey.currentContext, isNull);
      await tester.tap(find.text('案内'));
      await tester.pumpAndSettle();
      for (var step = 0; step < 8; step++) {
        await tester.tap(find.text(step == 0 ? '使い方を見る' : '次へ'));
        await tester.pumpAndSettle();
        expect(find.text('${step + 1} / 8'), findsOneWidget);
        if (step == 0) {
          expect(
            find.byKey(const ValueKey('guide-expanded-capture-menu')),
            findsOneWidget,
          );
          expect(find.text('ラベルを撮る'), findsOneWidget);
          expect(find.text('メニューを撮る'), findsOneWidget);
          expect(find.text('写真から選ぶ'), findsOneWidget);
          expect(
            tester.getRect(find.text('次へ')).bottom,
            lessThan(
              tester
                  .getRect(find.byKey(const ValueKey('capture-action-label')))
                  .top,
            ),
          );
          const output = String.fromEnvironment('JAPAN_UI_OUTPUT');
          if (output.isNotEmpty) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('guide-preview')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await Directory(output).create(recursive: true);
              await File(
                '$output/capture-guide.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        } else {
          expect(
            find.byKey(const ValueKey('guide-expanded-capture-menu')),
            findsNothing,
          );
        }
      }
      final overlay = find.byType(FeatureGuideOverlay);
      expect(
        find.descendant(of: overlay, matching: find.text('日本酒を旅する')),
        findsOneWidget,
      );
      expect(find.textContaining('10商品以上でオレンジ'), findsOneWidget);
      expect(find.textContaining('県別の記録一覧'), findsOneWidget);
      expect(guide.japanSakeKey.currentContext, isNotNull);
      final target = tester.getRect(find.byKey(guide.japanSakeKey));
      expect(target.top, greaterThanOrEqualTo(50));
      expect(target.top, lessThan(200));
      expect(guide.homeScrollController.offset, greaterThan(1500));
      expect(tester.takeException(), isNull);

      const output = String.fromEnvironment('JAPAN_UI_OUTPUT');
      if (output.isNotEmpty) {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('guide-preview')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File(
            '$output/japan-sake-tutorial.png',
          ).writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }
      // Back also restores a previous section that was scrolled offscreen.
      for (var step = 6; step >= 0; step--) {
        await tester.tap(find.text('戻る'));
        await tester.pumpAndSettle();
        expect(find.text('${step + 1} / 8'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      expect(guide.homeScrollController.offset, 0);
      for (var step = 1; step < 8; step++) {
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('home_feature_guide_shown_v5'), isTrue);
      await tester.tap(find.text('案内'));
      await tester.pumpAndSettle();
      expect(overlay, findsNothing);
      await tester.tap(find.text('もう一度'));
      await tester.pumpAndSettle();
      expect(overlay, findsOneWidget);
      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();
      expect(overlay, findsNothing);
    },
  );

  testWidgets(
    'existing completion is preserved unless the user replays the tutorial',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'home_feature_guide_shown_v5': true,
      });
      final guide = HomeFeatureGuide();
      await open(tester, guide);
      await tester.tap(find.text('案内'));
      await tester.pumpAndSettle();
      expect(find.byType(FeatureGuideOverlay), findsNothing);
      await tester.tap(find.text('もう一度'));
      await tester.pumpAndSettle();
      expect(find.byType(FeatureGuideOverlay), findsOneWidget);
      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('guide remains scrollable on a small screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 568),
            textScaler: TextScaler.linear(1.8),
          ),
          child: FeatureGuideOverlay(
            capturePreviewAnchor: () => const Offset(160, 520),
            titles: const ['場所を残して、次の一本へ'],
            messages: const ['解析を待つ間に場所を選べます。操作を始めたら、候補へ進むタイミングは自分で選べます。'],
            readTargets: (_) => [],
            prepareStep: (_) async {},
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('使い方を見る'));
    await tester.tap(find.text('使い方を見る'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'), findsOneWidget);
    await tester.ensureVisible(find.text('戻る'));
    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();
    expect(find.text('SAKEPEDIA GUIDE'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
