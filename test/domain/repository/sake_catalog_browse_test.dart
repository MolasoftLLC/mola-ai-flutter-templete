import 'dart:convert';
import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mola_gemini_flutter_template/domain/repository/place_map_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/api_client.dart';

void main() {
  PlaceMapRepository repository(
    Future<http.Response> Function(http.Request) handler,
  ) {
    final api = ApiClient.create();
    final client = ChopperClient(
      baseUrl: Uri.parse('https://example.com/api/'),
      services: [api],
      converter: const JsonConverter(),
      errorConverter: const JsonConverter(),
      client: MockClient(handler),
    );
    addTearDown(client.dispose);
    return PlaceMapRepository(api);
  }

  http.Response response(Object body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  test(
    'brand and product requests use catalog IDs and directional page cursors',
    () async {
      final requests = <http.Request>[];
      final repo = repository((r) async {
        requests.add(r);
        return response(
          r.url.path.endsWith('brands')
              ? {
                  'brands': [
                    {
                      'brandId': 12,
                      'name': '同名銘柄',
                      'brewery': '蔵B',
                      'productCount': 55,
                      'thumbnailImageUrl': 'https://example.com/photo.jpg',
                    },
                  ],
                  'nextCursor': 12,
                }
              : {
                  'sakes': [
                    {'sakeId': 499, 'name': '商品', 'source': 'master'},
                  ],
                  'nextCursor': 499,
                },
        );
      });
      final brands = await repo.fetchPrefectureBrands(15, afterId: 11);
      expect(brands.items.single.brandId, 12);
      expect(brands.items.single.productCount, 55);
      final products = await repo.fetchBrandProducts(12, beforeId: 500);
      expect(products.items.single.sakeId, 499);
      expect(requests[0].url.path, '/api/sakes/prefectures/15/brands');
      expect(requests[0].url.queryParameters['afterId'], '11');
      expect(requests[1].url.path, '/api/sakes/brands/12/products');
      expect(requests[1].url.queryParameters['beforeId'], '500');
    },
  );

  test(
    'failed or malformed catalog data is not shown as an empty catalog',
    () async {
      final repo = repository(
        (_) async => response({'error': 'offline'}, status: 503),
      );
      await expectLater(
        repo.fetchPrefectureBrands(15),
        throwsA(isA<PlaceMapException>()),
      );
      final malformed = repository(
        (_) async => response({'brands': 'invalid'}),
      );
      await expectLater(
        malformed.fetchPrefectureBrands(15),
        throwsFormatException,
      );
      final backwards = repository(
        (_) async => response({'brands': [], 'nextCursor': 10}),
      );
      await expectLater(
        backwards.fetchPrefectureBrands(15, afterId: 11),
        throwsFormatException,
      );
    },
  );

  test(
    'origin lookup splits over 200 distinct IDs and does not send personal records',
    () async {
      final requests = <http.Request>[];
      final repo = repository((r) async {
        requests.add(r);
        final body = jsonDecode(r.body) as Map<String, dynamic>;
        expect(body.keys, ['sakeIds']);
        final ids = (body['sakeIds'] as List).cast<int>();
        return response({
          'origins': [
            for (final id in ids)
              {
                'sakeId': id,
                'canonicalSakeId': id,
                'brandId': 11,
                'prefectureCode': '15',
              },
          ],
        });
      });
      final rows = await repo.fetchSakeOrigins([
        ...List.generate(201, (i) => i + 1),
        1,
      ]);
      expect(rows.length, 201);
      expect(requests.map((r) => r.url.path).toList(), [
        '/api/sakes/origins',
        '/api/sakes/origins',
      ]);
      expect((jsonDecode(requests[0].body)['sakeIds'] as List).length, 200);
      expect((jsonDecode(requests[1].body)['sakeIds'] as List).length, 1);
      expect(await repo.fetchSakeOrigins([]), isEmpty);
      expect(requests.length, 2);
    },
  );
}
