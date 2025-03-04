import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

part 'my_favorite_page_notifier.freezed.dart';

@freezed
abstract class MyFavoritePageState with _$MyFavoritePageState {
  const factory MyFavoritePageState({
    @Default(false) bool isLoading,
    String? sakeName,
    String? hint,
    File? sakeImage,
    String? geminiResponse,
  }) = _MyFavoritePageState;
}

class MyFavoritePageNotifier extends StateNotifier<MyFavoritePageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  MyFavoritePageNotifier({
    required this.context,
  }) : super(const MyFavoritePageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();

  @override
  Future<void> initState() async {
    super.initState();
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
}
