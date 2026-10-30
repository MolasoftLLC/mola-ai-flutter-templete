import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_scan/widgets/scan_record_questions.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    ScanRecordAnswers answers, {
    VoidCallback? done,
    Future<void> Function()? place,
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
            ),
          ),
        ),
      ),
    );
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pump();
  }

  for (final button in ['← NO', 'あとで']) {
    testWidgets('$button skips drinking questions without making a record', (
      tester,
    ) async {
      final answers = ScanRecordAnswers();
      var done = false;
      await show(tester, answers, done: () => done = true);
      await tap(tester, button);
      expect(done, isTrue);
      expect(answers.memo, isEmpty);
      expect(answers.liked, isNull);
      expect(answers.stars, isNull);
    });
  }
  testWidgets(
    'answers and optional stars become editable memo, place is explicitly selected',
    (tester) async {
      final answers = ScanRecordAnswers();
      var placeRequests = 0;
      var done = false;
      await show(
        tester,
        answers,
        done: () => done = true,
        place: () async {
          placeRequests++;
        },
      );
      await tap(tester, 'YES →');
      expect(find.text('好きな味だった？'), findsOneWidget);
      await tap(tester, '← NO');
      await tap(tester, 'YES →');
      expect(placeRequests, 1);
      await tap(tester, 'YES →');
      await tester.tap(find.byTooltip('4つ星'));
      await tester.pump();
      expect(done, isTrue);
      expect(answers.memo, contains('好みの味ではなかった'));
      expect(answers.memo, contains('また飲みたい'));
      expect(answers.memo, contains('★★★★（4/5）'));
    },
  );
  testWidgets('left/right flicks answer; short drag does not answer', (
    tester,
  ) async {
    final answers = ScanRecordAnswers();
    await show(tester, answers);
    await tester.timedDrag(
      find.byKey(const ValueKey('scan-question-0')),
      const Offset(15, 0),
      const Duration(seconds: 1),
    );
    await tester.pump();
    expect(answers.drank, isNull);
    await tester.drag(
      find.byKey(const ValueKey('scan-question-0')),
      const Offset(110, 0),
    );
    await tester.pump();
    expect(answers.drank, isTrue);
    await tester.drag(
      find.byKey(const ValueKey('scan-question-1')),
      const Offset(-110, 0),
    );
    await tester.pump();
    expect(answers.liked, isFalse);
  });
  testWidgets(
    'skip retains earlier answers and never invents stars or location',
    (tester) async {
      final answers = ScanRecordAnswers();
      var places = 0;
      await show(
        tester,
        answers,
        place: () async {
          places++;
        },
      );
      await tap(tester, 'YES →');
      for (var i = 0; i < 4; i++) {
        await tap(tester, 'あとで');
      }
      expect(answers.memo, '飲んだ');
      expect(answers.stars, isNull);
      expect(places, 0);
    },
  );
  testWidgets(
    'analysis finishing while choosing a place safely removes the cards',
    (tester) async {
      final answers = ScanRecordAnswers();
      final place = Completer<void>();
      await show(tester, answers, place: () => place.future);
      await tap(tester, 'YES →');
      await tap(tester, 'YES →');
      await tap(tester, 'YES →');
      await tester.pumpWidget(const MaterialApp(home: Text('解析完了')));
      place.complete();
      await tester.pump();
      expect(answers.memo, contains('好きな味だった'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('small screen supports large text without overflow', (
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
              child: ScanRecordQuestions(
                answers: ScanRecordAnswers(),
                onChanged: () {},
                onChoosePlace: () async {},
                onDone: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
