import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

part 'image_search_page_notifier.freezed.dart';

@freezed
abstract class ImageSearchPageState with _$ImageSearchPageState {
  const factory ImageSearchPageState(
      {@Default(false) bool isLoading,
      String? hint,
      File? sakeImage,
      String? geminiResponse,
      @Default(true) bool canUse}) = _ImageSearchPageState;
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
        /// TODO:最終的に課金した人のみにしよう
        response = await geminiMolaApiRepository.promptWithImageByOpenAI(
          state.sakeImage!,
          state.hint,
        );
      } else {
        response = await geminiMolaApiRepository.promptWithImage(
          state.sakeImage!,
          state.hint,
        );
      }
      state = state.copyWith(
        isLoading: false,
        sakeImage: null,
      );
      state = state.copyWith(geminiResponse: response);
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
