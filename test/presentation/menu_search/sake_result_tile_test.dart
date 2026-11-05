import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_sake_resolution.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/sake_result_tile.dart';

void main() {
  testWidgets('初期選択のマッチ度を表示し、候補を残して選択チェックを切り替える', (tester) async {
    const output = String.fromEnvironment('MENU_UI_OUTPUT');
    if (output.isNotEmpty) {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        final font = FontLoader('Preview')
          ..addFont(
            Future.value(
              ByteData.sublistView(
                await File('/Library/Fonts/Arial Unicode.ttf').readAsBytes(),
              ),
            ),
          );
        await font.load();
        final icons = FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
    }
    late MenuSakeCandidate selected;
    final candidates = [
      const MenuSakeCandidate(
        sake: Sake(sakeId: 1, name: '天吹 雄町 生', type: '純米吟醸'),
      ),
      const MenuSakeCandidate(
        sake: Sake(sakeId: 2, name: '天吹 雄町 火入れ', type: '純米吟醸'),
      ),
    ];
    selected = candidates.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: output.isEmpty ? null : 'Preview'),
        builder: (_, child) =>
            RepaintBoundary(key: const ValueKey('preview'), child: child!),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SingleChildScrollView(
              child: SakeResultTile(
                dark: true,
                sake: const Sake(name: '天吹 雄町'),
                detailedSake: selected.sake,
                hasDetails: true,
                isItemLoading: false,
                hasFailed: false,
                isFavorited: false,
                isSaved: false,
                isLoading: false,
                matchPercent: selected.sake.sakeId == 1 ? 76 : 58,
                isUnverified: false,
                candidates: candidates,
                onCandidateSelected: (candidate) =>
                    setState(() => selected = candidate),
                onOpenDetails: () {},
                onToggleFavorite: () async {},
                onSave: () async => false,
                buildInfoRow: (_, value, _) => Text(value),
                buildTypesRow: (types) => Text(types.join(',')),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    expect(find.textContaining('76'), findsWidgets);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('天吹 雄町 生'), findsNWidgets(2));
    expect(find.text('天吹 雄町 火入れ'), findsOneWidget);
    if (output.isNotEmpty) {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory(output).create(recursive: true);
        await File(
          '$output/menu-candidates.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.ensureVisible(find.text('天吹 雄町 火入れ'));
    await tester.tap(find.text('天吹 雄町 火入れ'));
    await tester.pumpAndSettle();
    expect(selected.sake.sakeId, 2);
    expect(find.textContaining('58'), findsWidgets);
    expect(find.text('天吹 雄町 生'), findsOneWidget);
    expect(find.text('天吹 雄町 火入れ'), findsNWidgets(2));
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.radio_button_unchecked), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
