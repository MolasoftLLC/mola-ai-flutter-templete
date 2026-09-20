import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/common/utils/image_cropper_service.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/menu_analysis_history_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/services/ad_counter_service.dart';

import '../../common/logger.dart';
import '../../common/localization/localization_extensions.dart';
import '../../common/utils/ad_utils.dart';
import '../../common/utils/custom_image_picker.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../common/dialogs/sake_preferences_dialog.dart';
import '../common/widgets/ad_consent_dialog.dart';
import '../../common/utils/snack_bar_utils.dart';
import '../../common/sake/taste_match.dart';
import '../../domain/eintities/menu_sake_resolution.dart';

part 'menu_search_page_notifier.freezed.dart';

@freezed
abstract class MenuSearchPageState with _$MenuSearchPageState {
  const factory MenuSearchPageState({
    @Default(false) bool isLoading,
    @Default(false) bool isExtractingInfo,
    @Default(false) bool isGettingDetails,
    @Default(false) bool isAdLoading,
    @Default(false) bool isAnalyzingInBackground,
    String? sakeName,
    String? hint,
    File? sakeImage,
    String? geminiResponse,
    @Default([]) List<Sake> extractedSakes,
    SakeMenuRecognitionResponse? sakeMenuRecognitionResponse,
    String? errorMessage,
    List<Sake>? sakes,
    @Default({}) Map<String, bool> sakeLoadingStatus,
    // 元の名前と取得した詳細情報の名前のマッピング
    @Default({}) Map<String, String> nameMapping,
    @Default({}) Map<String, List<MenuSakeCandidate>> resolutionCandidates,
    @Default({}) Map<String, int> matchPercents,
    @Default(<String>[]) List<String> unverifiedNames,
    // ユーザーの好み
    String? preferences,
    // 日本酒リストが表示された後にスクロールしたかどうか
    @Default(false) bool hasScrolledToResults,
    // メニュー解析履歴
    @Default([]) List<MenuAnalysisHistoryItem> menuAnalysisHistory,
    // 現在選択されている履歴項目のID
    String? selectedHistoryItemId,
    // 店舗名の編集中かどうか
    @Default(false) bool isEditingStoreName,
  }) = _MenuSearchPageState;
}

class MenuSearchPageNotifier extends StateNotifier<MenuSearchPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  MenuSearchPageNotifier({
    required this.context,
    MenuAnalysisHistoryRepository? historyRepository,
  }) : _historyRepository =
           historyRepository ?? MenuAnalysisHistoryRepository(),
       super(const MenuSearchPageState());

  final BuildContext context;
  final MenuAnalysisHistoryRepository _historyRepository;
  String? _activeAnalysisId;
  DateTime? _activeAnalysisDate;
  MenuAnalysisHistoryItem? _pendingHistoryItem;
  bool get hasPendingHistorySave => _pendingHistoryItem != null;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();
  SakeMenuRecognitionRepository get sakeMenuRecognitionRepository =>
      read<SakeMenuRecognitionRepository>();

  @override
  Future<void> initState() async {
    super.initState();
    // final prompt2 = '今から質問をします。「日本酒のみむろ杉の特徴を教えて」';
    // final prompt =
    //     '田所酒っていう日本酒の特徴を教えてください。もしそんな日本酒が存在しないなら「該当の日本酒は存在しないようです。」と言ってください。その後似たような名前の日本酒の候補がほしいです。';
    // await requestGemini(prompt2);

    // 初期化と移行を実行
    await _initializeWithMigration();
  }

  Future<void> _initializeWithMigration() async {
    try {
      logger.info('MenuSearchPageNotifier 初期化を開始します');
      // 既存の画像を永続的なストレージに移行
      await migrateMenuAnalysisImages();
      logger.info('画像の移行が完了しました');

      // メニュー解析履歴を読み込む
      await loadMenuAnalysisHistory();
      logger.info('メニュー解析履歴の読み込みが完了しました');

      logger.info('MenuSearchPageNotifier 初期化が完了しました');
    } catch (e) {
      logger.shout('MenuSearchPageNotifier 初期化中にエラーが発生しました: $e');
    }
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

  // ユーザーの好みを設定
  void setPreferences(String preferences) {
    state = state.copyWith(preferences: preferences);
  }

  Future<void> pickImageFromGallery() async {
    // Use CustomImagePicker to avoid READ_MEDIA_IMAGES permission
    final imageFile = await CustomImagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (imageFile != null) {
      // Show cropping UI
      final croppedFile = await ImageCropperService.cropAndRotateImage(
        imageFile.path,
      );

      if (croppedFile != null) {
        // ギャラリーから選択した画像も永続的に保存
        try {
          // ドキュメントディレクトリに画像を保存
          final permanentPath = await ImageCropperService.saveImagePermanently(
            croppedFile,
            'gallery_selected',
          );

          if (permanentPath != null) {
            logger.info('ギャラリー選択画像を永続的に保存しました: $permanentPath');
            // 永続的に保存した画像を使用
            final savedFile = File(permanentPath);
            state = state.copyWith(sakeImage: savedFile);
          } else {
            // 保存に失敗した場合は元のファイルを使用
            state = state.copyWith(sakeImage: croppedFile);
            logger.warning('ギャラリー選択画像の永続保存に失敗しました');
          }
        } catch (e) {
          // エラーが発生した場合は元のファイルを使用
          state = state.copyWith(sakeImage: croppedFile);
          logger.shout('ギャラリー選択画像の保存に失敗しました: $e');
        }
      }
    }
  }

  Future<void> pickImageFromCamera() async {
    // Use CustomImagePicker to avoid READ_MEDIA_IMAGES permission
    final imageFile = await CustomImagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (imageFile != null) {
      // Show cropping UI
      final croppedFile = await ImageCropperService.cropAndRotateImage(
        imageFile.path,
      );

      if (croppedFile != null) {
        // Save image to gallery
        try {
          await ImageGallerySaverPlus.saveFile(croppedFile.path);
          logger.info('画像をギャラリーに保存しました: ${croppedFile.path}');

          // アプリの永続ストレージにも保存
          final permanentPath = await ImageCropperService.saveImagePermanently(
            croppedFile,
            'camera_captured',
          );

          if (permanentPath != null) {
            logger.info('カメラ撮影画像を永続的に保存しました: $permanentPath');
            // 永続的に保存した画像を使用
            final savedFile = File(permanentPath);
            state = state.copyWith(sakeImage: savedFile);
          } else {
            // 永続保存に失敗した場合は元のファイルを使用
            state = state.copyWith(sakeImage: croppedFile);
            logger.warning('カメラ撮影画像の永続保存に失敗しました');
          }
        } catch (e) {
          // エラーが発生した場合は元のファイルを使用
          state = state.copyWith(sakeImage: croppedFile);
          logger.shout('カメラ撮影画像の保存に失敗しました: $e');
        }
      }
    }
  }

  void clearImage() {
    _activeAnalysisId = null;
    _activeAnalysisDate = null;
    _pendingHistoryItem = null;
    state = state.copyWith(
      sakeImage: null,
      extractedSakes: [],
      sakeMenuRecognitionResponse: null,
      sakes: <Sake>[],
      sakeLoadingStatus: {},
      nameMapping: {},
      errorMessage: null,
    );
  }

  Future<void> extractAndFetchSakeInfo(File? imageFile) async {
    if (imageFile == null) {
      return;
    }

    if (!await _ensureSakePreferencesReady()) {
      return;
    }

    _activeAnalysisId =
        'history_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    _activeAnalysisDate = DateTime.now();
    _pendingHistoryItem = null;

    // 初期状態をリセット
    state = state.copyWith(
      isLoading: true,
      isExtractingInfo: true,
      errorMessage: null,
      extractedSakes: [],
      sakes: <Sake>[],
      sakeLoadingStatus: {},
      nameMapping: {},
      resolutionCandidates: {},
      matchPercents: {},
      unverifiedNames: [],
      isAdLoading: true,
      hasScrolledToResults: false,
      isAnalyzingInBackground: false,
    );

    try {
      // Check if we should show an ad using shared counter (3-search cycle)
      final shouldShowAd = await AdCounterService.shouldShowAd();

      if (shouldShowAd) {
        // 広告表示前に同意ダイアログを表示
        final consent = await AdConsentDialog.show(
          context,
          title: context.l10n.adConfirmation,
          description: context.l10n.menuAdDescription,
          icon: Icons.menu_book,
        );

        // ユーザーが同意した場合のみ広告を表示
        if (consent == true) {
          // 広告のロードを開始
          try {
            final rewardedAd = await AdUtils.loadRewardedAd(
              onAdLoaded: (ad) {
                logger.info('リワード広告がロードされました');
              },
              onAdDismissed: () {
                logger.info('リワード広告が閉じられました');

                // 広告が閉じられた時の処理
                if (state.isAnalyzingInBackground) {
                  // まだ解析中の場合は、解析中の表示を継続
                  logger.info('広告が閉じられましたが、まだ解析中です');
                  state = state.copyWith(
                    isAdLoading: false,
                    isLoading: true,
                    isExtractingInfo: true,
                  );
                } else if (state.extractedSakes.isNotEmpty) {
                  // 解析が完了している場合は、詳細情報を取得
                  logger.info('広告が閉じられ、解析も完了しています。詳細情報を取得します');
                  state = state.copyWith(isAdLoading: false, isLoading: false);
                  _fetchSakeDetails(state.extractedSakes);
                } else {
                  // 解析結果がない場合（エラーなど）
                  state = state.copyWith(isAdLoading: false, isLoading: false);
                }
              },
              onAdFailedToLoad: (error) {
                logger.shout('リワード広告のロードに失敗しました: ${error.message}');
                state = state.copyWith(isAdLoading: false);
              },
              onUserEarnedReward: (reward) {
                logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
              },
            );

            if (rewardedAd != null) {
              // 広告を表示し、同時に裏側で解析を開始
              state = state.copyWith(
                isAdLoading: true,
                isAnalyzingInBackground: true,
              );

              // 広告を表示
              try {
                // 裏側で解析を開始（非同期で実行）
                _extractSakeInfoInBackground(imageFile);

                // 広告を表示（ユーザーはこれを見ている間に解析が進む）
                await AdUtils.showRewardedAd(
                  rewardedAd,
                  onUserEarnedReward: (reward) {
                    logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
                  },
                );

                return; // 処理完了（残りの処理はコールバックで行われる）
              } catch (e) {
                logger.shout('広告の表示に失敗しました: $e');
                // 広告の表示に失敗した場合は通常の解析を実行
                state = state.copyWith(
                  isAdLoading: false,
                  isLoading: true,
                  isExtractingInfo: true,
                  isAnalyzingInBackground: false,
                );
                await _extractSakeInfoInForeground(imageFile);
              }

              return; // 処理完了
            }
          } catch (e) {
            logger.shout('広告処理でエラーが発生しました: $e');
            state = state.copyWith(
              isAdLoading: false,
              isAnalyzingInBackground: false,
            );
          }
        } else {
          // ユーザーが広告視聴を拒否した場合
          logger.info('ユーザーが広告視聴を拒否しました');

          // SnackBarで通知
          SnackBarUtils.showWarningSnackBar(
            context,
            message: context.l10n.analysisCancelled,
            duration: const Duration(seconds: 4),
          );

          // 解析をキャンセルして処理を終了
          state = state.copyWith(
            isLoading: false,
            isExtractingInfo: false,
            isGettingDetails: false,
            isAdLoading: false,
            isAnalyzingInBackground: false,
          );
          return;
        }
      } else {
        // No ad needed, proceed directly to analysis
        await _extractSakeInfoInForeground(imageFile);
        return;
      }

      // 広告のロードに失敗した場合や広告がnullの場合はここに到達する
      // 通常の処理を続行
      await _extractSakeInfoInForeground(imageFile);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
        isGettingDetails: false,
        isAdLoading: false,
        isAnalyzingInBackground: false,
        errorMessage: context.l10n.errorMenuExtraction,
      );
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
        message: context.l10n.noPreferenceConfigured,
        duration: const Duration(seconds: 3),
      );
      return false;
    }

    final String? latest = myPageNotifier.state.preferences;
    if (latest != null && latest.trim().isNotEmpty) {
      state = state.copyWith(preferences: latest.trim());
    }

    return true;
  }

  /// 日本酒の詳細情報を取得する
  Future<void> _fetchSakeDetails(List<Sake> extractedSakes) async {
    if (extractedSakes.isEmpty) return;

    try {
      final loading = <String, bool>{
        for (final sake in extractedSakes)
          if (sake.name?.isNotEmpty == true) sake.name!: true,
      };
      state = state.copyWith(
        isGettingDetails: true,
        sakeLoadingStatus: loading,
        resolutionCandidates: const {},
        matchPercents: const {},
        unverifiedNames: const [],
      );

      final resolutions = await sakeMenuRecognitionRepository.resolveMenuSakes(
        extractedSakes,
      );
      final nameMapping = <String, String>{};
      final candidates = <String, List<MenuSakeCandidate>>{};
      final matchPercents = <String, int>{};
      final unverifiedNames = <String>[];
      final resolvedSakes = <Sake>[];
      final preference = read<MyPageNotifier>().state.tasteProfile;

      for (final resolution in resolutions) {
        MenuSakeCandidate? selected;
        if (resolution.status == MenuSakeResolutionStatus.resolved &&
            resolution.candidates.length == 1) {
          selected = resolution.candidates.single;
        } else if (resolution.status == MenuSakeResolutionStatus.multiple) {
          candidates[resolution.inputName] = resolution.candidates;
        }

        if (selected != null) {
          final sake = selected.sake;
          nameMapping[resolution.inputName] = sake.name ?? resolution.inputName;
          resolvedSakes.add(sake);
          final matchPercent = calculateOptionalSakeTasteMatchPercent(
            profile: selected.tasteProfile,
            preference: preference,
          );
          if (matchPercent != null) {
            matchPercents[resolution.inputName] = matchPercent;
          }
        } else if (resolution.fallback != null) {
          final fallback = resolution.fallback!;
          nameMapping[resolution.inputName] =
              fallback.name ?? resolution.inputName;
          resolvedSakes.add(fallback.copyWith(recommendationScore: null));
          unverifiedNames.add(resolution.inputName);
        }
      }

      state = state.copyWith(
        isGettingDetails: false,
        sakes: resolvedSakes,
        sakeLoadingStatus: {
          for (final sake in extractedSakes)
            if (sake.name?.isNotEmpty == true) sake.name!: false,
        },
        nameMapping: nameMapping,
        resolutionCandidates: candidates,
        matchPercents: matchPercents,
        unverifiedNames: unverifiedNames,
      );

      await addCurrentAnalysisToHistory();
    } catch (e) {
      logger.shout('詳細情報の取得中にエラーが発生しました: $e');
      state = state.copyWith(
        isGettingDetails: false,
        errorMessage: context.l10n.errorSakeDetailFetch,
      );
      await addCurrentAnalysisToHistory(analysisStatus: 'partial');
    }
  }

  void selectMenuCandidate(String inputName, MenuSakeCandidate candidate) {
    final mapped = Map<String, String>.from(state.nameMapping);
    final previousName = mapped[inputName];
    mapped[inputName] = candidate.sake.name ?? inputName;
    final sakes = [
      ...(state.sakes ?? const <Sake>[]),
    ]..removeWhere((sake) => previousName != null && sake.name == previousName);
    if (!sakes.any((sake) => sake.sakeId == candidate.sake.sakeId)) {
      sakes.add(candidate.sake);
    }
    final scores = Map<String, int>.from(state.matchPercents);
    final preference = read<MyPageNotifier>().state.tasteProfile;
    final matchPercent = calculateOptionalSakeTasteMatchPercent(
      profile: candidate.tasteProfile,
      preference: preference,
    );
    if (matchPercent != null) {
      scores[inputName] = matchPercent;
    } else {
      scores.remove(inputName);
    }
    final choices = Map<String, List<MenuSakeCandidate>>.from(
      state.resolutionCandidates,
    )..remove(inputName);
    state = state.copyWith(
      sakes: sakes,
      nameMapping: mapped,
      matchPercents: scores,
      resolutionCandidates: choices,
    );
    unawaited(addCurrentAnalysisToHistory());
  }

  /// フォアグラウンドでメニュー解析を実行する
  Future<void> _extractSakeInfoInForeground(File imageFile) async {
    try {
      // 画像から日本酒情報を抽出（直接List<Sake>を取得）
      final extractedSakes = await sakeMenuRecognitionRepository
          .extractSakeInfo(imageFile);

      if (extractedSakes == null || extractedSakes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isExtractingInfo: false,
          isAdLoading: false,
          isAnalyzingInBackground: false,
          errorMessage: context.l10n.errorNoSakeExtracted,
        );
        return;
      }

      // 抽出した日本酒情報を表示用に保存し、ローディングを終了
      // 各日本酒の読み込み状態を初期化
      final Map<String, bool> initialLoadingStatus = {};
      for (final sake in extractedSakes) {
        if (sake.name != null) {
          initialLoadingStatus[sake.name!] = false; // false = まだ読み込んでいない
        }
      }

      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
        isAdLoading: false,
        isAnalyzingInBackground: false,
        extractedSakes: extractedSakes,
        sakeLoadingStatus: initialLoadingStatus,
        hasScrolledToResults: false,
      );

      // マスター解決を待たず、抽出できた酒名をまず履歴へ確定保存する。
      await addCurrentAnalysisToHistory(analysisStatus: 'details_pending');
      // 詳細情報を取得
      await _fetchSakeDetails(extractedSakes);
    } catch (e) {
      logger.shout('メニュー解析中にエラーが発生しました: $e');
      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
        isGettingDetails: false,
        isAdLoading: false,
        isAnalyzingInBackground: false,
        errorMessage: context.l10n.errorMenuExtraction,
      );
    }
  }

  /// バックグラウンドでメニュー解析を実行する（広告表示中に実行）
  Future<void> _extractSakeInfoInBackground(File imageFile) async {
    try {
      logger.info('バックグラウンドでメニュー解析を開始します');

      // 画像から日本酒情報を抽出（直接List<Sake>を取得）
      final extractedSakes = await sakeMenuRecognitionRepository
          .extractSakeInfo(imageFile);

      if (extractedSakes == null || extractedSakes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isExtractingInfo: false,
          isAnalyzingInBackground: false,
          errorMessage: context.l10n.errorNoSakeExtracted,
        );
        return;
      }

      // 抽出した日本酒情報を表示用に保存
      // 各日本酒の読み込み状態を初期化
      final Map<String, bool> initialLoadingStatus = {};
      for (final sake in extractedSakes) {
        if (sake.name != null) {
          initialLoadingStatus[sake.name!] = false; // false = まだ読み込んでいない
        }
      }

      logger.info('バックグラウンド解析が完了しました: ${extractedSakes.length}件の日本酒情報を抽出');

      // 履歴の初回保存が終わるまでは解析中として扱う。広告終了コールバックと
      // 詳細取得が競合して、完成済み履歴を details_pending で上書きするのを防ぐ。
      state = state.copyWith(
        isExtractingInfo: false,
        extractedSakes: extractedSakes,
        sakeLoadingStatus: initialLoadingStatus,
        hasScrolledToResults: false,
      );
      await addCurrentAnalysisToHistory(analysisStatus: 'details_pending');

      if (state.isAdLoading) {
        logger.info('広告表示中のため、解析結果を保存し広告終了を待ちます');
        state = state.copyWith(isAnalyzingInBackground: false);
      } else {
        logger.info('広告が既に終了しているため、結果を表示します');
        state = state.copyWith(
          isLoading: false,
          isAnalyzingInBackground: false,
        );
        await _fetchSakeDetails(extractedSakes);
      }
    } catch (e) {
      logger.shout('バックグラウンド解析中にエラーが発生しました: $e');
      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
        isAnalyzingInBackground: false,
        errorMessage: context.l10n.errorMenuExtraction,
      );
    }
  }

  // 日本酒リストが表示された後にスクロールしたかどうかを設定
  void setHasScrolledToResults(bool value) {
    state = state.copyWith(hasScrolledToResults: value);
  }

  // メニュー解析履歴を読み込む
  Future<void> loadMenuAnalysisHistory() async {
    try {
      state = state.copyWith(
        menuAnalysisHistory: await _historyRepository.load(),
      );
    } catch (e) {
      logger.shout('メニュー解析履歴の読み込みに失敗しました: $e');
      state = state.copyWith(errorMessage: context.l10n.menuHistoryLoadFailed);
    }
  }

  // メニュー解析履歴を保存する
  Future<void> saveMenuAnalysisHistory() async {
    try {
      await _historyRepository.replaceAll(state.menuAnalysisHistory);
    } catch (e) {
      logger.shout('メニュー解析履歴の保存に失敗しました: $e');
      state = state.copyWith(errorMessage: context.l10n.menuHistorySaveFailed);
      rethrow;
    }
  }

  // 現在の解析結果をメニュー解析履歴に追加する
  Future<void> addCurrentAnalysisToHistory({String? analysisStatus}) async {
    if (state.extractedSakes.isEmpty) return;
    final analysisId = _activeAnalysisId ??=
        'history_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    final analysisDate = _activeAnalysisDate ??= DateTime.now();
    try {
      final existing = state.menuAnalysisHistory
          .where((item) => item.id == analysisId)
          .firstOrNull;
      String? imagePath = existing?.imagePath;
      if (imagePath == null && state.sakeImage != null) {
        try {
          imagePath = await ImageCropperService.saveImagePermanently(
            state.sakeImage!,
            'menu',
          );
        } catch (e) {
          // 画像の複製失敗だけで、抽出済みの商品名まで失わない。
          logger.warning('メニュー履歴画像の保存に失敗しました: $e');
        }
      }
      final savedSakes = buildMenuHistorySakes(
        extracted: state.extractedSakes
            .where((sake) => sake.name?.trim().isNotEmpty == true)
            .map((sake) => (name: sake.name!.trim(), type: sake.type))
            .toList(growable: false),
        resolved: (state.sakes ?? const <Sake>[])
            .where((sake) => sake.name?.trim().isNotEmpty == true)
            .map(
              (sake) => (
                sakeId: sake.sakeId,
                name: sake.name!.trim(),
                type: sake.type,
              ),
            )
            .toList(growable: false),
        nameMapping: state.nameMapping,
        matchPercents: state.matchPercents,
      );
      final newHistoryItem = MenuAnalysisHistoryItem(
        id: analysisId,
        date: analysisDate,
        storeName: existing?.storeName,
        sakes: savedSakes,
        imagePath: imagePath,
        analysisStatus:
            analysisStatus ??
            (state.resolutionCandidates.isEmpty &&
                    state.unverifiedNames.isEmpty &&
                    state.extractedSakes
                        .where((sake) => sake.name?.trim().isNotEmpty == true)
                        .every(
                          (sake) =>
                              state.nameMapping.containsKey(sake.name!.trim()),
                        )
                ? 'complete'
                : 'partial'),
      );
      await _historyRepository.upsert(newHistoryItem);
      final updatedHistory = [
        newHistoryItem,
        ...state.menuAnalysisHistory.where((item) => item.id != analysisId),
      ];
      updatedHistory.sort((a, b) => b.date.compareTo(a.date));
      _pendingHistoryItem = null;
      state = state.copyWith(
        menuAnalysisHistory: updatedHistory.take(20).toList(growable: false),
        errorMessage: state.errorMessage == context.l10n.menuHistorySaveFailed
            ? null
            : state.errorMessage,
      );
      logger.info('メニュー解析履歴に追加しました: ${newHistoryItem.id}');
    } catch (e) {
      logger.shout('メニュー解析履歴への追加に失敗しました: $e');
      _pendingHistoryItem = MenuAnalysisHistoryItem(
        id: analysisId,
        date: analysisDate,
        sakes: buildMenuHistorySakes(
          extracted: state.extractedSakes
              .where((sake) => sake.name?.trim().isNotEmpty == true)
              .map((sake) => (name: sake.name!.trim(), type: sake.type))
              .toList(growable: false),
          resolved: const [],
          nameMapping: const {},
          matchPercents: const {},
        ),
        imagePath: state.sakeImage?.path,
        analysisStatus: analysisStatus ?? 'partial',
      );
      state = state.copyWith(errorMessage: context.l10n.menuHistorySaveFailed);
    }
  }

  Future<void> retrySaveMenuAnalysisHistory() async {
    final pending = _pendingHistoryItem;
    if (pending == null) return;
    try {
      await _historyRepository.upsert(pending);
      final updated = [
        pending,
        ...state.menuAnalysisHistory.where((item) => item.id != pending.id),
      ]..sort((a, b) => b.date.compareTo(a.date));
      _pendingHistoryItem = null;
      state = state.copyWith(
        menuAnalysisHistory: updated.take(20).toList(growable: false),
        errorMessage: null,
      );
    } catch (e) {
      logger.shout('メニュー解析履歴の再保存に失敗しました: $e');
      state = state.copyWith(errorMessage: context.l10n.menuHistorySaveFailed);
    }
  }

  /// SharedPreferencesの旧一括履歴を、1件単位の永続ストレージへ移行する。
  Future<void> migrateMenuAnalysisImages() async {
    try {
      await _historyRepository.migrateLegacy();
    } catch (e) {
      logger.shout('メニュー解析履歴の画像の移行に失敗しました: $e');
      state = state.copyWith(errorMessage: context.l10n.menuHistoryLoadFailed);
    }
  }

  // 店舗名を設定する
  Future<void> setStoreName(String historyId, String storeName) async {
    try {
      final updatedHistory = state.menuAnalysisHistory.map((item) {
        if (item.id == historyId) {
          return item.copyWith(storeName: storeName);
        }
        return item;
      }).toList();
      final updatedItem = updatedHistory.firstWhere(
        (item) => item.id == historyId,
      );
      await _historyRepository.upsert(updatedItem);
      state = state.copyWith(
        menuAnalysisHistory: updatedHistory,
        isEditingStoreName: false,
      );
      logger.info('店舗名を設定しました: $historyId, $storeName');
    } catch (e) {
      logger.shout('店舗名の設定に失敗しました: $e');
      state = state.copyWith(errorMessage: context.l10n.menuHistorySaveFailed);
    }
  }

  // 履歴項目を選択する
  void selectHistoryItem(String? historyId) {
    state = state.copyWith(selectedHistoryItemId: historyId);
  }

  // 店舗名の編集状態を設定する
  void setEditingStoreName(bool isEditing) {
    state = state.copyWith(isEditingStoreName: isEditing);
  }

  // 履歴項目を削除する
  Future<void> deleteHistoryItem(String historyId) async {
    try {
      // 削除対象の履歴項目を取得
      final itemToDelete = state.menuAnalysisHistory.firstWhere(
        (item) => item.id == historyId,
        orElse: () => throw Exception('削除対象の履歴項目が見つかりませんでした'),
      );
      await _historyRepository.delete(historyId);

      // ファイルが存在する場合は削除を試みる
      if (itemToDelete.imagePath != null) {
        final file = File(itemToDelete.imagePath!);
        if (file.existsSync()) {
          try {
            await file.delete();
            logger.info('画像ファイルを削除しました: ${itemToDelete.imagePath}');
          } catch (e) {
            logger.warning('画像ファイルの削除に失敗しました: $e');
          }
        }
      }

      // 削除対象の履歴項目を除外した新しいリストを作成
      final updatedHistory = state.menuAnalysisHistory
          .where((item) => item.id != historyId)
          .toList();

      state = state.copyWith(menuAnalysisHistory: updatedHistory);
      logger.info('メニュー解析履歴を削除しました: $historyId');
    } catch (e) {
      logger.shout('メニュー解析履歴の削除に失敗しました: $e');
      state = state.copyWith(errorMessage: context.l10n.menuHistorySaveFailed);
    }
  }
}
