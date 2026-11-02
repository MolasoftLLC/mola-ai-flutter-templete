import 'dart:convert';
import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/preferences/taste_preference_profile.dart';
import 'package:mola_gemini_flutter_template/domain/repository/user_preference_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';

void main() {
  setUpAll(loggerConfigure);
  test('空・不完全な返答は未設定、明示的な0は有効', () {
    expect(TastePreferenceProfile.tryFromJson({}), isNull);
    expect(TastePreferenceProfile.tryFromJson({'fruity': .5}), isNull);
    final zero = {
      for (final k in TastePreferenceProfile.sample().toJson().keys) k: 0,
    };
    expect(TastePreferenceProfile.tryFromJson(zero)!.sweetness, 0);
  });
  test('全選択肢から中間値を基準に初期値を生成し、相反する選択を平均する', () {
    for (final choice in ['甘口', '辛口', 'スッキリ', 'フルーティ', 'にごり', '微発泡', '酸味']) {
      final p = TastePreferenceProfile.fromSelections([choice])!;
      expect(p.toJson().values.every((v) => v >= 0 && v <= 1), isTrue);
      expect(p.toJson().values.any((v) => v != .5), isTrue);
    }
    expect(TastePreferenceProfile.fromSelections(['甘口'])!.acidity, .5);
    expect(TastePreferenceProfile.fromSelections(['甘口', '辛口'])!.sweetness, .5);
    expect(TastePreferenceProfile.fromSelections([]), isNull);
    expect(TastePreferenceProfile.fromSelections(['未知の自由文']), isNull);
  });
  for (final existing in [false, true]) {
    test('初期選択の保存: 既存プロフィール=$existing', () async {
      final api = ApiClient.create();
      final requests = <http.Request>[];
      final initial = TastePreferenceProfile.fromSelections(['甘口', 'フルーティ'])!;
      final prior = TastePreferenceProfile.sample();
      final client = ChopperClient(
        baseUrl: Uri.parse('https://example.com'),
        services: [api],
        converter: const JsonConverter(),
        client: MockClient((r) async {
          requests.add(r);
          return http.Response(
            jsonEncode(
              r.method == 'PUT'
                  ? jsonDecode(r.body)['profile']
                  : existing
                  ? prior.toJson()
                  : {},
            ),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final repo = UserPreferenceRepository(api);
      final result = await repo.fetchTasteProfile(
        'user',
        initialProfile: initial,
      );
      expect(result!.toJson(), existing ? prior.toJson() : initial.toJson());
      expect(requests.where((r) => r.method == 'PUT').length, existing ? 0 : 1);
    });
  }
  test('未設定の取得だけでは0プロフィールを生成・保存しない', () async {
    final api = ApiClient.create();
    final client = ChopperClient(
      baseUrl: Uri.parse('https://example.com'),
      services: [api],
      converter: const JsonConverter(),
      client: MockClient((r) async {
        expect(r.method, 'GET');
        return http.Response(
          '{}',
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    expect(
      await UserPreferenceRepository(api).fetchTasteProfile('user'),
      isNull,
    );
  });
}
