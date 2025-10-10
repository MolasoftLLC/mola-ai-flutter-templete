import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/shared_key.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/shared_preference.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../repository/auth_repository.dart';
import '../../repository/saved_sake_sync_repository.dart';

part 'saved_sake_notifier.freezed.dart';

class SavedSakeGuestLimitReachedException implements Exception {
  const SavedSakeGuestLimitReachedException();
}

@freezed
class SavedSakeState with _$SavedSakeState {
  const factory SavedSakeState({
    @Default([]) List<Sake> savedSakeList,
    @Default(true) bool isGridView,
    @Default(<String>[]) List<String> activeFilterTags,
  }) = _SavedSakeState;
}

class SavedSakeNotifier extends StateNotifier<SavedSakeState>
    with LocatorMixin {
  SavedSakeNotifier() : super(const SavedSakeState()) {
    _loadSavedSakes();
    Future.microtask(_loadRemoteIfAvailable);
  }

  static const int guestSavedLimit = 8;
  static const _migrationUserKey = 'savedSakeMigratedUserId';

  final Random _random = Random();

  AuthRepository get _authRepository => read<AuthRepository>();
  SavedSakeSyncRepository get _syncRepository =>
      read<SavedSakeSyncRepository>();

  bool get _isGuest => _authRepository.currentUser == null;

  bool get hasReachedGuestLimit =>
      _isGuest && state.savedSakeList.length >= guestSavedLimit;

  bool _isRemoteImagePath(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  Future<void> _loadSavedSakes() async {
    try {
      final savedStrings =
          await SharedPreference.staticGetStringList(key: SAVED_SAKE_LIST);

      final savedSakes = savedStrings
          .map((jsonStr) {
            try {
              final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
              return Sake.fromJson(decoded);
            } catch (e) {
              logger.warning('保存済み日本酒の読み込みに失敗しました: $e');
              return null;
            }
          })
          .whereType<Sake>()
          .map((sake) => sake.savedId == null
              ? sake.copyWith(savedId: _generateId())
              : sake)
          .toList();

      savedSakes.sort((a, b) => _compareSavedId(b.savedId, a.savedId));

      final availableTags = _extractTags(savedSakes);
      final sanitizedFilters = state.activeFilterTags
          .where((tag) => availableTags.contains(tag))
          .toList();

      state = state.copyWith(
        savedSakeList: savedSakes,
        activeFilterTags: sanitizedFilters,
      );
      logger.info('保存済み日本酒を読み込みました: ${savedSakes.length}件');
    } catch (e) {
      logger.shout('保存済み日本酒の初期化に失敗しました: $e');
    }
  }

  Future<void> _loadRemoteIfAvailable() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      return;
    }
    await _loadSavedSakesFromServer(user.uid);
  }

  Future<void> _loadSavedSakesFromServer(String userId) async {
    try {
      final remoteSakes = await _syncRepository.fetchSavedSakes(userId);

      if (remoteSakes.isEmpty) {
        logger.info('サーバーから取得できる保存酒がありませんでした');
      }

      remoteSakes.sort((a, b) => _compareSavedId(b.savedId, a.savedId));

      final availableTags = _extractTags(remoteSakes);
      final sanitizedFilters = state.activeFilterTags
          .where((tag) => availableTags.contains(tag))
          .toList();

      state = state.copyWith(
        savedSakeList: remoteSakes,
        activeFilterTags: sanitizedFilters,
      );

      await _persistSavedSakes();
      logger.info('サーバーの保存酒を反映しました: ${remoteSakes.length}件');
    } catch (error) {
      logger.warning('サーバーの保存酒取得に失敗しました: $error');
    }
  }

  Future<void> refreshFromServer() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      return;
    }
    await _loadSavedSakesFromServer(user.uid);
  }

  Future<void> reloadLocal() async {
    await _loadSavedSakes();
  }

  Future<void> onUserSignedIn(String userId) async {
    await _migrateLocalSavedSakesIfNeeded(userId);
    await refreshFromServer();
    await SharedPreference.staticSetString(
      key: _migrationUserKey,
      value: userId,
    );
  }

  Future<void> onUserSignedOut() async {
    await _clearLocalSavedSakes();
    await SharedPreference.staticSetString(
      key: _migrationUserKey,
      value: '',
    );
  }

  Future<String> addSavedSake(Sake sake) async {
    final alreadySaved =
        state.savedSakeList.any((item) => _isSameSake(item, sake));
    if (_isGuest &&
        !alreadySaved &&
        state.savedSakeList.length >= guestSavedLimit) {
      throw const SavedSakeGuestLimitReachedException();
    }
    final savedId = sake.savedId ?? _generateId();
    final newSake = sake.copyWith(savedId: savedId);
    state = state.copyWith(
      savedSakeList: [newSake, ...state.savedSakeList],
    );
    await _persistSavedSakes();
    logger.info('保存済み日本酒を追加: ${newSake.name ?? '不明な日本酒'} (id=$savedId)');
    return savedId;
  }

  Future<void> toggleSavedSake(Sake sake) async {
    final exists = state.savedSakeList.any((item) => _isSameSake(item, sake));

    if (exists) {
      final updatedList = state.savedSakeList
          .where((item) => !_isSameSake(item, sake))
          .toList();
      state = state.copyWith(savedSakeList: updatedList);
      _syncFiltersWithAvailableTags();
      logger.info('保存済み日本酒を削除: ${sake.name ?? '不明な日本酒'}');
    } else {
      await addSavedSake(sake);
      return;
    }

    await _persistSavedSakes();
  }

  Future<void> updateSavedSake(Sake sake) async {
    final index = _findIndex(sake);
    if (index == -1) {
      logger.warning('保存済み日本酒の更新対象が見つかりません: ${sake.name}');
      return;
    }

    final updatedList = [...state.savedSakeList];
    updatedList[index] = sake;
    state = state.copyWith(savedSakeList: updatedList);
    _syncFiltersWithAvailableTags();
    await _persistSavedSakes();
    logger.info('保存済み日本酒を更新: ${sake.name ?? '名称不明'}');
  }

  Future<Sake?> addImageToSavedSake({
    required String savedId,
    required String localPath,
  }) async {
    final index = state.savedSakeList
        .indexWhere((item) => item.savedId != null && item.savedId == savedId);
    if (index == -1) {
      logger.warning('画像追加対象の保存酒が見つかりません: id=$savedId');
      return null;
    }

    final current = state.savedSakeList[index];
    final currentPaths = [...(current.imagePaths ?? const <String>[])];
    if (currentPaths.length >= 3) {
      logger.info('保存酒の画像は最大3枚です (id=$savedId)');
      return null;
    }

    var newPath = localPath;

    if (!_isGuest) {
      final user = _authRepository.currentUser;
      if (user == null) {
        logger.warning('ログイン情報が取得できず、画像アップロードを中止しました');
        return null;
      }

      final uploadedUrl = await _syncRepository.uploadSavedSakeImage(
        userId: user.uid,
        savedId: savedId,
        imageFile: File(localPath),
      );

      if (uploadedUrl == null || uploadedUrl.isEmpty) {
        logger.warning('保存酒画像のアップロード結果が不正です');
        return null;
      }

      newPath = uploadedUrl;

      try {
        final file = File(localPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // ignore delete errors
      }
    }

    if (currentPaths.contains(newPath)) {
      logger.info('同じ画像が既に登録されています: $newPath');
      return current;
    }

    final updatedPaths = [...currentPaths, newPath];
    final updated = current.copyWith(
      imagePaths: updatedPaths,
    );

    await updateSavedSake(updated);
    logger.info('保存酒に画像を追加: id=$savedId path=$newPath');
    return updated;
  }

  Future<Sake?> removeImageFromSavedSake({
    required String savedId,
    required String imagePath,
  }) async {
    final index = state.savedSakeList
        .indexWhere((item) => item.savedId != null && item.savedId == savedId);
    if (index == -1) {
      logger.warning('画像削除対象の保存酒が見つかりません: id=$savedId');
      return null;
    }

    if (!_isGuest && _isRemoteImagePath(imagePath)) {
      final user = _authRepository.currentUser;
      if (user == null) {
        logger.warning('ログイン情報が取得できず、画像削除を中止しました');
        return null;
      }
      final success = await _syncRepository.deleteSavedSakeImage(
        userId: user.uid,
        savedId: savedId,
        imageUrl: imagePath,
      );
      if (!success) {
        logger.warning('保存酒画像のサーバー削除に失敗しました: $imagePath');
        return null;
      }
    }

    final current = state.savedSakeList[index];
    final updatedPaths = [...(current.imagePaths ?? const <String>[])]
      ..remove(imagePath);
    final updated = current.copyWith(
      imagePaths: updatedPaths.isEmpty ? null : updatedPaths,
    );

    await updateSavedSake(updated);
    logger.info('保存酒の画像を削除: id=$savedId path=$imagePath');
    return updated;
  }

  Future<void> updateSavedSakeWithInfo(String savedId, Sake info) async {
    final index = state.savedSakeList
        .indexWhere((item) => item.savedId != null && item.savedId == savedId);
    if (index == -1) {
      logger.warning('情報更新対象が見つかりません (id=$savedId)');
      return;
    }

    final existing = state.savedSakeList[index];
    final merged = existing.copyWith(
      name: info.name ?? existing.name,
      brewery: info.brewery ?? existing.brewery,
      types: (info.types == null || info.types!.isEmpty)
          ? existing.types
          : info.types,
      taste: info.taste ?? existing.taste,
      sakeMeterValue: info.sakeMeterValue ?? existing.sakeMeterValue,
      type: info.type ?? existing.type,
      price: info.price ?? existing.price,
      description: info.description ?? existing.description,
      recommendationScore:
          info.recommendationScore ?? existing.recommendationScore,
    );

    final updatedList = [...state.savedSakeList];
    updatedList[index] = merged;
    state = state.copyWith(savedSakeList: updatedList);
    _syncFiltersWithAvailableTags();
    await _persistSavedSakes();
    logger.info('保存済み日本酒に解析結果を反映: ${merged.name ?? '名称不明'} (id=$savedId)');
  }

  bool isSaved(String? name, String? type) {
    return state.savedSakeList
        .any((item) => item.name == name && item.type == type);
  }

  void setGridView(bool isGrid) {
    if (state.isGridView == isGrid) {
      return;
    }
    state = state.copyWith(isGridView: isGrid);
  }

  void setFilterTags(List<String> tags) {
    final sanitized = _sanitizeTags(tags);
    state = state.copyWith(activeFilterTags: sanitized);
  }

  void clearFilterTags() {
    if (state.activeFilterTags.isEmpty) {
      return;
    }
    state = state.copyWith(activeFilterTags: const <String>[]);
  }

  Future<void> _persistSavedSakes() async {
    try {
      final encodedList =
          state.savedSakeList.map((sake) => jsonEncode(sake.toJson())).toList();
      await SharedPreference.staticSetStringList(
        key: SAVED_SAKE_LIST,
        list: encodedList,
      );
      logger.info('保存済み日本酒を永続化しました: ${encodedList.length}件');
    } catch (e) {
      logger.shout('保存済み日本酒の永続化に失敗しました: $e');
    }
  }

  int _compareSavedId(String? first, String? second) {
    final tf = _extractTimestamp(first);
    final ts = _extractTimestamp(second);
    if (tf != ts) {
      return tf.compareTo(ts);
    }
    final rf = _extractRandom(first);
    final rs = _extractRandom(second);
    return rf.compareTo(rs);
  }

  int _extractTimestamp(String? savedId) {
    if (savedId == null) return 0;
    final parts = savedId.split('_');
    if (parts.length < 3) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  int _extractRandom(String? savedId) {
    if (savedId == null) return 0;
    final parts = savedId.split('_');
    if (parts.length < 3) return 0;
    return int.tryParse(parts[2]) ?? 0;
  }

  bool _isSameSake(Sake a, Sake b) {
    if (a.savedId != null && b.savedId != null) {
      return a.savedId == b.savedId;
    }
    return a.name == b.name && a.type == b.type;
  }

  int _findIndex(Sake sake) {
    if (sake.savedId != null) {
      return state.savedSakeList
          .indexWhere((item) => item.savedId == sake.savedId);
    }
    return state.savedSakeList.indexWhere((item) => _isSameSake(item, sake));
  }

  String _generateId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(1 << 32);
    return 'saved_${millis}_$rand';
  }

  List<String> _sanitizeTags(List<String> tags) {
    if (tags.isEmpty) {
      return const <String>[];
    }
    final available = _extractTags(state.savedSakeList);
    final sanitized = <String>[];
    for (final raw in tags) {
      final tag = raw.trim();
      if (tag.isEmpty) {
        continue;
      }
      if (!available.contains(tag)) {
        continue;
      }
      if (sanitized.contains(tag)) {
        continue;
      }
      sanitized.add(tag);
    }
    return sanitized;
  }

  Set<String> _extractTags(List<Sake> source) {
    return source
        .expand((sake) => sake.userTags ?? const <String>[])
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet();
  }

  void _syncFiltersWithAvailableTags() {
    if (state.activeFilterTags.isEmpty) {
      return;
    }
    final available = _extractTags(state.savedSakeList);
    final filtered =
        state.activeFilterTags.where((tag) => available.contains(tag)).toList();
    if (filtered.length == state.activeFilterTags.length) {
      return;
    }
    state = state.copyWith(activeFilterTags: filtered);
  }

  Future<void> removeById(String savedId) async {
    final updatedList =
        state.savedSakeList.where((item) => item.savedId != savedId).toList();
    if (updatedList.length == state.savedSakeList.length) {
      return;
    }
    state = state.copyWith(savedSakeList: updatedList);
    _syncFiltersWithAvailableTags();
    await _persistSavedSakes();
    logger.info('保存済み日本酒を削除(解析失敗): id=$savedId');
  }

  Future<void> _migrateLocalSavedSakesIfNeeded(String userId) async {
    final migratedUser = await SharedPreference.staticGetString(
      key: _migrationUserKey,
      defaultValue: '',
    );
    if (migratedUser == userId) {
      return;
    }

    final localList = [...state.savedSakeList];
    if (localList.isEmpty) {
      return;
    }

    for (final sake in localList) {
      try {
        await _syncRepository.syncSavedSake(
          stage: SavedSakeSyncStage.analysisComplete,
          userId: userId,
          sake: sake,
        );
      } catch (error, stackTrace) {
        logger.warning('保存酒の移行に失敗しました: $error');
        logger.info(stackTrace.toString());
      }
    }

    await _clearLocalSavedSakes();
  }

  Future<void> _clearLocalSavedSakes() async {
    state = state.copyWith(
      savedSakeList: const [],
      activeFilterTags: const <String>[],
    );
    await SharedPreference.staticSetStringList(
      key: SAVED_SAKE_LIST,
      list: const <String>[],
    );
  }
}
