import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/domain/repository/auth_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_scan_repository.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/my_page/my_page_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_comparison/sake_comparison_page.dart';
import 'dart:ui' as ui;
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_comparison/comparison_item.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_comparison/device_text_reader.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_comparison/live_sake_scanner_page.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_comparison/live_sake_search.dart';
import '../../support/fake_menu_camera.dart';
import '../../support/fake_network_images.dart';

class StreamingCamera extends FakeMenuCamera {
  final frames = StreamController<CameraImageData>.broadcast();
  @override
  bool supportsImageStreaming() => true;
  @override
  Stream<CameraImageData> onStreamedFrameAvailable(
    int cameraId, {
    CameraImageStreamOptions? options,
  }) => frames.stream;
}

class _Auth implements AuthRepository {
  @override
  get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Api implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Profiles implements SakeScanRepository {
  final pending = <int, Completer<Map<int, SakeTasteProfileDetails>>>{};
  @override
  Future<Map<int, SakeTasteProfileDetails>> fetchTasteProfiles(List<int> ids) =>
      (pending[ids.single] = Completer()).future;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'candidate sheet pauses OCR, closes without selection, and adds twice with haptics and cart flights',
    (tester) async {
      const output = String.fromEnvironment('LIVE_SAKE_UI_OUTPUT');
      const photoPath = String.fromEnvironment('LIVE_SAKE_PHOTO');
      final photoBytes = await tester.runAsync(
        () => File(
          photoPath.isEmpty
              ? 'assets/images/sake_catalog_illustration.png'
              : photoPath,
        ).readAsBytes(),
      );
      final images = FakeImageClient(photoBytes!);
      debugNetworkImageHttpClientProvider = () => images;
      addTearDown(() {
        debugNetworkImageHttpClientProvider = null;
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      });
      final original = CameraPlatform.instance;
      final camera = StreamingCamera();
      CameraPlatform.instance = camera;
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      addTearDown(() async {
        CameraPlatform.instance = original;
        debugDefaultTargetPlatformOverride = null;
        await camera.frames.close();
        await camera.close();
      });
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      if (output.isNotEmpty) {
        await tester.runAsync(() async {
          for (final family in ['Preview', 'Roboto', 'Ahem']) {
            final font = FontLoader(family)
              ..addFont(
                Future.value(
                  ByteData.sublistView(
                    await File(
                      '/Library/Fonts/Arial Unicode.ttf',
                    ).readAsBytes(),
                  ),
                ),
              );
            await font.load();
          }
          await (FontLoader('MaterialIcons')
                ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
              .load();
        });
      }
      final haptics = <Object?>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      String reading = '酔鯨\n特別純米酒';
      final methods = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(DeviceTextReader.channel, (call) async {
            methods.add(call.method);
            expect((call.arguments as Map)['rotation'], 0);
            final region = (call.arguments as Map)['region'] as Map;
            expect(region['x'], closeTo(.06, .00001));
            // 390x320.72 viewport center-crops a 1080x1920 portrait frame.
            expect(region['y'], greaterThan(.06));
            expect(region['height'], lessThan(.88));
            return reading;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(DeviceTextReader.channel, null),
      );
      final saved = <ComparisonItem>[];
      final searches = <String>[];
      final model = LiveSakeSearch(
        search: (query) async {
          searches.add(query);
          return [
            SakeMapSearchResult(
              sakeId: query.contains('阿櫻') ? 2 : 1,
              name: query.contains('阿櫻') ? '阿櫻 特別純米' : '酔鯨 特別純米酒',
              isMaster: true,
              thumbnailImageUrl: 'https://example.invalid/missing-thumb.jpg',
              primaryImageUrl: query.contains('阿櫻')
                  ? null
                  : 'https://item-shopping.c.yimg.jp/i/g/fukumasu-ya_19533x001',
            ),
            if (!query.contains('阿櫻')) ...[
              const SakeMapSearchResult(
                sakeId: 3,
                name: '酔鯨 純米吟醸 吟麗',
                type: '純米吟醸',
                brewery: '酔鯨酒造',
                isMaster: true,
              ),
              const SakeMapSearchResult(
                sakeId: 4,
                name: '酔鯨 純米大吟醸 兵庫山田錦50%',
                type: '純米大吟醸',
                brewery: '酔鯨酒造',
                isMaster: true,
              ),
            ],
          ];
        },
        loadProfiles: (_) async => {},
      );
      await tester.pumpWidget(
        RepaintBoundary(
          key: const ValueKey('scanner-shot'),
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(fontFamily: output.isEmpty ? null : 'Preview'),
            home: LiveSakeScannerPage(
              search: model,
              onAdd: (item) async {
                saved.add(item);
                return true;
              },
              initialIds: const {},
              initialCount: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final viewport = tester.getRect(
        find.byKey(const ValueKey('scan-viewport')),
      );
      final guide = tester.getRect(find.byKey(const ValueKey('scan-guide')));
      expect(guide.left, closeTo(viewport.left + viewport.width * .06, .001));
      expect(guide.top, closeTo(viewport.top + viewport.height * .06, .001));
      expect(guide.bottom, lessThan(viewport.bottom));
      expect(camera.audio, [false]);
      expect(camera.flashes, [FlashMode.off]);
      final image = CameraImageData(
        format: const CameraImageFormat(
          ImageFormatGroup.bgra8888,
          raw: 1111970369,
        ),
        planes: [CameraImagePlane(bytes: Uint8List(16), bytesPerRow: 8)],
        width: 2,
        height: 2,
      );
      Future<void> frame() async {
        await tester.runAsync(() async {
          camera.frames.add(image);
          await Future<void>.delayed(const Duration(milliseconds: 480));
        });
        await tester.pumpAndSettle();
      }

      Future<void> shot(String name) async {
        if (output.isEmpty) return;
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('scanner-shot')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File(
            '$output/$name.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
        });
      }

      await frame();
      await frame();
      expect(
        find.byKey(const ValueKey('sake-candidate-sheet')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('recognized-sake-name')))
            .data,
        '酔鯨 特別純米酒',
      );
      expect(haptics, hasLength(1));
      final paused = methods.length;
      reading = '阿櫻 特純';
      await frame();
      await frame();
      expect(methods, hasLength(paused));
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('recognized-sake-name')))
            .data,
        '酔鯨 特別純米酒',
      );
      await tester.tap(find.byKey(const ValueKey('close-sake-candidates')));
      await tester.pump(const Duration(milliseconds: 50));
      camera.frames.add(image);
      await tester.pump();
      expect(methods, hasLength(paused)); // Closing animation is still paused.
      await tester.pumpAndSettle();
      expect(saved, isEmpty);
      expect(find.byKey(const ValueKey('sake-candidate-sheet')), findsNothing);
      reading = '酔鯨\n特別純米酒';
      await frame();
      await frame();
      expect(methods.length, greaterThan(paused));
      expect(find.byKey(const ValueKey('sake-candidate-sheet')), findsNothing);
      // Moving off the label re-arms it; no repeated vibration on the same text.
      reading = '';
      await frame();
      reading = '酔鯨\n特別純米酒';
      await frame();
      await frame();
      expect(
        find.byKey(const ValueKey('sake-candidate-sheet')),
        findsOneWidget,
      );
      expect(haptics, hasLength(2));
      expect(searches, isNotEmpty);
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(
        images.requested.map((u) => u.path),
        containsAllInOrder([
          '/missing-thumb.jpg',
          '/i/g/fukumasu-ya_19533x001',
        ]),
      );
      expect(
        find.byKey(const ValueKey('sake-catalog-illustration')),
        findsNWidgets(2),
      );
      expect(find.byIcon(Icons.liquor), findsNothing);
      await shot('01-candidates');
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byKey(const ValueKey('flying-sake-to-cart')), findsOneWidget);
      await shot('02-cart-flight');
      await tester.pumpAndSettle();
      expect(saved.single.sake.sakeId, 1);
      expect(haptics, hasLength(3));
      expect(find.byKey(const ValueKey('sake-candidate-sheet')), findsNothing);
      expect(find.byType(LiveSakeScannerPage), findsOneWidget);
      expect(find.text('カートを見る（1）'), findsOneWidget);
      expect(camera.disposed, isEmpty);
      await shot('02-added');
      reading = '阿櫻 特純';
      await frame();
      await frame();
      await tester.tap(find.byIcon(Icons.add_circle_outline).first);
      await tester.pumpAndSettle();
      expect(saved.map((item) => item.sake.sakeId), [1, 2]);
      expect(haptics, hasLength(5));
      expect(find.byKey(const ValueKey('sake-candidate-sheet')), findsNothing);
      expect(find.text('カートを見る（2）'), findsOneWidget);
      expect(camera.captures, 0);
      expect(methods, everyElement('recognizeFrame'));
      expect(camera.disposed, isEmpty);
      await shot('03-next-product');
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(camera.disposed, isNotEmpty);
      debugNetworkImageHttpClientProvider = null;
      debugDefaultTargetPlatformOverride = null;
    },
  );
  testWidgets(
    'entry opens scanner and late profiles cannot overwrite the next cart selection',
    (tester) async {
      final original = CameraPlatform.instance;
      final camera = StreamingCamera();
      CameraPlatform.instance = camera;
      addTearDown(() async {
        CameraPlatform.instance = original;
        await camera.frames.close();
        await camera.close();
      });
      SharedPreferences.setMockInitialValues({});
      final profiles = _Profiles();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthRepository>(create: (_) => _Auth()),
            Provider<MyPageState>(create: (_) => const MyPageState()),
            Provider<PlaceMapRepository>(
              create: (_) => PlaceMapRepository(_Api()),
            ),
            Provider<SakeScanRepository>.value(value: profiles),
          ],
          child: const MaterialApp(
            home: SakeComparisonPage(startScanning: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LiveSakeScannerPage), findsOneWidget);
      final scanner = tester.widget<LiveSakeScannerPage>(
        find.byType(LiveSakeScannerPage),
      );
      await scanner.onAdd(
        const ComparisonItem(
          id: 'first',
          sake: Sake(sakeId: 1, name: '七賢'),
          text: '七賢',
        ),
      );
      await scanner.onAdd(
        const ComparisonItem(
          id: 'second',
          sake: Sake(sakeId: 2, name: '阿櫻'),
          text: '阿櫻',
        ),
      );
      profiles.pending[2]!.complete({});
      profiles.pending[1]!.complete({
        1: const SakeTasteProfileDetails(
          fruity: .5,
          sweetness: .5,
          acidity: .5,
          umami: .5,
          kire: .5,
          dryness: .5,
        ),
      });
      await tester.pumpAndSettle();
      final prefs = await SharedPreferences.getInstance();
      final items = prefs
          .getStringList('sake_comparison_demo_v1_guest')!
          .map((row) => jsonDecode(row) as Map<String, dynamic>)
          .toList();
      expect(items.map((item) => item['sakeId']), [1, 2]);
      expect(items.first['profile'], isNotNull);
      expect(camera.captures, 0);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
