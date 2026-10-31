import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_scan/widgets/scan_location_panel.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_scan/widgets/scan_record_questions.dart';

void main() {
  testWidgets(
    'touch is reported before picker opens and ready rebuild keeps picker busy',
    (tester) async {
      final pending = Completer<void>();
      final events = <String>[];
      late StateSetter update;
      var ready = false;
      var done = false;
      final answers = ScanRecordAnswers();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                update = setState;
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: ScanLocationPanel(
                    message: ready ? '照合できました' : '照合しています',
                    ready: ready,
                    answers: answers,
                    onChanged: () {},
                    onInteraction: () => events.add('touch'),
                    onChoosePlace: () {
                      events.add('picker');
                      return pending.future;
                    },
                    onDone: () => done = true,
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('お店・場所を選ぶ'));
      await tester.pump();
      expect(events, ['touch', 'picker']);
      update(() => ready = true);
      await tester.pump();
      expect(find.text('場所を選択中…'), findsOneWidget);
      await tester.tap(find.text('候補を見る'));
      expect(done, isFalse);
      pending.complete();
      await tester.pump();
      expect(done, isFalse);
      await tester.tap(find.text('候補を見る'));
      expect(done, isTrue);
      expect(answers.memo, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
