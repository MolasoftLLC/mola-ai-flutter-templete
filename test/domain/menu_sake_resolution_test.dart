import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/common/sake/taste_match.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_sake_resolution.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/preferences/taste_preference_profile.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/sake_label_scan.dart';
import 'package:mola_gemini_flutter_template/domain/repository/saved_sake_sync_repository.dart';

void main() {
  test('複数のDB候補は商品ID・米や製法を含む商品名を分けたまま保持する', () {
    final resolution = MenuSakeResolution.fromJson({
      'inputName': '天吹 雄町',
      'status': 'multiple',
      'candidates': [
        {'sakeId': 1, 'name': '天吹 雄町 生', 'type': '純米吟醸'},
        {'sakeId': 2, 'name': '天吹 雄町 火入れ', 'type': '純米吟醸'},
      ],
    });

    expect(resolution.status, MenuSakeResolutionStatus.multiple);
    expect(resolution.candidates.map((item) => item.sake.sakeId), [1, 2]);
    expect(resolution.candidates.map((item) => item.sake.name), [
      '天吹 雄町 生',
      '天吹 雄町 火入れ',
    ]);
  });

  test('メニューと詳細画面で使う共通6軸計算は同一プロフィールなら100%', () {
    const profile = SakeTasteProfileDetails(
      fruity: .8,
      sweetness: .6,
      acidity: .4,
      umami: .5,
      body: .5,
      kire: .7,
      dryness: .3,
    );
    const preference = TastePreferenceProfile(
      fruity: .8,
      sweetness: .6,
      acidity: .4,
      umami: .5,
      kire: .7,
      spiciness: .3,
    );
    expect(
      calculateSharedSakeTasteMatchPercent(
        profile: profile,
        preference: preference,
      ),
      100,
    );
  });

  test('ユーザー設定または商品プロフィールがなければおすすめ判定を出さない', () {
    expect(
      calculateOptionalSakeTasteMatchPercent(
        profile: null,
        preference: TastePreferenceProfile.sample(),
      ),
      isNull,
    );
    expect(
      calculateOptionalSakeTasteMatchPercent(
        profile: const SakeTasteProfileDetails(
          fruity: .5,
          sweetness: .5,
          acidity: .5,
          umami: .5,
          kire: .5,
          dryness: .5,
        ),
        preference: null,
      ),
      isNull,
    );
  });

  test('履歴は商品ID・一致度・計算基準を保存し、旧履歴も読める', () {
    final current = SavedSake(
      name: '天吹 純米大吟醸',
      sakeId: 58,
      matchPercent: 84,
      recommendationBasis: 'taste_profile_v1',
      isRecommended: true,
      extractedName: '天吹',
    );
    expect(SavedSake.fromJson(current.toJson()).sakeId, 58);
    expect(SavedSake.fromJson(current.toJson()).matchPercent, 84);
    expect(SavedSake.fromJson(current.toJson()).extractedName, '天吹');
    expect(SavedSake.fromJson({'name': '旧履歴'}).recommendationBasis, isNull);
  });

  test('裏ラベルの送信識別子は再試行しても同じ内容なら同一になる', () {
    final encoded = base64Encode(utf8.encode('same-back-label'));
    final first = buildSavedSakeImageUploadIdentity(encoded, imageRole: 'back');
    final retry = buildSavedSakeImageUploadIdentity(encoded, imageRole: 'back');
    expect(retry.clientImageId, first.clientImageId);
    expect(retry.contentHash, first.contentHash);
    expect(first.contentHash, hasLength(64));
  });
}
