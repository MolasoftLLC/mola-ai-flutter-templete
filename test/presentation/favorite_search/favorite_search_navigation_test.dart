import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/common/widgets/primary_app_bar.dart';
import 'package:mola_gemini_flutter_template/presentation/favorite_search/favorite_search_page.dart';
import 'package:mola_gemini_flutter_template/presentation/main_search/main_search_page.dart';

void main() {
  testWidgets('産地で検索は戻るボタンを表示しない', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: FavoriteSearchPage.wrapped(),
      ),
    );

    final appBar = tester.widget<PrimaryAppBar>(find.byType(PrimaryAppBar));
    expect(appBar.automaticallyImplyLeading, isFalse);
    expect(appBar.leading, isNull);
    expect(find.byIcon(Icons.arrow_back), findsNothing);
  });

  testWidgets('検索ショートカットはRouteを重ねずおすすめタブへ戻る', (tester) async {
    int? selectedIndex;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Builder(
                    builder: (routeContext) => Scaffold(
                      body: TextButton(
                        onPressed: () => openPreferenceSearchTab(
                          routeContext,
                          onTabSelected: () => selectedIndex = 2,
                        ),
                        child: const Text('産地で検索'),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('検索画面を開く'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('検索画面を開く'));
    await tester.pumpAndSettle();
    expect(find.text('産地で検索'), findsOneWidget);

    await tester.tap(find.text('産地で検索'));
    await tester.pumpAndSettle();
    expect(selectedIndex, 2);
    expect(find.text('検索画面を開く'), findsOneWidget);
    expect(find.text('産地で検索'), findsNothing);
  });
}
