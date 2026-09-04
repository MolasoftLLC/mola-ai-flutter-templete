import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

void main() {
  test('DrinkingPlaceのJSONを往復できる', () {
    const place = DrinkingPlace(
      venueId: 'venue_123',
      providerPlaceId: 'ChIJ-test',
      displayName: '日本酒処 テスト',
      formattedAddress: '沖縄県那覇市',
      latitude: 26.2124,
      longitude: 127.6809,
      visibility: PlaceVisibility.public,
    );
    expect(DrinkingPlace.fromJson(place.toJson()), place);
  });

  test('旧place文字列を保持したまま新しい場所を優先できる', () {
    final sake = Sake.fromJson(const {
      'name': 'テスト酒',
      'place': '以前の店名',
      'drinkingPlace': {'displayName': '検証済み店舗', 'visibility': 'private'},
    });
    expect(sake.place, '以前の店名');
    expect(sake.drinkingPlace?.displayName, '検証済み店舗');
  });
}
