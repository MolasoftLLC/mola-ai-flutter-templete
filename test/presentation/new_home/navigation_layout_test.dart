import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/sake_bottom_navigation.dart';

void main() {
  setUpAll(() async {
    const font = String.fromEnvironment('JAPAN_UI_FONT');
    if (font.isNotEmpty) {
      await (FontLoader('Preview')..addFont(
            Future.value(ByteData.sublistView(await File(font).readAsBytes())),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('requested navigation order stays usable at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var selected = -1;
      var scans = 0;
      final scanKey = GlobalKey();
      final previewKey = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          locale: const Locale('ja'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: ThemeData(
            fontFamily: const String.fromEnvironment('JAPAN_UI_FONT').isEmpty
                ? null
                : 'Preview',
          ),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 844),
              padding: const EdgeInsets.only(bottom: 34),
              textScaler: TextScaler.linear(width == 320 ? 1.3 : 1),
            ),
            child: RepaintBoundary(
              key: previewKey,
              child: Scaffold(
                body: const SizedBox.expand(),
                bottomNavigationBar: SakeBottomNavigation(
                  currentPageIndex: 2,
                  onPageSelected: (index) => selected = index,
                  onScanTap: () => scans++,
                  scanKey: scanKey,
                  menuAnalysisKey: GlobalKey(),
                  mapKey: GlobalKey(),
                  myPageKey: GlobalKey(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('探す'), findsNothing);
      final labels = ['ホーム', '朱印帳', '解析', 'マップ', 'マイページ'];
      for (var i = 1; i < labels.length; i++) {
        expect(
          tester.getCenter(find.text(labels[i])).dx,
          greaterThan(tester.getCenter(find.text(labels[i - 1])).dx),
        );
      }
      for (final entry in {'ホーム': 0, '朱印帳': 6, 'マップ': 2, 'マイページ': 4}.entries) {
        await tester.tap(
          find.descendant(
            of: find.byType(SakeBottomNavigation),
            matching: find.text(entry.key),
          ),
        );
        expect(selected, entry.value);
      }
      await tester.tap(find.byKey(scanKey));
      expect(scans, 1);
      final barRect = tester.getRect(find.byType(SakeBottomNavigation));
      final cameraRect = tester.getRect(find.byKey(scanKey));
      expect(cameraRect.top, greaterThanOrEqualTo(barRect.top));
      expect(cameraRect.bottom, lessThan(barRect.bottom - 34));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      const directory = String.fromEnvironment('NAV_PREVIEW_DIR');
      if (directory.isNotEmpty) {
        await tester.runAsync(() async {
          final image =
              await (previewKey.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(directory).create(recursive: true);
          await File(
            '$directory/explore-${width.toInt()}.png',
          ).writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
