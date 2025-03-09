import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/logger.dart';
import '../../common/utils/ad_utils.dart';
import '../../common/utils/custom_image_picker.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/mola_api_repository.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../common/widgets/ad_consent_dialog.dart';

part 'main_search_page_notifier.freezed.dart';

enum SearchMode {
  name,
  bottle,
}

@freezed
abstract class MainSearchPageState with _$MainSearchPageState {
  const factory MainSearchPageState({
    @Default(false) bool isLoading,
    @Default(false) bool isAdLoading,
    @Default(false) bool isAnalyzingInBackground,
    @Default(0) int searchButtonClickCount,
    @Default(0) int analyzeButtonClickCount,
    String? sakeName,
    String? hint,
    File? sakeImage,
    String? sakeType,
    Sake? sakeInfo,
    String? errorMessage,
    String? geminiResponse,
    @Default(SearchMode.name) SearchMode searchMode,
  }) = _MainSearchPageState;
}

class MainSearchPageNotifier extends StateNotifier<MainSearchPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  MainSearchPageNotifier({
    required this.context,
  }) : super(const MainSearchPageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();

  MolaApiRepository get molaApiRepository => read<MolaApiRepository>();
  SakeMenuRecognitionRepository get sakeMenuRecognitionRepository =>
      read<SakeMenuRecognitionRepository>();

  @override
  Future<void> initState() async {
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {}
  }

  void setSakeName(String name) {
    state = state.copyWith(sakeName: name);
  }

  void setSakeType(String type) {
    state = state.copyWith(sakeType: type);
  }

  Future<void> searchSake() async {
    final sakeName = state.sakeName;
    if (sakeName == null || sakeName.isEmpty) {
      state = state.copyWith(
        errorMessage: '日本酒名を入力してください',
      );
      return;
    }
    // 初期化
    state = state.copyWith(sakeInfo: null);
    // Increment click count
    final newClickCount = state.searchButtonClickCount + 1;
    state = state.copyWith(
      searchButtonClickCount: newClickCount,
      errorMessage: null,
      sakeInfo: null,
    );

    // Check if we should show an ad (even-numbered clicks)
    if (newClickCount % 2 == 0) {
      // Show consent dialog before ad
      final consent = await AdConsentDialog.show(
        context,
        title: '広告視聴の確認',
        description: '広告を視聴すると、日本酒情報の検索が可能になります。広告の視聴に同意しますか？',
        icon: Icons.wine_bar,
      );

      // Only proceed with ad if user consents
      if (consent == true) {
        // Show ad and perform search in background
        state = state.copyWith(isAdLoading: true);

        // Load rewarded ad
        final rewardedAd = await AdUtils.loadRewardedAd(
          onAdLoaded: (ad) {
            logger.info('リワード広告がロードされました');
          },
          onAdDismissed: () {
            logger.info('リワード広告が閉じられました');
            state = state.copyWith(isAdLoading: false);
          },
          onAdFailedToLoad: (error) {
            logger.shout('リワード広告のロードに失敗しました: ${error.message}');
            state = state.copyWith(isAdLoading: false);
            // Proceed with search if ad fails to load
            _performSearch(sakeName);
          },
          onUserEarnedReward: (reward) {
            logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
          },
        );

        if (rewardedAd != null) {
          // Start search in background
          state = state.copyWith(isAnalyzingInBackground: true);
          final searchFuture = _performSearch(sakeName);

          // Show ad
          await AdUtils.showRewardedAd(
            rewardedAd,
            onUserEarnedReward: (reward) {
              logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
            },
          );

          // Wait for search to complete if it hasn't already
          await searchFuture;
          state = state.copyWith(isAnalyzingInBackground: false);
        } else {
          // Ad failed to load, proceed with search
          state = state.copyWith(isAdLoading: false);
          await _performSearch(sakeName);
        }
      } else {
        // User declined ad, proceed with search without ad
        state = state.copyWith(isLoading: true);
        await _performSearch(sakeName);
      }
    } else {
      // Odd-numbered click, proceed directly to search
      state = state.copyWith(isLoading: true);
      await _performSearch(sakeName);
    }
  }

  // Helper method to perform the actual search
  Future<void> _performSearch(String sakeName) async {
    try {
      final sakeInfo = await sakeMenuRecognitionRepository.getSakeInfo(
        sakeName,
        type: state.sakeType,
      );

      if (sakeInfo == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '日本酒情報が見つかりませんでした',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        sakeInfo: sakeInfo,
      );
    } catch (e) {
      logger.info('日本酒情報の取得に失敗: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '日本酒情報の取得に失敗しました',
      );
    }
  }

  // タイプをタップして検索するためのメソッド
  Future<void> searchByNameAndType({
    required String sakeName,
    required String sakeType,
  }) async {
    // 状態を更新
    state = state.copyWith(
      sakeName: sakeName,
      sakeType: sakeType,
      isLoading: true,
      errorMessage: null,
      sakeInfo: null,
    );

    try {
      final sakeInfo = await sakeMenuRecognitionRepository.getSakeInfo(
        sakeName,
        type: sakeType,
      );

      if (sakeInfo == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '日本酒情報が見つかりませんでした',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        sakeInfo: sakeInfo,
      );
    } catch (e) {
      logger.info('日本酒情報の取得に失敗: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '日本酒情報の取得に失敗しました',
      );
    }
  }

  // 検索モードを切り替える
  void setSearchMode(SearchMode mode) {
    state = state.copyWith(searchMode: mode);
  }

  Future<void> promptWithText() async {
    if (state.sakeName == null) {
      return;
    }
    if (state.isLoading == true) {
      return;
    }
    state = state.copyWith(isLoading: true);
    if (state.sakeName != null) {
      final response = await geminiMolaApiRepository.promptWithText(
        state.sakeName!,
      );
      state = state.copyWith(
        isLoading: false,
        sakeName: null,
      );
      state = state.copyWith(geminiResponse: response);
    }
  }

  void setText(String text) {
    state = state.copyWith(sakeName: text);
  }

  // 画像を選択する
  Future<void> pickImage(ImageSource source) async {
    // Use CustomImagePicker to avoid READ_MEDIA_IMAGES permission
    final imageFile = await CustomImagePicker.pickImage(source: source);

    if (imageFile != null) {
      state = state.copyWith(sakeImage: imageFile);
    }
  }

  // 画像をクリアする
  void clearImage() {
    state = state.copyWith(sakeImage: null);
  }

  // 酒瓶画像を解析する
  Future<void> analyzeSakeBottle() async {
    if (state.sakeImage == null) {
      logger.info('酒瓶解析: 画像がnullです');
      return;
    }

    // Increment click count
    final newClickCount = state.analyzeButtonClickCount + 1;
    state = state.copyWith(
      analyzeButtonClickCount: newClickCount,
      errorMessage: null,
    );

    // Check if we should show an ad (even-numbered clicks)
    if (newClickCount % 2 == 0) {
      // Show consent dialog before ad
      final consent = await AdConsentDialog.show(
        context,
        title: '広告視聴の確認',
        description: '広告を視聴すると、酒瓶の解析が可能になります。広告の視聴に同意しますか？',
        icon: Icons.camera_alt,
      );

      // Only proceed with ad if user consents
      if (consent == true) {
        // Show ad and perform analysis in background
        state = state.copyWith(isAdLoading: true);

        // Load rewarded ad
        final rewardedAd = await AdUtils.loadRewardedAd(
          onAdLoaded: (ad) {
            logger.info('リワード広告がロードされました');
          },
          onAdDismissed: () {
            logger.info('リワード広告が閉じられました');
            state = state.copyWith(isAdLoading: false);
          },
          onAdFailedToLoad: (error) {
            logger.shout('リワード広告のロードに失敗しました: ${error.message}');
            state = state.copyWith(isAdLoading: false);
            // Proceed with analysis if ad fails to load
            _performBottleAnalysis();
          },
          onUserEarnedReward: (reward) {
            logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
          },
        );

        if (rewardedAd != null) {
          // Start analysis in background
          state = state.copyWith(isAnalyzingInBackground: true);
          final analysisFuture = _performBottleAnalysis();

          // Show ad
          await AdUtils.showRewardedAd(
            rewardedAd,
            onUserEarnedReward: (reward) {
              logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
            },
          );

          // Wait for analysis to complete if it hasn't already
          await analysisFuture;
          state = state.copyWith(isAnalyzingInBackground: false);
        } else {
          // Ad failed to load, proceed with analysis
          state = state.copyWith(isAdLoading: false);
          await _performBottleAnalysis();
        }
      } else {
        // User declined ad, proceed with analysis without ad
        state = state.copyWith(isLoading: true);
        await _performBottleAnalysis();
      }
    } else {
      // Odd-numbered click, proceed directly to analysis
      state = state.copyWith(isLoading: true);
      await _performBottleAnalysis();
    }
  }

  // Helper method to perform the actual bottle analysis
  Future<void> _performBottleAnalysis() async {
    try {
      // 初期化
      state = state.copyWith(sakeInfo: null);
      final response = await sakeMenuRecognitionRepository
          .recognizeSakeBottle(state.sakeImage!);

      if (response == null) {
        logger.shout('酒瓶解析: APIレスポンスがnullです');
        state = state.copyWith(
          isLoading: false,
          errorMessage: '酒瓶の認識に失敗しました',
        );
        return;
      }

      if (response.sakeName == null) {
        logger.shout('酒瓶解析: 日本酒名が認識できませんでした');
        state = state.copyWith(
          isLoading: false,
          errorMessage: '酒瓶から日本酒名を認識できませんでした',
        );
        return;
      }

      logger
          .info('酒瓶解析: 認識成功 - 日本酒名=${response.sakeName}, タイプ=${response.type}');

      // 認識された日本酒情報を取得
      logger.info('酒瓶解析: 日本酒情報取得開始');
      final sakeInfo = await sakeMenuRecognitionRepository.getSakeInfo(
        response.sakeName!,
        type: response.type,
      );

      if (sakeInfo == null) {
        logger.shout('酒瓶解析: 日本酒情報が見つかりませんでした');
        state = state.copyWith(
          isLoading: false,
          errorMessage: '日本酒情報が見つかりませんでした',
        );
        return;
      }

      state = state.copyWith(
        sakeInfo: sakeInfo,
      );
      logger.info('酒瓶解析: 日本酒情報取得成功');

      // 結果を更新
      state = state.copyWith(
        isLoading: false,
      );
    } catch (e, stackTrace) {
      logger.shout('酒瓶解析に失敗: $e');
      logger.shout('スタックトレース: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '酒瓶解析に失敗しました: ${e.toString()}',
      );
    }
  }
}
