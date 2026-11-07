import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/venue_favorites_repository.dart';

const venue = MapVenue(
  venueId: 'far-away',
  displayName: '旅先のお店',
  latitude: 43.05,
  longitude: 141.35,
  sakeCount: 5,
  recordCount: 8,
  providerPlaceId: 'google-id',
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('新しいリポジトリでも店名・座標・Google place IDが復元される', () async {
    await VenueFavoritesRepository().save('a', [venue]);
    final loaded = await VenueFavoritesRepository().load('a');
    expect(loaded.single.displayName, venue.displayName);
    expect(loaded.single.latitude, venue.latitude);
    expect(loaded.single.longitude, venue.longitude);
    expect(loaded.single.providerPlaceId, 'google-id');
    expect(await VenueFavoritesRepository().load('b'), isEmpty);
    expect(await VenueFavoritesRepository().load(null), isEmpty);
    await VenueFavoritesRepository().save('a', []);
    expect(await VenueFavoritesRepository().load('a'), isEmpty);
  });
  test('ゲストと文字列guestのユーザーも分離する', () async {
    await VenueFavoritesRepository().save(null, [venue]);
    expect(await VenueFavoritesRepository().load('guest'), isEmpty);
  });
  test('不正な座標・破損行・重複IDでも有効な保存を取り出せる', () async {
    final prefs = await SharedPreferences.getInstance();
    final good = {
      'venueId': 'ok',
      'displayName': 'お店',
      'latitude': 35,
      'longitude': 139,
    };
    await prefs.setString(
      'map.venueFavorites.v1.guest',
      jsonEncode([
        good,
        'broken',
        {...good, 'latitude': 999},
        good,
      ]),
    );
    final loaded = await VenueFavoritesRepository().load(null);
    expect(loaded, hasLength(1));
    expect(loaded.single.venueId, 'ok');
  });
  test('一覧全体が壊れている場合は正常な空一覧と誤認させない', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('map.venueFavorites.v1.guest', '{');
    await expectLater(
      VenueFavoritesRepository().load(null),
      throwsFormatException,
    );
  });
}
