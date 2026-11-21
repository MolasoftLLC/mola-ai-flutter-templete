import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mola_gemini_flutter_template/domain/repository/mola_api_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/user_preference_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';

void main() {
  test('保存済みのおすすめを10件取得し、再選定APIで入れ替える', () async {
    final requests = <http.Request>[];
    final api = ApiClient.create();
    final client = ChopperClient(
      baseUrl: Uri.parse('https://example.com'),
      services: <ChopperService>[api],
      converter: const JsonConverter(),
      errorConverter: const JsonConverter(),
      client: MockClient((request) async {
        requests.add(request);
        return http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, dynamic>{
              'recommendations': <Map<String, dynamic>>[
                <String, dynamic>{'sakeId': 10, 'name': 'テスト酒', 'score': 92},
              ],
            }),
          ),
          200,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }),
    );
    addTearDown(client.dispose);

    final repository = MolaApiRepository(api);
    expect(
      (await repository.fetchHomeSakeRecommendations(limit: 10)).single.sakeId,
      10,
    );
    expect(
      (await repository.refreshHomeSakeRecommendations()).single.name,
      'テスト酒',
    );
    expect(requests[0].url.queryParameters['limit'], '10');
    expect(requests[1].method, 'POST');
    expect(requests[1].url.path, '/sakes/recommendations/refresh');
  });

  test('月次上限では再選定と好み再解析を別APIへ迂回せず通知する', () async {
    final api = ApiClient.create();
    var calls = 0;
    final client = ChopperClient(
      baseUrl: Uri.parse('https://example.com'),
      services: <ChopperService>[api],
      converter: const JsonConverter(),
      errorConverter: const JsonConverter(),
      client: MockClient((request) async {
        calls++;
        return http.Response.bytes(
          utf8.encode(jsonEncode(<String, dynamic>{'error': '月1回までです。'})),
          429,
          headers: <String, String>{
            'content-type': 'application/json; charset=utf-8',
          },
        );
      }),
    );
    addTearDown(client.dispose);

    await expectLater(
      MolaApiRepository(api).refreshHomeSakeRecommendations(),
      throwsA(isA<MonthlyRecommendationLimitException>()),
    );
    await expectLater(
      UserPreferenceRepository(api).analyzeTasteProfile(
        userId: 'user',
        favorites: <Map<String, dynamic>>[
          <String, dynamic>{'name': 'テスト酒'},
        ],
      ),
      throwsA(isA<MonthlyTasteAnalysisLimitException>()),
    );
    expect(calls, 2);
  });
}
