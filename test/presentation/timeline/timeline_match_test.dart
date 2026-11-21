import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mola_gemini_flutter_template/common/sake/taste_match.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/preferences/taste_preference_profile.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/my_page/my_page_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/common/widgets/sake_card_rail.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/venue_favorites_action.dart';

const preference = TastePreferenceProfile(
  fruity: .8,
  sweetness: .6,
  acidity: .5,
  umami: .5,
  kire: .7,
  spiciness: .3,
);
const profile = SakeTasteProfileDetails(
  fruity: .7,
  sweetness: .5,
  acidity: .6,
  umami: .6,
  kire: .7,
  dryness: .4,
);
void main() {
  testWidgets('タイムラインの％もホームと同じ好み計算と色を使う', (tester) async {
    await tester.pumpWidget(
      Provider<MyPageState>.value(
        value: const MyPageState(tasteProfile: preference),
        child: MaterialApp(
          home: Scaffold(
            body: SakeMatchBadge(
              profileFuture: Future.value(profile),
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final percent = calculateSharedSakeTasteMatchPercent(
      profile: profile,
      preference: preference,
    );
    expect(find.text('$percent%'), findsOneWidget);
    final decorated = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) => c.decoration is BoxDecoration)
        .map((c) => c.decoration! as BoxDecoration);
    expect(
      decorated.any(
        (d) =>
            d.gradient ==
            const LinearGradient(
              colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
            ),
      ),
      isTrue,
    );
  });
  testWidgets('好みや商品プロフィールがない時に数値を捏造しない', (tester) async {
    for (final state in [
      const MyPageState(),
      const MyPageState(tasteProfile: preference),
    ]) {
      await tester.pumpWidget(
        Provider<MyPageState>.value(
          value: state,
          child: MaterialApp(
            home: Scaffold(
              body: SakeMatchBadge(profileFuture: Future.value(null)),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.textContaining('%'), findsNothing);
    }
  });
  testWidgets('星とリストの両方を表示し、既存のお店一覧を開く', (tester) async {
    var opened = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(
            actions: [VenueFavoritesAction(onPressed: () => opened = true)],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.format_list_bulleted_rounded), findsOneWidget);
    await tester.tap(find.byTooltip('お気に入りのお店一覧'));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });
}
