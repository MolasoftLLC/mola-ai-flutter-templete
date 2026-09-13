import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_menu_recognition_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/api_client/sake_menu_recognition_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('楽天価格とアフィリエイトURLを一組で読み込み、不完全な情報は表示しない', () {
    final offer = SakeShopOffer.fromJson({
      'price': '2096',
      'affiliateUrl': 'https://hb.afl.rakuten.co.jp/hgc/test/?pc=item',
    });
    expect(offer?.price, 2096);
    expect(
      offer?.affiliateUrl,
      'https://hb.afl.rakuten.co.jp/hgc/test/?pc=item',
    );
    expect(
      SakeShopOffer.fromJson({'price': 0, 'affiliateUrl': offer!.affiliateUrl}),
      isNull,
    );
    expect(
      SakeShopOffer.fromJson({
        'price': 2096,
        'affiliateUrl': 'https://item.rakuten.co.jp/shop/item/',
      }),
      isNull,
    );
    expect(SakeShopOffer.fromJson(null), isNull);
  });

  for (final status in [200, 422, 502]) {
    test('候補解決APIの詳細・画像・IDを保持し、失敗を仮データにしない ($status)', () async {
      final api = SakeMenuRecognitionApiClient.create();
      final client = ChopperClient(
        baseUrl: Uri.parse('https://example.com'),
        services: [api],
        converter: const JsonConverter(),
        client: MockClient((request) async {
          expect(request.url.path, '/api/sakes/resolve-candidate');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['searchToken'], 'candidate:39');
          expect(body.containsKey('preferences'), isFalse);
          return http.Response(
            jsonEncode({
              'sake': {
                'sakeId': 390,
                'name': '神蔵 純米大吟醸 白',
                'primaryImageUrl': 'https://example.com/600.jpg',
                'thumbnailImageUrl': 'https://example.com/146.jpg',
                'imagePrice': 3000,
                'tasteProfile': {
                  'fruity': .7,
                  'sweetness': .6,
                  'acidity': .5,
                  'umami': .4,
                  'kire': .6,
                  'dryness': .4,
                },
              },
              'brewery': {'name': '松井酒造'},
              'analysis': {'description': '保存済みの説明'},
            }),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      addTearDown(client.dispose);
      final overview = await SakeMenuRecognitionRepository(
        api,
      ).resolveSakeCandidateOverview('candidate:39');
      if (status != 200) {
        expect(overview, isNull);
        return;
      }
      expect(overview!.sake.sakeId, 390);
      expect(overview.sake.brewery, '松井酒造');
      expect(overview.sake.description, '保存済みの説明');
      expect(overview.sake.primaryImageUrl, 'https://example.com/600.jpg');
      expect(overview.sake.thumbnailImageUrl, 'https://example.com/146.jpg');
      expect(overview.master.imagePrice, 3000);
      expect(overview.master.tasteProfile!.fruity, .7);
    });
  }
}
