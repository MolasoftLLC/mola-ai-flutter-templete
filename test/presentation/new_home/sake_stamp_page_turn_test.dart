import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_stamp_page_turn.dart';

void main() {
  final paper = find.byKey(const ValueKey('stamp-turning-paper'));
  final sheet = find.byKey(const ValueKey('stamp-page-turn-sheet'));
  late SakeStampPageTurnController controller;
  late ValueNotifier<int> page;
  var taps = 0;
  setUp(() {
    controller = SakeStampPageTurnController();
    page = ValueNotifier(0);
    taps = 0;
  });
  tearDown(() => page.dispose());

  Widget book({bool reduced = false}) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            height: 236,
            child: ValueListenableBuilder<int>(
              valueListenable: page,
              builder: (_, value, __) => SakeStampPageTurn(
                controller: controller,
                child: ColoredBox(
                  color: value == 0
                      ? const Color(0xFFFF0000)
                      : const Color(0xFF0000FF),
                  child: Center(
                    child: TextButton(
                      onPressed: () => taps++,
                      child: Text('page $value'),
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

  testWidgets('次のページに切り替える前の紙面をめくり、表紙は表示しない', (tester) async {
    await tester.pumpWidget(book());
    controller.turn(() => page.value = 1);
    await tester.pump();
    expect(paper, findsOneWidget);
    expect(find.byKey(const ValueKey('stamp-book-cover')), findsNothing);
    expect(find.text('page 1'), findsOneWidget);
    final image = tester.widget<RawImage>(paper).image!;
    final bytes = await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final offset = ((image.height ~/ 2) * image.width + 20) * 4;
    expect(
      bytes!.getUint8(offset),
      255,
    ); // The outgoing page is red, not the new blue page.
    expect(bytes.getUint8(offset + 2), 0);
    await tester.pump(const Duration(milliseconds: 100));
    final transform = tester.widget<Transform>(sheet).transform;
    expect(transform.entry(0, 0), inExclusiveRange(0, 1));
    expect(transform.entry(2, 0), lessThan(0));
    await tester.tap(find.text('page 1'), warnIfMissed: false);
    expect(taps, 0);
    await tester.pumpAndSettle();
    expect(paper, findsNothing);
    await tester.tap(find.text('page 1'));
    expect(taps, 1);
    expect(controller.isBusy, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('前のページは右綴じで逆向きにめくる', (tester) async {
    await tester.pumpWidget(book());
    controller.turn(() => page.value = 1, backwards: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<Transform>(sheet).alignment, Alignment.centerRight);
    expect(
      tester.widget<Transform>(sheet).transform.entry(2, 0),
      greaterThan(0),
    );
    await tester.pumpAndSettle();
    expect(paper, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ドラッグ量に追従し、取り消すと元のページへ戻る', (tester) async {
    await tester.pumpWidget(book());
    controller.begin(() => page.value = 1, backwards: false);
    controller.update(.25);
    await tester.pump();
    final first = tester.widget<Transform>(sheet).transform.entry(0, 0);
    controller.update(.55);
    await tester.pump();
    expect(
      tester.widget<Transform>(sheet).transform.entry(0, 0),
      lessThan(first),
    );
    controller.finish(commit: false, onCancel: () => page.value = 0);
    await tester.pumpAndSettle();
    expect(page.value, 0);
    expect(paper, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('連続移動と途中破棄で古い紙面やコールバックを残さない', (tester) async {
    await tester.pumpWidget(book());
    controller.turn(() => page.value = 1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    controller.turn(() => page.value = 2);
    await tester.pumpAndSettle();
    expect(page.value, 2);
    expect(paper, findsNothing);
    controller.turn(() => page.value = 3);
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(controller.isBusy, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('データ更新だけでは紙も表紙もめくらず、未表示時も移動できる', (tester) async {
    controller.turn(() => page.value = 1);
    expect(page.value, 1);
    await tester.pumpWidget(book());
    page.value = 2;
    await tester.pumpAndSettle();
    expect(find.text('page 2'), findsOneWidget);
    expect(paper, findsNothing);
    expect(controller.isBusy, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('モーション低減では紙も表紙も回転せず即時に移動する', (tester) async {
    await tester.pumpWidget(book(reduced: true));
    controller.turn(() => page.value = 1);
    await tester.pump();
    expect(page.value, 1);
    expect(paper, findsNothing);
    expect(controller.isBusy, isFalse);
    expect(tester.hasRunningAnimations, isFalse);
    controller.begin(() => page.value = 2, backwards: false);
    controller.finish(commit: false, onCancel: () => page.value = 1);
    await tester.pump();
    expect(page.value, 1);
    expect(tester.takeException(), isNull);
  });
}
