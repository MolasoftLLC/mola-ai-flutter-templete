import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/domain/repository/saved_sake_sync_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    loggerConfigure();
    SharedPreferences.setMockInitialValues({});
  });

  test('変更不可のネストMapを含む編集済み記録を同期できる', () async {
    Map<String, dynamic>? sentSake;
    final api = ApiClient.create();
    final client = ChopperClient(
      baseUrl: Uri.parse('https://example.com'),
      services: [api],
      converter: const JsonConverter(),
      client: MockClient((request) async {
        expect(request.url.path, '/saved-sakes/analysis-start');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        sentSake = body['sake'] as Map<String, dynamic>;
        return http.Response('', 200);
      }),
    );
    addTearDown(client.dispose);

    final sake = Sake.fromJson({
      'savedId': 'saved_test',
      'name': '冩樂 純米吟醸 播州山田錦',
      'personalTasteRatings': {'sweetness': 4, 'acidity': 3},
      'community': {'envyCount': 0, 'emptyValue': null},
    });

    final result = await SavedSakeSyncRepository(api).syncSavedSake(
      stage: SavedSakeSyncStage.analysisStart,
      userId: 'test-user',
      sake: sake,
    );

    expect(result, isTrue);
    expect(sentSake?['personalTasteRatings'], {'sweetness': 4, 'acidity': 3});
    expect(sentSake?['community'], {'envyCount': 0});
  });
}
