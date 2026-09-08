import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_scan_repository.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/sake_master_detail_page.dart';
import 'package:provider/provider.dart';

void main() {
  test('検索候補は詳細用とサムネイル用のURLを分けて保持する', () {
    final result = SakeMapSearchResult.fromJson({
      'sakeId': 26,
      'name': '鍋島',
      'source': 'master',
      'primaryImageUrl': 'https://example.com/600.jpg',
      'thumbnailImageUrl': 'https://example.com/146.jpg',
    });
    expect(result.primaryImageUrl, 'https://example.com/600.jpg');
    expect(result.thumbnailImageUrl, 'https://example.com/146.jpg');
    final legacy = SakeMapSearchResult.fromJson({
      'name': '鍋島',
      'imageUrl': 'https://example.com/old.jpg',
    });
    expect(legacy.primaryImageUrl, 'https://example.com/old.jpg');
    expect(legacy.thumbnailImageUrl, isNull);
  });
  testWidgets('sake_masterから取得した詳細を表示する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      Provider<SakeScanRepository>.value(
        value: _FakeSakeScanRepository(),
        child: const MaterialApp(
          home: SakeMasterDetailPage(
            venueSake: VenueSake(sakeId: 123, name: '一覧の名称', recordCount: 2),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('マスター純米酒'), findsOneWidget);
    expect(find.text('サンプル酒造'), findsWidgets);
    expect(find.text('やわらかな香りとすっきりした後味。'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    await tester.scrollUntilVisible(find.text('基本スペック'), 300);
    expect(find.byKey(const Key('sake-taste-radar-chart')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('ご飯に合うかも！'), 300);
    expect(find.text('ぶり大根・煮付け'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('+2.5'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('容量と参考価格'), 300);
    expect(find.text('720 ml'), findsOneWidget);
    expect(find.text('¥2,300（税込）'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('詳細APIの文字列数値と分類・スタイルを保持する', () {
    final overview = SakeOverview.fromJson({
      'sake': {
        'sakeId': 123,
        'name': '純米吟醸',
        'polishingRatio': '50.0',
        'category': '純米吟醸',
        'styles': [
          {'code': 'nama', 'name': '生酒'},
        ],
        'variants': [
          {'volumeMl': 720, 'suggestedPrice': '2300', 'taxIncluded': true},
        ],
      },
      'brewery': {'name': 'サンプル酒造'},
    });
    expect(overview.master.polishingRatio, 50);
    expect(overview.master.category, '純米吟醸');
    expect(overview.master.styles.single.name, '生酒');
    expect(overview.master.variants.single.suggestedPrice, 2300);
    expect(overview.sake.brewery, 'サンプル酒造');
  });

  testWidgets('取得失敗時は一覧情報を残して再試行できる', (tester) async {
    final repository = _FakeSakeScanRepository()..fail = true;
    await tester.pumpWidget(
      Provider<SakeScanRepository>.value(
        value: repository,
        child: const MaterialApp(
          home: SakeMasterDetailPage(
            venueSake: VenueSake(sakeId: 123, name: '一覧の名称', recordCount: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('一覧の名称'), findsOneWidget);
    expect(find.text('詳細情報を取得できませんでした。'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('マスター純米酒'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeSakeScanRepository implements SakeScanRepository {
  bool fail = false;
  @override
  Future<SakeOverview> fetchOverview(int sakeId) async {
    if (fail) throw Exception('test failure');
    return const SakeOverview(
      sake: Sake(
        sakeId: 123,
        name: 'マスター純米酒',
        brewery: 'サンプル酒造',
        type: '純米酒',
        description: 'やわらかな香りとすっきりした後味。',
      ),
      analysisCompleted: true,
      master: SakeMasterDetails(
        category: '純米',
        polishingRatio: 50,
        sakeMeterValue: 2.5,
        tasteProfile: SakeTasteProfileDetails(
          fruity: .72,
          sweetness: .54,
          acidity: .48,
          umami: .7,
          kire: .64,
          dryness: .52,
          aroma: .72,
          body: .66,
        ),
        variants: [
          SakeProductVariant(
            volumeMl: 720,
            suggestedPrice: 2300,
            taxIncluded: true,
            currency: 'JPY',
          ),
        ],
      ),
    );
  }

  @override
  Future<SakeScanResult> scanFront(File image) => throw UnimplementedError();

  @override
  Future<SakeScanResult> scanBack(String scanSessionId, File image) =>
      throw UnimplementedError();

  @override
  Future<SakeScanConfirmation> confirm(String scanSessionId, int sakeId) =>
      throw UnimplementedError();
}
