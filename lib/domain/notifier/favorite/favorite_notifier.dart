import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:mola_gemini_flutter_template/common/logger.dart';
import '../../../infrastructure/local_database/shared_key.dart';
import '../../../infrastructure/local_database/shared_preference.dart';
import '../../repository/auth_repository.dart';
import '../../repository/favorite_sync_repository.dart';
import '../../repository/gemini_mola_api_repository.dart';

part 'favorite_notifier.freezed.dart';

// お気に入りの日本酒情報を保持するクラス
class FavoriteSake {
  final String name;
  final String? type;

  FavoriteSake({required this.name, this.type});

  // JSONからオブジェクトを生成
  factory FavoriteSake.fromJson(Map<String, dynamic> json) {
    return FavoriteSake(
      name: json['name'] as String,
      type: json['type'] as String?,
    );
  }

  // オブジェクトをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteSake && other.name == name && other.type == type;
  }

  @override
  int get hashCode => name.hashCode ^ (type?.hashCode ?? 0);
}

@freezed
abstract class FavoriteState with _$FavoriteState {
  const factory FavoriteState({
    @Default([]) List<FavoriteSake> myFavoriteList,
  }) = _FavoriteState;
}

class FavoriteNotifier extends StateNotifier<FavoriteState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  FavoriteNotifier() : super(const FavoriteState()) {
    _loadFavorites();
    Future.microtask(_loadRemoteIfLoggedIn);
  }

  static const int guestFavoriteLimit = 8;
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();

  AuthRepository get _authRepository => read<AuthRepository>();
  FavoriteSyncRepository get _favoriteSyncRepository =>
      read<FavoriteSyncRepository>();
  bool get _isGuest => _authRepository.currentUser == null;

  static const _favoriteMigrationUserKey = 'favoriteMigratedUserId';

  bool get hasReachedGuestLimit =>
      _isGuest && state.myFavoriteList.length >= guestFavoriteLimit;

  @override
  Future<void> initState() async {
    super.initState();
    await fetchFavorites();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  SharedPreference get sharedPreference => read<SharedPreference>();

  // お気に入りリストを読み込む
  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = prefs.getStringList('favorites') ?? [];

    final favorites = favoritesJson.map((json) {
      return FavoriteSake.fromJson(jsonDecode(json));
    }).toList();

    state = state.copyWith(myFavoriteList: favorites);
  }

  // お気に入りリストを保存する
  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesJson = state.myFavoriteList.map((sake) {
      return jsonEncode(sake.toJson());
    }).toList();

    await prefs.setStringList('favorites', favoritesJson);
  }

  // お気に入りに追加または削除
  Future<void> addOrRemoveFavorite(FavoriteSake favoriteSake) async {
    // 既に同じ名前とタイプの組み合わせが存在するか確認
    final exists = state.myFavoriteList.any((item) =>
        item.name == favoriteSake.name && item.type == favoriteSake.type);

    Future<void> applyLocalChange() async {
      if (!exists && hasReachedGuestLimit) {
        throw const FavoriteGuestLimitReachedException();
      }
      if (exists) {
        final updatedList = state.myFavoriteList
            .where((item) => !(item.name == favoriteSake.name &&
                item.type == favoriteSake.type))
            .toList();
        state = state.copyWith(myFavoriteList: updatedList);
      } else {
        final updatedList = [...state.myFavoriteList, favoriteSake];
        state = state.copyWith(myFavoriteList: updatedList);
      }
      await _saveFavorites();
    }

    if (_isGuest) {
      await applyLocalChange();
      return;
    }

    final user = _authRepository.currentUser;
    if (user == null) {
      logger.warning('ログイン情報が取得できず、お気に入り操作をローカル処理に切り替えます');
      await applyLocalChange();
      return;
    }

    if (exists) {
      final success = await _favoriteSyncRepository.removeFavorite(
        userId: user.uid,
        sake: favoriteSake,
      );
      if (!success) {
        logger.warning('お気に入りの削除に失敗しました (remote)');
        return;
      }
      final updatedList = state.myFavoriteList
          .where((item) => !(item.name == favoriteSake.name &&
              item.type == favoriteSake.type))
          .toList();
      state = state.copyWith(myFavoriteList: updatedList);
    } else {
      final success = await _favoriteSyncRepository.addFavorite(
        userId: user.uid,
        sake: favoriteSake,
      );
      if (!success) {
        logger.warning('お気に入りの追加に失敗しました (remote)');
        return;
      }
      final updatedList = [...state.myFavoriteList, favoriteSake];
      state = state.copyWith(myFavoriteList: updatedList);
    }

    await _saveFavorites();
  }

  // お気に入りかどうかを確認
  bool isFavorite(String name, String? type) {
    return state.myFavoriteList
        .any((item) => item.name == name && item.type == type);
  }

  // 後方互換性のために残しておく（既存のコードが壊れないように）
  // 新しいコードでは使用しないでください
  @Deprecated('Use addOrRemoveFavorite instead')
  Future<void> addOrRemoveString(String name) async {
    final favoriteSake = FavoriteSake(
      name: name,
      type: '',
    );

    await addOrRemoveFavorite(favoriteSake);
  }

  Future<void> fetchFavorites() async {
    final favoriteStrings =
        await sharedPreference.getStringList(key: FAVORITE_SAKE_LIST) ?? [];

    // 文字列リストをFavoriteSakeオブジェクトのリストに変換
    final List<FavoriteSake> favoriteSakes =
        favoriteStrings.map((favoriteString) {
      try {
        // JSONとして解析を試みる
        final Map<String, dynamic> json = jsonDecode(favoriteString);
        return FavoriteSake.fromJson(json);
      } catch (e) {
        // 古い形式（文字列のみ）の場合は名前だけのFavoriteSakeを作成
        return FavoriteSake(name: favoriteString, type: null);
      }
    }).toList();

    state = state.copyWith(myFavoriteList: favoriteSakes);
    logger.shout('お気に入りリスト読み込み完了: ${state.myFavoriteList.length}件');
  }

  Future<void> _loadRemoteIfLoggedIn() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      return;
    }
    await _loadFavoritesFromServer(user.uid);
  }

  Future<void> _loadFavoritesFromServer(String userId) async {
    final remoteFavorites =
        await _favoriteSyncRepository.fetchFavorites(userId);
    if (remoteFavorites.isEmpty) {
      logger.info('サーバー上にお気に入りが存在しませんでした');
    }
    state = state.copyWith(myFavoriteList: remoteFavorites);
    await _saveFavorites();
    logger.info('サーバーのお気に入りを反映しました: ${remoteFavorites.length}件');
  }

  Future<void> refreshFromServer() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      return;
    }
    await _loadFavoritesFromServer(user.uid);
  }

  Future<void> reloadLocal() async {
    await _loadFavorites();
  }

  Future<void> onUserSignedIn(String userId) async {
    await _migrateLocalFavoritesIfNeeded(userId);
    await _loadFavoritesFromServer(userId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoriteMigrationUserKey, userId);
  }

  Future<void> onUserSignedOut() async {
    await _clearLocalFavorites();
    await _loadFavorites();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_favoriteMigrationUserKey, '');
  }

  Future<void> _migrateLocalFavoritesIfNeeded(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final migratedUser = prefs.getString(_favoriteMigrationUserKey) ?? '';
    if (migratedUser == userId) {
      return;
    }

    final localFavorites = [...state.myFavoriteList];
    if (localFavorites.isEmpty) {
      return;
    }

    for (final favorite in localFavorites) {
      final success = await _favoriteSyncRepository.addFavorite(
        userId: userId,
        sake: favorite,
      );
      if (!success) {
        logger.warning('お気に入りの移行に失敗しました: ${favorite.name}');
      }
    }

    await _clearLocalFavorites();
  }

  Future<void> _clearLocalFavorites() async {
    state = state.copyWith(myFavoriteList: const []);
    await _saveFavorites();
  }
}

class FavoriteGuestLimitReachedException implements Exception {
  const FavoriteGuestLimitReachedException();
}
