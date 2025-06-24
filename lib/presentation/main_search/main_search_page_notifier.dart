import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/logger.dart';
import '../../common/services/ad_counter_service.dart';
import '../../common/utils/ad_utils.dart';
import '../../common/utils/custom_image_picker.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/sake_bottle_image.dart';
import '../../domain/repository/mola_api_repository.dart';
import '../../domain/repository/sake_bottle_image_repository.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../common/widgets/ad_consent_dialog.dart';
import '../../common/utils/snack_bar_utils.dart';

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
  SakeBottleImageRepository get sakeBottleImageRepository =>
      read<SakeBottleImageRepository>();

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

    // Check if we should show an ad using shared counter (3-search cycle)
    final shouldShowAd = await AdCounterService.shouldShowAd();
    if (shouldShowAd) {
      // Show consent dialog before ad
      final consent = await AdConsentDialog.show(
        context,
        title: '広告視聴の確認',
        description: '広告を視聴すると、日本酒情報の検索が可能になります。広告の視聴にご協力ください！',
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
          // 広告を表示し、視聴後に検索を開始
          state = state.copyWith(isAdLoading: true);

          // 広告を表示
          await AdUtils.showRewardedAd(
            rewardedAd,
            onUserEarnedReward: (reward) {
              logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
            },
          );
          
          // 広告視聴後に検索を開始
          state = state.copyWith(isAdLoading: false, isLoading: true);
          await _performSearch(sakeName);
        } else {
          // Ad failed to load, proceed with search
          state = state.copyWith(isAdLoading: false);
          await _performSearch(sakeName);
        }
      } else {
        // User declined ad, cancel search completely
        SnackBarUtils.showWarningSnackBar(
          context,
          message: '検索をキャンセルしました。検索機能向上のため、次回は広告視聴にご協力ください。',
          duration: const Duration(seconds: 4),
        );
        
        // Reset loading state and do not perform search
        // Also revert the click count increment
        state = state.copyWith(
          isLoading: false,
          searchButtonClickCount: newClickCount - 1,
        );
        return;
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
      // Show cropping UI
      final croppedFile =
          await ImageCropperService.cropAndRotateImage(imageFile.path);

      if (croppedFile != null) {
        // Save to gallery
        final galleryPath =
            await ImageCropperService.saveImageToGallery(croppedFile);
        if (galleryPath != null) {
          logger.info('クロップした画像をギャラリーに保存しました: $galleryPath');
        }

        state = state.copyWith(sakeImage: croppedFile);
      }
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

    // Check if we should show an ad using shared counter (3-search cycle)
    final shouldShowAd = await AdCounterService.shouldShowAd();
    if (shouldShowAd) {
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
          // 広告を表示し、視聴後に解析を開始
          state = state.copyWith(isAdLoading: true);

          // 広告を表示
          await AdUtils.showRewardedAd(
            rewardedAd,
            onUserEarnedReward: (reward) {
              logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
            },
          );
          
          // 広告視聴後に解析を開始
          state = state.copyWith(isAdLoading: false, isLoading: true);
          await _performBottleAnalysis();
        } else {
          // Ad failed to load, proceed with analysis
          state = state.copyWith(isAdLoading: false);
          await _performBottleAnalysis();
        }
      } else {
        // User declined ad, cancel analysis completely
        SnackBarUtils.showWarningSnackBar(
          context,
          message: '解析をキャンセルしました。解析精度向上のため、次回は広告視聴にご協力ください。',
          duration: const Duration(seconds: 4),
        );
        
        // Reset loading state and do not perform analysis
        // Also revert the click count increment
        state = state.copyWith(
          isLoading: false,
          analyzeButtonClickCount: newClickCount - 1,
        );
        return;
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

      // Save the bottle image with sake name and type
      try {
        await sakeBottleImageRepository.saveSakeBottleImage(
          state.sakeImage!,
          sakeName: sakeInfo.name,
          type: sakeInfo.type,
        );
        logger.info('酒瓶画像を保存しました: ${sakeInfo.name}');
      } catch (e) {
        // 画像保存に失敗しても解析結果の表示には影響させない
        logger.warning('酒瓶画像の保存に失敗しましたが、解析結果は表示されます: $e');
      }
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
