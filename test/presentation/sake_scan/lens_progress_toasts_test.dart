import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_scan/widgets/lens_progress_toasts.dart';

void main() {
  testWidgets('途中結果は順番に表示され、短時間で消える', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LensProgressToasts(titles: ['一白水成', '竹林'])),
      ),
    );
    expect(find.text('一白水成'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('竹林'), findsOneWidget);
    expect(find.text('一白水成'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('竹林'), findsNothing);
  });

  testWidgets('候補画面へ進んだら表示待ちのトーストを破棄する', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LensProgressToasts(titles: ['一白水成', '竹林'])),
      ),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);
  });
}
