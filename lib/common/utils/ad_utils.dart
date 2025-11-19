import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// AdMob広告の管理を行うユーティリティクラス
class AdUtils {
  static bool _initialized = false;

  /// AdMobの初期化
  static Future<void> initialize() async {
    if (_initialized) return;

    print('Initializing AdMob...');
    await MobileAds.instance.initialize();
    print('AdMob initialization complete');
    _initialized = true;
  }

  /// リワード広告をロードする
  ///
  /// [onAdLoaded] 広告がロードされた時に呼ばれるコールバック
  /// [onAdDismissed] 広告が閉じられた時に呼ばれるコールバック
  /// [onAdFailedToLoad] 広告のロードに失敗した時に呼ばれるコールバック
  /// [onUserEarnedReward] ユーザーが報酬を獲得した時に呼ばれるコールバック
  static Future<RewardedAd?> loadRewardedAd({
    required Function(RewardedAd ad) onAdLoaded,
    required Function() onAdDismissed,
    required Function(LoadAdError error) onAdFailedToLoad,
    required Function(RewardItem reward) onUserEarnedReward,
  }) async {
    // プラットフォーム別の広告ユニットID
    final String adUnitId;
    const bool isDebug = kDebugMode;

    if (isDebug) {
      // Use Google test ad units in debug mode
      if (Platform.isAndroid) {
        adUnitId = 'ca-app-pub-3940256099942544/5224354917'; // Android test ID
      } else if (Platform.isIOS) {
        adUnitId = 'ca-app-pub-3940256099942544/1712485313'; // iOS test ID
      } else {
        adUnitId = 'ca-app-pub-3940256099942544/5224354917'; // General test ID
      }
    } else {
      // Use real ad units in production
      if (Platform.isAndroid) {
        adUnitId = 'ca-app-pub-1815956042591114/4683295121'; // Android用
      } else if (Platform.isIOS) {
        adUnitId = 'ca-app-pub-1815956042591114/2538082740'; // iOS用
      } else {
        adUnitId =
            'ca-app-pub-3940256099942544/5224354917'; // その他のプラットフォーム用テストID
      }
    }
    print(
        'Loading rewarded ad with ID: $adUnitId on ${Platform.isIOS ? "iOS" : "Android"}');

    final completer = Completer<RewardedAd?>();

    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          print(
              'Rewarded ad loaded successfully on ${Platform.isIOS ? "iOS" : "Android"}');
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              print('Ad dismissed');
              onAdDismissed();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              print('Ad failed to show: ${error.message}');
              ad.dispose();
            },
            onAdShowedFullScreenContent: (ad) {
              print('Ad showed fullscreen content');
            },
          );
          onAdLoaded(ad);
          completer.complete(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Ad failed to load: ${error.code} - ${error.message}');
          print(
              'Error details: domain=${error.domain}, responseInfo=${error.responseInfo}');
          onAdFailedToLoad(error);
          completer.complete(null);
        },
      ),
    );

    return completer.future;
  }

  /// リワード広告を表示する
  static Future<bool> showRewardedAd(
    RewardedAd ad, {
    required Function(RewardItem reward) onUserEarnedReward,
  }) async {
    final completer = Completer<bool>();

    print('Showing rewarded ad...');
    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward(reward);
        completer.complete(true);
      },
    );

    return completer.future;
  }
}
