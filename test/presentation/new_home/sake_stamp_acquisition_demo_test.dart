import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_stamp_acquisition_demo.dart';

void main() {
  final haptics = <String>[];
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'SakeSeal',
    )..addFont(rootBundle.load('assets/fonts/YujiSyuku-Regular.ttf'))).load();
    const font = String.fromEnvironment('JAPAN_UI_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('PreviewUI')..addFont(
            Future.value(ByteData.sublistView(await File(font).readAsBytes())),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  setUp(() {
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> open(
    WidgetTester tester, {
    bool reduced = false,
    bool actual = false,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('demo-preview'),
        child: MaterialApp(
          locale: const Locale('ja'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: const String.fromEnvironment('JAPAN_UI_FONT').isEmpty
                ? null
                : 'PreviewUI',
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduced,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: Center(
              child: actual
                  ? Builder(
                      builder: (context) => TextButton(
                        key: const ValueKey('actual-award'),
                        onPressed: () => showGeneralDialog<void>(
                          context: context,
                          barrierColor: const Color(
                            0xFF071C35,
                          ).withValues(alpha: .88),
                          pageBuilder: (_, __, ___) =>
                              const SakeStampAcquisitionDemo(
                                demo: false,
                                brandName: '栄光冨士',
                                prefectureName: '山形県',
                                brandId: 309,
                              ),
                        ),
                        child: const Text('award'),
                      ),
                    )
                  : const SakeStampDemoButton(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(
      find.byKey(ValueKey(actual ? 'actual-award' : 'sake-stamp-demo-button')),
    );
    await tester.pump();
  }

  testWidgets(
    'home demo plays once, replays with one haptic per press and closes without a data provider',
    (tester) async {
      await open(tester);
      await tester.pump(const Duration(milliseconds: 600));
      expect(haptics, isEmpty);
      final seal = find.byKey(const ValueKey('acquisition-demo-seal'));
      final before = tester
          .widget<Transform>(seal)
          .transform
          .getMaxScaleOnAxis();
      await tester.pump(const Duration(milliseconds: 550));
      expect(
        tester.widget<Transform>(seal).transform.getMaxScaleOnAxis(),
        lessThan(before),
      );
      expect(haptics, ['HapticFeedbackType.lightImpact']);
      await tester.pumpAndSettle();
      expect(find.text('新しい酒印を獲得！'), findsOneWidget);
      expect(find.text('デモのため、酒印・飲んだ記録は追加されません'), findsOneWidget);
      expect(haptics.length, 1);
      await tester.tap(find.byKey(const ValueKey('replay-stamp-demo')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pumpAndSettle();
      expect(haptics.length, 2);
      await tester.tap(find.byKey(const ValueKey('close-stamp-demo')));
      await tester.pumpAndSettle();
      expect(find.byType(SakeStampAcquisitionDemo), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dismissing before impact cancels animation and haptic', (
    tester,
  ) async {
    await open(tester);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const ValueKey('close-stamp-demo')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 3));
    expect(haptics, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('実取得は対象銘柄を押印し、デモの説明とリプレイは表示しない', (tester) async {
    await open(tester, actual: true);
    await tester.pumpAndSettle();
    expect(find.text('栄光冨士  ·  山形県'), findsOneWidget);
    expect(find.text('一杯の出会いを、日々の思い出に'), findsOneWidget);
    expect(find.textContaining('デモ'), findsNothing);
    expect(find.byKey(const ValueKey('replay-stamp-demo')), findsNothing);
    const output = String.fromEnvironment('STAMP_REAL_OUTPUT');
    if (output.isNotEmpty) {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('demo-preview')),
      );
      await tester.runAsync(() async {
        final img = await boundary.toImage(pixelRatio: 2);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File(
          '$output/real-acquisition.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
    }
    await tester.tap(find.byKey(const ValueKey('close-stamp-demo')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'reduce motion displays final artwork immediately without haptics',
    (tester) async {
      await open(tester, reduced: true);
      await tester.pumpAndSettle();
      final opacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('acquisition-demo-title')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 1);
      expect(tester.binding.hasScheduledFrame, isFalse);
      await tester.tap(find.byKey(const ValueKey('replay-stamp-demo')));
      await tester.pumpAndSettle();
      expect(haptics, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'small phone and large text can scroll to close without overflow',
    (tester) async {
      await open(tester, size: const Size(320, 568), textScale: 1.8);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(
        find.byKey(const ValueKey('close-stamp-demo')),
      );
      await tester.tap(find.byKey(const ValueKey('close-stamp-demo')));
      await tester.pumpAndSettle();
      expect(find.byType(SakeStampAcquisitionDemo), findsNothing);
    },
  );

  testWidgets('render actual animation frames for visual review', (
    tester,
  ) async {
    const output = String.fromEnvironment('STAMP_DEMO_OUTPUT');
    if (output.isEmpty) return;
    await open(tester);
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('demo-preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File(
          '$output/frame-${i.toString().padLeft(3, '0')}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(tester.takeException(), isNull);
  });
}
