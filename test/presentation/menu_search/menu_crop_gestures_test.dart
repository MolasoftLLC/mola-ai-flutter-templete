import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_photo_crop_page.dart';

void main() {
  late Directory directory;
  late File photo;
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('menu-crop-gestures-');
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawColor(Colors.white, BlendMode.src);
    canvas.drawRect(
      const Rect.fromLTWH(20, 20, 200, 360),
      Paint()..color = Colors.blue,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(240, 420);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    photo = await File(
      '${directory.path}/photo.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
    picture.dispose();
  });
  tearDownAll(() => directory.delete(recursive: true));

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
  });

  late Future<File?> result;
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final navigator = GlobalKey<NavigatorState>();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          locale: const Locale('ja'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(),
        ),
      );
      result = navigator.currentState!.push<File>(
        MaterialPageRoute(builder: (_) => MenuPhotoCropPage(image: photo)),
      );
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a vertical corner drag moves the crop instead of scrolling the page',
    (tester) async {
      await open(tester);
      final handle = find.byKey(const ValueKey('crop-topLeft'));
      final start = tester.getCenter(handle);
      final scroll = tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position;
      final scrollStart = scroll.pixels;
      final gesture = await tester.startGesture(start);
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();
      expect(tester.getCenter(handle).dy, closeTo(start.dy + 48, 1));
      expect(scroll.pixels, scrollStart);
      await gesture.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'the corner follows a one-pixel movement without jumping to the finger',
    (tester) async {
      await open(tester);
      final handle = find.byKey(const ValueKey('crop-topLeft'));
      final start = tester.getCenter(handle);
      final gesture = await tester.startGesture(start + const Offset(16, 14));
      await gesture.moveBy(const Offset(1, 1));
      await tester.pump();
      expect(tester.getCenter(handle).dx, closeTo(start.dx + 1, .1));
      expect(tester.getCenter(handle).dy, closeTo(start.dy + 1, .1));
      await gesture.moveBy(const Offset(28, 36));
      await tester.pump();
      expect(tester.getCenter(handle).dx, closeTo(start.dx + 29, .1));
      expect(tester.getCenter(handle).dy, closeTo(start.dy + 37, .1));
      await gesture.up();
    },
  );
  testWidgets(
    'corners can be grabbed off the visible line and edges resize directly',
    (tester) async {
      await open(tester);
      final corner = find.byKey(const ValueKey('crop-topLeft'));
      final start = tester.getCenter(corner);
      final gesture = await tester.startGesture(start + const Offset(28, 16));
      await gesture.moveBy(const Offset(24, 36));
      await tester.pump();
      expect(
        (tester.getCenter(corner) - start - const Offset(24, 36)).distance,
        lessThan(.1),
      );
      await gesture.up();
      final before = tester.getRect(
        find.byKey(const ValueKey('crop-selection')),
      );
      await tester.dragFrom(
        tester.getCenter(find.byKey(const ValueKey('crop-top'))),
        const Offset(0, 24),
      );
      await tester.pump();
      final after = tester.getRect(
        find.byKey(const ValueKey('crop-selection')),
      );
      expect(after.left, before.left);
      expect(after.right, before.right);
      expect(after.top, closeTo(before.top + 24, .1));
      expect(after.bottom, before.bottom);
    },
  );

  testWidgets(
    'dragging inside moves the entire selection and clamps to image boundaries',
    (tester) async {
      await open(tester);
      await tester.dragFrom(
        tester.getCenter(find.byKey(const ValueKey('crop-topLeft'))),
        const Offset(40, 60),
      );
      await tester.pump();
      await tester.dragFrom(
        tester.getCenter(find.byKey(const ValueKey('crop-bottomRight'))),
        const Offset(-30, -40),
      );
      await tester.pump();
      final selection = find.byKey(const ValueKey('crop-selection'));
      final before = tester.getRect(selection);
      final gesture = await tester.startGesture(before.center);
      await gesture.moveBy(const Offset(20, 30));
      await tester.pump();
      final moved = tester.getRect(selection);
      expect(moved.width, closeTo(before.width, .1));
      expect(moved.height, closeTo(before.height, .1));
      expect(
        (moved.topLeft - before.topLeft - const Offset(20, 30)).distance,
        lessThan(.1),
      );
      await gesture.moveBy(const Offset(2000, 2000));
      await tester.pump();
      final clamped = tester.getRect(selection);
      final image = tester.getRect(find.byType(RawImage));
      expect(clamped.right, closeTo(image.right, .1));
      expect(clamped.bottom, closeTo(image.bottom, .1));
      expect(clamped.width, closeTo(before.width, .1));
      expect(clamped.height, closeTo(before.height, .1));
      await gesture.up();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('confirm saves the selected bounds and preserves the original', (
    tester,
  ) async {
    final original = await tester.runAsync(photo.readAsBytes);
    await open(tester);
    await tester.dragFrom(
      tester.getCenter(find.byKey(const ValueKey('crop-topLeft'))),
      const Offset(40, 60),
    );
    await tester.pump();
    final selected = tester.getRect(
      find.byKey(const ValueKey('crop-selection')),
    );
    final image = tester.getRect(find.byType(RawImage));
    final expectedWidth =
        ((selected.right - image.left) / image.width * 240).round() -
        ((selected.left - image.left) / image.width * 240).round();
    final expectedHeight =
        ((selected.bottom - image.top) / image.height * 420).round() -
        ((selected.top - image.top) / image.height * 420).round();
    await tester.runAsync(() async {
      await tester.tap(find.text('この範囲で決定'));
      final cropped = await result.timeout(const Duration(seconds: 5));
      expect(cropped, isNotNull);
      expect(cropped!.path, isNot(photo.path));
      final codec = await ui.instantiateImageCodec(await cropped.readAsBytes());
      final output = (await codec.getNextFrame()).image;
      expect(output.width, expectedWidth);
      expect(output.height, expectedHeight);
      expect(await photo.readAsBytes(), original);
      output.dispose();
      codec.dispose();
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
