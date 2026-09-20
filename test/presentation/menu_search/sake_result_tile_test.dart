import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_sake_resolution.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/sake_result_tile.dart';

void main() {
  testWidgets('DB候補が複数なら商品を選択でき、未確定のまま詳細扱いにしない', (tester) async {
    MenuSakeCandidate? selected;
    final candidates = [
      const MenuSakeCandidate(
        sake: Sake(sakeId: 1, name: '天吹 雄町 生', type: '純米吟醸'),
      ),
      const MenuSakeCandidate(
        sake: Sake(sakeId: 2, name: '天吹 雄町 火入れ', type: '純米吟醸'),
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: SakeResultTile(
            sake: const Sake(name: '天吹 雄町'),
            detailedSake: null,
            hasDetails: false,
            isItemLoading: false,
            hasFailed: false,
            isFavorited: false,
            isSaved: false,
            isLoading: false,
            matchPercent: null,
            isUnverified: false,
            candidates: candidates,
            onCandidateSelected: (candidate) => selected = candidate,
            onOpenDetails: null,
            onToggleFavorite: () async {},
            onSave: () async => false,
            buildInfoRow: (_, value, _) => Text(value),
            buildTypesRow: (types) => Text(types.join(',')),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.bookmark_outline), findsNothing);
    await tester.tap(find.byTooltip('候補を選択'));
    await tester.pumpAndSettle();
    expect(find.text('天吹 雄町 生'), findsOneWidget);
    expect(find.text('天吹 雄町 火入れ'), findsOneWidget);
    await tester.tap(find.text('天吹 雄町 火入れ'));
    await tester.pumpAndSettle();
    expect(selected?.sake.sakeId, 2);
  });
}
