import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_sake_resolution.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/sake_result_tile.dart';

void main() {
  test('discovery eligibility is explicit and defaults to false', () {
    expect(
      MenuSakeResolution.fromJson({
        'inputName': '酒',
        'status': 'unresolved',
      }).canDiscover,
      false,
    );
    expect(
      MenuSakeResolution.fromJson({
        'inputName': '酒',
        'status': 'unresolved',
        'canDiscover': true,
      }).canDiscover,
      true,
    );
  });
  testWidgets(
    'unmatched result offers confirmation or label capture, while a master offers labeled details',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var discovered = 0;
      var scanned = 0;
      var opened = 0;
      Widget app({bool master = false, bool discover = true}) => MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SakeResultTile(
              sake: const Sake(name: '川中島', type: '特純'),
              detailedSake: Sake(name: '川中島 特別純米', sakeId: master ? 12 : null),
              hasDetails: true,
              isItemLoading: false,
              hasFailed: false,
              isFavorited: false,
              isSaved: false,
              isLoading: false,
              matchPercent: null,
              isUnverified: !master,
              candidates: const [],
              dark: true,
              onCandidateSelected: (_) {},
              onOpenDetails: master ? () => opened++ : null,
              onDiscover: discover ? () => discovered++ : null,
              onScanLabel: () => scanned++,
              onToggleFavorite: () async {},
              onSave: () async => false,
              buildInfoRow: (_, value, _) => Text(value),
              buildTypesRow: (types) => Text(types.join(',')),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      expect(find.text('詳細を見る'), findsNothing);
      await tester.tap(find.text('新発見のお酒を確認'));
      expect(discovered, 1);
      await tester.tap(find.text('ラベルを撮影して確認'));
      expect(scanned, 1);
      await tester.pumpWidget(app(discover: false));
      await tester.pumpAndSettle();
      expect(find.text('新発見のお酒を確認'), findsNothing);
      expect(find.text('ラベルを撮影して確認'), findsOneWidget);
      await tester.pumpWidget(app(master: true));
      await tester.pumpAndSettle();
      expect(find.text('詳細を見る'), findsOneWidget);
      expect(find.text('新発見のお酒を確認'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
