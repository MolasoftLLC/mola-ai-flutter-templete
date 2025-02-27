import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/favorite/favorite_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/logger.dart';
import '../../common/utils/ad_utils.dart';
import '../../common/services/background_service.dart';
import '../../domain/eintities/response/open_ai_response/open_ai_response.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/mola_api_repository.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';

part 'image_search_page_notifier.freezed.dart';

@freezed
abstract class ImageSearchPageState with _$ImageSearchPageState {
  const factory ImageSearchPageState({
    @Default(false) bool isLoading,
    @Default('メニュー') String hint,
    @Default('メニュー') String searchCategory,
    File? sakeImage,
    String? geminiResponse,
    @Default(true) bool canUse,
    @Default(false) bool isAdLoading,
    @Default(false) bool isAnalyzingInBackground,
    List<OpenAIResponse>? openAiResponseList,
    SakeMenuRecognitionResponse? sakeMenuRecognitionResponse,
  }) = _ImageSearchPageState;
}

class ImageSearchPageNotifier extends StateNotifier<ImageSearchPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  ImageSearchPageNotifier({
    required this.context,
  }) : super(const ImageSearchPageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();
  MolaApiRepository get molaApiRepository => read<MolaApiRepository>();
  SakeMenuRecognitionRepository get sakeMenuRecognitionRepository =>
      read<SakeMenuRecognitionRepository>();

  FavoriteNotifier get favoriteNotifier => read<FavoriteNotifier>();
  @override
  Future<void> initState() async {
    super.initState();
    final count = await geminiMolaApiRepository.checkApiUseCount();
    if (count > 100) {
      state = state.copyWith(canUse: false);
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

  Future<void> promptWithImage(bool isOpenAi) async {
    if (state.sakeImage == null) {
      return;
    }
    if (state.isLoading == true) {
      return;
    }
    
    state = state.copyWith(isLoading: true);
    
    if (state.sakeImage != null) {
      var response = '';
      if (isOpenAi) {
        state = state.copyWith(searchCategory: state.hint);
        if (state.hint == 'メニュー') {
          logger.shout('メニュー検索');
          
          // 広告のロードを開始
          state = state.copyWith(isAdLoading: true);
          
          // 広告をロード
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
              
              // 広告のロードに失敗した場合は、通常の処理を続行
              _analyzeMenuInForeground();
            },
            onUserEarnedReward: (reward) {
              logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
            },
          );
          
          if (rewardedAd != null) {
            // バックグラウンドでメニュー解析を開始
            _analyzeMenuInBackground();
            
            // 広告を表示
            await AdUtils.showRewardedAd(
              rewardedAd,
              onUserEarnedReward: (reward) {
                logger.info('ユーザーが報酬を獲得しました: ${reward.amount}');
              },
            );
          } else {
            // 広告のロードに失敗した場合は、通常の処理を続行
            _analyzeMenuInForeground();
          }
        } else {
          /// TODO:最終的に課金した人のみにしよう
          final openAIRes = await molaApiRepository.promptWithImageByOpenAI(
            state.sakeImage!,
            state.hint,
          );
          state = state.copyWith(openAiResponseList: openAIRes);
        }
      } else {
        response = await geminiMolaApiRepository.promptWithImage(
          state.sakeImage!,
          state.hint,
        );
        state = state.copyWith(geminiResponse: response);
      }
      
      if (!state.isAnalyzingInBackground) {
        state = state.copyWith(
          isLoading: false,
          sakeImage: null,
        );
      }
    }
  }

  void setText(String text) {
    state = state.copyWith(hint: text);
  }

  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      state = state.copyWith(sakeImage: File(pickedFile.path));
    }
  }

  Future<void> pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      state = state.copyWith(sakeImage: File(pickedFile.path));
    }
  }

  void clearImage() {
    state = state.copyWith(sakeImage: null);
  }
  
  /// フォアグラウンドでメニュー解析を実行する
  Future<void> _analyzeMenuInForeground() async {
    if (state.sakeImage == null) return;
    
    try {
      // 通常の処理を実行
      final sakeMenuRecognitionResponse =
          await sakeMenuRecognitionRepository.recognizeMenu(
        state.sakeImage!,
      );
      
      if (sakeMenuRecognitionResponse != null) {
        // Convert the SakeMenuRecognitionResponse to OpenAIResponse for compatibility
        final openAIRes = sakeMenuRecognitionResponse.sakes!.map((sake) {
          final description = <String, String>{
            '特徴': sake.taste!,
            '辛口か甘口か': sake.sakeMeterValue! > 0 ? '辛口' : '甘口',
            '酒造情報': sake.brewery!,
            '日本酒度合い': sake.sakeMeterValue.toString(),
            '使用米': '',
            'バリエーション': sake.types!.join(', '),
            'アルコール度': '',
          };
          return OpenAIResponse(
            title: sake.name,
            description: description,
          );
        }).toList();
        
        state = state.copyWith(
          openAiResponseList: openAIRes,
          sakeMenuRecognitionResponse: sakeMenuRecognitionResponse,
        );
      } else {
        // Fallback to the old API if the new one fails
        await _fallbackToOpenAI();
      }
    } catch (e) {
      logger.shout('メニュー解析でエラーが発生しました: $e');
      await _fallbackToOpenAI();
    } finally {
      state = state.copyWith(
        isLoading: false,
        sakeImage: null,
      );
    }
  }
  
  /// バックグラウンドでメニュー解析を実行する
  Future<void> _analyzeMenuInBackground() async {
    if (state.sakeImage == null) return;
    
    state = state.copyWith(isAnalyzingInBackground: true);
    
    try {
      // バックグラウンドで処理を実行
      final result = await BackgroundService.compute<File, SakeMenuRecognitionResponse?>(
        _backgroundMenuAnalysis,
        state.sakeImage!,
      );
      
      if (result != null) {
        // 結果を処理
        final openAIRes = result.sakes!.map((sake) {
          final description = <String, String>{
            '特徴': sake.taste!,
            '辛口か甘口か': sake.sakeMeterValue! > 0 ? '辛口' : '甘口',
            '酒造情報': sake.brewery!,
            '日本酒度合い': sake.sakeMeterValue.toString(),
            '使用米': '',
            'バリエーション': sake.types!.join(', '),
            'アルコール度': '',
          };
          return OpenAIResponse(
            title: sake.name,
            description: description,
          );
        }).toList();
        
        state = state.copyWith(
          openAiResponseList: openAIRes,
          sakeMenuRecognitionResponse: result,
          isAnalyzingInBackground: false,
          isLoading: false,
          sakeImage: null,
        );
      } else {
        // バックグラウンド処理が失敗した場合は、フォールバック処理
        await _fallbackToOpenAI();
      }
    } catch (e) {
      logger.shout('バックグラウンド処理でエラーが発生しました: $e');
      await _fallbackToOpenAI();
    }
  }
  
  /// バックグラウンド処理用のメニュー解析メソッド
  static Future<SakeMenuRecognitionResponse?> _backgroundMenuAnalysis(File file) async {
    try {
      // このメソッドはバックグラウンドで実行されるため、
      // 直接リポジトリにアクセスできない。
      // 実際の実装では、APIクライアントを直接使用するか、
      // 必要なデータをMenuAnalysisDataクラスで渡す必要がある。
      
      // 注意: この実装はサンプルです。実際の実装では、
      // APIクライアントを直接使用するなどの対応が必要です。
      return null;
    } catch (e) {
      return null;
    }
  }
  
  /// OpenAIのAPIを使用したフォールバック処理
  Future<void> _fallbackToOpenAI() async {
    try {
      if (state.sakeImage == null) return;
      
      final openAIRes = await molaApiRepository.promptWithMenuByOpenAI(
        state.sakeImage!,
        favoriteNotifier.state.myFavoriteList,
      );
      
      state = state.copyWith(
        openAiResponseList: openAIRes,
        isAnalyzingInBackground: false,
        isLoading: false,
        sakeImage: null,
      );
    } catch (e) {
      logger.shout('OpenAIフォールバック処理でエラーが発生しました: $e');
      state = state.copyWith(
        isAnalyzingInBackground: false,
        isLoading: false,
        sakeImage: null,
      );
    }
  }
}
