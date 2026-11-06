import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/domain/repository/auth_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_menu_recognition_repository.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/my_page/my_page_notifier.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/capture_radial_menu.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_comparison/sake_comparison_page.dart';

class PreviewAuth implements AuthRepository {
  @override
  get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PreviewRepository implements SakeMenuRecognitionRepository {
  @override
  SakeMenuRecognitionRepository forkSession() => this;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('comparison sample flow screenshots', (tester) async {
    const output = String.fromEnvironment('COMPARISON_UI_OUTPUT');
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    if (output.isNotEmpty) {
      await tester.runAsync(() async {
        for (final family in ['Preview', 'Ahem', 'Roboto']) {
          final loader = FontLoader(family)
            ..addFont(
              Future.value(
                ByteData.sublistView(
                  await File('/Library/Fonts/Arial Unicode.ttf').readAsBytes(),
                ),
              ),
            );
          await loader.load();
        }
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
    }
    final anchor = GlobalKey();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<AuthRepository>(create: (_) => PreviewAuth()),
          Provider<SakeMenuRecognitionRepository>(
            create: (_) => PreviewRepository(),
          ),
          Provider<MyPageState>(create: (_) => const MyPageState()),
        ],
        child: MaterialApp(
          theme: ThemeData(fontFamily: output.isEmpty ? null : 'Preview'),
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (_, child) =>
              RepaintBoundary(key: const ValueKey('shot'), child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              backgroundColor: const Color(0xFF203961),
              appBar: AppBar(title: const Text('SAKEPEDIA')),
              bottomNavigationBar: SizedBox(
                height: 96,
                child: Center(
                  child: IconButton(
                    key: anchor,
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.orange,
                      size: 38,
                    ),
                    onPressed: () async {
                      final action = await showCaptureRadialMenu(
                        context,
                        anchorKey: anchor,
                      );
                      if (action == CaptureAction.comparison && context.mounted)
                        await Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SakeComparisonPage(),
                          ),
                        );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Future<void> shot(String name) async {
      expect(tester.takeException(), isNull);
      if (output.isEmpty) return;
      await tester.runAsync(() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('shot')),
        );
        final img = await boundary.toImage(pixelRatio: 2);
        final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File(
          '$output/$name.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        img.dispose();
      });
    }

    await tester.tap(find.byKey(anchor));
    await tester.pumpAndSettle();
    await shot('01-menu');
    await tester.tap(find.byKey(const ValueKey('capture-action-comparison')));
    await tester.pumpAndSettle();
    await shot('02-empty');
    await tester.tap(find.text('サンプルで試す'));
    await tester.pumpAndSettle();
    await shot('03-cart');
    expect(find.text('3本'), findsOneWidget);
    await tester.tap(find.text('こだわりで絞り込む'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'フルーティ'));
    await tester.pumpAndSettle();
    await shot('04-preferences');
    await tester.tap(find.text('この条件でおすすめを見る'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await shot('05-recommended');
    expect(find.text('今のおすすめ 1本'), findsOneWidget);
    await tester.tap(find.text('サンプルA 華やか純米吟醸').first);
    await tester.pumpAndSettle();
    await shot('06-detail');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('お酒の操作').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('カートから外す'));
    await tester.pumpAndSettle();
    expect(find.text('2本'), findsOneWidget);
    await shot('07-removed');
    await tester.pumpWidget(const SizedBox());
  });
}
