import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:mola_gemini_flutter_template/domain/notifier/auth/auth_notifier.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/common/map/place_registration_inbox.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/saved_sake/saved_sake_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/menu_search_page_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/place_registration_page.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/venue_favorites_action.dart';
import 'package:mola_gemini_flutter_template/presentation/common/widgets/primary_app_bar.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';

class _Saved extends StateNotifier<SavedSakeState>
    implements SavedSakeNotifier {
  _Saved()
    : super(
        const SavedSakeState(
          savedSakeList: [
            Sake(
              savedId: '1',
              name: '宮寒梅 純米大吟醸',
              imagePaths: ['/missing-bottle.jpg'],
              impression: 'この感想を保全',
              isPublic: false,
            ),
          ],
        ),
      );
  @override
  List<Sake> get savedSakes => state.savedSakeList;
  @override
  Future<void> updateSavedSake(Sake sake) async {
    state = state.copyWith(savedSakeList: [sake]);
  }

  @override
  Future<void> setSavedSakePlace(String id, DrinkingPlace place) async {
    await updateSavedSake(
      savedSakes.single.copyWith(
        place: place.displayName,
        drinkingPlace: place,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Menus extends StateNotifier<MenuSearchPageState>
    implements MenuSearchPageNotifier {
  _Menus()
    : super(
        MenuSearchPageState(
          menuAnalysisHistory: [
            MenuAnalysisHistoryItem(
              id: 'm',
              date: DateTime(2026, 11, 21),
              sakes: [
                SavedSake(name: '酒1'),
                SavedSake(name: '酒2'),
              ],
            ),
          ],
        ),
      );
  bool fail = false;
  @override
  Future<void> setHistoryPlace(String id, DrinkingPlace? place) async {
    if (fail) throw StateError('failed');
    state = state.copyWith(
      menuAnalysisHistory: state.menuAnalysisHistory
          .map(
            (m) =>
                m.copyWith(drinkingPlace: place, storeName: place?.displayName),
          )
          .toList(),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  _User(this.uid);
  @override
  final String uid;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const place = DrinkingPlace(
    displayName: '日本酒のお店',
    latitude: 35.6,
    longitude: 139.7,
  );
  Future<void> pump(
    WidgetTester tester,
    _Saved saved,
    _Menus menus,
    Widget child, {
    String? font,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          StateNotifierProvider<SavedSakeNotifier, SavedSakeState>.value(
            value: saved,
          ),
          StateNotifierProvider<
            MenuSearchPageNotifier,
            MenuSearchPageState
          >.value(value: menus),
        ],
        child: MaterialApp(
          theme: ThemeData(fontFamily: font),
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('地図左上の赤バッジはメニュー内の商品数ではなく記録2件を表示する', (tester) async {
    final saved = _Saved(), menus = _Menus();
    addTearDown(saved.dispose);
    addTearDown(menus.dispose);
    await pump(
      tester,
      saved,
      menus,
      Scaffold(appBar: AppBar(leading: const PlaceRegistrationAction())),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
    expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    await tester.tap(find.byType(PlaceRegistrationAction));
    await tester.pumpAndSettle();
    expect(find.text('場所を登録する'), findsOneWidget);
    expect(find.text('宮寒梅 純米大吟醸'), findsOneWidget);
    expect(find.text('撮影したメニュー'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('場所登録で一覧から外れ、感想・画像・公開設定を保全する', (tester) async {
    final saved = _Saved(),
        menus = _Menus(),
        store = PlaceRegistrationDismissals('guest');
    addTearDown(saved.dispose);
    addTearDown(menus.dispose);
    addTearDown(store.dispose);
    await store.load();
    await pump(
      tester,
      saved,
      menus,
      PlaceRegistrationPage(store: store, pickPlace: (_, __) async => place),
    );
    await tester.tap(find.text('場所を登録').first);
    await tester.pumpAndSettle();
    expect(find.text('宮寒梅 純米大吟醸'), findsNothing);
    expect(saved.savedSakes.single.impression, 'この感想を保全');
    expect(saved.savedSakes.single.imagePaths, ['/missing-bottle.jpg']);
    expect(saved.savedSakes.single.isPublic, false);
    expect(saved.savedSakes.single.drinkingPlace, place);
    await tester.tap(find.text('場所を登録'));
    await tester.pumpAndSettle();
    expect(find.text('場所を登録できる記録はありません'), findsOneWidget);
    expect(menus.state.menuAnalysisHistory.single.sakes.length, 2);
  });
  testWidgets('覚えていないは写真や履歴を消さず、元に戻せる', (tester) async {
    final saved = _Saved(),
        menus = _Menus(),
        store = PlaceRegistrationDismissals('guest');
    addTearDown(saved.dispose);
    addTearDown(menus.dispose);
    addTearDown(store.dispose);
    await store.load();
    await pump(tester, saved, menus, PlaceRegistrationPage(store: store));
    await tester.tap(find.text('覚えていない').first);
    await tester.pumpAndSettle();
    expect(find.text('宮寒梅 純米大吟醸'), findsNothing);
    expect(saved.savedSakes.length, 1);
    expect(saved.savedSakes.single.imagePaths, isNotEmpty);
    await tester.tap(find.text('元に戻す'));
    await tester.pumpAndSettle();
    expect(find.text('宮寒梅 純米大吟醸'), findsOneWidget);
  });
  testWidgets('場所保存が失敗しても対象は消えず再試行できる', (tester) async {
    final saved = _Saved(),
        menus = _Menus()..fail = true,
        store = PlaceRegistrationDismissals('guest');
    addTearDown(saved.dispose);
    addTearDown(menus.dispose);
    addTearDown(store.dispose);
    await store.load();
    await pump(
      tester,
      saved,
      menus,
      PlaceRegistrationPage(store: store, pickPlace: (_, __) async => place),
    );
    await tester.tap(find.text('場所を登録').last);
    await tester.pumpAndSettle();
    expect(find.text('撮影したメニュー'), findsOneWidget);
    expect(find.text('保存できませんでした。もう一度お試しください。'), findsOneWidget);
  });

  testWidgets('場所選択中にアカウントが変わっても別アカウントへ保存しない', (tester) async {
    final saved = _Saved(),
        menus = _Menus(),
        store = PlaceRegistrationDismissals('a');
    addTearDown(saved.dispose);
    addTearDown(menus.dispose);
    addTearDown(store.dispose);
    await store.load();
    final auth = ValueNotifier(AuthState(user: _User('a')));
    addTearDown(auth.dispose);
    final picked = Completer<DrinkingPlace?>();
    await tester.pumpWidget(
      ValueListenableBuilder<AuthState>(
        valueListenable: auth,
        builder: (_, state, __) => Provider<AuthState>.value(
          value: state,
          child: MultiProvider(
            providers: [
              StateNotifierProvider<SavedSakeNotifier, SavedSakeState>.value(
                value: saved,
              ),
              StateNotifierProvider<
                MenuSearchPageNotifier,
                MenuSearchPageState
              >.value(value: menus),
            ],
            child: MaterialApp(
              home: PlaceRegistrationPage(
                store: store,
                pickPlace: (_, __) => picked.future,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('場所を登録').first);
    await tester.pump();
    auth.value = AuthState(user: _User('b'));
    await tester.pump();
    picked.complete(place);
    await tester.pumpAndSettle();
    expect(saved.savedSakes.single.drinkingPlace, isNull);
    expect(find.text('宮寒梅 純米大吟醸'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('小さい画面と文字拡大でも2つの操作が収まる', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final saved = _Saved(),
        menus = _Menus(),
        store = PlaceRegistrationDismissals('guest');
    addTearDown(saved.dispose);
    addTearDown(menus.dispose);
    addTearDown(store.dispose);
    await store.load();
    await pump(
      tester,
      saved,
      menus,
      MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 740),
          textScaler: TextScaler.linear(1.6),
        ),
        child: PlaceRegistrationPage(store: store),
      ),
    );
    expect(find.text('場所を登録'), findsNWidgets(2));
    expect(find.text('覚えていない'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
  testWidgets('実装した一覧とマップヘッダーの確認画像', (tester) async {
    const output = String.fromEnvironment('PLACE_INBOX_UI_OUTPUT');
    if (output.isEmpty) return;
    tester.view.physicalSize = const Size(390, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await (FontLoader('Preview')..addFont(
            File(
              '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
            ).readAsBytes().then(ByteData.sublistView),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    final saved = _Saved(),
        menus = _Menus(),
        store = PlaceRegistrationDismissals('guest');
    await store.load();
    addTearDown(saved.dispose);
    addTearDown(menus.dispose);
    addTearDown(store.dispose);
    final key = GlobalKey();
    Future<void> shot(Widget child, String name) async {
      await pump(
        tester,
        saved,
        menus,
        RepaintBoundary(key: key, child: child),
        font: 'Preview',
      );
      await tester.runAsync(() async {
        final im =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage(pixelRatio: 3);
        final data = await im.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$output/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
        im.dispose();
      });
    }

    await shot(PlaceRegistrationPage(store: store), 'place-inbox');
    tester.view.physicalSize = const Size(390, 112);
    await shot(
      Scaffold(
        appBar: PrimaryAppBar(
          title: '日本酒マップ',
          titleFontSize: 21,
          leading: const PlaceRegistrationAction(),
          actions: [VenueFavoritesAction(onPressed: () {})],
        ),
      ),
      'map-place-badge',
    );
  });
}
