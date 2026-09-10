import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_scan_repository.dart';

void main() {
  test('同一起動中は同じ日本酒の詳細閲覧を一度だけ数える', () {
    final memory = SakeDetailViewMemory();

    expect(memory.markViewed(26), isTrue);
    expect(memory.markViewed(26), isFalse);
    expect(memory.markViewed(27), isTrue);
  });

  test('新しいメモリなら同じ日本酒を再度数えられる', () {
    final firstLaunch = SakeDetailViewMemory();
    final nextLaunch = SakeDetailViewMemory();

    expect(firstLaunch.markViewed(26), isTrue);
    expect(nextLaunch.markViewed(26), isTrue);
  });
}
