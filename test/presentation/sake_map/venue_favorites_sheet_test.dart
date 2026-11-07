import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/venue_favorites_controller.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/venue_favorites_sheet.dart';
import 'venue_favorites_controller_test.dart' show MemoryStore, venue;

void main() {
  const previewOutput = String.fromEnvironment('VENUE_FAVORITES_PREVIEW');
  const previewFont = String.fromEnvironment('VENUE_FAVORITES_PREVIEW_FONT');
  setUpAll(() async {
    if (previewFont.isNotEmpty) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('VenuePreview')..addFont(
            File(
              previewFont,
            ).readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
          ))
          .load();
    }
  });
  Future<void> screenshot(WidgetTester tester, String name) async {
    if (previewOutput.isEmpty) return;
    final render = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('preview')),
    );
    await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory(previewOutput).create(recursive: true);
      await File(
        '$previewOutput/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('店名と2つの地図動線、星の解除が利用できる', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = MemoryStore()..data[null] = [venue];
    final controller = VenueFavoritesController(store: store);
    MapVenue? focused, opened;
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('preview'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF143861),
            fontFamily: previewFont.isEmpty ? null : 'VenuePreview',
          ),
          home: Scaffold(
            body: VenueFavoritesSheet(
              controller: controller,
              onShowVenue: (v) => focused = v,
              onOpenMaps: (v) => opened = v,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await screenshot(tester, 'saved-venue');
    expect(find.text('日本酒のお店'), findsOneWidget);
    await tester.tap(find.text('日本酒マップで見る'));
    expect(focused?.venueId, 'v1');
    await tester.tap(find.text('Googleマップ'));
    expect(opened?.providerPlaceId, 'google-place');
    await tester.tap(find.byTooltip('お気に入りから外す'));
    await tester.pumpAndSettle();
    expect(find.textContaining('お気に入りのお店はまだありません'), findsOneWidget);
    expect(store.data[null], isEmpty);
    await screenshot(tester, 'empty-list');
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('保存失敗時は星を残しエラーを伝える', (tester) async {
    final store = MemoryStore()
      ..data[null] = [venue]
      ..failSave = true;
    final controller = VenueFavoritesController(store: store);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VenueFavoritesSheet(
            controller: controller,
            onShowVenue: (_) {},
            onOpenMaps: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('お気に入りから外す'));
    await tester.pumpAndSettle();
    expect(find.textContaining('保存できませんでした'), findsOneWidget);
    expect(find.text('日本酒のお店'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
