import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/utils/snack_bar_utils.dart';

void main() {
  Future<EdgeInsets> showSnackBar(
    WidgetTester tester, {
    required bool hasBottomNavigation,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: hasBottomNavigation
              ? SnackBarAvoidanceScope(
                  bottomObstacleHeight: 43,
                  child: Builder(
                    builder: (context) => Center(
                      child: ElevatedButton(
                        onPressed: () => SnackBarUtils.showSnackBar(
                          context,
                          message: '保存しました',
                        ),
                        child: const Text('表示'),
                      ),
                    ),
                  ),
                )
              : Builder(
                  builder: (context) => Center(
                    child: ElevatedButton(
                      onPressed: () => SnackBarUtils.showSnackBar(
                        context,
                        message: '保存しました',
                      ),
                      child: const Text('表示'),
                    ),
                  ),
                ),
          bottomNavigationBar: hasBottomNavigation
              ? const SizedBox(height: 78)
              : null,
        ),
      ),
    );
    await tester.tap(find.text('表示'));
    await tester.pumpAndSettle();
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    return snackBar.margin! as EdgeInsets;
  }

  testWidgets('共通ボトムナビ表示中は張り出す撮影ボタンより上に表示する', (tester) async {
    final margin = await showSnackBar(tester, hasBottomNavigation: true);

    expect(margin.bottom, 16 + 43);
  });

  testWidgets('ボトムナビがない画面では通常の下余白だけを使う', (tester) async {
    final margin = await showSnackBar(tester, hasBottomNavigation: false);

    expect(margin.bottom, 16);
  });
}
