import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:chopper/chopper.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mola_gemini_flutter_template/domain/repository/auth_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/my_page/widgets/app_feedback_dialog.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/japan_sake_page.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/japan_sake_map.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _guestId = '12345678-1234-4123-8123-123456789abc';

class _Auth implements AuthRepository {
  _Auth(this.loggedIn);
  final bool loggedIn;
  @override
  User? get currentUser => loggedIn ? _User() : null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  @override
  String get uid => 'test-account-id';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await JapanSakeMapData.load();
    const font = String.fromEnvironment('JAPAN_UI_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('FeedbackPreview')..addFont(
            Future.value(ByteData.sublistView(await File(font).readAsBytes())),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_feedback_guest_id_v1': _guestId,
    });
    PackageInfo.setMockInitialValues(
      appName: 'SAKEPEDIA',
      packageName: 'test.sakepedia',
      version: '5.0.37',
      buildNumber: '167',
      buildSignature: '',
    );
  });

  Future<void> open(
    WidgetTester tester, {
    required bool loggedIn,
    required Future<http.Response> Function(http.Request) send,
    bool general = false,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = ApiClient.create();
    final client = ChopperClient(
      baseUrl: Uri.parse('https://example.com/api/'),
      services: [api],
      converter: const JsonConverter(),
      errorConverter: const JsonConverter(),
      client: MockClient(
        (request) async => request.url.path.endsWith('app-feedback')
            ? send(request)
            : http.Response(
                '{"brands":[]}',
                200,
                headers: {'content-type': 'application/json'},
              ),
      ),
    );
    addTearDown(client.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ApiClient>.value(value: api),
          Provider<AuthRepository>.value(value: _Auth(loggedIn)),
          Provider<PlaceMapRepository>.value(value: PlaceMapRepository(api)),
        ],
        child: RepaintBoundary(
          key: const ValueKey('feedback-preview'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ja'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: ThemeData(
              fontFamily: const String.fromEnvironment('JAPAN_UI_FONT').isEmpty
                  ? null
                  : 'FeedbackPreview',
            ),
            home: general
                ? Builder(
                    builder: (context) => Scaffold(
                      body: TextButton(
                        onPressed: () => showAppFeedbackDialog(context),
                        child: const Text('フィードバック'),
                      ),
                    ),
                  )
                : const JapanSakePage(initialPrefectureCode: 15),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  http.Response response({int status = 201}) => http.Response(
    jsonEncode(
      status == 201
          ? {'accepted': true}
          : {'error': '送信できませんでした。入力内容はそのままで、もう一度お試しください。'},
    ),
    status,
    headers: {'content-type': 'application/json'},
  );
  Future<void> preview(WidgetTester tester, String name) async {
    const output = String.fromEnvironment('JAPAN_UI_OUTPUT');
    if (output.isEmpty) return;
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('feedback-preview')),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(output).create(recursive: true);
      await File('$output/$name.png').writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
  }

  for (final loggedIn in [false, true]) {
    for (final topic in [
      AppFeedbackTopic.sakeCorrection,
      AppFeedbackTopic.sakeBrandAddition,
    ]) {
      testWidgets(
        '${topic.name} sends the existing ${loggedIn ? 'account' : 'guest'} identity and no prefecture',
        (tester) async {
          final requests = <http.Request>[];
          await open(
            tester,
            loggedIn: loggedIn,
            send: (request) async {
              requests.add(request);
              return response();
            },
          );
          final menu = find.byKey(const ValueKey('japan-sake-feedback-menu'));
          expect(
            find.descendant(of: menu, matching: find.byIcon(Icons.add)),
            findsOneWidget,
          );
          await tester.tap(menu);
          await tester.pumpAndSettle();
          expect(find.text('間違いを教えてあげる'), findsOneWidget);
          expect(find.text('追加の銘柄を教えてあげる'), findsOneWidget);
          expect(requests, isEmpty);
          if (!loggedIn && topic == AppFeedbackTopic.sakeCorrection) {
            await preview(tester, 'menu');
          }
          await tester.tap(find.text(topic.title(false)));
          await tester.pumpAndSettle();
          expect(find.byType(BottomSheet), findsNothing);
          expect(find.text(topic.title(false)), findsOneWidget);
          final identity = loggedIn ? 'test-account-id' : 'guest_$_guestId';
          expect(find.text('ユーザーID: $identity'), findsOneWidget);
          final input = find.byKey(const Key('app-feedback-content'));
          expect(
            tester
                .widget<TextField>(
                  find.descendant(of: input, matching: find.byType(TextField)),
                )
                .maxLength,
            2000 - topic.contentPrefix.length,
          );
          if (!loggedIn && topic == AppFeedbackTopic.sakeCorrection) {
            await tester.enterText(input, '銘柄名と確認した情報です。');
            await tester.pumpAndSettle();
            await preview(tester, 'correction');
            await tester.enterText(input, '');
          }
          await tester.tap(find.byKey(const Key('app-feedback-send')));
          await tester.pumpAndSettle();
          expect(requests, isEmpty);
          await tester.enterText(input, '  銘柄名と確認した情報です。  ');
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('app-feedback-send')));
          await tester.pumpAndSettle();
          expect(requests, hasLength(1));
          expect(requests.single.url.path, '/api/app-feedback');
          final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
          expect(body['userId'], identity);
          expect(body['guestId'], loggedIn ? isNull : _guestId);
          expect(body['content'], '${topic.contentPrefix}銘柄名と確認した情報です。');
          expect(body['version'], '5.0.37+167');
          expect(body.keys.toSet(), {
            'requestId',
            'userId',
            'content',
            'version',
            'platform',
            if (!loggedIn) 'guestId',
          });
          expect(body['content'], isNot(contains('新潟')));
          expect(find.byType(AlertDialog), findsNothing);
          expect(find.text('フィードバックを送信しました。ありがとうございます！'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'failed suggestions keep text and request ID for retry; cancellation does not send',
    (tester) async {
      final bodies = <Map<String, dynamic>>[];
      await open(
        tester,
        loggedIn: false,
        send: (request) async {
          bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          return response(status: bodies.length == 1 ? 503 : 201);
        },
      );
      final menu = find.byKey(const ValueKey('japan-sake-feedback-menu'));
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('キャンセル'));
      await tester.pumpAndSettle();
      expect(bodies, isEmpty);
      await tester.tap(menu);
      await tester.pumpAndSettle();
      await tester.tap(find.text('追加の銘柄を教えてあげる'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('app-feedback-content')),
        '追加してほしい銘柄',
      );
      final send = find.byKey(const Key('app-feedback-send'));
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(find.text('追加してほしい銘柄'), findsOneWidget);
      expect(find.textContaining('送信できませんでした。'), findsOneWidget);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(bodies, hasLength(2));
      expect(bodies[0], bodies[1]);
      expect(find.byType(AlertDialog), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'My Page general feedback keeps its original title and unprefixed content',
    (tester) async {
      final bodies = <Map<String, dynamic>>[];
      await open(
        tester,
        loggedIn: true,
        general: true,
        send: (request) async {
          bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          return response();
        },
      );
      await tester.tap(find.text('フィードバック'));
      await tester.pumpAndSettle();
      expect(find.text('フィードバック'), findsNWidgets(2));
      final input = find.byKey(const Key('app-feedback-content'));
      expect(
        tester
            .widget<TextField>(
              find.descendant(of: input, matching: find.byType(TextField)),
            )
            .maxLength,
        2000,
      );
      await tester.enterText(input, 'アプリの感想');
      await tester.tap(find.byKey(const Key('app-feedback-send')));
      await tester.pumpAndSettle();
      expect(bodies.single['content'], 'アプリの感想');
      expect(tester.takeException(), isNull);
    },
  );
}
