import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';

void main() {
  group('MapVenue.fromJson', () {
    test('公開許可されたマップ画像URLを読み込む', () {
      final venue = MapVenue.fromJson(const {
        'venueId': 'venue_1',
        'displayName': '日本酒処',
        'latitude': 26.2,
        'longitude': 127.7,
        'sakeCount': 2,
        'recordCount': 4,
        'latestImageUrl': 'https://example.com/latest.jpg',
      });

      expect(venue.latestImageUrl, 'https://example.com/latest.jpg');
    });

    test('移行中のlatestRecord形式にも対応する', () {
      final venue = MapVenue.fromJson(const {
        'venueId': 'venue_1',
        'displayName': '日本酒処',
        'latitude': 26.2,
        'longitude': 127.7,
        'sakeCount': 2,
        'recordCount': 4,
        'latestRecord': {'imageUrl': 'https://example.com/nested.jpg'},
      });

      expect(venue.latestImageUrl, 'https://example.com/nested.jpg');
    });
  });

  group('VenueSake.fromJson', () {
    test('sake_masterのメイン画像を優先する', () {
      final sake = VenueSake.fromJson(const {
        'sakeId': 123,
        'name': 'サンプル純米酒',
        'recordCount': 3,
        'primaryImageUrl': 'https://example.com/master.jpg',
        'imageUrl': 'https://example.com/legacy.jpg',
      });

      expect(sake.primaryImageUrl, 'https://example.com/master.jpg');
      expect(sake.imageUrl, 'https://example.com/master.jpg');
    });

    test('旧imageUrlレスポンスも引き続き読み込む', () {
      final sake = VenueSake.fromJson(const {
        'name': '旧形式のお酒',
        'recordCount': 1,
        'imageUrl': 'https://example.com/legacy.jpg',
      });

      expect(sake.primaryImageUrl, 'https://example.com/legacy.jpg');
    });
  });

  group('SakeMapSearchResult.fromJson', () {
    test('登録店舗数を読み込む', () {
      final sake = SakeMapSearchResult.fromJson(const {
        'sakeId': 123,
        'name': '獺祭',
        'source': 'master',
        'venueCount': 3,
        'type': '純米大吟醸',
        'primaryImageUrl': 'https://example.com/dassai.jpg',
      });

      expect(sake.venueCount, 3);
      expect(sake.type, '純米大吟醸');
      expect(sake.primaryImageUrl, 'https://example.com/dassai.jpg');
    });

    test('AI未検証候補はマスターIDを持たず検索トークンを保持する', () {
      final sake = SakeMapSearchResult.fromJson(const {
        'sakeId': null,
        'searchToken': 'candidate:12',
        'name': '鍋島 純米吟醸',
        'brewery': '富久千代酒造',
        'type': '純米吟醸',
        'source': 'ai_candidate',
        'venueCount': 0,
      });

      expect(sake.sakeId, isNull);
      expect(sake.searchToken, 'candidate:12');
      expect(sake.isMaster, isFalse);
      expect(sake.venueCount, 0);
    });
  });
}
