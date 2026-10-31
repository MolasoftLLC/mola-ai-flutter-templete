import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/presentation/common/help/my_page_feature_guide.dart';

void main() {
  for (final showMap in [true, false]) {
    testWidgets('あなたの地図の案内: 表示=$showMap', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final guide = MyPageFeatureGuide();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Column(
                  children: [
                    TextButton(
                      onPressed: () => guide.showIfNeeded(context, force: true),
                      child: const Text('案内'),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: guide.scrollController,
                        child: Column(
                          children: [
                            for (final key in [
                              guide.accountKey,
                              guide.savedKey,
                              guide.historyKey,
                              if (showMap) guide.myMapKey,
                              guide.favoritesKey,
                              guide.preferencesKey,
                            ])
                              SizedBox(key: key, height: 120, width: 300),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('案内'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text(i == 0 ? '使い方を見る' : '次へ'));
        await tester.pumpAndSettle();
      }
      expect(find.text(showMap ? 'あなたの地図' : 'お気に入りのお酒'), findsOneWidget);
      expect(find.text(showMap ? '4 / 6' : '4 / 5'), findsOneWidget);
      await tester.tap(find.text('スキップ'));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      guide.dispose();
    });
  }
}
