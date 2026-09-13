import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';

void main() {
  test('英数字一文字のOCRノイズは酒名として扱わない', () {
    expect(isPlausibleRecognizedSakeName('W'), isFalse);
    expect(isPlausibleRecognizedSakeName(' Ｗ '), isFalse);
    expect(isPlausibleRecognizedSakeName('7'), isFalse);
    expect(isPlausibleRecognizedSakeName('作'), isTrue);
    expect(isPlausibleRecognizedSakeName('WAKAZE'), isTrue);
  });

  test('スキャン候補からW単独だけを除外する', () {
    final result = SakeScanResult.fromJson(<String, dynamic>{
      'status': 'candidates',
      'scanSessionId': 'scan_test',
      'candidates': <Map<String, dynamic>>[
        <String, dynamic>{'sakeId': 1, 'name': 'W'},
        <String, dynamic>{'sakeId': 2, 'name': '作'},
        <String, dynamic>{'sakeId': 3, 'name': 'WAKAZE'},
      ],
    });

    expect(result.candidates.map((candidate) => candidate.name), [
      '作',
      'WAKAZE',
    ]);
  });

  test('裏ラベル撮影理由をAPIレスポンスから変換する', () {
    final result = SakeScanResult.fromJson(<String, dynamic>{
      'status': 'need_back_label',
      'scanSessionId': 'scan_test',
      'backLabelReason': 'ocr_unreadable',
      'candidates': const <dynamic>[],
    });

    expect(result.status, SakeScanApiStatus.needBackLabel);
    expect(result.backLabelReason, SakeScanBackLabelReason.ocrUnreadable);
  });

  test('サーバーの酒概要レスポンスをFlutter表示モデルへ変換する', () {
    final overview = SakeOverview.fromJson(<String, dynamic>{
      'sake': <String, dynamic>{
        'sakeId': 1,
        'brandId': 1,
        'name': '東洋美人 限定純米吟醸 醇道一途 雄町',
        'type': '限定純米吟醸',
        'imageUrl': 'https://example.com/toyobijin.jpg',
      },
      'brand': <String, dynamic>{'id': 1, 'name': '東洋美人'},
      'brewery': <String, dynamic>{
        'id': 1,
        'name': '株式会社澄川酒造場',
        'prefectureCode': '35',
      },
      'analysis': <String, dynamic>{'name': 'AI側の商品名', 'taste': '華やかで米の旨味がある'},
      'publicSavedSakeCount': 2,
      'recentPublicPosts': <Map<String, dynamic>>[
        <String, dynamic>{'savedId': 'saved_1'},
      ],
      'relatedProducts': <Map<String, dynamic>>[
        <String, dynamic>{'sakeId': 2, 'name': '別の商品'},
      ],
    });

    expect(overview.analysisCompleted, isTrue);
    expect(overview.sake.sakeId, 1);
    expect(overview.sake.name, '東洋美人 限定純米吟醸 醇道一途 雄町');
    expect(overview.sake.brewery, '株式会社澄川酒造場');
    expect(overview.sake.prefectureCode, '35');
    expect(overview.sake.primaryImageUrl, 'https://example.com/toyobijin.jpg');
    expect(overview.sake.taste, '華やかで米の旨味がある');
    expect(overview.sake.community?['publicSavedSakeCount'], 2);
    expect(overview.sake.sameBrandSakes, hasLength(1));
  });

  test('解析キャッシュがない酒概要は詳細解析が必要になる', () {
    final overview = SakeOverview.fromJson(<String, dynamic>{
      'sake': <String, dynamic>{'sakeId': 1, 'name': '東洋美人'},
      'brand': <String, dynamic>{'id': 1, 'name': '東洋美人'},
      'brewery': <String, dynamic>{'id': 1, 'name': '株式会社澄川酒造場'},
      'analysis': null,
      'publicSavedSakeCount': 0,
      'recentPublicPosts': const <dynamic>[],
      'relatedProducts': const <dynamic>[],
    });

    expect(overview.analysisCompleted, isFalse);
    expect(overview.analysisPayload, isNull);
    expect(overview.sake.name, '東洋美人');
  });
}
