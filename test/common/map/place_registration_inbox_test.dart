import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/common/map/place_registration_inbox.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('酒瓶は保存単位、メニューは1枚単位で数え、地図登録済みと写真なしブックマークを除く', () {
    const photo = Sake(savedId: 'b', name: 'お酒', imagePaths: ['b.jpg']);
    const mapped = DrinkingPlace(
      displayName: 'お店',
      latitude: 35,
      longitude: 139,
    );
    final menus = [
      MenuAnalysisHistoryItem(
        id: 'm',
        date: DateTime(2026),
        sakes: [
          SavedSake(name: '酒1'),
          SavedSake(name: '酒2'),
        ],
      ),
      MenuAnalysisHistoryItem(
        id: 'done',
        date: DateTime(2026),
        sakes: [],
        imagePath: 'm.jpg',
        drinkingPlace: mapped,
      ),
    ];
    final items = pendingPlaceRegistrations(
      bottles: [
        photo,
        photo,
        photo.copyWith(savedId: 'mapped', drinkingPlace: mapped),
        photo.copyWith(savedId: 'text-only', place: '昔のお店'),
        const Sake(savedId: 'bookmark', name: '保存した商品'),
      ],
      menus: menus,
    );
    expect(items.map((i) => i.key), ['bottle:b', 'bottle:text-only', 'menu:m']);
    expect(
      pendingPlaceRegistrations(
        bottles: [photo],
        menus: menus,
        dismissed: {'bottle:b', 'menu:m'},
      ),
      isEmpty,
    );
    expect(photo.imagePaths, ['b.jpg']);
    expect(menus.first.sakes.length, 2);
  });
  test('覚えていないと元に戻すが永続化し、ゲスト・別アカウントと混ざらない', () async {
    final a = PlaceRegistrationDismissals('a'),
        b = PlaceRegistrationDismissals('b'),
        guest = PlaceRegistrationDismissals('guest');
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    addTearDown(guest.dispose);
    await Future.wait([a.load(), b.load(), guest.load()]);
    await Future.wait([
      a.setDismissed('bottle:1', true),
      a.setDismissed('menu:2', true),
    ]);
    expect(a.ids, {'bottle:1', 'menu:2'});
    expect(b.ids, isEmpty);
    expect(guest.ids, isEmpty);
    final reload = PlaceRegistrationDismissals('a');
    addTearDown(reload.dispose);
    await reload.load();
    expect(reload.ids, a.ids);
    await reload.setDismissed('bottle:1', false);
    expect(reload.ids, {'menu:2'});
  });
  test('地図表示には有効な座標が必要で、0座標自体は有効', () {
    expect(hasMapPlace(const DrinkingPlace(displayName: '店名だけ')), false);
    expect(
      hasMapPlace(
        const DrinkingPlace(displayName: '不正', latitude: 95, longitude: 139),
      ),
      false,
    );
    expect(
      hasMapPlace(
        const DrinkingPlace(displayName: '原点', latitude: 0, longitude: 0),
      ),
      true,
    );
  });
}
