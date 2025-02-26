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

          // Use the new repository for menu image uploads
          final sakeMenuRecognitionResponse = await sakeMenuRecognitionRepository.recognizeMenu(
            state.sakeImage!,
          );
          if (sakeMenuRecognitionResponse != null) {
            // Convert the SakeMenuRecognitionResponse to OpenAIResponse for compatibility
            final openAIRes = sakeMenuRecognitionResponse.sakes.map((sake) {
              final description = <String, String>{
                '特徴': sake.taste,
                '辛口か甘口か': sake.sakeMeterValue > 0 ? '辛口' : '甘口',
                '酒造情報': sake.brewery,
                '日本酒度合い': sake.sakeMeterValue.toString(),
                '使用米': '',
                'バリエーション': sake.types.join(', '),
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
            final openAIRes = await molaApiRepository.promptWithMenuByOpenAI(
              state.sakeImage!,
              favoriteNotifier.state.myFavoriteList,
            );
            state = state.copyWith(openAiResponseList: openAIRes);
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
      state = state.copyWith(
        isLoading: false,
        sakeImage: null,
      );
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
}
