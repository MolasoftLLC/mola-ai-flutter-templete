import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/logger.dart';
import '../../common/services/ad_counter_service.dart';
import '../../common/utils/ad_utils.dart';
import '../../common/utils/custom_image_picker.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/gemini_mola_api_repository.dart';
import '../../domain/repository/mola_api_repository.dart';
import '../../domain/repository/sake_bottle_image_repository.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../../domain/repository/saved_sake_sync_repository.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../common/widgets/ad_consent_dialog.dart';
import '../common/widgets/guest_limit_dialog.dart';
import '../../common/utils/snack_bar_utils.dart';
import '../common/dialogs/sake_preferences_dialog.dart';

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
    @Default(SearchMode.bottle) SearchMode searchMode,
    @Default([]) List<String> pendingSavedSakeIds,
    String? analyzingImagePath,
    @Default(true) bool shareToTimeline,
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
  SavedSakeSyncRepository get savedSakeSyncRepository =>
      read<SavedSakeSyncRepository>();
  AuthRepository get authRepository => read<AuthRepository>();

  final Map<String, bool> _savedIdPublicFlags = <String, bool>{};
  static const String _timelineSharePreferenceKey =
      'timeline_share_checkbox_preference';

  @override
  Future<void> initState() async {
    super.initState();
    unawaited(_restoreTimelineSharePreference());
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

  Future<void> onTimelineShareToggle(bool newValue) async {
    if (newValue) {
      state = state.copyWith(shareToTimeline: true);
      await _persistTimelineSharePreference(true);
      return;
    }

    final shouldDisable = await _showTimelineOptOutDialog();
    final updatedValue = !shouldDisable;
    state = state.copyWith(shareToTimeline: updatedValue);
    await _persistTimelineSharePreference(updatedValue);
  }

  Future<void> _restoreTimelineSharePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getBool(_timelineSharePreferenceKey);
      final effectiveValue = storedValue ?? true;

      if (storedValue == null) {
        await prefs.setBool(_timelineSharePreferenceKey, true);
      }

      if (state.shareToTimeline != effectiveValue) {
        state = state.copyWith(shareToTimeline: effectiveValue);
      }
    } catch (error, stackTrace) {
      logger.warning('タイムライン共有設定の復元に失敗しました: $error');
      logger.info(stackTrace.toString());
    }
  }

  Future<void> _persistTimelineSharePreference(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_timelineSharePreferenceKey, value);
    } catch (error, stackTrace) {
      logger.warning('タイムライン共有設定の保存に失敗しました: $error');
      logger.info(stackTrace.toString());
    }
  }

  Future<bool> _showTimelineOptOutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('タイムラインへの掲載について'),
          content: const Text(
            'タイムラインで表示されるのは日本酒情報と1枚目の写真だけです。'
            'あなたの感想やメモなどは表示されません。ぜひみんなが日本酒を知る機会にご協力ください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('このまま解析'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('チェックを外す'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> saveAndAnalyzeBottle() async {
    final image = state.sakeImage;
    if (image == null) {
      logger.info('保存して解析: 画像がnullです');
      return false;
    }

    if (!await _ensureSakePreferencesReady()) {
      return false;
    }

    final savedPath =
        await ImageCropperService.saveImagePermanently(image, 'saved_sake');
    if (savedPath == null) {
      SnackBarUtils.showWarningSnackBar(
        context,
        message: '画像の保存に失敗しました',
      );
      return false;
    }

    final savedNotifier = read<SavedSakeNotifier>();
    if (savedNotifier.hasReachedGuestLimit) {
      await GuestLimitDialog.showSavedSakeLimit(
        context,
        maxCount: SavedSakeNotifier.guestSavedLimit,
      );
      return false;
    }
    if (savedNotifier.hasReachedMemberLimit) {
      SnackBarUtils.showWarningSnackBar(
        context,
        message:
            '保存酒は${SavedSakeNotifier.memberSavedLimit}件まで保存できます。不要な保存酒を削除してください。',
      );
      return false;
    }
    final shouldShareTimeline = state.shareToTimeline;

    final placeholder = Sake(
      savedId: null,
      name: '解析中',
      imagePaths: [savedPath],
      isPublic: shouldShareTimeline,
    );
    String savedId;
    try {
      savedId = await savedNotifier.addSavedSake(placeholder);
    } on SavedSakeGuestLimitReachedException {
      await GuestLimitDialog.showSavedSakeLimit(
        context,
        maxCount: SavedSakeNotifier.guestSavedLimit,
      );
      return false;
    } on SavedSakeMemberLimitReachedException {
      SnackBarUtils.showWarningSnackBar(
        context,
        message:
            '保存酒は${SavedSakeNotifier.memberSavedLimit}件まで保存できます。不要な保存酒を削除してください。',
      );
      return false;
    }

    final placeholderWithId = placeholder.copyWith(savedId: savedId);
    _savedIdPublicFlags[savedId] = shouldShareTimeline;
    unawaited(
      _syncSavedSake(
        stage: SavedSakeSyncStage.analysisStart,
        sake: placeholderWithId,
        imageFile: File(savedPath),
        isPublic: shouldShareTimeline,
      ),
    );

    SnackBarUtils.showInfoSnackBar(
      context,
      message: 'マイページに保存しました！',
    );

    // 保存後は選択画像をクリア
    state = state.copyWith(
      sakeImage: null,
      analyzingImagePath: savedPath,
      pendingSavedSakeIds: [...state.pendingSavedSakeIds, savedId],
      isAnalyzingInBackground: true,
      isLoading: true,
    );

    unawaited(analyzeSakeBottle(inBackground: true, savedIdHint: savedId));
    return true;
  }

  // 酒瓶画像を解析する
  Future<void> analyzeSakeBottle(
      {bool inBackground = false, String? savedIdHint}) async {
    File? analysisFile = state.sakeImage;
    if (analysisFile == null && state.analyzingImagePath != null) {
      final fileFromPath = File(state.analyzingImagePath!);
      if (fileFromPath.existsSync()) {
        analysisFile = fileFromPath;
      }
    }

    if (analysisFile == null || !analysisFile.existsSync()) {
      logger.info('酒瓶解析: 画像がnullです');
      if (savedIdHint != null) {
        _handleAnalysisFailure(savedIdHint, '解析に使用する画像が見つかりませんでした');
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: '解析に使用する画像が見つかりませんでした',
        isAnalyzingInBackground: false,
      );
      return;
    }

    if (!await _ensureSakePreferencesReady()) {
      state = state.copyWith(
        isLoading: false,
        isAnalyzingInBackground: false,
      );
      return;
    }

    // Increment click count
    final newClickCount = state.analyzeButtonClickCount + 1;
    state = state.copyWith(
      analyzeButtonClickCount: newClickCount,
      errorMessage: null,
      isAnalyzingInBackground:
          inBackground ? true : state.isAnalyzingInBackground,
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
            _performBottleAnalysis(
              inBackground: inBackground,
              savedIdHint: savedIdHint,
              imageFile: analysisFile!,
            );
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
          state = state.copyWith(
            isAdLoading: false,
            isLoading: inBackground ? state.isLoading : true,
          );
          await _performBottleAnalysis(
            inBackground: inBackground,
            savedIdHint: savedIdHint,
            imageFile: analysisFile,
          );
        } else {
          // Ad failed to load, proceed with analysis
          state = state.copyWith(isAdLoading: false);
          await _performBottleAnalysis(
            inBackground: inBackground,
            savedIdHint: savedIdHint,
            imageFile: analysisFile,
          );
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
          isAnalyzingInBackground: false,
        );
        return;
      }
    } else {
      // Odd-numbered click, proceed directly to analysis
      state = state.copyWith(isLoading: inBackground ? state.isLoading : true);
      await _performBottleAnalysis(
        inBackground: inBackground,
        savedIdHint: savedIdHint,
        imageFile: analysisFile,
      );
    }
  }

  // Helper method to perform the actual bottle analysis
  Future<void> _performBottleAnalysis({
    bool inBackground = false,
    String? savedIdHint,
    File? imageFile,
  }) async {
    File? analysisFile = imageFile ?? state.sakeImage;
    if (analysisFile == null && state.analyzingImagePath != null) {
      final fileFromPath = File(state.analyzingImagePath!);
      if (fileFromPath.existsSync()) {
        analysisFile = fileFromPath;
      }
    }

    final currentPendingId = savedIdHint ??
        (state.pendingSavedSakeIds.isNotEmpty
            ? state.pendingSavedSakeIds.first
            : null);
    try {
      // 初期化
      state = state.copyWith(sakeInfo: null);
      if (analysisFile == null || !analysisFile.existsSync()) {
        logger.info('酒瓶解析: 解析に使用する画像が見つかりませんでした');
        if (currentPendingId != null) {
          _handleAnalysisFailure(
            currentPendingId,
            '解析に使用する画像が見つかりませんでした',
          );
        }
        state = state.copyWith(
          isLoading: false,
          errorMessage: '解析に使用する画像が見つかりませんでした',
          isAnalyzingInBackground: false,
        );
        return;
      }

      final response =
          await sakeMenuRecognitionRepository.recognizeSakeBottle(analysisFile);

      if (response == null) {
        logger.shout('酒瓶解析: APIレスポンスがnullです');
        _handleAnalysisFailure(
          currentPendingId,
          '酒瓶の認識に失敗しました',
        );
        return;
      }

      if (response.sakeName == null) {
        logger.shout('酒瓶解析: 日本酒名が認識できませんでした');
        _handleAnalysisFailure(
          currentPendingId,
          '酒瓶から日本酒名を認識できませんでした',
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
        _handleAnalysisFailure(
          currentPendingId,
          '日本酒情報が見つかりませんでした',
        );
        return;
      }

      state = state.copyWith(
        sakeInfo: sakeInfo,
      );
      logger.info('酒瓶解析: 日本酒情報取得成功');

      // 結果を更新
      List<String> pendingIds = state.pendingSavedSakeIds;
      if (currentPendingId != null) {
        final savedNotifier = read<SavedSakeNotifier>();
        await savedNotifier.updateSavedSakeWithInfo(
          currentPendingId,
          sakeInfo.copyWith(savedId: currentPendingId),
        );

        final updatedList = savedNotifier.state.savedSakeList;
        final index =
            updatedList.indexWhere((item) => item.savedId == currentPendingId);
        final sakeForSync = index != -1
            ? updatedList[index]
            : sakeInfo.copyWith(savedId: currentPendingId);

        final savedIdForSync = sakeForSync.savedId;
        final shareFlag = savedIdForSync != null
            ? (_savedIdPublicFlags[savedIdForSync] ?? sakeForSync.isPublic)
            : sakeForSync.isPublic;

        unawaited(
          _syncSavedSake(
            stage: SavedSakeSyncStage.analysisComplete,
            sake: sakeForSync,
            imageFile: analysisFile,
            isPublic: shareFlag,
          ),
        );

        pendingIds = _removePendingId(currentPendingId);
      }

      state = state.copyWith(
        isLoading: false,
        isAnalyzingInBackground:
            inBackground ? false : state.isAnalyzingInBackground,
        pendingSavedSakeIds: pendingIds,
        analyzingImagePath: inBackground ? null : state.analyzingImagePath,
      );

      // Save the bottle image with sake name and type
      try {
        await sakeBottleImageRepository.saveSakeBottleImage(
          analysisFile,
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
      _handleAnalysisFailure(
        currentPendingId,
        '酒瓶解析に失敗しました: ${e.toString()}',
      );
    }
  }

  Future<void> _syncSavedSake({
    required SavedSakeSyncStage stage,
    required Sake sake,
    File? imageFile,
    bool? isPublic,
  }) async {
    final user = authRepository.currentUser;
    if (user == null) {
      return;
    }

    try {
      final bool shareFlag = isPublic ??
          (sake.savedId != null
              ? (_savedIdPublicFlags[sake.savedId!] ?? sake.isPublic)
              : sake.isPublic);

      final success = await savedSakeSyncRepository.syncSavedSake(
        stage: stage,
        userId: user.uid,
        sake: sake,
        imageFile: imageFile,
        isPublic: shareFlag,
      );

      if (success && stage == SavedSakeSyncStage.analysisComplete) {
        final savedId = sake.savedId;
        if (savedId != null && savedId.isNotEmpty) {
          final notifier = read<SavedSakeNotifier>();
          final list = notifier.state.savedSakeList;
          final index = list.indexWhere(
              (item) => item.savedId != null && item.savedId == savedId);
          if (index != -1) {
            final target = list[index];
            if (target.syncStatus != SavedSakeSyncStatus.serverSynced ||
                target.isPublic != shareFlag) {
              notifier.updateSavedSake(
                target.copyWith(
                  syncStatus: SavedSakeSyncStatus.serverSynced,
                  isPublic: shareFlag,
                ),
              );
            }
          }
          _savedIdPublicFlags.remove(savedId);
        }
      }
    } catch (error, stackTrace) {
      logger.warning('保存酒同期で例外が発生しました: $error');
      logger.info(stackTrace.toString());
    }
  }

  List<String> _removePendingId(String? id) {
    if (id == null) {
      return state.pendingSavedSakeIds;
    }
    final updated = [...state.pendingSavedSakeIds];
    updated.remove(id);
    return updated;
  }

  void _handleAnalysisFailure(String? savedId, String message) {
    if (savedId != null) {
      read<SavedSakeNotifier>().removeById(savedId);
    }
    final path = state.analyzingImagePath;
    if (path != null) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // ignore delete errors
      }
    }
    state = state.copyWith(
      isLoading: false,
      errorMessage: message,
      isAnalyzingInBackground: false,
      pendingSavedSakeIds: _removePendingId(savedId),
      analyzingImagePath: null,
    );
    if (savedId != null) {
      _savedIdPublicFlags.remove(savedId);
    }
  }

  Future<bool> _ensureSakePreferencesReady() async {
    final myPageNotifier = read<MyPageNotifier>();
    final bool ensured = await ensureSakePreferences(
      context: context,
      myPageNotifier: myPageNotifier,
    );

    if (!ensured) {
      SnackBarUtils.showWarningSnackBar(
        context,
        message: '好みの設定が完了していません。好みを登録してからお試しください。',
        duration: const Duration(seconds: 3),
      );
    }

    return ensured;
  }
}
