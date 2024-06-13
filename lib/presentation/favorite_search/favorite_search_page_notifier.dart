import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../domain/eintities/response/open_ai_response/open_ai_response.dart';

part 'favorite_search_page_notifier.freezed.dart';

@freezed
abstract class FavoriteSearchPageState with _$FavoriteSearchPageState {
  const factory FavoriteSearchPageState({
    @Default(false) bool isLoading,
    String? sakeName,
    String? hint,
    File? sakeImage,
    double? nihonshudo,
    String? selectedPrefecture,
    List<String>? selectedFlavors,
    List<String>? selectedTastes,
    List<String>? selectedDesigns,
    String? geminiResponse,
    List<OpenAIResponse>? openAiResponseList,
  }) = _FavoriteSearchPageState;
}

class FavoriteSearchPageNotifier extends StateNotifier<FavoriteSearchPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  FavoriteSearchPageNotifier({
    required this.context,
  }) : super(const FavoriteSearchPageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();

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

  Future<void> promptWithFavorite() async {
    state = state.copyWith(isLoading: true);
    final isEmpty = checkEmpty();
    if (isEmpty) {
      state = state.copyWith(
        isLoading: false,
      );
      return;
    }
    final response = await geminiMolaApiRepository.promptWithFavorite(
      flavors: state.selectedFlavors,
      designs: state.selectedDesigns,
      tastes: state.selectedTastes,
      prefecture: state.selectedPrefecture,
    );
    state = state.copyWith(
      isLoading: false,
    );
    state = state.copyWith(geminiResponse: response);
  }

  bool checkEmpty() {
    if (state.selectedDesigns != null) {
      if (state.selectedDesigns!.isNotEmpty) {
        return false;
      }
      return false;
    }
    if (state.selectedTastes != null) {
      if (state.selectedTastes!.isNotEmpty) {
        return false;
      }
      return false;
    }
    if (state.selectedPrefecture != null) {
      return false;
    }
    if (state.selectedFlavors != null) {
      if (state.selectedFlavors!.isNotEmpty) {
        return false;
      }
      return false;
    }
    return true;
  }

  void setPrefecture(String? value) {
    state = state.copyWith(selectedPrefecture: value);
  }

  void toggleSelectedFlavor(String flavor) {
    if (state.selectedFlavors != null) {
      final newSelectedFlavors = List<String>.from(state.selectedFlavors!);
      if (newSelectedFlavors.contains(flavor)) {
        newSelectedFlavors.removeWhere((value) => flavor == value);
      } else {
        newSelectedFlavors.add(flavor);
      }
      state = state.copyWith(selectedFlavors: newSelectedFlavors);
    } else {
      state = state.copyWith(selectedFlavors: [flavor]);
    }
  }

  void toggleSelectedTaste(String taste) {
    if (state.selectedTastes != null) {
      final newSelectedTastes = List<String>.from(state.selectedTastes!);
      if (newSelectedTastes.contains(taste)) {
        newSelectedTastes.removeWhere((value) => taste == value);
      } else {
        newSelectedTastes.add(taste);
      }
      state = state.copyWith(selectedTastes: newSelectedTastes);
    } else {
      state = state.copyWith(selectedTastes: [taste]);
    }
  }

  void toggleSelectedDesigns(String design) {
    if (state.selectedDesigns != null) {
      final newSelectedDesigns = List<String>.from(state.selectedDesigns!);
      if (newSelectedDesigns.contains(design)) {
        newSelectedDesigns.removeWhere((value) => design == value);
      } else {
        newSelectedDesigns.add(design);
      }
      state = state.copyWith(selectedDesigns: newSelectedDesigns);
    } else {
      state = state.copyWith(selectedDesigns: [design]);
    }
  }
}
