import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_stamp_repository.dart';

void main() {
  test(
    'fetch follows cursor and binds all pages to the same account',
    () async {
      var requests = 0;
      final repo = SakeStampRepository(
        baseUrl: Uri.parse('https://example.com/api'),
        accountReader: () => 'A',
        tokenReader: (_) async => 'token-A',
        client: MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer token-A');
          expect(r.url.path, '/api/sake-stamps');
          requests++;
          final id = requests == 1 ? 1 : 2;
          if (requests == 2) expect(r.url.queryParameters['after'], '200');
          return http.Response(
            jsonEncode({
              'stamps': [
                {
                  'brandId': id,
                  'sakeId': id,
                  'prefectureCode': 6,
                  'source': 'analyzed_detail',
                  'observedAt': '2026-10-30T00:00:00Z',
                },
              ],
              'nextCursor': requests == 1 ? 200 : null,
            }),
            200,
          );
        }),
      );
      addTearDown(repo.close);
      expect((await repo.fetch('A')).map((s) => s.brandId), [1, 2]);
    },
  );
  test(
    'switch during token refresh prevents sending A stamps with B token',
    () async {
      var uid = 'A';
      var sent = false;
      final repo = SakeStampRepository(
        baseUrl: Uri.parse('https://example.com'),
        accountReader: () => uid,
        tokenReader: (_) async {
          uid = 'B';
          return 'token-B';
        },
        client: MockClient((_) async {
          sent = true;
          return http.Response('{}', 200);
        }),
      );
      addTearDown(repo.close);
      await expectLater(repo.upload('A', []), throwsStateError);
      expect(sent, false);
    },
  );
  test(
    'switch while request is in flight rejects old-account response',
    () async {
      var uid = 'A';
      final gate = Completer<http.Response>();
      final repo = SakeStampRepository(
        baseUrl: Uri.parse('https://example.com'),
        accountReader: () => uid,
        tokenReader: (_) async => 'token-A',
        client: MockClient((_) => gate.future),
      );
      addTearDown(repo.close);
      final response = repo.fetch('A');
      await Future<void>.delayed(Duration.zero);
      uid = 'B';
      gate.complete(http.Response('{"stamps":[],"nextCursor":null}', 200));
      await expectLater(response, throwsStateError);
    },
  );
}
