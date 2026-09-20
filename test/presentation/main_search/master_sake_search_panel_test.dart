import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/main_search/main_search_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePlaceMapRepository extends PlaceMapRepository {
  _FakePlaceMapRepository({required this.normalResults, this.normalCompleter})
    : super(ApiClient.create());

  final List<SakeMapSearchResult> normalResults;
  final Completer<List<SakeMapSearchResult>>? normalCompleter;
  final aiCompleter = Completer<List<SakeMapSearchResult>>();
  String? aiQuery;
  int normalSearchCount = 0;
  int aiSearchCount = 0;

  @override
  Future<List<SakeMapSearchResult>> searchSakeMasters(String query) {
    normalSearchCount++;
    return normalCompleter?.future ?? Future.value(normalResults);
  }

  @override
  Future<List<SakeMapSearchResult>> searchSakeMastersByAi(
    String query, {
    int limit = 7,
  }) {
    aiSearchCount++;
    aiQuery = query;
    return aiCompleter.future;
  }
}

Widget _app(_FakePlaceMapRepository repository) =>
    Provider<PlaceMapRepository>.value(
      value: repository,
      child: const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          backgroundColor: Color(0xFF1D3567),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: MasterSakeSearchPanel(),
          ),
        ),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('空欄ではAI解析ボタンを灰色の無効状態で常時表示する', (tester) async {
    final repository = _FakePlaceMapRepository(normalResults: const []);
    await tester.pumpWidget(_app(repository));

    final button = find.byKey(const ValueKey('masterSakeAiSearchButton'));
    expect(button, findsOneWidget);
    expect(tester.widget<InkWell>(button).onTap, isNull);
    final ink = tester.widget<Ink>(
      find.ancestor(of: button, matching: find.byType(Ink)),
    );
    final decoration = ink.decoration! as BoxDecoration;
    expect(decoration.gradient, isNull);
    expect(decoration.color, const Color(0xFFD5D8DC));
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: button, matching: find.byType(Tooltip)),
    );
    expect(tooltip.message, '日本酒名を入力するとAI解析を利用できます');
    final semantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.label == '日本酒名を入力するとAI解析を利用できます',
      ),
    );
    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.enabled, isFalse);

    await tester.enterText(
      find.byKey(const ValueKey('masterSakeNameSearchField')),
      '   ',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(button);
    expect(repository.normalSearchCount, 0);
    expect(repository.aiSearchCount, 0);
  });

  testWidgets('通常検索中はAI解析ボタンの位置を維持して無効化する', (tester) async {
    final normalCompleter = Completer<List<SakeMapSearchResult>>();
    final repository = _FakePlaceMapRepository(
      normalResults: const [],
      normalCompleter: normalCompleter,
    );
    await tester.pumpWidget(_app(repository));
    final button = find.byKey(const ValueKey('masterSakeAiSearchButton'));
    final initialSize = tester.getSize(button);

    await tester.enterText(
      find.byKey(const ValueKey('masterSakeNameSearchField')),
      '神蔵',
    );
    await tester.pump(const Duration(milliseconds: 450));

    expect(button, findsOneWidget);
    expect(tester.getSize(button), initialSize);
    expect(tester.widget<InkWell>(button).onTap, isNull);
    final tooltip = tester.widget<Tooltip>(
      find.ancestor(of: button, matching: find.byType(Tooltip)),
    );
    expect(tooltip.message, '通常検索中のためAI解析は利用できません');
    await tester.tap(button);
    expect(repository.aiSearchCount, 0);

    normalCompleter.complete(const []);
    await tester.pump();
    expect(tester.widget<InkWell>(button).onTap, isNotNull);
  });

  testWidgets('通常候補があってもAI解析でき、候補を保持して追加結果を表示する', (tester) async {
    final repository = _FakePlaceMapRepository(
      normalResults: const [
        SakeMapSearchResult(
          sakeId: 279,
          name: '神蔵 純米大吟醸',
          brewery: '松井酒造',
          type: '純米大吟醸',
          isMaster: true,
        ),
      ],
    );
    await tester.pumpWidget(_app(repository));

    await tester.enterText(
      find.byKey(const ValueKey('masterSakeNameSearchField')),
      '神蔵',
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(find.text('候補の日本酒'), findsOneWidget);
    expect(find.text('候補になければ右上のAI解析！'), findsOneWidget);
    expect(find.text('AI解析'), findsOneWidget);
    final buttonSize = tester.getSize(
      find.byKey(const ValueKey('masterSakeAiSearchButton')),
    );

    final ink = tester.widget<Ink>(
      find.ancestor(
        of: find.byKey(const ValueKey('masterSakeAiSearchButton')),
        matching: find.byType(Ink),
      ),
    );
    final decoration = ink.decoration! as BoxDecoration;
    expect((decoration.gradient! as LinearGradient).colors, const [
      Color(0xFFFFA13C),
      Color(0xFFE95C5A),
    ]);

    await tester.tap(find.byKey(const ValueKey('masterSakeAiSearchButton')));
    await tester.pump();
    expect(find.text('解析中'), findsOneWidget);
    expect(repository.aiQuery, '神蔵');
    expect(repository.aiSearchCount, 1);
    final searchingButton = find.byKey(
      const ValueKey('masterSakeAiSearchButton'),
    );
    expect(tester.widget<InkWell>(searchingButton).onTap, isNull);
    expect(tester.getSize(searchingButton), buttonSize);
    final searchingTooltip = tester.widget<Tooltip>(
      find.ancestor(of: searchingButton, matching: find.byType(Tooltip)),
    );
    expect(searchingTooltip.message, 'AIで追加候補を解析中');

    repository.aiCompleter.complete(const [
      SakeMapSearchResult(
        searchToken: 'candidate:42',
        name: '神蔵 純米吟醸 ひやおろし',
        brewery: '松井酒造',
        type: '純米吟醸',
        isMaster: false,
      ),
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('神蔵 純米大吟醸'), findsOneWidget);
    expect(find.text('神蔵 純米吟醸 ひやおろし'), findsOneWidget);
  });

  testWidgets('候補0件時に右上のAI解析を案内する', (tester) async {
    final repository = _FakePlaceMapRepository(normalResults: const []);
    await tester.pumpWidget(_app(repository));

    await tester.enterText(
      find.byKey(const ValueKey('masterSakeNameSearchField')),
      '未登録酒',
    );
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump();

    expect(find.text('日本酒情報が見つかりませんでした'), findsOneWidget);
    expect(find.text('さらに右上のAI解析から追加検索が可能です'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('masterSakeAiSearchButton')),
      findsOneWidget,
    );
  });
}
