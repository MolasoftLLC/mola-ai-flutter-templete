import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mola_gemini_flutter_template/common/utils/image_cropper_service.dart';
import 'package:mola_gemini_flutter_template/common/utils/image_utils.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/shared_key.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/shared_preference.dart';
import 'package:path_provider/path_provider.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/services/ad_counter_service.dart';

import '../../common/logger.dart';
import '../../common/utils/ad_utils.dart';
import '../../common/utils/custom_image_picker.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../common/widgets/ad_consent_dialog.dart';
import '../../common/utils/snack_bar_utils.dart';

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
  }) : super(const MenuSearchPageState());

  final BuildContext context;
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
    final imageFile =
        await CustomImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      // Show cropping UI
      final croppedFile = await ImageCropperService.cropAndRotateImage(imageFile.path);
      
      if (croppedFile != null) {
        // ギャラリーから選択した画像も永続的に保存
        try {
          // ドキュメントディレクトリに画像を保存
          final permanentPath = await ImageCropperService.saveImagePermanently(
            croppedFile,
            'gallery_selected'
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
    final imageFile =
        await CustomImagePicker.pickImage(source: ImageSource.camera);
    if (imageFile != null) {
      // Show cropping UI
      final croppedFile = await ImageCropperService.cropAndRotateImage(imageFile.path);
      
      if (croppedFile != null) {
        // Save image to gallery
        try {
          await ImageGallerySaver.saveFile(croppedFile.path);
          logger.info('画像をギャラリーに保存しました: ${croppedFile.path}');
          
          // アプリの永続ストレージにも保存
          final permanentPath = await ImageCropperService.saveImagePermanently(
            croppedFile,
            'camera_captured'
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

    // 初期状態をリセット
    state = state.copyWith(
      isLoading: true,
      isExtractingInfo: true,
      errorMessage: null,
      sakes: <Sake>[],
      sakeLoadingStatus: {},
      nameMapping: {},
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
          title: '広告視聴の確認',
          description: 'メニューから日本酒情報を解析するには広告の視聴が必要です。広告の視聴をお願いします！',
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
                state = state.copyWith(
                  isAdLoading: false,
                  isLoading: false,
                );
                _fetchSakeDetails(state.extractedSakes);
              } else {
                // 解析結果がない場合（エラーなど）
                state = state.copyWith(
                  isAdLoading: false,
                  isLoading: false,
                );
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
            message: '解析をキャンセルしました。解析精度向上のため、次回は広告視聴にご協力ください。',
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
        errorMessage: '日本酒情報の抽出に失敗しました: $e',
      );
    }
  }

  /// 日本酒の詳細情報を取得する
  Future<void> _fetchSakeDetails(List<Sake> extractedSakes) async {
    if (extractedSakes.isEmpty) return;

    try {
      // 詳細情報の取得を開始
      state = state.copyWith(isGettingDetails: true);

      for (final extractedSake in extractedSakes) {
        try {
          final sakeName = extractedSake.name;
          final sakeType = extractedSake.type;

          if (sakeName != null && sakeName.isNotEmpty) {
            // この日本酒の読み込み状態を「読み込み中」に設定
            final updatedLoadingStatus =
                Map<String, bool>.from(state.sakeLoadingStatus);
            updatedLoadingStatus[sakeName] = true; // true = 読み込み中
            state = state.copyWith(sakeLoadingStatus: updatedLoadingStatus);

            logger.info('日本酒情報を取得中: $sakeName');
            final sakeInfo = await sakeMenuRecognitionRepository.getSakeInfo(
              sakeName,
              type: sakeType,
              preferences: state.preferences ?? '甘口でフルーティ',
            );

            // 読み込み状態を更新（成功または失敗）
            final newLoadingStatus =
                Map<String, bool>.from(state.sakeLoadingStatus);
            newLoadingStatus[sakeName] = false; // 読み込み完了

            if (sakeInfo != null) {
              // 名前のマッピングを更新（元の名前 -> 取得した詳細情報の名前）
              final newNameMapping =
                  Map<String, String>.from(state.nameMapping);
              newNameMapping[sakeName] = sakeInfo.name ?? sakeName;

              // 現在のsakesリストに新しい情報を追加（重複チェック）
              final List<Sake> currentSakes = state.sakes ?? [];
              
              // 既に同じ名前の日本酒が存在するかチェック
              bool isDuplicate = currentSakes.any((existingSake) => 
                existingSake.name == sakeInfo.name);
              
              // 重複していない場合のみ追加
              final List<Sake> updatedSakes = isDuplicate 
                  ? currentSakes 
                  : [...currentSakes, sakeInfo];
                  
              state = state.copyWith(
                sakes: updatedSakes,
                sakeLoadingStatus: newLoadingStatus,
                nameMapping: newNameMapping,
              );
            } else {
              // 詳細情報の取得に失敗した場合も状態を更新
              state = state.copyWith(sakeLoadingStatus: newLoadingStatus);
            }
          }
        } catch (e) {
          // 個別の日本酒情報取得に失敗しても続行
          final sakeName = extractedSake.name;
          if (sakeName != null) {
            final updatedLoadingStatus =
                Map<String, bool>.from(state.sakeLoadingStatus);
            updatedLoadingStatus[sakeName] = false; // 読み込み完了（エラー）
            state = state.copyWith(sakeLoadingStatus: updatedLoadingStatus);
          }
          logger.shout('日本酒情報の取得に失敗: ${extractedSake.name}, エラー: $e');
        }
      }

      // すべての詳細情報の取得が完了
      state = state.copyWith(isGettingDetails: false);

      // 詳細情報の取得が完了したら、メニュー解析履歴に追加
      if (state.sakes != null && state.sakes!.isNotEmpty) {
        await addCurrentAnalysisToHistory();
      }
    } catch (e) {
      logger.shout('詳細情報の取得中にエラーが発生しました: $e');
      state = state.copyWith(
        isGettingDetails: false,
        errorMessage: '日本酒の詳細情報の取得に失敗しました',
      );
    }
  }

  /// フォアグラウンドでメニュー解析を実行する
  Future<void> _extractSakeInfoInForeground(File imageFile) async {
    try {
      // 画像から日本酒情報を抽出（直接List<Sake>を取得）
      final extractedSakes =
          await sakeMenuRecognitionRepository.extractSakeInfo(imageFile);

      if (extractedSakes == null || extractedSakes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isExtractingInfo: false,
          isAdLoading: false,
          isAnalyzingInBackground: false,
          errorMessage: '日本酒情報を抽出できませんでした',
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
        errorMessage: '日本酒情報の抽出に失敗しました: $e',
      );
    }
  }
  
  /// バックグラウンドでメニュー解析を実行する（広告表示中に実行）
  Future<void> _extractSakeInfoInBackground(File imageFile) async {
    try {
      logger.info('バックグラウンドでメニュー解析を開始します');
      
      // 画像から日本酒情報を抽出（直接List<Sake>を取得）
      final extractedSakes =
          await sakeMenuRecognitionRepository.extractSakeInfo(imageFile);

      if (extractedSakes == null || extractedSakes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isExtractingInfo: false,
          isAnalyzingInBackground: false,
          errorMessage: '日本酒情報を抽出できませんでした',
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
      
      // 広告が表示中かどうかをチェック
      if (state.isAdLoading) {
        // 広告表示中の場合は、解析結果を保存するが、ローディング表示は維持
        // 広告終了時のコールバックで適切な表示に切り替える
        logger.info('広告表示中のため、解析結果を保存し広告終了を待ちます');
        state = state.copyWith(
          isExtractingInfo: false,
          isAnalyzingInBackground: false,
          extractedSakes: extractedSakes,
          sakeLoadingStatus: initialLoadingStatus,
          hasScrolledToResults: false,
        );
      } else {
        // 広告が既に終了している場合は、ローディング表示を終了し結果を表示
        logger.info('広告が既に終了しているため、結果を表示します');
        state = state.copyWith(
          isLoading: false,
          isExtractingInfo: false,
          isAnalyzingInBackground: false,
          extractedSakes: extractedSakes,
          sakeLoadingStatus: initialLoadingStatus,
          hasScrolledToResults: false,
        );
        
        // 詳細情報を取得
        await _fetchSakeDetails(extractedSakes);
      }
    } catch (e) {
      logger.shout('バックグラウンド解析中にエラーが発生しました: $e');
      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
        isAnalyzingInBackground: false,
        errorMessage: '日本酒情報の抽出に失敗しました: $e',
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
      final historyJson =
          await SharedPreference.staticGetString(key: MENU_ANALYSIS_HISTORY);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        final List<MenuAnalysisHistoryItem> history = historyList
            .map((item) => MenuAnalysisHistoryItem.fromJson(item))
            .toList();

        // base64データがある、または画像ファイルが存在する項目のみを保持
        final List<MenuAnalysisHistoryItem> validHistory = [];
        for (final item in history) {
          // base64データがある場合は保持する
          if (item.base64Image != null && item.base64Image!.isNotEmpty) {
            logger.info('base64データが存在するため履歴を保持: ${item.id}');
            validHistory.add(item);
          }
          // base64データがなくても、画像ファイルが存在(またはnull)する場合は保持
          else if (item.imagePath == null || File(item.imagePath!).existsSync()) {
            validHistory.add(item);
          } else {
            logger.warning('メニュー画像ファイルが見つかりません: ${item.imagePath}');
          }
        }

        // 日付の新しい順に並べ替え
        validHistory.sort((a, b) => b.date.compareTo(a.date));

        // 最大20件まで保存（古いものから削除）
        final limitedHistory =
            validHistory.length > 20 ? validHistory.sublist(0, 20) : validHistory;

        state = state.copyWith(menuAnalysisHistory: limitedHistory);
      }
    } catch (e) {
      logger.shout('メニュー解析履歴の読み込みに失敗しました: $e');
    }
  }

  // メニュー解析履歴を保存する
  Future<void> saveMenuAnalysisHistory() async {
    try {
      final historyJson = jsonEncode(
        state.menuAnalysisHistory.map((item) => item.toJson()).toList(),
      );
      await SharedPreference.staticSetString(
          key: MENU_ANALYSIS_HISTORY, value: historyJson);
    } catch (e) {
      logger.shout('メニュー解析履歴の保存に失敗しました: $e');
    }
  }

  // 現在の解析結果をメニュー解析履歴に追加する
  Future<void> addCurrentAnalysisToHistory() async {
    if (state.sakes == null || state.sakes!.isEmpty) return;
    
    // Check if we already have a history item with the same sakes to prevent duplication
    if (state.menuAnalysisHistory.isNotEmpty) {
      // Generate the list of sake names for comparison
      final List<String> currentSakeNames = state.sakes!
          .map((sake) => sake.name ?? '不明な日本酒')
          .toList();
      
      // Check the most recent history item (which would be the one we might be duplicating)
      final latestHistoryItem = state.menuAnalysisHistory.first;
      final List<String> latestHistorySakeNames = latestHistoryItem.sakes
          .map((sake) => sake.name)
          .toList();
      
      // If the sake lists have the same length and contain the same items, it's likely a duplicate
      if (currentSakeNames.length == latestHistorySakeNames.length &&
          currentSakeNames.toSet().containsAll(latestHistorySakeNames.toSet())) {
        logger.info('メニュー解析履歴の重複を防止しました');
        return;
      }
    }

    try {
      // Save the current image permanently if available
      String? imagePath;
      String? base64Image;
      if (state.sakeImage != null) {
        // Save to permanent storage
        imagePath = await ImageCropperService.saveImagePermanently(
          state.sakeImage!,
          'menu'
        );
        
        // Compress and encode to base64
        base64Image = await ImageUtils.compressAndEncodeImage(
          state.sakeImage!,
          quality: 55,
          format: CompressFormat.webp,
        );
        
        logger.info('メニュー画像をbase64エンコードしました');
      }
      
      // 現在の日本酒情報から保存用のデータを作成
      final List<SavedSake> savedSakes = state.sakes!
          .map((sake) => SavedSake(
                name: sake.name ?? '不明な日本酒',
                type: sake.type,
                isRecommended: (sake.recommendationScore ?? 0) > 6,
              ))
          .toList();

      // 新しい履歴項目を作成
      final newHistoryItem = MenuAnalysisHistoryItem(
        id: 'history_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        date: DateTime.now(),
        sakes: savedSakes,
        imagePath: imagePath,
        base64Image: base64Image, // Add base64 encoded image
      );

      // 現在の履歴に追加
      final updatedHistory = [
        newHistoryItem,
        ...state.menuAnalysisHistory,
      ];

      // 日付の新しい順に並べ替え
      updatedHistory.sort((a, b) => b.date.compareTo(a.date));

      // 最大20件まで保存（古いものから削除）
      final limitedHistory = updatedHistory.length > 20
          ? updatedHistory.sublist(0, 20)
          : updatedHistory;

      // 状態を更新
      state = state.copyWith(menuAnalysisHistory: limitedHistory);

      // 永続化
      await saveMenuAnalysisHistory();

      logger.info('メニュー解析履歴に追加しました: ${newHistoryItem.id}');
    } catch (e) {
      logger.shout('メニュー解析履歴への追加に失敗しました: $e');
    }
  }

  /// Migrate existing menu analysis images to permanent storage and encode to base64
  Future<void> migrateMenuAnalysisImages() async {
    try {
      logger.info('メニュー解析履歴の画像移行を開始します');
      final historyJson =
          await SharedPreference.staticGetString(key: MENU_ANALYSIS_HISTORY);
      if (historyJson != null && historyJson.isNotEmpty) {
        logger.info('履歴データが見つかりました。デコード中...');
        final List<dynamic> historyList = jsonDecode(historyJson);
        final List<MenuAnalysisHistoryItem> history = historyList
            .map((item) => MenuAnalysisHistoryItem.fromJson(item))
            .toList();
        
        logger.info('解析履歴アイテム数: ${history.length}');
        bool hasChanges = false;
        final updatedHistory = <MenuAnalysisHistoryItem>[];
        
        for (final item in history) {
          // 処理する履歴項目のIDをログ出力
          logger.info('処理中の履歴ID: ${item.id}');
          
          // 既にbase64データがある場合はスキップ
          if (item.base64Image != null && item.base64Image!.isNotEmpty) {
            logger.info('既にbase64データが存在します: ${item.id}');
            updatedHistory.add(item);
            continue;
          }
          
          if (item.imagePath != null) {
            logger.info('画像パスが存在します: ${item.imagePath}');
            final file = File(item.imagePath!);
            if (file.existsSync()) {
              logger.info('画像ファイルが存在します: ${item.imagePath}');
              // アプリのドキュメントディレクトリにあるか確認
              final appDir = await getApplicationDocumentsDirectory();
              String? permanentPath = item.imagePath;
              
              if (!item.imagePath!.startsWith(appDir.path)) {
                logger.info('画像を永続的ストレージに移行します');
                // 画像を永続的ストレージに移行
                permanentPath = await ImageCropperService.saveImagePermanently(
                  file,
                  'menu'
                );
                if (permanentPath != null) {
                  logger.info('画像を移行しました: $permanentPath');
                } else {
                  logger.warning('画像の移行に失敗しました');
                }
              }
              
              // パス移行に関係なくbase64エンコードを試みる
              try {
                logger.info('画像をbase64エンコードします');
                // 圧縮してbase64エンコード
                final base64Image = await ImageUtils.compressAndEncodeImage(
                  file,
                  quality: 55,
                  format: CompressFormat.webp,
                );
                
                if (base64Image.isNotEmpty) {
                  logger.info('base64エンコードに成功しました: ${base64Image.length} 文字');
                  
                  // 新しい履歴項目を作成（パスとbase64データを更新）
                  final updatedItem = MenuAnalysisHistoryItem(
                    id: item.id,
                    date: item.date,
                    storeName: item.storeName,
                    sakes: item.sakes,
                    imagePath: permanentPath,
                    base64Image: base64Image,
                  );
                  updatedHistory.add(updatedItem);
                  hasChanges = true;
                  logger.info('メニュー解析履歴の画像をbase64エンコードしました: ${item.id}');
                } else {
                  logger.warning('base64エンコード結果が空です');
                  // base64エンコードに失敗したが、パスは更新
                  final updatedItem = MenuAnalysisHistoryItem(
                    id: item.id,
                    date: item.date,
                    storeName: item.storeName,
                    sakes: item.sakes,
                    imagePath: permanentPath,
                    base64Image: null,
                  );
                  updatedHistory.add(updatedItem);
                  hasChanges = permanentPath != item.imagePath;
                }
              } catch (e) {
                logger.warning('画像のbase64エンコードに失敗しました: $e');
                // エンコードに失敗した場合、可能であればパスを更新
                final updatedItem = MenuAnalysisHistoryItem(
                  id: item.id,
                  date: item.date,
                  storeName: item.storeName,
                  sakes: item.sakes,
                  imagePath: permanentPath,
                  base64Image: null,
                );
                updatedHistory.add(updatedItem);
                hasChanges = permanentPath != item.imagePath;
                logger.warning('メニュー解析履歴の画像のbase64エンコードに失敗しました: ${item.id} - $e');
              }
            } else {
              logger.warning('ファイルが存在しません: ${item.imagePath}');
              // ファイルが存在しない場合、パスをnullに設定
              final updatedItem = MenuAnalysisHistoryItem(
                id: item.id,
                date: item.date,
                storeName: item.storeName,
                sakes: item.sakes,
                imagePath: null, // 無効なパスを削除
                base64Image: null,
              );
              updatedHistory.add(updatedItem);
              hasChanges = true;
              logger.warning('存在しないメニュー解析履歴の画像をnullに設定しました: ${item.id}');
            }
          } else {
            logger.info('画像パスがありません: ${item.id}');
            // 画像パスがない場合、そのまま追加
            updatedHistory.add(item);
          }
        }
        
        if (hasChanges) {
          logger.info('メニュー解析履歴を更新します');
          state = state.copyWith(menuAnalysisHistory: updatedHistory);
          await saveMenuAnalysisHistory();
          logger.info('メニュー解析履歴の画像の移行が完了しました');
        } else {
          logger.info('変更はありませんでした');
        }
      } else {
        logger.info('メニュー解析履歴がまだ存在しません');
      }
    } catch (e) {
      logger.shout('メニュー解析履歴の画像の移行に失敗しました: $e');
    }
  }

  // 店舗名を設定する
  Future<void> setStoreName(String historyId, String storeName) async {
    try {
      final updatedHistory = state.menuAnalysisHistory.map((item) {
        if (item.id == historyId) {
          return MenuAnalysisHistoryItem(
            id: item.id,
            date: item.date,
            storeName: storeName,
            sakes: item.sakes,
            imagePath: item.imagePath,     // 画像パスを保持
            base64Image: item.base64Image, // base64エンコードデータを保持
          );
        }
        return item;
      }).toList();

      state = state.copyWith(
        menuAnalysisHistory: updatedHistory,
        isEditingStoreName: false,
      );

      // 永続化
      await saveMenuAnalysisHistory();

      logger.info('店舗名を設定しました: $historyId, $storeName');
    } catch (e) {
      logger.shout('店舗名の設定に失敗しました: $e');
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

      // 状態を更新
      state = state.copyWith(menuAnalysisHistory: updatedHistory);

      // 永続化
      await saveMenuAnalysisHistory();

      logger.info('メニュー解析履歴を削除しました: $historyId');
    } catch (e) {
      logger.shout('メニュー解析履歴の削除に失敗しました: $e');
    }
  }
}
