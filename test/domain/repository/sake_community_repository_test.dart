import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_community_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/sake_menu_recognition_api_client.dart';

void main() {
  test('同意確認と公開評価を認証付きAPIの契約どおり送る', () async {
    final requests = <http.Request>[];
    final api = SakeMenuRecognitionApiClient.create();
    final client = ChopperClient(
      baseUrl: Uri.parse('https://example.com'),
      services: <ChopperService>[api],
      converter: const JsonConverter(),
      client: MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/sakes/label-consent' &&
            request.method == 'GET') {
          return http.Response(
            jsonEncode(<String, dynamic>{'agreed': true}),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response(
          jsonEncode(<String, dynamic>{'review': <String, dynamic>{}}),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final repository = SakeCommunityApiRepository(api);

    expect(await repository.hasAcceptedLabelConsent(), isTrue);
    await repository.saveReview(
      sakeId: 50,
      overallRating: 4,
      tasteRatings: const <String, int>{'fruity': 5, 'sweetness': 3},
      comment: '華やか',
    );

    expect(requests[0].url.path, '/api/sakes/label-consent');
    expect(requests[1].method, 'PUT');
    expect(requests[1].url.path, '/api/sakes/50/review');
    expect(jsonDecode(requests[1].body), <String, dynamic>{
      'overallRating': 4,
      'tasteRatings': <String, dynamic>{'fruity': 5, 'sweetness': 3},
      'comment': '華やか',
    });
  });
}
