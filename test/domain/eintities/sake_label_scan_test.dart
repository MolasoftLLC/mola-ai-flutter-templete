import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';

void main() {
  test('旧tasteは読み込まず保存もしない・空のdescriptionは補完しない', () {
    for (final description in [null, '', 'このお酒の説明']) {
      final overview = SakeOverview.fromJson({
        'sake': {'sakeId': 278, 'description': description},
        'analysis': {'taste': '廃止された味の説明'},
      });
      expect(overview.sake.description, description);
      expect(overview.sake.toJson().containsKey('taste'), isFalse);
    }
  });

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

  test('公式サイト由来の未登録候補をsakeId 0でも保持する', () {
    final result = SakeScanResult.fromJson(<String, dynamic>{
      'status': 'candidates',
      'scanSessionId': 'scan_lens',
      'candidates': <Map<String, dynamic>>[
        <String, dynamic>{
          'sakeId': 0,
          'name': '花雪 純米吟醸',
          'brewery': '河津酒造株式会社',
          'candidateSource': 'official_temporary',
          'sourceUrl': 'https://example.jp/products/hanayuki',
        },
        <String, dynamic>{'sakeId': 0, 'name': '根拠なし候補'},
      ],
    });

    expect(result.candidates, hasLength(1));
    expect(result.candidates.single.isOfficialTemporary, isTrue);
    expect(result.candidates.single.name, '花雪 純米吟醸');
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
      'analysis': <String, dynamic>{
        'name': 'AI側の商品名',
        'description': '華やかで米の旨味がある',
      },
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
    expect(overview.sake.description, '華やかで米の旨味がある');
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

  test('みんなの評価と公開ラベル画像を酒概要から変換する', () {
    final overview = SakeOverview.fromJson(<String, dynamic>{
      'sake': <String, dynamic>{'sakeId': 50, 'name': '来福'},
      'community': <String, dynamic>{
        'averageRating': 4.2,
        'reviewCount': 12,
        'averageTasteRatings': <String, dynamic>{'fruity': 3.5},
        'images': <Map<String, dynamic>>[
          <String, dynamic>{
            'imageId': 8,
            'imageUrl': 'https://example.com/user-label.jpg',
            'username': '酒好き',
            'isOwner': true,
            'createdAt': '2026-09-14T00:00:00.000Z',
          },
        ],
        'reviews': <Map<String, dynamic>>[
          <String, dynamic>{
            'reviewId': 9,
            'sakeId': 50,
            'overallRating': 5,
            'tasteRatings': <String, dynamic>{'sweetness': 4},
            'comment': '華やかでおいしい',
            'username': '酒好き',
            'createdAt': '2026-09-14T00:00:00.000Z',
            'updatedAt': '2026-09-14T00:00:00.000Z',
          },
        ],
      },
    });

    expect(overview.community.averageRating, 4.2);
    expect(overview.community.reviewCount, 12);
    expect(overview.community.images.single.imageId, 8);
    expect(overview.community.images.single.isOwner, isTrue);
    expect(overview.community.reviews.single.comment, '華やかでおいしい');
    expect(overview.community.averageTasteRatings['fruity'], 3.5);
  });
}
