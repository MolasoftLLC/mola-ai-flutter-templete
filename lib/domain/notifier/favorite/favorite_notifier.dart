import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mola_gemini_flutter_template/domain/repository/gemini_mola_api_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../../common/logger.dart';
import '../../../infrastructure/local_database/shared_key.dart';
import '../../../infrastructure/local_database/shared_preference.dart';

part 'favorite_notifier.freezed.dart';

@freezed
abstract class FavoriteState with _$FavoriteState {
  const factory FavoriteState({
    @Default(false) bool isLoading,
    @Default([]) List<String> myFavoriteList,
  }) = _FavoriteState;
}

class FavoriteNotifier extends StateNotifier<FavoriteState>
    with LocatorMixin, RouteAware, WidgetsBindingObserver {
  FavoriteNotifier() : super(const FavoriteState());

  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();
  GeminiMolaApiRepository get geminiMolaApiRepository =>
      read<GeminiMolaApiRepository>();

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

  // 文字列を追加または削除する関数
  Future<void> addOrRemoveString(String value) async {
    final sakeList =
        await sharedPreference.getStringList(key: FAVORITE_SAKE_LIST);
    if (sakeList.contains(value)) {
      sakeList.remove(value);
    } else {
      sakeList.add(value);
    }
    await sharedPreference.setStringList(
        key: FAVORITE_SAKE_LIST, list: sakeList);
    await setMyFavorite(sakeList);
  }

  Future<void> setMyFavorite(List<String> myFavoriteList) async {
    state = state.copyWith(myFavoriteList: myFavoriteList);
  }

  Future<void> fetchFavorites() async {
    final myFavoriteList =
        await sharedPreference.getStringList(key: FAVORITE_SAKE_LIST);
    await setMyFavorite(myFavoriteList);
    logger.shout(state.myFavoriteList);
  }
}
