import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_sake_resolution.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/my_page/my_page_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/repository/auth_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_menu_recognition_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/menu_analysis_history_repository.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_photo_crop_page.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_photo_flow_page.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_search_page_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/menu_capture_entry.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/menu_photo_style.dart';

import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/menu_history_list.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/menu_history_tile.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/menu_result_place_field.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_history_page.dart';

import 'package:mola_gemini_flutter_template/domain/notifier/favorite/favorite_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/saved_sake/saved_sake_notifier.dart';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_camera_page.dart';
import '../../support/fake_menu_camera.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File photo;
  setUpAll(() async {
    loggerConfigure();
    directory = await Directory.systemTemp.createTemp('menu-photo-test-');
    final image = img.Image(width: 240, height: 420);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    for (var y = 40; y < 390; y += 55) {
      img.fillRect(
        image,
        x1: 20,
        y1: y,
        x2: 180,
        y2: y + 8,
        color: img.ColorRgb8(23, 57, 95),
      );
    }
    photo = await File(
      '${directory.path}/menu.png',
    ).writeAsBytes(img.encodePng(image));
    final loaded = Completer<void>();
    final stream = FileImage(photo).resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (_, _) {
        if (!loaded.isCompleted) loaded.complete();
      },
      onError: (Object error, StackTrace? stack) =>
          loaded.completeError(error, stack),
    );
    stream.addListener(listener);
    await loaded.future;
    stream.removeListener(listener);
    final illustrationLoaded = Completer<void>();
    final illustrationStream = const ResizeImage(
      AssetImage('assets/images/menu_capture_illustration.png'),
      width: 528,
    ).resolve(ImageConfiguration.empty);
    final illustrationListener = ImageStreamListener(
      (_, _) {
        if (!illustrationLoaded.isCompleted) illustrationLoaded.complete();
      },
      onError: (Object error, StackTrace? stack) =>
          illustrationLoaded.completeError(error, stack),
    );
    illustrationStream.addListener(illustrationListener);
    await illustrationLoaded.future;
    illustrationStream.removeListener(illustrationListener);
    const fontPath = String.fromEnvironment('MENU_UI_FONT');
    if (fontPath.isNotEmpty) {
      final loader = FontLoader('MenuPreview')
        ..addFont(
          Future.value(
            ByteData.sublistView(await File(fontPath).readAsBytes()),
          ),
        );
      await loader.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  tearDownAll(() => directory.delete(recursive: true));
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'ai_data_sharing_consent_v1_test-user': true,
      'sake_preferences': '辛口',
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => directory.path,
        );
  });

  Future<void> size(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
  }

  Widget app(
    Widget home, {
    double scale = 1,
    Locale locale = const Locale('ja'),
  }) => RepaintBoundary(
    key: const ValueKey('preview'),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: const String.fromEnvironment('MENU_UI_FONT').isEmpty
            ? null
            : 'MenuPreview',
      ),
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scale),
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
        child: child!,
      ),
      home: home,
    ),
  );

  Future<void> preview(WidgetTester tester, String name) async {
    const output = String.fromEnvironment('MENU_UI_OUTPUT');
    if (output.isEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    });
  }

  MenuPhotoConfirmation confirmation({
    VoidCallback? analyze,
    bool cropped = false,
    String? error,
  }) => MenuPhotoConfirmation(
    photo: photo,
    cropped: cropped,
    error: error,
    onBack: () {},
    onAnalyze: analyze ?? () {},
    onRetake: () {},
    onCrop: () {},
    onRestore: () {},
  );

  testWidgets('撮影と写真選択を入口にし、最新5件から実際の履歴を開ける', (tester) async {
    await size(tester);
    String? opened;
    var camera = 0, gallery = 0, more = 0;
    await tester.pumpWidget(
      app(
        Scaffold(
          backgroundColor: MenuPhotoStyle.blue,
          appBar: MenuPhotoStyle.appBar('メニュー解析'),
          body: SingleChildScrollView(
            child: MenuCaptureEntry(
              history: List.generate(
                7,
                (i) => MenuAnalysisHistoryItem(
                  id: 'history-$i',
                  date: DateTime(2026, 10, 29 - i),
                  storeName: i == 0 ? 'とんかつ大将' : null,
                  imagePath: photo.path,
                  sakes: List.generate(7 - i, (n) => SavedSake(name: '酒$n')),
                ),
              ),
              onCamera: () => camera++,
              onGallery: () => gallery++,
              onMore: () => more++,
              onHistory: (id) => opened = id,
            ),
          ),
          bottomNavigationBar: const SizedBox(
            height: 98,
            child: ColoredBox(color: MenuPhotoStyle.ink),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('メニューを撮影'));
    await tester.tap(find.text('写真から選ぶ'));
    await tester.tap(find.text('とんかつ大将'));
    await tester.tap(find.text('もっと見る'));
    expect((camera, gallery, more, opened), (1, 1, 1, 'history-0'));
    expect(find.text('10/25のメニュー'), findsOneWidget);
    expect(find.text('10/24のメニュー'), findsNothing);
    expect(find.text('選択した写真を確認'), findsNothing);
    expect(
      tester.widget<Text>(find.text('メニューを撮影')).style!.color,
      MenuPhotoStyle.ink,
    );
    final button = tester.widget<Material>(
      find.byKey(const ValueKey('menu-capture-button')),
    );
    expect(button.color, Colors.white);
    expect(
      (button.shape! as RoundedRectangleBorder).side.color,
      MenuPhotoStyle.scanOrange,
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is MenuPhotoIcon && widget.name == 'camera',
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
    await preview(tester, 'entry');
  });

  testWidgets('履歴を20件ずつ追加し、二重取得せず最後までスクロールできる', (tester) async {
    await size(tester);
    var requests = 0;
    final items = <MenuAnalysisHistoryItem>[];
    final waiting = Completer<bool>();
    String? opened;
    late StateSetter update;
    await tester.pumpWidget(
      app(
        Scaffold(
          backgroundColor: MenuPhotoStyle.blue,
          appBar: MenuPhotoStyle.appBar('過去の解析'),
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MenuHistoryList(
                history: items,
                onOpen: (id) => opened = id,
                loadMore: () async {
                  requests++;
                  if (requests == 1) {
                    update(
                      () => items.addAll(
                        List.generate(
                          20,
                          (i) => MenuAnalysisHistoryItem(
                            id: 'history-$i',
                            date: DateTime(
                              2026,
                              10,
                              29,
                            ).subtract(Duration(days: i)),
                            imagePath: photo.path,
                            storeName: '店舗$i',
                            sakes: [SavedSake(name: '正雪')],
                          ),
                        ),
                      ),
                    );
                    return true;
                  }
                  final more = await waiting.future;
                  update(
                    () => items.addAll(
                      List.generate(
                        5,
                        (i) => MenuAnalysisHistoryItem(
                          id: 'older-$i',
                          date: DateTime(2026, 9, 1),
                          imagePath: photo.path,
                          storeName: '古い店舗$i',
                          sakes: [],
                        ),
                      ),
                    ),
                  );
                  return more;
                },
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests, 1);
    await preview(tester, 'history');
    expect(find.byType(MenuHistoryTile).evaluate().length, lessThan(20));
    await tester.scrollUntilVisible(
      find.text('店舗19'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(requests, 2);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pump();
    expect(requests, 2);
    waiting.complete(false);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('古い店舗4'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('古い店舗4'));
    expect(opened, 'older-4');
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('履歴追加の失敗でも表示済み行を保持し、再読み込みで復旧する', (tester) async {
    var requests = 0;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: MenuHistoryList(
            history: [
              MenuAnalysisHistoryItem(
                id: 'kept',
                date: DateTime(2026),
                storeName: '保持する店舗',
                imagePath: photo.path,
                sakes: [],
              ),
            ],
            onOpen: (_) {},
            loadMore: () async {
              if (++requests == 1) throw StateError('offline');
              return false;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('保持する店舗'), findsOneWidget);
    expect(requests, 1);
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('再読み込み'), findsNothing);
    expect(find.text('保持する店舗'), findsOneWidget);
  });

  testWidgets('履歴の場所を選び直し、座標付きで保存し、失敗時は再試行できる', (tester) async {
    await size(tester);
    var calls = 0;
    DrinkingPlace? saved;
    const place = DrinkingPlace(
      displayName: '新しい店舗',
      latitude: 35,
      longitude: 135,
      providerPlaceId: 'g-2',
    );
    final original = MenuAnalysisHistoryItem(
      id: 'place',
      date: DateTime(2026),
      sakes: [],
      storeName: '元の店舗',
    );
    await tester.pumpWidget(
      app(
        Scaffold(
          backgroundColor: MenuPhotoStyle.blue,
          body: MenuResultPlaceField(
            history: original,
            pickPlace: (_, initial) async {
              expect(initial, '元の店舗');
              return place;
            },
            onSave: (value) async {
              if (++calls == 1) throw StateError('disk full');
              saved = value;
            },
          ),
        ),
      ),
    );
    await preview(tester, 'place-registered');
    await tester.tap(find.text('元の店舗'));
    await tester.pumpAndSettle();
    expect(saved, isNull);
    expect(find.text('元の店舗'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.location_on_outlined));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(saved, place);
    expect(saved!.latitude, 35);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      app(
        Scaffold(
          backgroundColor: MenuPhotoStyle.blue,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: MenuResultPlaceField(
              history: MenuAnalysisHistoryItem(
                id: 'unregistered',
                date: DateTime(2026),
                sakes: [],
              ),
              onSave: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await preview(tester, 'place-add');
  });

  testWidgets('写真全体を確認し、明示的に押すまで解析しない。拡大できる', (tester) async {
    await size(tester);
    var calls = 0;
    await tester.pumpWidget(app(confirmation(analyze: () => calls++)));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(tester.widget<Image>(find.byType(Image).first).fit, BoxFit.contain);
    await preview(tester, 'confirmation');
    expect(find.text('タップで拡大'), findsNothing);
    expect(
      tester.getTopLeft(find.text('この写真で解析する')).dy,
      lessThan(tester.getTopLeft(find.text('撮り直す')).dy),
    );
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    await tester.tap(find.text('この写真で解析する'));
    expect(calls, 1);
  });

  testWidgets('切り抜き後の状態とリセット、通信エラーを表示する', (tester) async {
    await size(tester);
    await tester.pumpWidget(app(confirmation(cropped: true)));
    await tester.pumpAndSettle();
    expect(find.text('切り抜き済み'), findsOneWidget);
    expect(find.text('元に戻す'), findsOneWidget);
    await preview(tester, 'cropped');
    await tester.pumpWidget(
      app(confirmation(error: '通信できませんでした。もう一度お試しください。')),
    );
    await tester.pumpAndSettle();
    expect(find.text('この写真で解析する').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('小さい画面・拡大文字・英語でも確認と解析の操作が収まる', (tester) async {
    await size(tester, size: const Size(320, 568));
    for (final locale in [const Locale('ja'), const Locale('en')]) {
      await tester.pumpWidget(
        app(
          confirmation(cropped: true, error: '通信エラー'),
          scale: 1.5,
          locale: locale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(FilledButton).hitTestable(), findsNWidgets(3));
    }
  });

  testWidgets('解析中は中止ボタンを表示し、写真保持の説明は出さない', (tester) async {
    await size(tester);
    var cancelled = false;
    await tester.pumpWidget(
      app(MenuAnalysisProgress(photo: photo, onCancel: () => cancelled = true)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('写真は消えません'), findsNothing);
    await preview(tester, 'progress');
    await tester.tap(find.text('解析を中止'));
    expect(cancelled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('切り抜き範囲を動かし、元画像を変更せず切り抜いた画像を返す', (tester) async {
    await size(tester);
    final originalBytes = await tester.runAsync(photo.readAsBytes);
    await tester.runAsync(() async {
      await tester.pumpWidget(app(MenuPhotoCropPage(image: photo)));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    await preview(tester, 'crop');
    await tester.dragFrom(
      tester.getCenter(find.byKey(const ValueKey('crop-topLeft'))),
      const Offset(30, 40),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await preview(tester, 'crop-adjusted');
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(originalBytes!);
      final image = (await codec.getNextFrame()).image;
      final encoded = await encodeMenuCrop(
        image,
        const Rect.fromLTWH(.25, .25, .5, .5),
      );
      final decoded = img.decodePng(encoded)!;
      expect((decoded.width, decoded.height), (120, 210));
      expect(await photo.readAsBytes(), originalBytes);
      image.dispose();
      codec.dispose();
    });
  });

  test('切り抜きの四隅は画像の外に出ず、範囲が反転しない', () {
    const rect = Rect.fromLTWH(.2, .2, .6, .6);
    expect(
      adjustMenuCrop(
        rect,
        const Offset(-1, -1),
        MenuCropCorner.topLeft,
      ).topLeft,
      Offset.zero,
    );
    expect(
      adjustMenuCrop(
        rect,
        const Offset(2, 2),
        MenuCropCorner.bottomRight,
      ).bottomRight,
      const Offset(1, 1),
    );
    expect(
      adjustMenuCrop(rect, const Offset(2, 2), MenuCropCorner.topLeft).width,
      closeTo(.08, .00001),
    );
  });

  Future<(MenuSearchPageNotifier, _Repository, _History)> setupNotifier(
    WidgetTester tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: _Auth()),
          Provider<FavoriteState>.value(value: const FavoriteState()),
          Provider<SavedSakeState>.value(value: const SavedSakeState()),
          Provider<FavoriteNotifier>.value(value: _Favorites()),
          Provider<SavedSakeNotifier>.value(value: _Saved()),
        ],
        child: app(
          Builder(
            builder: (c) {
              context = c;
              return const SizedBox();
            },
          ),
        ),
      ),
    );
    final repository = _Repository();
    final history = _History();
    final notifier = MenuSearchPageNotifier(
      context: context,
      historyRepository: history,
    );
    notifier.read = <T>() {
      if (T == AuthRepository) return _Auth() as T;
      if (T == MyPageNotifier) return _Preferences() as T;
      if (T == SakeMenuRecognitionRepository) return repository as T;
      throw StateError('Unexpected dependency $T');
    };
    addTearDown(() {
      if (notifier.mounted) notifier.dispose();
    });
    await tester.runAsync(() => notifier.selectPhoto(photo));
    return (notifier, repository, history);
  }

  Future<void> settleUntil(
    WidgetTester tester,
    bool Function() condition,
  ) async {
    for (var i = 0; i < 100 && !condition(); i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      condition(),
      isTrue,
      reason: 'Asynchronous menu operation did not settle',
    );
  }

  testWidgets('撮影は使用確認を挟まず切り抜き・撮り直し画面へ進み、キャンセルなら元写真を保つ', (tester) async {
    await size(tester);
    final originalPlatform = CameraPlatform.instance;
    final camera = FakeMenuCamera(path: photo.path);
    CameraPlatform.instance = camera;
    addTearDown(() async {
      CameraPlatform.instance = originalPlatform;
      await camera.close();
    });
    final (notifier, repo, _) = await setupNotifier(tester);
    MenuSearchPageState? state;
    notifier.addListener((value) => state = value);
    var picked = false;
    unawaited(notifier.pickImageFromCamera().then((_) => picked = true));
    await tester.pumpAndSettle();
    expect(find.byType(MenuCameraPage), findsOneWidget);
    await preview(tester, 'menu-camera');
    await tester.tap(find.byKey(const ValueKey('menu-camera-shutter')));
    await settleUntil(tester, () => picked);
    await tester.pumpAndSettle();
    expect(state!.sakeImage, isNotNull);
    expect(repo.requests, isEmpty);
    final selected = state!.sakeImage;
    final flow = Navigator.of(notifier.context).push<void>(
      MaterialPageRoute(builder: (_) => MenuPhotoFlowPage(notifier: notifier)),
    );
    await tester.pumpAndSettle();
    expect(find.text('この写真で解析する'), findsOneWidget);
    expect(find.text('切り抜き'), findsOneWidget);
    expect(find.text('撮り直す'), findsOneWidget);
    await tester.tap(find.text('撮り直す'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuCameraPage), findsOneWidget);
    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();
    expect(state!.sakeImage, selected);
    expect(repo.requests, isEmpty);
    await tester.tap(find.text('撮り直す'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('menu-camera-shutter')));
    await settleUntil(tester, () => state!.sakeImage != selected);
    await tester.pumpAndSettle();
    expect(find.byType(MenuCameraPage), findsNothing);
    expect(find.text('この写真で解析する'), findsOneWidget);
    expect(camera.captures, 2);
    expect(repo.requests, isEmpty);
    Navigator.of(notifier.context).pop();
    await tester.pumpAndSettle();
    await flow;
    notifier.dispose();
  });

  testWidgets('過去の解析詳細も青背景で、場所変更後のタイトル・位置情報が残る', (tester) async {
    await size(tester);
    final (notifier, _, history) = await setupNotifier(tester);
    final record = MenuAnalysisHistoryItem(
      id: 'detail',
      date: DateTime(2026, 10, 28),
      storeName: '魚処 天悟',
      imagePath: photo.path,
      sakes: [
        SavedSake(
          name: '正雪 純米',
          details: const Sake(
            name: '正雪 純米',
            type: '純米',
            description: 'すっきりとした口当たりのお酒です。',
          ),
          matchPercent: 75,
        ),
      ],
    );
    history.items.add(record);
    await notifier.loadMenuAnalysisHistory();
    final opened = MenuHistoryPage.open(
      notifier.context,
      notifier,
      historyId: record.id,
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor,
      MenuPhotoStyle.blue,
    );
    expect(find.byType(MenuResultPlaceField), findsOneWidget);
    await preview(tester, 'history-detail');
    await tester.scrollUntilVisible(
      find.text('正雪 純米'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('正雪 純米'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('すっきりとした口当たりのお酒です。'));
    await preview(tester, 'history-sake');
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    const place = DrinkingPlace(
      displayName: '移動後の店舗',
      formattedAddress: '京都府',
      latitude: 35,
      longitude: 135,
    );
    await tester.runAsync(() => notifier.setHistoryPlace('detail', place));
    await tester.pumpAndSettle();
    expect(find.text('移動後の店舗'), findsNWidgets(2));
    expect(find.text('京都府'), findsOneWidget);
    expect(history.items.single.date, record.date);
    expect(history.items.single.imagePath, record.imagePath);
    expect(history.items.single.drinkingPlace, place);
    Navigator.of(notifier.context).pop();
    await tester.pumpAndSettle();
    await opened;
    notifier.dispose();
  });

  testWidgets('選んだ写真は自動解析しない。切り抜きを戻し、中止後も元写真を保持する', (tester) async {
    final (notifier, repo, _) = await setupNotifier(tester);
    MenuSearchPageState? state;
    notifier.addListener((s) => state = s);
    expect(repo.requests, isEmpty);
    final original = state!.sakeImage;
    notifier.applyCroppedPhoto(File('${directory.path}/cropped.png'));
    expect(notifier.isPhotoCropped, isTrue);
    notifier.restoreOriginalPhoto();
    expect(state!.sakeImage, original);
    notifier.applyCroppedPhoto(File('${directory.path}/cropped.png'));
    notifier.cancelAnalysis();
    expect(state!.sakeImage!.path.endsWith('cropped.png'), isTrue);
    notifier.restoreOriginalPhoto();
    expect(state!.sakeImage, original);
  });

  testWidgets('確認→任意の切り抜きキャンセル→解析中止→再解析→結果へ進む', (tester) async {
    final (notifier, repo, history) = await setupNotifier(tester);
    unawaited(
      Navigator.of(notifier.context).push<void>(
        MaterialPageRoute(
          builder: (_) => MenuPhotoFlowPage(notifier: notifier),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.requests, isEmpty);
    await tester.tap(find.text('切り抜き'));
    await settleUntil(
      tester,
      () => find.byKey(const ValueKey('crop-topLeft')).evaluate().isNotEmpty,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('キャンセル'));
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('この写真で解析する'), findsOneWidget);
    expect(notifier.isPhotoCropped, isFalse);
    await tester.tap(find.text('この写真で解析する'));
    await settleUntil(tester, () => repo.requests.length == 1);
    await tester.ensureVisible(find.text('解析を中止'));
    await tester.tap(find.text('解析を中止'));
    await tester.pumpAndSettle();
    expect(find.text('この写真で解析する'), findsOneWidget);
    repo.requests.first.complete([const Sake(name: '中止した結果')]);
    await tester.pumpAndSettle();
    expect(history.items, isEmpty);
    await tester.tap(find.text('この写真で解析する'));
    await settleUntil(tester, () => repo.requests.length == 2);
    repo.requests.last.complete([const Sake(name: '現在の結果')]);
    await settleUntil(
      tester,
      () => find.byType(MenuPhotoFlowPage).evaluate().isEmpty,
    );
    expect(history.items.single.sakes.single.name, '現在の結果');
    notifier.dispose();
  });

  testWidgets('中止後に届く解析結果を捨て、次の解析だけ保存する', (tester) async {
    final (notifier, repo, history) = await setupNotifier(tester);
    MenuSearchPageState? state;
    notifier.addListener((s) => state = s);
    var oldFinished = false;
    unawaited(
      notifier.extractAndFetchSakeInfo(photo).then((_) => oldFinished = true),
    );
    await settleUntil(tester, () => repo.requests.length == 1);
    notifier.cancelAnalysis();
    var newFinished = false;
    unawaited(
      notifier.extractAndFetchSakeInfo(photo).then((_) => newFinished = true),
    );
    await settleUntil(tester, () => repo.requests.length == 2);
    repo.requests.first.complete([const Sake(name: '古い結果')]);
    await settleUntil(tester, () => oldFinished);
    expect(state!.extractedSakes, isEmpty);
    expect(history.items, isEmpty);
    repo.requests.last.complete([const Sake(name: '現在の結果')]);
    await settleUntil(tester, () => newFinished);
    expect(state!.extractedSakes.single.name, '現在の結果');
    expect(state!.isMasterLookupComplete, isTrue);
    expect(history.items.single.sakes.single.name, '現在の結果');
    notifier.dispose();
  });

  testWidgets('解析の失敗後も写真を残し、再試行できる。連打で二重送信しない', (tester) async {
    final (notifier, repo, _) = await setupNotifier(tester);
    MenuSearchPageState? state;
    notifier.addListener((s) => state = s);
    var finished = false;
    unawaited(
      notifier.extractAndFetchSakeInfo(photo).then((_) => finished = true),
    );
    await notifier.extractAndFetchSakeInfo(photo);
    await settleUntil(tester, () => repo.requests.length == 1);
    repo.requests.first.completeError(const SocketException('offline'));
    await settleUntil(tester, () => finished);
    expect(state!.sakeImage, isNotNull);
    expect(state!.errorMessage, isNotNull);
    finished = false;
    unawaited(
      notifier.extractAndFetchSakeInfo(photo).then((_) => finished = true),
    );
    await settleUntil(tester, () => repo.requests.length == 2);
    repo.requests.last.complete([]);
    await settleUntil(tester, () => finished);
    expect(state!.isLoading, isFalse);
    expect(state!.sakeImage, isNotNull);
  });
}

class _Auth implements AuthRepository {
  @override
  User get currentUser => _User();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  @override
  String get uid => 'test-user';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Preferences implements MyPageNotifier {
  @override
  MyPageState get state => const MyPageState(preferences: '辛口');
  @override
  Future<void> reloadPreferencesFromLocal() async {}
  @override
  Future<void> refreshTasteProfile() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repository implements SakeMenuRecognitionRepository {
  final requests = <Completer<List<Sake>?>>[];
  @override
  SakeMenuRecognitionRepository forkSession() => this;
  @override
  Future<List<Sake>?> extractSakeInfo(File image) {
    final request = Completer<List<Sake>?>();
    requests.add(request);
    return request.future;
  }

  @override
  Future<List<MenuSakeResolution>> resolveMenuSakes(
    List<Sake> sakes, {
    bool masterOnly = false,
    bool includeDescription = false,
    int? selectedSakeId,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _History implements MenuAnalysisHistoryRepository {
  final items = <MenuAnalysisHistoryItem>[];
  @override
  Future<List<MenuAnalysisHistoryItem>> load() async => items.toList();
  @override
  String get ownerId => 'test-user';
  @override
  Future<void> upsert(MenuAnalysisHistoryItem item) async {
    items.removeWhere((i) => i.id == item.id);
    items.add(item);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Favorites implements FavoriteNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Saved implements SavedSakeNotifier {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
