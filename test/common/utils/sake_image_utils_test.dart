import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/utils/sake_image_utils.dart';

void main() {
  test('NoImageは実画像候補として扱わない', () {
    expect(isSakePlaceholderImagePath(sakeNoImageUrl), isTrue);
    expect(isSakePlaceholderImagePath('$sakeNoImageUrl?version=2'), isTrue);
    expect(
      isSakePlaceholderImagePath('https://example.com/bottle.jpg'),
      isFalse,
    );
  });

  test('一覧はユーザー写真、実画像、NoImageの順で選ぶ', () {
    expect(
      preferredSakeImagePath(
        personalImagePaths: const ['https://example.com/memory.jpg'],
        thumbnailImageUrl: sakeNoImageUrl,
      ),
      'https://example.com/memory.jpg',
    );
    expect(
      preferredSakeImagePath(
        thumbnailImageUrl: sakeNoImageUrl,
        primaryImageUrl: 'https://example.com/community.jpg',
      ),
      'https://example.com/community.jpg',
    );
    expect(
      preferredSakeImagePath(primaryImageUrl: sakeNoImageUrl),
      sakeNoImageUrl,
    );
  });
}
