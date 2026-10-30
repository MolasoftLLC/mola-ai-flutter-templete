import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_stamp_book_opening.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await (FontLoader(
      'SakeSeal',
    )..addFont(rootBundle.load('assets/fonts/YujiSyuku-Regular.ttf'))).load();
  });
  final cover = find.byKey(const ValueKey('stamp-book-cover'));
  final sheet = find.byKey(const ValueKey('stamp-opening-sheet'));
  var taps = 0;
  Widget book({
    bool reduced = false,
    double scale = 1,
    String label = 'stamps',
  }) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        disableAnimations: reduced,
        textScaler: TextScaler.linear(scale),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9F8),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: RepaintBoundary(
              key: const ValueKey('opening-preview'),
              child: SakeStampBookOpening(
                child: SizedBox(
                  height: 236,
                  child: ColoredBox(
                    color: const Color(0xFFFFF8E9),
                    child: Center(
                      child: TextButton(
                        onPressed: () => taps++,
                        child: Text(label),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> shot(WidgetTester tester, String name) async {
    const output = String.fromEnvironment('STAMP_OPENING_OUTPUT');
    if (output.isEmpty) return;
    final render = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('opening-preview')),
    );
    await tester.runAsync(() async {
      final img = await render.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
      img.dispose();
    });
  }

  testWidgets('タップで左綴じの表紙が持ち上がり、完了までは酒印を誤タップしない', (tester) async {
    taps = 0;
    await tester.pumpWidget(book());
    expect(cover, findsOneWidget);
    await shot(tester, '00-cover');
    await tester.tap(cover);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final transform = tester.widget<Transform>(sheet).transform;
    expect(transform.entry(2, 0), lessThan(0));
    expect(transform.entry(0, 0), inExclusiveRange(0, 1));
    expect(taps, 0);
    await shot(tester, '01-opening');
    await tester.pumpAndSettle();
    expect(cover, findsNothing);
    await tester.tap(find.text('stamps'));
    expect(taps, 1);
    await tester.pumpWidget(book(label: 'changed'));
    expect(cover, findsNothing);
    await tester.tap(find.text('changed'));
    expect(taps, 2);
    expect(tester.takeException(), isNull);
  });
  testWidgets('短いドラッグは戻り、左へのスワイプで開く。縦ドラッグでは開かない', (tester) async {
    await tester.pumpWidget(book());
    await tester.drag(cover, const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(cover, findsOneWidget);
    final short = await tester.startGesture(tester.getCenter(cover));
    await short.moveBy(const Offset(-20, 0));
    await tester.pump(const Duration(milliseconds: 200));
    await short.moveBy(const Offset(-10, 0));
    await tester.pump(const Duration(milliseconds: 200));
    await short.up();
    await tester.pumpAndSettle();
    expect(cover, findsOneWidget);
    expect(tester.widget<Transform>(sheet).transform.entry(0, 0), 1);
    await tester.fling(cover, const Offset(-250, 0), 1000);
    await tester.pumpAndSettle();
    expect(cover, findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('小画面・文字拡大でも紙が操作領域内に収まり、終了時にアニメーションを破棄する', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(book(scale: 1.5));
    final drag = await tester.startGesture(tester.getCenter(cover));
    await drag.moveBy(const Offset(-30, 0));
    await tester.pump();
    await drag.moveBy(const Offset(-90, 0));
    await tester.pump();
    final page = tester.renderObject<RenderBox>(
      find.descendant(of: sheet, matching: find.byType(ClipRRect)).first,
    );
    final stage = tester.getRect(find.byType(SakeStampBookOpening));
    for (final corner in [
      Offset.zero,
      Offset(page.size.width, 0),
      Offset(page.size.width, page.size.height),
      Offset(0, page.size.height),
    ]) {
      expect(stage.inflate(.1).contains(page.localToGlobal(corner)), true);
    }
    expect(
      find.ancestor(of: sheet, matching: find.byType(ClipRRect)),
      findsNothing,
    );
    await shot(tester, '02-small-drag');
    await drag.up();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('モーション低減なら回転なしで開き、読み上げの操作でも開ける', (tester) async {
    await tester.pumpWidget(book(reduced: true));
    final semantics = tester.widget<Semantics>(
      find.ancestor(of: cover, matching: find.byType(Semantics)).first,
    );
    expect(semantics.properties.button, true);
    expect(semantics.properties.onTap, isNotNull);
    semantics.properties.onTap!();
    await tester.pump();
    expect(cover, findsNothing);
    expect(tester.hasRunningAnimations, false);
    expect(tester.takeException(), isNull);
  });
}
