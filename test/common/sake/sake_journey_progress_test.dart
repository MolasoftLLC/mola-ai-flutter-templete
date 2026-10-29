import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/sake/personal_sake_record.dart';
import 'package:mola_gemini_flutter_template/common/sake/sake_journey_progress.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_catalog_browse.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/presentation/new_home/widgets/japan_sake_map.dart';

void main() {
  test(
    'uses My Records criteria and excludes bookmarks and automatic scan images',
    () {
      expect(
        hasPersonalSakeRecord(
          const Sake(
            sakeId: 1,
            name: '保存酒',
            description: 'AIの商品説明',
            imagePaths: ['front.jpg'],
          ),
        ),
        isFalse,
      );
      for (final sake in [
        const Sake(impression: '好き'),
        const Sake(place: '自宅'),
        const Sake(userTags: ['辛口']),
        const Sake(personalTasteRatings: {'aroma': 3}),
        const Sake(imagePaths: ['front.jpg', 'additional.jpg']),
      ]) {
        expect(hasPersonalSakeRecord(sake), isTrue);
      }
      expect(
        hasPersonalSakeRecord(
          const Sake(impression: ' ', place: ' ', userTags: [' ']),
        ),
        isFalse,
      );
    },
  );
  test(
    'deduplicates products and canonical aliases and uses catalog origin instead of drinking location',
    () {
      final result = aggregateSakeJourney(
        [
          const Sake(
            sakeId: 1,
            impression: '初回',
            place: '東京',
            prefectureCode: '13',
          ),
          const Sake(sakeId: 1, impression: '2回目'),
          const Sake(sakeId: 100, impression: '統合前のID'),
          const Sake(sakeId: 2, impression: '同じ銘柄の別商品', isBookmarked: false),
          const Sake(sakeId: 3, name: '保存だけ'),
          const Sake(impression: '産地不明', prefectureCode: '13'),
        ],
        [
          const SakeProductOrigin(
            sakeId: 1,
            canonicalSakeId: 1,
            brandId: 11,
            prefectureCode: 15,
          ),
          const SakeProductOrigin(
            sakeId: 100,
            canonicalSakeId: 1,
            brandId: 11,
            prefectureCode: 15,
          ),
          const SakeProductOrigin(
            sakeId: 2,
            canonicalSakeId: 2,
            brandId: 11,
            prefectureCode: 15,
          ),
          const SakeProductOrigin(
            sakeId: 3,
            canonicalSakeId: 3,
            brandId: 12,
            prefectureCode: 1,
          ),
        ],
      );
      expect(result.counts, {15: 2});
      expect(result.brandIdsByPrefecture, {
        15: {11},
      });
      expect(result.productsByPrefecture[15]!.map((sake) => sake.impression), [
        '初回',
        '同じ銘柄の別商品',
      ]);
      expect(result.productsByPrefecture.keys, [15]);
      expect(result.unresolvedRecords, 1);
    },
  );
  test('changes color at 1, 5 and 10 distinct products', () {
    expect(sakeJourneyColor(0), isNot(sakeJourneyColor(1)));
    expect(sakeJourneyColor(1), sakeJourneyColor(4));
    expect(sakeJourneyColor(4), isNot(sakeJourneyColor(5)));
    expect(sakeJourneyColor(5), sakeJourneyColor(9));
    expect(sakeJourneyColor(9), isNot(sakeJourneyColor(10)));
    expect(sakeJourneyColor(10), japanMapOrange);
    expect(sakeJourneyColor(50), japanMapOrange);
  });
  test(
    'record list opens the canonical product without changing the saved record',
    () {
      const original = Sake(sakeId: 100, savedId: 'personal', impression: '記録');
      final result = aggregateSakeJourney(
        [original],
        [
          const SakeProductOrigin(
            sakeId: 100,
            canonicalSakeId: 1,
            brandId: 11,
            prefectureCode: 15,
          ),
        ],
      );
      final product = result.productsByPrefecture[15]!.single;
      expect(product.sakeId, 1);
      expect(product.savedId, 'personal');
      expect(product.impression, '記録');
      expect(original.sakeId, 100);
    },
  );
}
