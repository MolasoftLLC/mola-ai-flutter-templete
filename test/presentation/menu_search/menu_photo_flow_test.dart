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
    const fontPath = String.fromEnvironment('MENU_UI_FONT');
    if (fontPath.isNotEmpty) {
      final loader = FontLoader('MenuPreview')
        ..addFont(
          Future.value(
            ByteData.sublistView(await File(fontPath).readAsBytes()),
          ),
        );
      await loader.load();
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
  }) => MaterialApp(
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
    home: RepaintBoundary(key: const ValueKey('preview'), child: home),
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

  testWidgets('撮影と写真選択を入口にし、最新2件から実際の履歴を開ける', (tester) async {
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
                3,
                (i) => MenuAnalysisHistoryItem(
                  id: 'history-$i',
                  date: DateTime(2026, 10, 29 - i),
                  storeName: i == 0 ? 'とんかつ大将' : null,
                  imagePath: photo.path,
                  sakes: List.generate(
                    7 - i * 2,
                    (n) => SavedSake(name: '酒$n'),
                  ),
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
    expect(find.text('10/27のメニュー'), findsNothing);
    expect(tester.takeException(), isNull);
    await preview(tester, 'entry');
  });

  testWidgets('写真全体を確認し、明示的に押すまで解析しない。拡大できる', (tester) async {
    await size(tester);
    var calls = 0;
    await tester.pumpWidget(app(confirmation(analyze: () => calls++)));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(tester.widget<Image>(find.byType(Image).first).fit, BoxFit.contain);
    await preview(tester, 'confirmation');
    await tester.tap(find.text('タップで拡大'));
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

  testWidgets('解析中は中止と写真保持の説明を表示する', (tester) async {
    await size(tester);
    var cancelled = false;
    await tester.pumpWidget(
      app(MenuAnalysisProgress(photo: photo, onCancel: () => cancelled = true)),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('写真は消えません'), findsOneWidget);
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
    await tester.drag(
      find.byKey(const ValueKey('crop-topLeft')),
      const Offset(30, 40),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
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
      Provider<AuthRepository>.value(
        value: _Auth(),
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
  String get ownerId => 'test-user';
  @override
  Future<void> upsert(MenuAnalysisHistoryItem item) async {
    items.removeWhere((i) => i.id == item.id);
    items.add(item);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
