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
    List<Map<String, dynamic>>? extractedSakes,
    SakeMenuRecognitionResponse? sakeMenuRecognitionResponse,
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

  Future<void> recognizeMenu() async {
    if (state.sakeImage == null) {
      return;
    }
    if (state.isLoading == true) {
      return;
    }
    
    // 画像から日本酒情報を抽出
    state = state.copyWith(isLoading: true, isExtractingInfo: true);
    
    final extractResponse = await sakeMenuRecognitionRepository.extractSakeInfo(
      state.sakeImage!,
    );
    
    if (extractResponse == null) {
      state = state.copyWith(
        isLoading: false,
        isExtractingInfo: false,
      );
      return;
    }
    
    final extractedSakes = (extractResponse['sakes'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    
    state = state.copyWith(
      isExtractingInfo: false,
      isGettingDetails: true,
      extractedSakes: extractedSakes,
    );
    
    // 抽出した日本酒情報から詳細情報を取得
    final detailsResponse = await sakeMenuRecognitionRepository.getSakeInfoBatch(
      extractedSakes,
    );
    
    state = state.copyWith(
      isLoading: false,
      isGettingDetails: false,
      sakeMenuRecognitionResponse: detailsResponse,
    );
  }
  
  // 従来のメソッド（バックアップ用）
  Future<void> recognizeMenuLegacy() async {
    if (state.sakeImage == null) {
      return;
    }
    if (state.isLoading == true) {
      return;
    }
    state = state.copyWith(isLoading: true);

    logger.shout(state.sakeImage);
    final response = await sakeMenuRecognitionRepository.recognizeMenu(
      state.sakeImage!,
    );

    state = state.copyWith(
      isLoading: false,
      sakeMenuRecognitionResponse: response,
    );
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
      extractedSakes: null,
      sakeMenuRecognitionResponse: null,
    );
  }
}
