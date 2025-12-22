import 'package:state_notifier/state_notifier.dart';

import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/saved_sake_sync_repository.dart';
import 'envy_result.dart';

class TimelineEnvyRankingState {
  const TimelineEnvyRankingState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.sakes = const <Sake>[],
    this.errorMessage,
    this.enviedKeys = const <String>{},
    this.pendingEnvyKeys = const <String>{},
  });

  final bool isLoading;
  final bool isRefreshing;
  final List<Sake> sakes;
  final String? errorMessage;
  final Set<String> enviedKeys;
  final Set<String> pendingEnvyKeys;

  TimelineEnvyRankingState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<Sake>? sakes,
    Set<String>? enviedKeys,
    Set<String>? pendingEnvyKeys,
    Object? errorMessage = _rankingStateSentinel,
  }) {
    return TimelineEnvyRankingState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      sakes: sakes ?? this.sakes,
      enviedKeys: enviedKeys ?? this.enviedKeys,
      pendingEnvyKeys: pendingEnvyKeys ?? this.pendingEnvyKeys,
      errorMessage: identical(errorMessage, _rankingStateSentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class TimelineEnvyRankingNotifier
    extends StateNotifier<TimelineEnvyRankingState> {
  TimelineEnvyRankingNotifier(this._repository, this._authRepository)
      : super(const TimelineEnvyRankingState(isLoading: true)) {
    _init();
  }

  final SavedSakeSyncRepository _repository;
  final AuthRepository _authRepository;

  Future<void> _init() async {
    await fetchRanking();
  }

  Future<void> fetchRanking({bool isRefresh = false}) async {
    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }
    final records = await _repository.fetchTimelineEnvyRanking(limit: 20);
    if (records.isEmpty) {
      state = state.copyWith(
        sakes: const <Sake>[],
        enviedKeys: const <String>{},
        pendingEnvyKeys: const <String>{},
        errorMessage: 'ランキングを取得できませんでした。時間をおいて再度お試しください。',
      );
    } else {
      _syncStateWithSakes(records);
      state = state.copyWith(errorMessage: null);
    }
    state = state.copyWith(
      isLoading: false,
      isRefreshing: false,
    );
  }

  Future<void> refresh() => fetchRanking(isRefresh: true);

  Future<EnvyResult> incrementEnvy(Sake sake) async {
    final key = envyKey(sake);
    final savedId = sake.savedId?.trim();
    if (key.isEmpty || savedId == null || savedId.isEmpty) {
      return EnvyResult.failed;
    }

    if (state.enviedKeys.contains(key)) {
      return EnvyResult.already;
    }

    if (state.pendingEnvyKeys.contains(key)) {
      return EnvyResult.pending;
    }

    final pending = Set<String>.from(state.pendingEnvyKeys)..add(key);
    state = state.copyWith(pendingEnvyKeys: pending);

    final success = await _repository.incrementEnvyCount(
      userId: _authRepository.currentUser?.uid,
      savedId: savedId,
    );

    final nextPending = Set<String>.from(state.pendingEnvyKeys)..remove(key);

    if (!success) {
      state = state.copyWith(pendingEnvyKeys: nextPending);
      return EnvyResult.failed;
    }

    final updatedEnvied = Set<String>.from(state.enviedKeys)..add(key);
    final updatedSakes = state.sakes.map((item) {
      if (item.savedId?.trim() == savedId) {
        return item.copyWith(envyCount: item.envyCount + 1);
      }
      return item;
    }).toList();

    state = state.copyWith(
      enviedKeys: updatedEnvied,
      pendingEnvyKeys: nextPending,
      sakes: updatedSakes,
    );

    return EnvyResult.success;
  }

  void _syncStateWithSakes(List<Sake> sakes) {
    final validKeys = <String>{
      for (final sake in sakes) envyKey(sake),
    }..removeWhere((key) => key.isEmpty);
    final filteredEnvied =
        state.enviedKeys.where((key) => validKeys.contains(key)).toSet();
    final filteredPending =
        state.pendingEnvyKeys.where((key) => validKeys.contains(key)).toSet();

    state = state.copyWith(
      sakes: sakes,
      enviedKeys: filteredEnvied,
      pendingEnvyKeys: filteredPending,
    );
  }

  static String envyKey(Sake sake) {
    final savedId = sake.savedId?.trim();
    if (savedId != null && savedId.isNotEmpty) {
      return 'id:$savedId';
    }
    final name = sake.name?.trim().toLowerCase() ?? '';
    final type = sake.type?.trim().toLowerCase() ?? '';
    if (name.isEmpty && type.isEmpty) {
      return '';
    }
    return 'meta:$name|$type';
  }
}

const _rankingStateSentinel = Object();
