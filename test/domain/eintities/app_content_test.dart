import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/app_content.dart';

void main() {
  test('app content parses release and promotion placements', () {
    final content = AppContent.fromJson({
      'release': {
        'minimumVersion': '5.1.0',
        'storeUrl': 'https://example.com/store',
        'message': '重要なお知らせ',
        'messageUrl': 'https://example.com/news',
      },
      'startupPromotions': [
        {
          'id': 1,
          'placement': 'startup',
          'title': '起動告知',
          'imageUrl': 'https://example.com/start.png',
          'linkType': 'external',
        },
      ],
      'homeBanners': [
        {
          'id': 2,
          'placement': 'home_banner',
          'title': 'ホーム告知',
          'imageUrl': 'https://example.com/home.png',
          'linkType': 'internal',
          'linkTarget': 'map',
        },
      ],
    });

    expect(content.release.minimumVersion, '5.1.0');
    expect(content.release.message, '重要なお知らせ');
    expect(content.startupPromotions.single.id, 1);
    expect(content.homeBanners.single.linkTarget, 'map');
  });

  test('legacy version response remains compatible', () {
    final release = AppReleaseSetting.fromJson({'version': '4.8.0'});
    expect(release.minimumVersion, '4.8.0');
  });

  test('home recommendation rounds score and keeps product identity', () {
    final recommendation = HomeSakeRecommendation.fromJson({
      'sakeId': 77,
      'name': '純米大吟醸 朝日',
      'brewery': '来福酒造',
      'score': 92.6,
      'imageUrl': 'https://example.com/sake.jpg',
    });
    expect(recommendation.sakeId, 77);
    expect(recommendation.name, '純米大吟醸 朝日');
    expect(recommendation.score, 93);
  });
}
