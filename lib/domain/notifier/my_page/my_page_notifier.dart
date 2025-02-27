import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../../domain/repository/gemini_mola_api_repository.dart';

part 'my_page_notifier.freezed.dart';

@freezed
abstract class MyPageState with _$MyPageState {
  const factory MyPageState({
    @Default(false) bool isLoading,
    String? sakeName,
    String? hint,
    File? sakeImage,
    String? geminiResponse,
    String? preferences,
    // TextEditingControllerはfreezedで管理できないため、別途保持
  }) = _MyPageState;
}

class MyPageNotifier extends StateNotifier<MyPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  MyPageNotifier() : super(const MyPageState()) {
    _loadPreferences();
    // TextEditingControllerの初期化
    _preferencesController = TextEditingController(text: state.preferences);
    // リスナーを追加して、コントローラーの変更をStateに反映
    _preferencesController.addListener(_updatePreferencesFromController);
  }

  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();
  
  // TextEditingControllerをNotifier内で管理
  late final TextEditingController _preferencesController;
  
  // コントローラーを外部から取得するためのゲッター
  TextEditingController get preferencesController => _preferencesController;

  // コントローラーの変更をStateに反映するリスナー
  void _updatePreferencesFromController() {
    if (_preferencesController.text != state.preferences) {
      state = state.copyWith(preferences: _preferencesController.text);
    }
  }

  @override
  Future<void> initState() async {
    super.initState();
  }

  @override
  void dispose() {
    // コントローラーのリスナーを削除してからdispose
    _preferencesController.removeListener(_updatePreferencesFromController);
    _preferencesController.dispose();
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

  // 好みの設定を読み込む
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPreferences = prefs.getString('sake_preferences');
    if (savedPreferences != null) {
      state = state.copyWith(preferences: savedPreferences);
      // コントローラーのテキストも更新
      _preferencesController.text = savedPreferences;
    }
  }

  // 好みの設定を保存する
  Future<void> savePreferences() async {
    if (state.preferences != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('sake_preferences', state.preferences!);
    }
  }

  // 好みの設定を更新する
  void setPreferences(String preferences) {
    // Stateを更新
    state = state.copyWith(preferences: preferences);
    
    // コントローラーのテキストも更新（カーソル位置を維持するため、
    // 現在のテキストと異なる場合のみ更新）
    if (_preferencesController.text != preferences) {
      final currentPosition = _preferencesController.selection.baseOffset;
      _preferencesController.text = preferences;
      
      // カーソル位置を復元（テキストの長さを超えないように）
      if (currentPosition >= 0 && currentPosition <= preferences.length) {
        _preferencesController.selection = TextSelection.fromPosition(
          TextPosition(offset: currentPosition),
        );
      }
    }
  }
} 