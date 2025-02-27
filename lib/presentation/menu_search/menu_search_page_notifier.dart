import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/logger.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';

part 'menu_search_page_notifier.freezed.dart';

@freezed
abstract class MenuSearchPageState with _$MenuSearchPageState {
  const factory MenuSearchPageState({
    @Default(false) bool isLoading,
    @Default(false) bool isExtractingInfo,
    @Default(false) bool isGettingDetails,
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
    );

    try {
      // 画像から日本酒情報を抽出（直接List<Sake>を取得）
      final extractedSakes =
          await sakeMenuRecognitionRepository.extractSakeInfo(imageFile);

      if (extractedSakes == null || extractedSakes.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isExtractingInfo: false,
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
        extractedSakes: extractedSakes,
        sakeLoadingStatus: initialLoadingStatus,
      );

      // バックグラウンドで詳細情報を順次取得
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
              preferences: '甘口でフルーティ',
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
          print('日本酒情報の取得に失敗: ${extractedSake.name}, エラー: $e');
        }
      }

      // すべての詳細情報の取得が完了
      state = state.copyWith(isGettingDetails: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
        isGettingDetails: false,
        errorMessage: '日本酒情報の抽出に失敗しました: $e',
      );
    }
  }
}
