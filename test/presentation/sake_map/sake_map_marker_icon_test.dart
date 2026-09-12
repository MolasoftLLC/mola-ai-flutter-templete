import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_map/sake_map_marker_icon.dart';

void main() {
  test('地図ピンの件数は99件を超えると99+で表示する', () {
    expect(formatSakeMarkerCount(1), '1');
    expect(formatSakeMarkerCount(99), '99');
    expect(formatSakeMarkerCount(100), '99+');
    expect(formatSakeMarkerCount(999), '99+');
  });
}
