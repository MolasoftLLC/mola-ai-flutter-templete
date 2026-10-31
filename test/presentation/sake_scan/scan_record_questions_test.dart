import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_scan/widgets/scan_record_questions.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    ScanRecordAnswers answers, {
    Future<void> Function()? place,
    VoidCallback? done,
    String? placeName,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScanRecordQuestions(
              answers: answers,
              onChanged: () {},
              onChoosePlace: place ?? () async {},
              onDone: done ?? () {},
              placeName: placeName,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('place selection never creates drinking or taste answers', (
    tester,
  ) async {
    final answers = ScanRecordAnswers();
    var requests = 0;
    await show(
      tester,
      answers,
      place: () async {
        requests++;
      },
    );
    expect(find.text('このお酒、飲んだ？'), findsNothing);
    expect(find.text('好きな味だった？'), findsNothing);
    await tester.tap(find.text('お店・場所を選ぶ'));
    await tester.pump();
    expect(requests, 1);
    expect(answers.memo, isEmpty);
    expect(answers.drank, isNull);
    expect(answers.stars, isNull);
    await show(tester, answers, placeName: 'テストのお店');
    expect(find.text('テストのお店'), findsOneWidget);
    expect(find.text('この場所で続ける'), findsOneWidget);
  });
  testWidgets('skip does not open location or create a record', (tester) async {
    var done = false;
    final answers = ScanRecordAnswers();
    await show(
      tester,
      answers,
      done: () => done = true,
      place: () async => fail('must not request location'),
    );
    await tester.tap(find.text('あとで'));
    expect(done, isTrue);
    expect(answers.memo, isEmpty);
  });
  testWidgets('picker is single flight and safe when analysis completes', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await show(
      tester,
      ScanRecordAnswers(),
      place: () {
        calls++;
        return pending.future;
      },
    );
    await tester.tap(find.text('お店・場所を選ぶ'));
    await tester.pump();
    await tester.tap(find.text('場所を選択中…'));
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
  testWidgets('compact location question fits narrow screen with larger text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ScanRecordQuestions(
                  answers: ScanRecordAnswers(),
                  onChanged: () {},
                  onChoosePlace: () async {},
                  onDone: () {},
                  onPhoto: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
