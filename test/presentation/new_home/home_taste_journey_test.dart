import 'dart:io';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/auth/auth_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/my_page/my_page_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/favorite/favorite_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/app_page_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/common/help/home_feature_guide.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/journey/sake_journey.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/home_taste_journey.dart';

class _App implements AppPageNotifier {
  @override
  final homeFeatureGuide = HomeFeatureGuide();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'real home adapter respects tutorial visibility and persists later without intercepting search',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final interval = VisibilityDetectorController.instance.updateInterval;
      VisibilityDetectorController.instance.updateInterval = Duration.zero;
      addTearDown(
        () => VisibilityDetectorController.instance.updateInterval = interval,
      );
      final app = _App();
      var searches = 0;
      final child = MaterialApp(
        home: Scaffold(
          body: HomeTasteJourney(
            onSearch: () async {
              searches++;
            },
            onScan: () async {},
            onRecommendations: () {},
          ),
        ),
      );
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthState>.value(value: const AuthState()),
            Provider<MyPageState>.value(
              value: const MyPageState(preferences: '甘口'),
            ),
            Provider<FavoriteState>.value(value: const FavoriteState()),
            Provider<AppPageState>.value(value: const AppPageState()),
            Provider<AppPageNotifier>.value(value: app),
          ],
          child: child,
        ),
      );
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-taste-journey')), findsOneWidget);
      app.homeFeatureGuide.visibility.value = true;
      await tester.pump();
      expect(find.byKey(const ValueKey('home-taste-journey')), findsNothing);
      app.homeFeatureGuide.visibility.value = false;
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'お酒を探す'));
      await tester.pumpAndSettle();
      expect(searches, 1);
      await tester.tap(find.text('あとで'));
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('home-taste-journey')), findsNothing);
      expect((await SakeJourneyStore.instance.load('guest')).until, isNotNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      app.homeFeatureGuide.dispose();
    },
  );

  testWidgets(
    'each stage has one action and forwards taps without automatically opening dialogs',
    (tester) async {
      const cases = [
        (JourneySnapshot(), 0, '好みを選ぶ'),
        (JourneySnapshot(steps: {JourneyStep.preference}), 0, 'お酒を探す'),
        (
          JourneySnapshot(steps: {JourneyStep.preference, JourneyStep.like}),
          1,
          'もう少し探す',
        ),
        (
          JourneySnapshot(steps: {JourneyStep.preference, JourneyStep.like}),
          2,
          'お気に入りから診断',
        ),
        (
          JourneySnapshot(
            steps: {
              JourneyStep.preference,
              JourneyStep.like,
              JourneyStep.diagnosis,
            },
          ),
          2,
          '解析してみる',
        ),
      ];
      for (final (progress, likes, label) in cases) {
        var tapped = 0, later = 0, hidden = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: HomeTasteJourneyCard(
                  progress: progress,
                  likes: likes,
                  onAction: () => tapped++,
                  onLater: () => later++,
                  onHide: () => hidden++,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(FilledButton), findsOneWidget);
        expect(find.byType(AlertDialog), findsNothing);
        await tester.tap(find.widgetWithText(FilledButton, label));
        expect(tapped, 1);
        await tester.tap(find.text('あとで'));
        expect(later, 1);
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('この案内を表示しない'));
        await tester.pumpAndSettle();
        expect(hidden, 1);
      }
    },
  );
  testWidgets(
    'progress is preparation, not taste accuracy; card fits small screen and large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (_, child) => MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeTasteJourneyCard(
                progress: const JourneySnapshot(
                  steps: {JourneyStep.preference, JourneyStep.like},
                ),
                likes: 2,
                onAction: () {},
                onLater: () {},
                onHide: () {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('お酒えらびの準備 2 / 4'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('render implemented journey guide states', (tester) async {
    const output = String.fromEnvironment('JOURNEY_UI_OUTPUT');
    if (output.isEmpty) return;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      final font = FontLoader('Preview')
        ..addFont(
          Future.value(
            ByteData.sublistView(
              await File('/Library/Fonts/Arial Unicode.ttf').readAsBytes(),
            ),
          ),
        );
      await font.load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final states = [
      (const JourneySnapshot(), 0, '01-preferences'),
      (
        const JourneySnapshot(
          steps: {JourneyStep.preference, JourneyStep.like},
        ),
        2,
        '02-diagnosis',
      ),
      (
        const JourneySnapshot(
          steps: {
            JourneyStep.preference,
            JourneyStep.like,
            JourneyStep.diagnosis,
          },
        ),
        2,
        '03-scan',
      ),
    ];
    for (final (progress, likes, name) in states) {
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('journey-preview'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: 'Preview'),
            home: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: const Color(0xFF143861),
                title: const Text(
                  'SAKEPEDIA',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.only(top: 24),
                children: [
                  HomeTasteJourneyCard(
                    progress: progress,
                    likes: likes,
                    onAction: () {},
                    onLater: () {},
                    onHide: () {},
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '最近調べたお酒',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('journey-preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File('$output/$name.png').writeAsBytes(png!.buffer.asUint8List());
      });
    }
  });
}
