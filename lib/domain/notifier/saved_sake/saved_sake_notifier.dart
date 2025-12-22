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

class SavedSakeMemberLimitReachedException implements Exception {
  const SavedSakeMemberLimitReachedException();
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
    Future.microtask(_fetchRemoteOnInit);
  }

  static const int guestSavedLimit = 8;
  static const int memberSavedLimit = 50;

  final Random _random = Random();
  final Set<String> _syncingImageIds = <String>{};

  AuthRepository get _authRepository => read<AuthRepository>();
  SavedSakeSyncRepository get _syncRepository =>
      read<SavedSakeSyncRepository>();

  bool get _isGuest => _authRepository.currentUser == null;

  bool get hasReachedGuestLimit =>
      _isGuest && state.savedSakeList.length >= guestSavedLimit;

  bool get hasReachedMemberLimit =>
      !_isGuest && state.savedSakeList.length >= memberSavedLimit;

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

      await _setSavedSakeList(savedSakes);
      logger.info('保存済み日本酒を読み込みました: ${savedSakes.length}件');
    } catch (e) {
      logger.shout('保存済み日本酒の初期化に失敗しました: $e');
    }
  }

  Future<void> _fetchRemoteOnInit() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      return;
    }
    await refreshFromServer();
  }

  Future<bool> refreshFromServer() async {
    final user = _authRepository.currentUser;
    if (user == null) {
      return false;
    }

    try {
      final remoteSakes = await _syncRepository.fetchSavedSakes(user.uid);
      if (remoteSakes.isEmpty) {
        logger.info('サーバーから取得できる保存酒がありませんでした');
        return false;
      }

      final normalized = remoteSakes
          .map(
            (sake) => sake.copyWith(
              syncStatus: SavedSakeSyncStatus.serverSynced,
            ),
          )
          .toList();

      await _mergeRemoteSakes(normalized);
      logger.info('サーバーの保存酒をローカルに統合しました: ${normalized.length}件');
      return true;
    } catch (error, stackTrace) {
      logger.warning('サーバーの保存酒取得に失敗しました: $error');
      logger.info(stackTrace.toString());
      return false;
    }
  }

  Future<void> reloadLocal() async {
    await _loadSavedSakes();
  }

  Future<void> onUserSignedIn(String userId) async {
    await refreshFromServer();
  }

  Future<void> onUserSignedOut() async {
    final locals = state.savedSakeList
        .where((sake) => sake.syncStatus == SavedSakeSyncStatus.localOnly)
        .toList();
    await _setSavedSakeList(locals);
  }

  Future<String> addSavedSake(Sake sake) async {
    final alreadySaved =
        state.savedSakeList.any((item) => _isSameSake(item, sake));
    if (_isGuest &&
        !alreadySaved &&
        state.savedSakeList.length >= guestSavedLimit) {
      throw const SavedSakeGuestLimitReachedException();
    }
    if (!_isGuest &&
        !alreadySaved &&
        state.savedSakeList.length >= memberSavedLimit) {
      throw const SavedSakeMemberLimitReachedException();
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
      if (!_isGuest) {
        final user = _authRepository.currentUser;
        if (user != null) {
          Sake? target;
          for (final item in state.savedSakeList) {
            if (_isSameSake(item, sake)) {
              target = item;
              break;
            }
          }
          final savedId = target?.savedId;
          final shouldRequestServerDelete = target != null &&
              target.syncStatus == SavedSakeSyncStatus.serverSynced;
          if (savedId != null &&
              savedId.isNotEmpty &&
              shouldRequestServerDelete) {
            final success = await _syncRepository.deleteSavedSakeRecord(
              userId: user.uid,
              savedId: savedId,
            );
            if (!success) {
              logger.warning('保存酒のサーバー削除に失敗したためローカル削除を中止しました: id=$savedId');
              return;
            }
          } else if (savedId != null && savedId.isNotEmpty) {
            logger.info('ローカルのみの保存酒のためサーバー削除はスキップしました: id=$savedId');
          } else {
            logger.info('削除対象の savedId が未設定のためサーバー削除はスキップしました');
          }
        }
      }

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

  Future<Sake?> syncSavedSakeToServer(String savedId) async {
    final user = _authRepository.currentUser;
    if (user == null) {
      logger.warning('保存酒の同期を実行できません: ログイン情報がありません');
      return null;
    }

    final index = state.savedSakeList
        .indexWhere((item) => item.savedId != null && item.savedId == savedId);
    if (index == -1) {
      logger.warning('手動同期対象の保存酒が見つかりません: id=$savedId');
      return null;
    }

    if (_syncingImageIds.contains(savedId)) {
      logger.info('保存酒同期は既に進行中です: id=$savedId');
      return null;
    }
    _syncingImageIds.add(savedId);

    try {
      final target = state.savedSakeList[index];
      if (target.syncStatus == SavedSakeSyncStatus.serverSynced) {
        logger.info('保存酒は既にサーバーと同期済みです: id=$savedId');
        return target;
      }

      final imagePaths = [...(target.imagePaths ?? const <String>[])];
      final localPaths =
          imagePaths.where((path) => !_isRemoteImagePath(path)).toList();

      File? primaryImage;
      if (localPaths.isNotEmpty) {
        for (final candidate in localPaths) {
          if (candidate.isEmpty) {
            continue;
          }
          final file = File(candidate);
          if (file.existsSync()) {
            primaryImage = file;
            break;
          }
        }
      }

      var succeeded = true;

      final startResult = await _syncRepository.syncSavedSake(
        stage: SavedSakeSyncStage.analysisStart,
        userId: user.uid,
        sake: target,
        imageFile: primaryImage,
        isPublic: target.isPublic,
      );

      if (!startResult) {
        succeeded = false;
      }

      if (succeeded && localPaths.length > 1) {
        for (final path in localPaths) {
          if (primaryImage != null && path == primaryImage.path) {
            continue;
          }
          if (path.isEmpty) {
            continue;
          }
          final file = File(path);
          if (!file.existsSync()) {
            continue;
          }

          final uploadedUrl = await _syncRepository.uploadSavedSakeImage(
            userId: user.uid,
            savedId: savedId,
            imageFile: file,
          );

          if (uploadedUrl == null || uploadedUrl.isEmpty) {
            succeeded = false;
            break;
          }
        }
      }

      if (succeeded) {
        final completeResult = await _syncRepository.syncSavedSake(
          stage: SavedSakeSyncStage.analysisComplete,
          userId: user.uid,
          sake: target,
          isPublic: target.isPublic,
        );
        succeeded = succeeded && completeResult;
      }

      if (!succeeded) {
        logger.warning('保存酒の手動同期に失敗しました: id=$savedId');
        return null;
      }

      final synced = target.copyWith(
        syncStatus: SavedSakeSyncStatus.serverSynced,
      );
      final nextList = [...state.savedSakeList];
      nextList[index] = synced;
      state = state.copyWith(savedSakeList: nextList);
      _syncFiltersWithAvailableTags();
      await _persistSavedSakes();

      await refreshFromServer();

      try {
        return state.savedSakeList
            .firstWhere((item) => item.savedId == savedId);
      } catch (_) {
        return synced;
      }
    } catch (error, stackTrace) {
      logger.warning('保存酒の手動同期処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
      return null;
    } finally {
      _syncingImageIds.remove(savedId);
    }
  }

  Future<bool> updateTimelineVisibility({
    required String savedId,
    required bool isPublic,
  }) async {
    final index = state.savedSakeList
        .indexWhere((item) => item.savedId != null && item.savedId == savedId);
    if (index == -1) {
      logger.warning('公開設定更新対象の保存酒が見つかりません: id=$savedId');
      return false;
    }

    final user = _authRepository.currentUser;
    if (user == null) {
      logger.warning('公開設定更新に失敗: ログイン情報がありません');
      return false;
    }

    final success = await _syncRepository.updateSavedSakeVisibility(
      userId: user.uid,
      savedId: savedId,
      isPublic: isPublic,
    );
    if (!success) {
      return false;
    }

    final updatedList = [...state.savedSakeList];
    updatedList[index] = updatedList[index].copyWith(isPublic: isPublic);
    state = state.copyWith(savedSakeList: updatedList);
    await _persistSavedSakes();
    logger.info('公開設定を更新しました: id=$savedId isPublic=$isPublic');
    return true;
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

  Future<void> _mergeRemoteSakes(List<Sake> remoteSakes) async {
    final merged = _mergeSavedSakeLists(state.savedSakeList, remoteSakes);
    await _setSavedSakeList(merged);
  }

  Future<void> _setSavedSakeList(List<Sake> nextList) async {
    final sorted = [...nextList]
      ..sort((a, b) => _compareSavedId(b.savedId, a.savedId));

    final availableTags = _extractTags(sorted);
    final sanitizedFilters = state.activeFilterTags
        .where((tag) => availableTags.contains(tag))
        .toList();

    state = state.copyWith(
      savedSakeList: sorted,
      activeFilterTags: sanitizedFilters,
    );

    await _persistSavedSakes();
  }

  List<Sake> _mergeSavedSakeLists(
    List<Sake> current,
    List<Sake> remote,
  ) {
    final Map<String, Sake> byId = {};
    final List<Sake> withoutId = [];

    for (final sake in current) {
      final id = sake.savedId;
      if (id == null || id.isEmpty) {
        withoutId.add(sake);
        continue;
      }
      byId[id] = sake;
    }

    for (final remoteSake in remote) {
      final id = remoteSake.savedId;
      if (id == null || id.isEmpty) {
        withoutId.add(remoteSake);
        continue;
      }

      final existing = byId[id];
      if (existing == null) {
        byId[id] = remoteSake;
        continue;
      }

      byId[id] = _mergeSakeRecords(existing, remoteSake);
    }

    return [...byId.values, ...withoutId];
  }

  Sake _mergeSakeRecords(Sake local, Sake remote) {
    final mergedImagePaths =
        _mergeImagePaths(local.imagePaths, remote.imagePaths);

    return remote.copyWith(
      name: remote.name ?? local.name,
      brewery: remote.brewery ?? local.brewery,
      types: (remote.types != null && remote.types!.isNotEmpty)
          ? remote.types
          : local.types,
      taste: remote.taste ?? local.taste,
      sakeMeterValue: remote.sakeMeterValue ?? local.sakeMeterValue,
      type: remote.type ?? local.type,
      price: remote.price ?? local.price,
      description: remote.description ?? local.description,
      recommendationScore:
          remote.recommendationScore ?? local.recommendationScore,
      impression: local.impression ?? remote.impression,
      place: local.place ?? remote.place,
      userTags: (local.userTags != null && local.userTags!.isNotEmpty)
          ? local.userTags
          : remote.userTags,
      imagePaths: mergedImagePaths,
      syncStatus: SavedSakeSyncStatus.serverSynced,
    );
  }

  List<String>? _mergeImagePaths(
    List<String>? localPaths,
    List<String>? remotePaths,
  ) {
    final remoteList = remotePaths ?? const <String>[];
    if (remoteList.isNotEmpty) {
      return remoteList.toSet().toList();
    }

    if (localPaths == null || localPaths.isEmpty) {
      return null;
    }

    return localPaths.toSet().toList();
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
}
