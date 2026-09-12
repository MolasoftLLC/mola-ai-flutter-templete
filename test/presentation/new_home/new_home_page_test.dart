import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/new_home_page.dart';

void main() {
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
