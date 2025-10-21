import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:mola_gemini_flutter_template/common/logger.dart';
import '../../repository/gemini_mola_api_repository.dart';
import '../../repository/mola_api_repository.dart';
import '../../repository/auth_repository.dart';
import '../favorite/favorite_notifier.dart';
import '../../repository/sake_menu_recognition_repository.dart';
import '../../repository/user_preference_repository.dart';
import '../../repository/sake_user_repository.dart';

part 'my_page_notifier.freezed.dart';

@freezed
abstract class MyPageState with _$MyPageState {
  const factory MyPageState({
    @Default(false) bool isLoading,
    String? sakeName,
    String? hint,
    File? sakeImage,
    String? geminiResponse,
    String? userName,
    String? preferences,
    String? sakePreferenceAnalysis,
    // TextEditingControllerはfreezedで管理できないため、別途保持
  }) = _MyPageState;
}

class MyPageNotifier extends StateNotifier<MyPageState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  MyPageNotifier() : super(const MyPageState()) {
    _loadLocalPreferences();
    // TextEditingControllerの初期化
    _preferencesController = TextEditingController(text: state.preferences);
    // リスナーを追加して、コントローラーの変更をStateに反映
    _preferencesController.addListener(_updatePreferencesFromController);
    Future.microtask(_loadRemoteIfLoggedIn);
  }

  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();

  MolaApiRepository get molaApiRepository => read<MolaApiRepository>();
  SakeMenuRecognitionRepository get sakeMenuRecognitionRepository =>
      read<SakeMenuRecognitionRepository>();
  AuthRepository get _authRepository => read<AuthRepository>();
  UserPreferenceRepository get _userPreferenceRepository =>
      read<UserPreferenceRepository>();
  SakeUserRepository get _sakeUserRepository => read<SakeUserRepository>();
  bool get _isGuest => _authRepository.currentUser == null;

  static const _preferencesMigrationUserKey = 'preferencesMigratedUserId';

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
  Future<void> _loadLocalPreferences() async {
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
      if (!_isGuest) {
        final user = _authRepository.currentUser;
        if (user != null) {
          final success = await _userPreferenceRepository.updatePreferences(
            userId: user.uid,
            preferences: state.preferences!,
          );
          if (!success) {
            logger.warning('好み設定のリモート更新に失敗しました');
          }
        }
      }
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

  // お酒診断の結果を取得する
  Future<void> analyzeSakePreference(List<FavoriteSake> sakes) async {
    if (sakes.isEmpty) {
      logger.info('お気に入りが空のため、好み分析は実行されません');
      return;
    }

    state = state.copyWith(isLoading: true);

    final preference =
        await sakeMenuRecognitionRepository.analyzeSakePreference(sakes);

    state = state.copyWith(
      isLoading: false,
      sakePreferenceAnalysis: preference,
    );
  }

  // お酒診断の結果を好みの設定として保存する
  void saveSakePreferenceAsPreferences() {
    if (state.sakePreferenceAnalysis != null) {
      setPreferences(state.sakePreferenceAnalysis!);
      savePreferences();
    }
  }

  Future<void> _loadRemoteIfLoggedIn() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      return;
    }
    await refreshPreferencesFromServer();
    await fetchUserProfile();
  }

  Future<void> refreshPreferencesFromServer() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      return;
    }

    final remote = await _userPreferenceRepository.fetchPreferences(user.uid);
    if (remote == null) {
      logger.info('サーバー上に好み設定が存在しませんでした');
      return;
    }

    if (state.preferences != remote) {
      state = state.copyWith(preferences: remote);
    }
    if (_preferencesController.text != remote) {
      _preferencesController.text = remote;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sake_preferences', remote);
    logger.info('好み設定をサーバーから同期しました');
  }

  Future<void> reloadPreferencesFromLocal() async {
    await _loadLocalPreferences();
  }

  Future<void> onUserSignedIn(String userId) async {
    await _migrateLocalPreferencesIfNeeded(userId);
    await refreshPreferencesFromServer();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferencesMigrationUserKey, userId);
    await fetchUserProfile();
  }

  Future<void> onUserSignedOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferencesMigrationUserKey, '');
    await prefs.remove('sake_preferences');
    state = state.copyWith(
      preferences: null,
      userName: null,
    );
    if (_preferencesController.text.isNotEmpty) {
      _preferencesController.text = '';
    }
  }

  Future<void> fetchUserProfile() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      state = state.copyWith(userName: null);
      return;
    }

    final remote = await _sakeUserRepository.fetchUser(user.uid);
    String? resolvedName;

    if (remote != null) {
      final remoteUserName = remote['username'];
      if (remoteUserName is String && remoteUserName.trim().isNotEmpty) {
        resolvedName = remoteUserName.trim();
      } else {
        final displayName = remote['displayName'];
        if (displayName is String && displayName.trim().isNotEmpty) {
          resolvedName = displayName.trim();
        }
      }
    }

    resolvedName ??= user.displayName;
    resolvedName ??= user.email;

    state = state.copyWith(userName: resolvedName);
  }

  Future<bool> updateUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (trimmed.characters.length > 10) {
      logger.info('ユーザー名が10文字を超えています');
      return false;
    }

    final success = await _sakeUserRepository.updateUsername(trimmed);
    if (success) {
      state = state.copyWith(userName: trimmed);
      logger.info('ユーザー名を更新しました');
    } else {
      logger.warning('ユーザー名の更新に失敗しました');
    }
    return success;
  }

  Future<void> _migrateLocalPreferencesIfNeeded(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final migratedUser = prefs.getString(_preferencesMigrationUserKey) ?? '';
    if (migratedUser == userId) {
      return;
    }

    final localPreference =
        state.preferences ?? prefs.getString('sake_preferences');
    if (localPreference == null || localPreference.trim().isEmpty) {
      return;
    }

    final success = await _userPreferenceRepository.updatePreferences(
      userId: userId,
      preferences: localPreference,
    );
    if (success) {
      logger.info('好み設定をサーバーへ移行しました');
    } else {
      logger.warning('好み設定のサーバー移行に失敗しました');
    }
  }
}
