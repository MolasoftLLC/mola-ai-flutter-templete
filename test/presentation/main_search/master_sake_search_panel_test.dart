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
  _FakePlaceMapRepository({required this.normalResults})
    : super(ApiClient.create());

  final List<SakeMapSearchResult> normalResults;
  final aiCompleter = Completer<List<SakeMapSearchResult>>();
  String? aiQuery;

  @override
  Future<List<SakeMapSearchResult>> searchSakeMasters(String query) async =>
      normalResults;

  @override
  Future<List<SakeMapSearchResult>> searchSakeMastersByAi(
    String query, {
    int limit = 7,
  }) {
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
