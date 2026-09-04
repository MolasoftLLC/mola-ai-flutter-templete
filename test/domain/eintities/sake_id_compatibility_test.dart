import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

void main() {
  group('Sake sakeId JSON互換性', () {
    test('sakeIdがない既存保存データを読み込める', () {
      final sake = Sake.fromJson(<String, dynamic>{
        'name': '既存酒',
        'type': '純米酒',
      });

      expect(sake.name, '既存酒');
      expect(sake.sakeId, isNull);
    });

    test('sakeIdをJSONへ保持して保存酒同期用データに含める', () {
      const sake = Sake(sakeId: 101, name: '獺祭');

      final json = sake.toJson();

      expect(json['sakeId'], 101);
      expect(Sake.fromJson(json).sakeId, 101);
    });
  });
}
