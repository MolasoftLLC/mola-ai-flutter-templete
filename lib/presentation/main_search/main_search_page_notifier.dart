import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../common/logger.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/mola_api_repository.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';

part 'main_search_page_notifier.freezed.dart';

@freezed
abstract class MainSearchPageState with _$MainSearchPageState {
  const factory MainSearchPageState({
    @Default(false) bool isLoading,
    String? sakeName,
    String? sakeType,
    Sake? sakeInfo,
    String? errorMessage,
  }) = _MainSearchPageState;
}

class MainSearchPageNotifier extends StateNotifier<MainSearchPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  MainSearchPageNotifier({
    required this.context,
  }) : super(const MainSearchPageState());

  final BuildContext context;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();

  MolaApiRepository get molaApiRepository => read<MolaApiRepository>();
  SakeMenuRecognitionRepository get sakeMenuRecognitionRepository =>
      read<SakeMenuRecognitionRepository>();

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

  void setSakeName(String name) {
    state = state.copyWith(sakeName: name);
  }

  void setSakeType(String type) {
    state = state.copyWith(sakeType: type);
  }

  Future<void> searchSake() async {
    final sakeName = state.sakeName;
    if (sakeName == null || sakeName.isEmpty) {
      state = state.copyWith(
        errorMessage: '日本酒名を入力してください',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      sakeInfo: null,
    );

    try {
      final sakeInfo = await sakeMenuRecognitionRepository.getSakeInfo(
        sakeName,
        type: state.sakeType,
      );

      if (sakeInfo == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '日本酒情報が見つかりませんでした',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        sakeInfo: sakeInfo,
      );
    } catch (e) {
      logger.info('日本酒情報の取得に失敗: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '日本酒情報の取得に失敗しました',
      );
    }
  }

  // タイプをタップして検索するためのメソッド
  Future<void> searchByNameAndType({
    required String sakeName,
    required String sakeType,
  }) async {
    // 状態を更新
    state = state.copyWith(
      sakeName: sakeName,
      sakeType: sakeType,
      isLoading: true,
      errorMessage: null,
      sakeInfo: null,
    );

    try {
      final sakeInfo = await sakeMenuRecognitionRepository.getSakeInfo(
        sakeName,
        type: sakeType,
      );

      if (sakeInfo == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: '日本酒情報が見つかりませんでした',
        );
        return;
      }

      state = state.copyWith(
        isLoading: false,
        sakeInfo: sakeInfo,
      );
    } catch (e) {
      logger.info('日本酒情報の取得に失敗: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: '日本酒情報の取得に失敗しました',
      );
    }
  }
}
