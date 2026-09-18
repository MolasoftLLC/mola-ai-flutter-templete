import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' show User;
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
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/saved_sake/saved_sake_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/favorite/favorite_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/my_page/my_page_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/preferences/taste_preference_profile.dart';
import 'package:mola_gemini_flutter_template/domain/repository/auth_repository.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';

void main() {
  setUpAll(loggerConfigure);
  setUp(() => SharedPreferences.setMockInitialValues({}));
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

  test('一覧と詳細で共通の味わいマッチ度を使用する', () {
    const profile = SakeTasteProfileDetails(
      fruity: .7,
      sweetness: .5,
      acidity: .4,
      umami: .6,
      kire: .8,
      dryness: .3,
    );
    const preference = TastePreferenceProfile(
      fruity: .7,
      sweetness: .5,
      acidity: .4,
      umami: .6,
      kire: .8,
      spiciness: .3,
    );
    expect(
      calculateSakeTastePreferenceMatchPercent(
        profile: profile,
        preference: preference,
      ),
      100,
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
    final launcher = _FakeUrlLauncher();
    final previousLauncher = UrlLauncherPlatform.instance;
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = previousLauncher);
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
    expect(find.byKey(const Key('detail-obi-divider')), findsWidgets);
    expect(find.byType(Divider), findsNothing);
    expect(find.text('ログインすると、あなたにおすすめかどうかが分かります！'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('マスター純米酒'), findsWidgets);
    expect(find.text('サンプル酒造'), findsWidgets);
    expect(find.text('やわらかな香りとすっきりした後味。'), findsOneWidget);
    expect(find.text('近くで飲める場所を探す'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
    expect(find.byKey(const Key('compact-sake-header')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('基本スペック'), 300);
    expect(find.byKey(const Key('sake-taste-radar-chart')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('この食事に合うかも！'), 300);
    expect(find.text('ぶり大根・煮付け'), findsOneWidget);
    expect(
      find.byKey(const Key('pairing-assets/images/pairings/simmered_fish.jpg')),
      findsOneWidget,
    );
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('+2.5'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('容量と参考価格'), 300);
    expect(find.text('720 ml'), findsOneWidget);
    expect(find.text('¥2,300（税込）'), findsOneWidget);
    expect(find.text('¥2,150'), findsOneWidget);
    expect(find.byKey(const Key('shop-price-link-Yahoo!')), findsOneWidget);
    expect(find.text('¥2,096'), findsOneWidget);
    await tester.tap(find.byKey(const Key('shop-price-link-楽天市場')));
    await tester.pumpAndSettle();
    expect(
      launcher.openedUrl,
      'https://hb.afl.rakuten.co.jp/hgc/test/?pc=item',
    );
    expect(launcher.mode, PreferredLaunchMode.externalApplication);
    expect(find.text('¥2,180'), findsNothing);
    expect(find.text('¥2,080'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('みんなの平均評価と横スライドの評価カードを表示する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeSakeScanRepository(
      overview: SakeOverview(
        sake: const Sake(sakeId: 123, name: '来福'),
        analysisCompleted: true,
        community: SakeCommunitySummary(
          averageRating: 4.2,
          reviewCount: 12,
          reviews: <SakeCommunityReview>[
            SakeCommunityReview(
              reviewId: 9,
              sakeId: 123,
              overallRating: 5,
              username: '酒好き',
              imageUrl: 'https://example.com/review.jpg',
              comment: '華やかでおいしい',
              tasteRatings: const {
                'fruity': 5,
                'sweetness': 4,
                'acidity': 3,
                'umami': 4,
                'kire': 5,
                'spiciness': 2,
              },
              createdAt: DateTime(2026, 9, 14),
              updatedAt: DateTime(2026, 9, 14),
            ),
            SakeCommunityReview(
              reviewId: 10,
              sakeId: 123,
              overallRating: 3,
              username: '辛口好き',
              tasteRatings: const {'acidity': 3},
              createdAt: DateTime(2026, 9, 14),
              updatedAt: DateTime(2026, 9, 14),
            ),
          ],
        ),
      ),
    );
    await tester.pumpWidget(
      Provider<SakeScanRepository>.value(
        value: repository,
        child: const MaterialApp(
          home: SakeMasterDetailPage(
            venueSake: VenueSake(sakeId: 123, name: '来福', recordCount: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('4.2'), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('4.2 (12件)'), findsOneWidget);
    expect(find.text('華やかでおいしい'), findsOneWidget);
    final photo = tester.getRect(find.byKey(const Key('review-photo-9')));
    final chart = tester.getRect(find.byKey(const Key('review-taste-radar-9')));
    final chartPanel = tester.getRect(
      find.byKey(const Key('review-chart-panel-9')),
    );
    final comment = tester.getRect(find.text('華やかでおいしい'));
    expect(photo.height, greaterThanOrEqualTo(180));
    expect(photo.right, lessThan(chart.left));
    expect(chart.top - chartPanel.top, greaterThanOrEqualTo(30));
    expect(comment.top, greaterThan(photo.bottom));
    expect(comment.top, greaterThan(chart.bottom));
    expect(find.byKey(const Key('review-taste-radar-9')), findsOneWidget);
    expect(find.text('このお酒を評価'), findsOneWidget);
    await tester.drag(
      find.byKey(const Key('community-review-carousel')).first,
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('酸味 3'), findsOneWidget);
    expect(find.byKey(const Key('review-taste-radar-10')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('評価カードは写真だけ・チャートだけならメディア領域を全幅で使う', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final longComment = List.filled(8, '華やかな香りと余韻を楽しめる一本です。').join();
    await tester.pumpWidget(
      Provider<SakeScanRepository>.value(
        value: _FakeSakeScanRepository(
          overview: SakeOverview(
            sake: const Sake(sakeId: 123, name: '来福'),
            analysisCompleted: true,
            community: SakeCommunitySummary(
              reviews: <SakeCommunityReview>[
                SakeCommunityReview(
                  reviewId: 11,
                  sakeId: 123,
                  overallRating: 5,
                  username: '写真だけ',
                  imageUrl: 'https://example.com/photo.jpg',
                  comment: longComment,
                  createdAt: DateTime(2026, 9, 14),
                  updatedAt: DateTime(2026, 9, 14),
                ),
                SakeCommunityReview(
                  reviewId: 12,
                  sakeId: 123,
                  overallRating: 4,
                  username: 'チャートだけ',
                  tasteRatings: const {
                    'fruity': 5,
                    'sweetness': 4,
                    'acidity': 3,
                    'umami': 4,
                    'kire': 5,
                    'spiciness': 2,
                  },
                  createdAt: DateTime(2026, 9, 14),
                  updatedAt: DateTime(2026, 9, 14),
                ),
              ],
            ),
          ),
        ),
        child: const MaterialApp(
          home: SakeMasterDetailPage(
            venueSake: VenueSake(sakeId: 123, name: '来福', recordCount: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();
    final photo = tester.getRect(find.byKey(const Key('review-photo-11')));
    expect(photo.width, greaterThan(250));
    final commentScroll = find.byKey(const Key('review-comment-scroll-11'));
    expect(tester.getSize(commentScroll).height, lessThanOrEqualTo(59));
    final commentTop = tester.getTopLeft(find.text(longComment)).dy;
    await tester.drag(commentScroll, const Offset(0, -70));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text(longComment)).dy, lessThan(commentTop));
    await tester.drag(
      find.byKey(const Key('community-review-carousel')).first,
      const Offset(-300, 0),
    );
    await tester.pumpAndSettle();
    final chartPanel = tester.getRect(
      find.byKey(const Key('review-chart-panel-12')),
    );
    expect(chartPanel.width, greaterThan(250));
    expect(find.byKey(const Key('review-photo-12')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('みんなの評価がないとき、マッチ度は全幅で左揃えにする', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      Provider<MyPageState?>.value(
        value: const MyPageState(
          tasteProfile: TastePreferenceProfile(
            fruity: .7,
            sweetness: .5,
            acidity: .4,
            umami: .6,
            kire: .8,
            spiciness: .3,
          ),
        ),
        child: Provider<SakeScanRepository>.value(
          value: _FakeSakeScanRepository(
            overview: const SakeOverview(
              sake: Sake(sakeId: 123, name: '来福'),
              analysisCompleted: true,
              master: SakeMasterDetails(
                tasteProfile: SakeTasteProfileDetails(
                  fruity: .7,
                  sweetness: .5,
                  acidity: .4,
                  umami: .6,
                  kire: .8,
                  dryness: .3,
                ),
              ),
            ),
          ),
          child: const MaterialApp(
            home: SakeMasterDetailPage(
              venueSake: VenueSake(sakeId: 123, name: '来福', recordCount: 0),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final summary = tester.getRect(find.byKey(const Key('sake-score-summary')));
    final title = tester.getRect(find.text('あなたの好みマッチ度'));
    final percent = tester.getRect(find.text('100%'));
    final gauge = tester.getRect(find.byKey(const Key('sake-match-gauge')));
    expect((title.left - percent.left).abs(), lessThan(2));
    expect((title.left - gauge.left).abs(), lessThan(2));
    expect(gauge.width, greaterThan(summary.width * .8));
    expect(tester.takeException(), isNull);
  });

  testWidgets('マッチ度とみんなの評価を中央に揃え、画像との間隔を確保する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = _FakeSakeScanRepository(
      overview: const SakeOverview(
        sake: Sake(sakeId: 123, name: '来福'),
        analysisCompleted: true,
        master: SakeMasterDetails(
          tasteProfile: SakeTasteProfileDetails(
            fruity: .7,
            sweetness: .5,
            acidity: .4,
            umami: .6,
            kire: .8,
            dryness: .3,
          ),
        ),
        community: SakeCommunitySummary(averageRating: 4.2, reviewCount: 12),
      ),
    );
    await tester.pumpWidget(
      Provider<MyPageState?>.value(
        value: const MyPageState(
          tasteProfile: TastePreferenceProfile(
            fruity: .7,
            sweetness: .5,
            acidity: .4,
            umami: .6,
            kire: .8,
            spiciness: .3,
          ),
        ),
        child: Provider<SakeScanRepository>.value(
          value: repository,
          child: const MaterialApp(
            home: SakeMasterDetailPage(
              venueSake: VenueSake(sakeId: 123, name: '来福', recordCount: 0),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final summary = tester.getRect(find.byKey(const Key('sake-score-summary')));
    final image = tester.getRect(find.byKey(const Key('sake-hero-image')));
    expect(image.top - summary.bottom, greaterThanOrEqualTo(16));
    final title = tester.getCenter(find.text('あなたの好みマッチ度'));
    final percent = tester.getCenter(find.text('100%'));
    final gauge = tester.getCenter(find.byKey(const Key('sake-match-gauge')));
    expect((title.dx - percent.dx).abs(), lessThan(2));
    expect((title.dx - gauge.dx).abs(), lessThan(2));
    final ratingTitle = tester.getCenter(find.text('みんなの評価').first);
    final ratingLine = tester.getCenter(
      find.byKey(const Key('sake-community-rating-line')),
    );
    expect((ratingTitle.dx - ratingLine.dx).abs(), lessThan(2));
    await tester.binding.setSurfaceSize(const Size(320, 844));
    await tester.pumpAndSettle();
    final narrowSummary = tester.getRect(
      find.byKey(const Key('sake-score-summary')),
    );
    final narrowImage = tester.getRect(
      find.byKey(const Key('sake-hero-image')),
    );
    expect(narrowImage.top - narrowSummary.bottom, greaterThanOrEqualTo(16));
    expect(tester.takeException(), isNull);
  });

  testWidgets('評価がない場合の余白と近くで飲める場所のCTAを表示する', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      Provider<SakeScanRepository>.value(
        value: _FakeSakeScanRepository(),
        child: const MaterialApp(
          home: SakeMasterDetailPage(
            venueSake: VenueSake(sakeId: 123, name: '来福', recordCount: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('まだ評価はありません'), 300);
    final emptyText = tester.widget<Text>(find.text('まだ評価はありません'));
    expect(emptyText.style?.fontSize, 12);
    final emptyRect = tester.getRect(find.text('まだ評価はありません'));
    final reviewRect = tester.getRect(find.text('このお酒を評価'));
    expect(reviewRect.left - emptyRect.right, greaterThanOrEqualTo(12));
    await tester.scrollUntilVisible(find.text('近くで飲める場所を探す'), 300);
    expect(
      find.ancestor(
        of: find.text('近くで飲める場所を探す'),
        matching: find.byType(FilledButton),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('あなたの記録の編集中に余白をタップするとフォーカスが外れる', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final saved = SavedSakeNotifier()
      ..read = (<T>() => _GuestAuthRepository() as T);
    addTearDown(saved.dispose);
    await saved.addSavedSake(const Sake(sakeId: 123, name: 'マスター純米酒'));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SakeScanRepository>.value(value: _FakeSakeScanRepository()),
          Provider<SavedSakeNotifier>.value(value: saved),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('ja'),
          home: SakeMasterDetailPage(
            venueSake: VenueSake(sakeId: 123, name: 'マスター純米酒', recordCount: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('編集'), 300);
    await tester.tap(find.text('編集'));
    await tester.pumpAndSettle();
    final memo = find.byType(TextField).first;
    await tester.tap(memo);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.text('あなたの記録を編集'));
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('公開評価の感想入力中に別の項目をタップするとキーボードを閉じる', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: _SignedInAuthRepository()),
          Provider<SakeScanRepository>.value(value: _FakeSakeScanRepository()),
        ],
        child: const MaterialApp(
          home: SakeMasterDetailPage(
            venueSake: VenueSake(sakeId: 123, name: '来福', recordCount: 0),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('このお酒を評価'), 300);
    await tester.tap(find.byKey(const Key('sake-community-review-button')));
    await tester.pumpAndSettle();
    final comment = find.byType(TextField);
    expect(tester.widget<TextField>(comment).maxLines, 3);
    await tester.ensureVisible(comment);
    await tester.tap(comment);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    await tester.tap(find.text('辛さ').last);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);
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
              name: '鍋島 純米吟醸 山田錦 生酒',
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
    expect(find.text('鍋島 純米吟醸 山田錦 生酒'), findsWidgets);
    expect(repository.requestedToken, 'candidate:12');

    repository.complete();
    await tester.pumpAndSettle();
    expect(find.text('詳細情報を取得中'), findsNothing);
    expect(find.text('鍋島 純米吟醸'), findsWidgets);
    expect(find.text('鍋島 純米吟醸 山田錦 生酒'), findsNothing);
    expect(find.textContaining('未検証'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('AI解析済みの味わい説明'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('AI解析済みの味わい説明'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AI候補の解決後は取得済みのIDと画像で保存・お気に入りを操作できる', (tester) async {
    final repository = _FakeSakeMenuRecognitionRepository();
    final saved = SavedSakeNotifier()
      ..read = (<T>() => _GuestAuthRepository() as T);
    final favorite = FavoriteNotifier()
      ..read = (<T>() => _GuestAuthRepository() as T);
    addTearDown(saved.dispose);
    addTearDown(favorite.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SakeMenuRecognitionRepository>.value(value: repository),
          Provider<SavedSakeNotifier>.value(value: saved),
          Provider<FavoriteNotifier>.value(value: favorite),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('ja'),
          home: SakeMasterDetailPage(
            venueSake: VenueSake(
              searchToken: 'candidate:12',
              name: '鍋島',
              type: '純米吟醸',
              recordCount: 0,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byIcon(Icons.bookmark_outline), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    repository.complete();
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark_outline), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    await tester.tap(find.byIcon(Icons.bookmark_outline));
    await tester.pumpAndSettle();
    expect(saved.state.savedSakeList.single.sakeId, 456);
    expect(saved.state.savedSakeList.single.name, '鍋島 純米吟醸');
    expect(
      saved.state.savedSakeList.single.primaryImageUrl,
      'https://example.com/600.jpg',
    );
    expect(saved.state.savedSakeList.single.description, 'AI解析済みの味わい説明');
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(favorite.state.myFavoriteList.single.name, '鍋島 純米吟醸');
    await tester.tap(find.byIcon(Icons.bookmark));
    await tester.pumpAndSettle();
    expect(saved.state.savedSakeList, isEmpty);
    await tester.tap(find.byIcon(Icons.favorite));
    await tester.pumpAndSettle();
    expect(favorite.state.myFavoriteList, isEmpty);
    expect(repository.calls, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

class _GuestAuthRepository implements AuthRepository {
  @override
  get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SignedInAuthRepository implements AuthRepository {
  @override
  User? get currentUser => _FakeUser();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUrlLauncher extends UrlLauncherPlatform {
  @override
  get linkDelegate => null;
  String? openedUrl;
  PreferredLaunchMode? mode;
  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    openedUrl = url;
    mode = options.mode;
    return true;
  }
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
  String? requestedToken;
  int calls = 0;

  @override
  Future<SakeOverview?> resolveSakeCandidateOverview(String searchToken) {
    requestedToken = searchToken;
    calls++;
    return _completer.future;
  }

  void complete() {
    _completer.complete(
      const SakeOverview(
        sake: Sake(
          sakeId: 456,
          primaryImageUrl: 'https://example.com/600.jpg',
          thumbnailImageUrl: 'https://example.com/146.jpg',
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
  _FakeSakeScanRepository({this.overview});

  final SakeOverview? overview;
  bool fail = false;
  bool? lastTrackView;

  @override
  Future<SakeOverview> fetchOverview(
    int sakeId, {
    bool trackView = false,
  }) async {
    lastTrackView = trackView;
    if (fail) throw Exception('test failure');
    return overview ??
        const SakeOverview(
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
            imageProductUrl:
                'https://store.shopping.yahoo.co.jp/example/sake.html',
            imagePrice: 2150,
            imageCurrency: 'JPY',
            rakutenOffer: SakeShopOffer(
              price: 2096,
              affiliateUrl: 'https://hb.afl.rakuten.co.jp/hgc/test/?pc=item',
            ),
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
