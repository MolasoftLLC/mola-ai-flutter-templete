import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/domain/repository/auth_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_scan_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_menu_recognition_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_user_repository.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/saved_sake/saved_sake_notifier.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_scan/sake_scan_page.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_scan/widgets/label_capture_guide.dart';
import '../../support/fake_menu_camera.dart';

void main() {
  late CameraPlatform original;
  late FakeMenuCamera camera;
  setUpAll(() async {
    loggerConfigure();
    const font = String.fromEnvironment('GUIDE_UI_FONT');
    if (font.isNotEmpty) {
      final loader = FontLoader('GuidePreview')
        ..addFont(
          Future.value(ByteData.sublistView(await File(font).readAsBytes())),
        );
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    original = CameraPlatform.instance;
    camera = FakeMenuCamera();
    CameraPlatform.instance = camera;
  });
  tearDown(() async {
    CameraPlatform.instance = original;
    await camera.close();
  });
  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double scale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: _Auth()),
          Provider<SakeUserRepository>.value(value: _Users()),
          Provider<SakeScanRepository>.value(value: _Scan()),
          Provider<SakeMenuRecognitionRepository>.value(value: _Menus()),
          Provider<SavedSakeNotifier>.value(value: _Saved()),
        ],
        child: RepaintBoundary(
          key: const ValueKey('guide-preview'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ja'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData(
              fontFamily: const String.fromEnvironment('GUIDE_UI_FONT').isEmpty
                  ? null
                  : 'GuidePreview',
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(scale),
                padding: const EdgeInsets.only(top: 44, bottom: 34),
              ),
              child: child!,
            ),
            home: SakeScanPage.wrapped(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  Finder guidePaint() => find.descendant(
    of: find.byType(LabelCaptureGuide),
    matching: find.byType(CustomPaint),
  );
  Future<void> preview(WidgetTester tester, String name) async {
    const output = String.fromEnvironment('GUIDE_UI_OUTPUT');
    if (output.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('guide-preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  testWidgets('日本酒瓶の枠を撮影エリアの約8割の高さまで広げ、操作を妨げず表示を切り替えられる', (tester) async {
    await open(tester);
    final size = tester.getSize(guidePaint());
    expect(size.height, greaterThan((844 - 78) * .80));
    expect(size.width / size.height, lessThan(.38));
    final bounds = tester.getRect(guidePaint());
    // The 626pt outline keeps its size and moves 12% of the 766pt viewport up.
    expect(size.width, closeTo(187.8, .01));
    expect(size.height, closeTo(626, .01));
    expect(bounds.top, closeTo(44 + 128 - 766 * .12, .01));
    expect(bounds.bottom, closeTo(844 - 34 - 12 - 766 * .12, .01));
    expect(find.textContaining('ラベルが大きく写る距離'), findsOneWidget);
    await preview(tester, 'front');
    await tester.tap(find.text('補助枠を消す'));
    await tester.pumpAndSettle();
    expect(find.byType(LabelCaptureGuide), findsNothing);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'sake_scan_capture_guide_visible_v1',
      ),
      false,
    );
    await tester.tap(find.text('補助枠を表示'));
    await tester.pumpAndSettle();
    expect(tester.getSize(guidePaint()), size);
    await close(tester);
  });
  testWidgets('小さな画面と大きな文字でも瓶の枠を大きく保ち、メニュー用の四角い枠は維持する', (tester) async {
    await open(tester, size: const Size(320, 568), scale: 1.5);
    final size = tester.getSize(guidePaint());
    expect(size.height, greaterThan((568 - 78) * .60));
    expect(tester.takeException(), isNull);
    await preview(tester, 'small');
    await tester.tap(find.text('メニュー検索'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<LabelCaptureGuide>(find.byType(LabelCaptureGuide))
          .isBackLabel,
      true,
    );
    expect(tester.takeException(), isNull);
    await close(tester);
  });
}

class _Auth implements AuthRepository {
  @override
  User? get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users implements SakeUserRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Scan implements SakeScanRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Menus implements SakeMenuRecognitionRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Saved implements SavedSakeNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
