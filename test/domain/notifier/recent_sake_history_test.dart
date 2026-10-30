import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/recent_sake_history.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

void main() {
  test('reopening a product shows one existing record with its place', () {
    final history = RecentSakeHistory();
    final saved = [
      const Sake(sakeId: 1297, savedId: 'saved_200_1', name: '花邑'),
      const Sake(
        sakeId: 1297,
        savedId: 'saved_100_1',
        name: '花邑',
        place: '記録したお店',
        impression: '感想',
      ),
      const Sake(sakeId: 172, savedId: 'saved_300_1', name: '花邑 雄町'),
    ];
    history.record(const Sake(sakeId: 1297, name: '花邑'));
    final result = history.merge(saved);
    expect(result, hasLength(2));
    expect(result.first.savedId, 'saved_100_1');
    expect(result.first.place, '記録したお店');
    expect(result.first.impression, '感想');
    expect(saved, hasLength(3));
    expect(history.merge(saved), hasLength(2));
  });

  test('unlinked records and different products are not merged by name', () {
    final history = RecentSakeHistory();
    final result = history.merge([
      const Sake(name: '花邑', savedId: 'saved_100_1'),
      const Sake(name: '花邑', savedId: 'saved_200_1'),
      const Sake(name: '花邑', sakeId: 1),
      const Sake(name: '花邑', sakeId: 2),
    ]);
    expect(result, hasLength(4));
  });
}
