import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/sake/flavor_characteristics.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/preferences/taste_preference_profile.dart';
import 'package:mola_gemini_flutter_template/presentation/common/widgets/sake_flavor_characteristics.dart';

void main() {
  const aged = SakeFlavorCharacteristic.agedAroma;
  test('明示された特徴と根拠を残す。分類・保管・銘柄から推測しない', () {
    final evidence = SakeFlavorEvidence.fromProduct(
      tags: ['熟成香'],
      description: 'とろりとした口当たり。長い余韻。',
    );
    expect(evidence.evidence[aged], '熟成香');
    expect(evidence.evidence.length, 3);
    final unknown = SakeFlavorEvidence.fromProduct(
      description: '酔仙。箱入り。常温保存可能。辛口で旨味がある。3年熟成。',
    );
    expect(unknown.evidence, isEmpty);
    expect(unknown.caution(aged.preference), isNull);
  });
  test('否定・抑制・比較・香り以外の甘みは熟成香と断定しない', () {
    for (final text in [
      '熟成香はありません',
      '老香なし',
      'ナッツの香りを抑えた',
      '古酒とは違い熟成香を感じさせない',
      'カラメルのような甘み',
    ]) {
      expect(
        SakeFlavorEvidence.fromProduct(description: text).evidence,
        isEmpty,
        reason: text,
      );
    }
    expect(
      SakeFlavorEvidence.fromProduct(
        description: 'ナッツを思わせる香り。',
      ).evidence.containsKey(aged),
      true,
    );
  });
  test('苦手設定は該当だけを後ろへ移動し同順位を保つ。解除で元順', () {
    final items = ['a', 'unknown', 'b', 'fresh'];
    SakeFlavorEvidence evidence(String item) => SakeFlavorEvidence.fromProduct(
      tags: ['a', 'b'].contains(item) ? ['熟成香'] : [],
    );
    expect(
      prioritizeFlavorPreferences(
        items,
        preferences: aged.preference,
        evidenceFor: evidence,
      ),
      ['unknown', 'fresh', 'a', 'b'],
    );
    expect(
      prioritizeFlavorPreferences(
        items,
        preferences: '甘口',
        evidenceFor: evidence,
      ),
      items,
    );
    expect(evidence('a').caution(aged.preference), contains('苦手な風味'));
    expect(evidence('unknown').conflicts(aged.preference), isEmpty);
  });
  test('苦手設定は六軸を変えず、単独では六軸を生成しない', () {
    final original = TastePreferenceProfile.fromSelections(['甘口'])!;
    expect(
      TastePreferenceProfile.fromSelections(['甘口', aged.preference])!.toJson(),
      original.toJson(),
    );
    expect(TastePreferenceProfile.fromSelections([aged.preference]), isNull);
    expect(TastePreferenceProfile.fromSelections(['甘口', '未知の設定']), isNull);
  });

  testWidgets('苦手を登録・解除でき、不明と該当の根拠を表示する', (tester) async {
    const output = String.fromEnvironment('FLAVOR_PREVIEW');
    const font = String.fromEnvironment('VENUE_FAVORITES_PREVIEW_FONT');
    if (font.isNotEmpty) {
      await tester.runAsync(() async {
        await (FontLoader('FlavorPreview')..addFont(
              File(font).readAsBytes().then((b) => ByteData.sublistView(b)),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = <String>[];
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('preview'),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: font.isEmpty ? null : 'FlavorPreview',
            colorSchemeSeed: const Color(0xFF143861),
          ),
          home: Scaffold(
            backgroundColor: Colors.white,
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'お酒の好み',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SakeFlavorAvoidanceChoices(
                      selected: selected,
                      onChanged: (next) => setState(() => selected = next),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '商品詳細での表示例',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    SakeFlavorCharacteristics(
                      evidence: SakeFlavorEvidence.fromProduct(
                        description: 'ナッツを思わせる香りと長い余韻。',
                      ),
                      preferences: selected.join('、'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text(aged.preference));
    await tester.pumpAndSettle();
    expect(selected, [aged.preference]);
    expect(find.text('苦手な風味の確認'), findsOneWidget);
    expect(find.text('とろり・重厚な口当たり：不明'), findsOneWidget);
    expect(find.text('「ナッツを思わせる香りと長い余韻」'), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (output.isNotEmpty) {
      await tester.runAsync(() async {
        final render = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('preview')),
        );
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(output).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.tap(find.text(aged.preference));
    await tester.pumpAndSettle();
    expect(selected, isEmpty);
    expect(find.text('苦手な風味の確認'), findsNothing);
  });
}
