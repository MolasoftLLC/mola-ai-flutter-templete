import 'dart:async';
import 'dart:io';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_camera_page.dart';
import '../../support/fake_menu_camera.dart';

void main() {
  late CameraPlatform original;
  late FakeMenuCamera camera;
  setUp(() {
    loggerConfigure();
    original = CameraPlatform.instance;
    camera = FakeMenuCamera();
    CameraPlatform.instance = camera;
  });
  tearDown(() async {
    CameraPlatform.instance = original;
    await camera.close();
  });
  Widget app(Widget home) => MaterialApp(
    locale: const Locale('ja'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: home,
  );
  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  }

  testWidgets(
    'shutter returns the full image immediately, with no system review and no duplicate captures',
    (tester) async {
      File? captured;
      camera.captureGate = Completer<void>();
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                captured = await Navigator.of(context).push<File>(
                  MaterialPageRoute(builder: (_) => const MenuCameraPage()),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(camera.descriptions.single.name, 'wide');
      expect(camera.audio, [false]);
      await tester.tap(find.byKey(const ValueKey('menu-camera-shutter')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('menu-camera-shutter')));
      await tester.pump();
      expect(camera.captures, 1);
      expect(captured, isNull);
      camera.captureGate!.complete();
      await tester.pumpAndSettle();
      expect(captured!.path, camera.path);
      expect(find.byType(MenuCameraPage), findsNothing);
      expect(camera.disposed, camera.created);
      await close(tester);
    },
  );

  testWidgets(
    'permission failure offers retry and back instead of opening the system picker',
    (tester) async {
      camera.denied = true;
      await tester.pumpWidget(app(const MenuCameraPage()));
      await tester.pumpAndSettle();
      expect(find.textContaining('カメラの使用が許可されていません'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('menu-camera-shutter')),
            )
            .onPressed,
        isNull,
      );
      camera.denied = false;
      await tester.tap(find.text('再読み込み'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('menu-camera-shutter')),
            )
            .onPressed,
        isNotNull,
      );
      expect(camera.created, hasLength(1));
      await close(tester);
      expect(camera.disposed, camera.created);
    },
  );

  testWidgets(
    'capture failures can be retried, and light is controlled without microphone access',
    (tester) async {
      camera.failCapture = true;
      await tester.pumpWidget(
        app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push<File>(
                MaterialPageRoute(builder: (_) => const MenuCameraPage()),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('menu-camera-shutter')));
      await tester.pumpAndSettle();
      expect(find.text('撮影できませんでした。もう一度撮影してください。'), findsOneWidget);
      expect(camera.captures, 1);
      await tester.tap(find.byTooltip('ライトの切り替え'));
      await tester.pumpAndSettle();
      expect(camera.flashes.last, FlashMode.torch);
      camera.failCapture = false;
      await tester.tap(find.byKey(const ValueKey('menu-camera-shutter')));
      await tester.pumpAndSettle();
      expect(camera.captures, 2);
      expect(camera.audio, [false]);
      await close(tester);
    },
  );

  testWidgets(
    'background/resume during initialization disposes the stale camera before opening another',
    (tester) async {
      camera.initializeGate = Completer<void>();
      await tester.pumpWidget(app(const MenuCameraPage()));
      await tester.pump();
      await tester.pump();
      expect(camera.created, hasLength(1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      camera.initializeGate!.complete();
      await tester.pumpAndSettle();
      expect(camera.created, hasLength(2));
      expect(camera.disposed, [1]);
      await close(tester);
      expect(camera.disposed, [1, 2]);
      expect(tester.takeException(), isNull);
    },
  );
}
