import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_sake_resolution.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_scan_repository.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/menu_alternative_candidates.dart';

Widget host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);
void main() {
  testWidgets('確定後も控えめな入口が残り、開くまで取得せず直接選べる', (tester) async {
    var calls = 0;
    MenuSakeCandidate? selected;
    await tester.pumpWidget(
      host(
        MenuAlternativeCandidates(
          sakeId: 1,
          onSelected: (c) => selected = c,
          loadPage: (_) async {
            calls++;
            return const RelatedSakeProductsPage(
              sakes: [Sake(sakeId: 2, name: '花邑 雄町')],
            );
          },
        ),
      ),
    );
    expect(calls, 0);
    expect(find.text('この銘柄の他の候補'), findsOneWidget);
    await tester.tap(find.text('この銘柄の他の候補'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(selected, isNull);
    await tester.tap(find.text('花邑 雄町'));
    expect(selected?.sake.sakeId, 2);
    await tester.tap(find.text('この銘柄の他の候補'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この銘柄の他の候補'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
  testWidgets('取得失敗は再試行でき、選択中の商品を書き換えない', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(
        MenuAlternativeCandidates(
          sakeId: 1,
          onSelected: (_) => fail('Unexpected selection'),
          loadPage: (_) async {
            if (calls++ == 0) throw Exception();
            return const RelatedSakeProductsPage(sakes: []);
          },
        ),
      ),
    );
    await tester.tap(find.text('この銘柄の他の候補'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取得できませんでした。再試行'));
    await tester.pumpAndSettle();
    expect(find.text('同じ銘柄の他の商品はまだありません'), findsOneWidget);
  });
}
