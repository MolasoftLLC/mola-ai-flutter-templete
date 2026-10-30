import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/utils/sake_image_utils.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/presentation/common/widgets/sake_list_card.dart';

void main() {
  for (final url in [null, sakeNoImageUrl, '$sakeNoImageUrl?version=2']) {
    testWidgets('写真なしは端末内の手描き画像を切り取らずに表示する: $url', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SakeListCard(
              sake: Sake(name: '黎明 本醸造', primaryImageUrl: url),
              profileFuture: null,
              preference: null,
              onOpen: () {},
            ),
          ),
        ),
      );
      await tester.runAsync(
        () => precacheImage(
          const AssetImage('assets/images/sake_placeholder.png'),
          tester.element(find.byType(SakeListCard)),
        ),
      );
      await tester.pumpAndSettle();
      final images = tester.widgetList<Image>(find.byType(Image)).toList();
      expect(images, hasLength(1));
      expect(
        (images.single.image as AssetImage).assetName,
        'assets/images/sake_placeholder.png',
      );
      expect(images.single.fit, BoxFit.contain);
      expect(tester.takeException(), isNull);
    });
  }
}
