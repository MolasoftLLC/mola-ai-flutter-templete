import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// The platform store simulates a real persistence failure.
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/saved_sake/saved_sake_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/repository/auth_repository.dart';

class _Guest implements AuthRepository {
  @override
  get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailedStore extends InMemorySharedPreferencesStore {
  _FailedStore() : super.empty();
  @override
  Future<bool> setValue(String type, String key, Object value) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loggerConfigure);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  const place = DrinkingPlace(displayName: 'お店', latitude: 35, longitude: 139);
  Future<SavedSakeNotifier> ready() async {
    final n = SavedSakeNotifier()..read = (<T>() => _Guest() as T);
    addTearDown(n.dispose);
    await Future<void>.delayed(Duration.zero);
    await n.addSavedSake(
      const Sake(
        savedId: 'test-bottle',
        name: '酒',
        impression: '感想',
        imagePaths: ['photo.jpg'],
        isPublic: false,
      ),
    );
    return n;
  }

  test('場所だけを永続保存し、写真・感想・公開状態を保全する', () async {
    final n = await ready();
    await n.setSavedSakePlace('test-bottle', place);
    final record = n.savedSakes.single;
    expect(record.drinkingPlace, place);
    expect(record.impression, '感想');
    expect(record.imagePaths, ['photo.jpg']);
    expect(record.isPublic, false);
    final persisted =
        jsonDecode(
              (await SharedPreferences.getInstance())
                  .getStringList('savedSakeList')!
                  .single,
            )
            as Map;
    expect(persisted['drinkingPlace']['displayName'], 'お店');
  });
  test('端末保存失敗時に一覧が消えるような状態更新をしない', () async {
    final n = await ready();
    final old = n.savedSakes.single;
    final previous = SharedPreferencesStorePlatform.instance;
    addTearDown(() => SharedPreferencesStorePlatform.instance = previous);
    SharedPreferencesStorePlatform.instance = _FailedStore();
    await expectLater(
      n.setSavedSakePlace('test-bottle', place),
      throwsStateError,
    );
    expect(n.savedSakes.single, old);
  });
}
