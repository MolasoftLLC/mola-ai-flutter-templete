import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

void main() {
  test(
    'same brand with different types keeps separate products and scores in history',
    () {
      final junmai = menuRowKey('松の寿', '純米');
      final yamahai = menuRowKey('松の寿', '山廃');
      final result = buildMenuHistorySakes(
        extracted: [(name: '松の寿', type: '純米'), (name: '松の寿', type: '山廃')],
        resolved: [],
        nameMapping: {junmai: '松の寿 純米酒', yamahai: '松の寿 山廃純米'},
        matchPercents: {junmai: 80, yamahai: 50},
        details: {
          junmai: Sake(sakeId: 1, name: '松の寿 純米酒', type: '純米'),
          yamahai: Sake(sakeId: 2, name: '松の寿 山廃純米', type: '山廃純米'),
        },
      );
      expect(result.map((s) => s.sakeId), [1, 2]);
      expect(result.map((s) => s.matchPercent), [80, 50]);
      expect(result.map((s) => s.type), ['純米', '山廃純米']);
      expect(result.map((s) => s.extractedName), ['松の寿', '松の寿']);
    },
  );
}
