import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_menu_recognition_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_scan_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/sake_menu_recognition_api_client.dart';
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

  test('保存した写真がある場合はYahoo商品画像を詳細へ混在させない', () {
    const fallback = VenueSake(
      sakeId: 123,
      name: '冩樂 純米吟醸',
      recordCount: 0,
      primaryImageUrl: 'https://images.example/yahoo.jpg',
    );
    final paths = detailImagePaths(
      personalRecord: const Sake(
        imagePaths: [
          '/local/front-bottle.jpg',
          'https://images.example/memory.jpg',
        ],
      ),
      overviewSake: const Sake(
        primaryImageUrl: 'https://images.example/yahoo.jpg',
      ),
      fallback: fallback,
    );

    expect(paths, [
      '/local/front-bottle.jpg',
      'https://images.example/memory.jpg',
    ]);
  });

  test('保存した写真がない場合だけYahooの600px商品画像を表示する', () {
    const fallback = VenueSake(
      sakeId: 123,
      name: '冩樂 純米吟醸',
      recordCount: 0,
      primaryImageUrl: 'https://images.example/list-fallback-600.jpg',
    );
    final paths = detailImagePaths(
      personalRecord: const Sake(imagePaths: []),
      overviewSake: const Sake(
        primaryImageUrl: 'https://images.example/yahoo-600.jpg',
      ),
      fallback: fallback,
    );

    expect(paths, ['https://images.example/yahoo-600.jpg']);
  });

  test('味わいプロフィールの一致度は30〜100%で算出する', () {
    expect(
      calculateTastePreferenceMatchPercent(
        sakeValues: const [.7, .5, .4, .6, .8, .3],
        preferenceValues: const [.7, .5, .4, .6, .8, .3],
      ),
      100,
    );
    expect(
      calculateTastePreferenceMatchPercent(
        sakeValues: const [0, 0, 0, 0, 0, 0],
        preferenceValues: const [1, 1, 1, 1, 1, 1],
      ),
      30,
    );
    expect(
      calculateTastePreferenceMatchPercent(
        sakeValues: const [.5, .5, .5, .5, .5, .5],
        preferenceValues: const [.5, .5, .5, .5, .5, .5],
      ),
      100,
    );
    expect(
      calculateTastePreferenceMatchPercent(
        sakeValues: const [.6, .6, .6, .6, .6, .6],
        preferenceValues: const [.5, .5, .5, .5, .5, .5],
      ),
      78,
    );
  });

  test('あなたが感じた味わいの5段階評価を保存用JSONに保持する', () {
    const sake = Sake(
      personalTasteRatings: {
        'fruity': 5,
        'sweetness': 3,
        'acidity': 2,
        'umami': 4,
        'kire': 1,
        'spiciness': 2,
      },
    );

    expect(Sake.fromJson(sake.toJson()).personalTasteRatings, {
      'fruity': 5,
      'sweetness': 3,
      'acidity': 2,
      'umami': 4,
      'kire': 1,
      'spiciness': 2,
    });
  });

  testWidgets('sake_masterから取得した詳細を表示する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeSakeScanRepository();
    await tester.pumpWidget(
      Provider<SakeScanRepository>.value(
        value: repository,
        child: const MaterialApp(
          home: SakeMasterDetailPage(
            venueSake: VenueSake(sakeId: 123, name: '一覧の名称', recordCount: 2),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.lastTrackView, isTrue);
    expect(find.text('ログインすると、あなたにおすすめかどうかが分かります！'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('マスター純米酒'), findsWidgets);
    expect(find.text('サンプル酒造'), findsWidgets);
    expect(find.text('やわらかな香りとすっきりした後味。'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.byKey(const Key('compact-sake-header')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('基本スペック'), 300);
    expect(find.byKey(const Key('sake-taste-radar-chart')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('この食事に合うかも！'), 300);
    expect(find.text('ぶり大根・煮付け'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('+2.5'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('容量と参考価格'), 300);
    expect(find.text('720 ml'), findsOneWidget);
    expect(find.text('¥2,300（税込）'), findsOneWidget);
    expect(find.text('¥2,150'), findsOneWidget);
    expect(find.byKey(const Key('shop-price-link-Yahoo!')), findsOneWidget);
    expect(find.text('¥2,180'), findsNothing);
    expect(find.text('¥2,080'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('詳細APIの文字列数値と分類・スタイルを保持する', () {
    final overview = SakeOverview.fromJson({
      'sake': {
        'sakeId': 123,
        'name': '純米吟醸',
        'primaryImageUrl': 'https://example.com/detail.jpg',
        'thumbnailImageUrl': 'https://example.com/card.jpg',
        'polishingRatio': '50.0',
        'category': '純米吟醸',
        'imageProductUrl':
            'https://store.shopping.yahoo.co.jp/example/sake.html',
        'imagePrice': '2150',
        'imageCurrency': 'JPY',
        'detailViewCount': '8',
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
    expect(overview.master.imagePrice, 2150);
    expect(overview.master.imageCurrency, 'JPY');
    expect(overview.master.detailViewCount, 8);
    expect(overview.sake.primaryImageUrl, 'https://example.com/detail.jpg');
    expect(overview.sake.thumbnailImageUrl, 'https://example.com/card.jpg');
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
    expect(find.text('ログインすると、あなたにおすすめかどうかが分かります！'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('一覧の名称'), findsWidgets);
    expect(find.text('詳細情報を取得できませんでした。'), findsOneWidget);
    repository.fail = false;
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(find.text('マスター純米酒'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI検索候補は詳細ページ内で情報を取得して表示する', (tester) async {
    final repository = _FakeSakeMenuRecognitionRepository();
    await tester.pumpWidget(
      Provider<SakeMenuRecognitionRepository>.value(
        value: repository,
        child: const MaterialApp(
          home: SakeMasterDetailPage(
            venueSake: VenueSake(
              searchToken: 'candidate:12',
              name: '鍋島 純米吟醸',
              brewery: '富久千代酒造',
              type: '純米吟醸',
              recordCount: 0,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('詳細情報を取得中'), findsOneWidget);
    expect(repository.requestedName, '鍋島 純米吟醸');
    expect(repository.requestedType, '純米吟醸');

    repository.complete();
    await tester.pumpAndSettle();
    expect(find.text('詳細情報を取得中'), findsNothing);
    expect(find.textContaining('未検証'), findsNothing);
    await tester.scrollUntilVisible(find.text('AI解析済みの味わい説明'), 300);
    expect(find.text('AI解析済みの味わい説明'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _UnusedSakeMenuRecognitionApiClient
    implements SakeMenuRecognitionApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSakeMenuRecognitionRepository extends SakeMenuRecognitionRepository {
  _FakeSakeMenuRecognitionRepository()
    : super(_UnusedSakeMenuRecognitionApiClient());

  final _completer = Completer<SakeOverview?>();
  String? requestedName;
  String? requestedType;

  @override
  Future<SakeOverview?> getSakeOverviewByName(
    String sakeName, {
    String? type,
    String? preferences,
  }) {
    requestedName = sakeName;
    requestedType = type;
    return _completer.future;
  }

  void complete() {
    _completer.complete(
      const SakeOverview(
        sake: Sake(
          name: '鍋島 純米吟醸',
          brewery: '富久千代酒造',
          type: '純米吟醸',
          description: 'AI解析済みの味わい説明',
        ),
        analysisCompleted: true,
      ),
    );
  }
}

class _FakeSakeScanRepository implements SakeScanRepository {
  bool fail = false;
  bool? lastTrackView;

  @override
  Future<SakeOverview> fetchOverview(
    int sakeId, {
    bool trackView = false,
  }) async {
    lastTrackView = trackView;
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
        imageSource: 'yahoo_shopping',
        imageProductUrl: 'https://store.shopping.yahoo.co.jp/example/sake.html',
        imagePrice: 2150,
        imageCurrency: 'JPY',
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

  @override
  Future<void> rejectCandidates(String scanSessionId, List<int> sakeIds) =>
      throw UnimplementedError();
}
