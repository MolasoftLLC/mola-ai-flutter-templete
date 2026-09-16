import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/new_home_page.dart';

void main() {
  test('同じお酒のマッチ度詳細は画面外へ出ても再取得しない', () async {
    final cache = SakeMatchOverviewCache();
    var calls = 0;
    Future<SakeOverview> load(int id) async {
      calls++;
      return SakeOverview(sake: Sake(sakeId: id), analysisCompleted: true);
    }

    final first = cache.fetch(123, load);
    final second = cache.fetch(123, load);
    expect(identical(first, second), isTrue);
    expect((await second).sake.sakeId, 123);
    expect(calls, 1);
    cache.clear();
    await cache.fetch(123, load);
    expect(calls, 2);
  });

  group('preferredSakeCardImagePath', () {
    test('ユーザー写真を最優先する', () {
      const sake = Sake(
        imagePaths: ['/local/user-photo.jpg'],
        thumbnailImageUrl: 'https://example.com/thumbnail.jpg',
        primaryImageUrl: 'https://example.com/primary.jpg',
      );

      expect(preferredSakeCardImagePath(sake), '/local/user-photo.jpg');
    });

    test('ユーザー写真がなければサムネイルを使う', () {
      const sake = Sake(
        thumbnailImageUrl: 'https://example.com/thumbnail.jpg',
        primaryImageUrl: 'https://example.com/primary.jpg',
      );

      expect(
        preferredSakeCardImagePath(sake),
        'https://example.com/thumbnail.jpg',
      );
    });

    test('サムネイルがなければ詳細画像へフォールバックする', () {
      const sake = Sake(primaryImageUrl: 'https://example.com/primary.jpg');

      expect(
        preferredSakeCardImagePath(sake),
        'https://example.com/primary.jpg',
      );
    });
  });
}
