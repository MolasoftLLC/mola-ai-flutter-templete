import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/menu_analysis_history.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/shared_key.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/shared_preference.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/logger.dart';
import '../../common/utils/ad_utils.dart';
import '../../common/utils/custom_image_picker.dart';
import '../../common/services/background_service.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';

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
    
    // メニュー解析履歴を読み込む
    await loadMenuAnalysisHistory();
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
    final imageFile = await CustomImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      state = state.copyWith(sakeImage: imageFile);
    }
  }

  Future<void> pickImageFromCamera() async {
    // Use CustomImagePicker to avoid READ_MEDIA_IMAGES permission
    final imageFile = await CustomImagePicker.pickImage(source: ImageSource.camera);
    if (imageFile != null) {
      // Save image to gallery
      try {
        await ImageGallerySaver.saveFile(imageFile.path);
        logger.info('画像をギャラリーに保存しました: ${imageFile.path}');
      } catch (e) {
        logger.shout('ギャラリーへの画像保存に失敗しました: $e');
      }
      
      state = state.copyWith(sakeImage: imageFile);
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

  /// バックグラウンド処理用のメニュー解析メソッド
  /// 
  /// このメソッドはフォアグラウンドで実行されるリポジトリメソッドを呼び出します
  /// 実際のAPI処理はリポジトリクラスに委譲します
  static Future<List<Sake>?> _backgroundMenuAnalysis(File file) async {
    try {
      if (!file.existsSync()) {
        print('File does not exist: ${file.path}');
        return null;
      }
      
      // 注意: このメソッドは実際にはバックグラウンドで実行されず、
      // フォアグラウンドでのAPI処理を開始するためのプレースホルダーとして機能します
      // 実際のAPI処理は_extractSakeInfoInForegroundメソッドで行われます
      
      // 処理中であることを示すためのダミー遅延
      await Future.delayed(Duration(milliseconds: 100));
      
      // nullを返すことで、_extractSakeInfoInForegroundメソッドが呼び出されるようにします
      return null;
    } catch (e) {
      print('Error in background menu analysis: $e');
      return null;
    }
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
    );

    try {
      // 広告のロードを開始
      try {
        final rewardedAd = await AdUtils.loadRewardedAd(
          onAdLoaded: (ad) {
            logger.info('リワード広告がロードされました');
          },
          onAdDismissed: () {
            logger.info('リワード広告が閉じられました');
            state = state.copyWith(isAdLoading: false);
            
            // 広告が閉じられた後、APIの結果が既に取得されていれば詳細情報を取得
            if (state.extractedSakes.isNotEmpty) {
              _fetchSakeDetails(state.extractedSakes);
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
          // バックグラウンドでメニュー解析を開始
          state = state.copyWith(isAnalyzingInBackground: true);
          
          // API処理を開始（広告表示と並行して実行）
          // 注意: 広告表示中にAPI処理を行い、広告終了後に結果を表示します
          final apiProcessing = sakeMenuRecognitionRepository.extractSakeInfo(imageFile);
          
          // 広告表示と並行してAPI処理を実行
          apiProcessing.then((extractedSakes) {
            if (extractedSakes != null && extractedSakes.isNotEmpty) {
              // 結果を処理（広告が閉じられた後に表示）
              state = state.copyWith(
                extractedSakes: extractedSakes,
                isAnalyzingInBackground: false,
                isLoading: false,
                isExtractingInfo: false,
              );
              
              // 各日本酒の読み込み状態を初期化
              final Map<String, bool> initialLoadingStatus = {};
              for (final sake in extractedSakes) {
                if (sake.name != null) {
                  initialLoadingStatus[sake.name!] = false; // false = まだ読み込んでいない
                }
              }
              
              state = state.copyWith(
                sakeLoadingStatus: initialLoadingStatus,
              );
              
              // 詳細情報の取得は広告が閉じられた後に開始
              // 注意: onAdDismissedでも同じチェックを行うため、ここでは広告がまだ表示中の場合のみ何もしない
              if (!state.isAdLoading) {
                _fetchSakeDetails(extractedSakes);
              }
            } else {
              // API処理に失敗した場合
              if (!state.isAdLoading) {
                // 広告が既に閉じられている場合はエラーメッセージを表示
                state = state.copyWith(
                  isLoading: false,
                  isExtractingInfo: false,
                  isAnalyzingInBackground: false,
                  errorMessage: '日本酒情報を抽出できませんでした',
                );
              }
            }
          }).catchError((e) {
            logger.shout('API処理でエラーが発生しました: $e');
            if (!state.isAdLoading) {
              // 広告が既に閉じられている場合はエラーメッセージを表示
              state = state.copyWith(
                isLoading: false,
                isExtractingInfo: false,
                isAnalyzingInBackground: false,
                errorMessage: '日本酒情報の抽出に失敗しました: $e',
              );
            }
          });
          
          // 広告を表示
          try {
            await AdUtils.showRewardedAd(
              rewardedAd,
              onUserEarnedReward: (reward) {
                logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
              },
            );
            
            // 広告が閉じられた後、APIの結果が既に取得されていれば詳細情報を取得
            if (!state.isAnalyzingInBackground && state.extractedSakes.isNotEmpty) {
              _fetchSakeDetails(state.extractedSakes);
            }
          } catch (e) {
            logger.shout('広告の表示に失敗しました: $e');
            // 広告の表示に失敗した場合も、バックグラウンド処理は続行
          }
          
          return; // バックグラウンド処理を開始したので、ここで終了
        }
      } catch (e) {
        logger.shout('広告処理でエラーが発生しました: $e');
        state = state.copyWith(isAdLoading: false);
      }
      
      // 広告のロードに失敗した場合や広告がnullの場合は、通常の処理を続行
      await _extractSakeInfoInForeground(imageFile);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
        isGettingDetails: false,
        isAdLoading: false,
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
              
              // 現在のsakesリストに新しい情報を追加
              final List<Sake> currentSakes = state.sakes ?? [];
              final List<Sake> updatedSakes = [...currentSakes, sakeInfo];
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
  
  // 日本酒リストが表示された後にスクロールしたかどうかを設定
  void setHasScrolledToResults(bool value) {
    state = state.copyWith(hasScrolledToResults: value);
  }
  
  // メニュー解析履歴を読み込む
  Future<void> loadMenuAnalysisHistory() async {
    try {
      final historyJson = await SharedPreference.getString(MENU_ANALYSIS_HISTORY);
      if (historyJson != null && historyJson.isNotEmpty) {
        final List<dynamic> historyList = jsonDecode(historyJson);
        final List<MenuAnalysisHistoryItem> history = historyList
            .map((item) => MenuAnalysisHistoryItem.fromJson(item))
            .toList();
        
        // 日付の新しい順に並べ替え
        history.sort((a, b) => b.date.compareTo(a.date));
        
        // 最大20件まで保存
        final limitedHistory = history.length > 20 ? history.sublist(0, 20) : history;
        
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
      await SharedPreference.setString(MENU_ANALYSIS_HISTORY, historyJson);
    } catch (e) {
      logger.shout('メニュー解析履歴の保存に失敗しました: $e');
    }
  }
  
  // 現在の解析結果をメニュー解析履歴に追加する
  Future<void> addCurrentAnalysisToHistory() async {
    if (state.sakes == null || state.sakes!.isEmpty) return;
    
    try {
      // 現在の日本酒情報から保存用のデータを作成
      final List<SavedSake> savedSakes = state.sakes!.map((sake) => SavedSake(
        name: sake.name ?? '不明な日本酒',
        type: sake.type,
        isRecommended: sake.isRecommended ?? false,
      )).toList();
      
      // 新しい履歴項目を作成
      final newHistoryItem = MenuAnalysisHistoryItem(
        id: 'history_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}',
        date: DateTime.now(),
        sakes: savedSakes,
      );
      
      // 現在の履歴に追加
      final updatedHistory = [
        newHistoryItem,
        ...state.menuAnalysisHistory,
      ];
      
      // 最大20件まで保存
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
}
