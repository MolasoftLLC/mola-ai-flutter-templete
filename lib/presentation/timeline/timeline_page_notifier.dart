import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/saved_sake_sync_repository.dart';

const _stateSentinel = Object();

enum EnvyResult { success, already, pending, failed }

enum ReportResult { success, already, pending, failed, unauthenticated }

enum TimelineFeedType { public, mine }

class TimelinePageState {
  const TimelinePageState({
    this.isLoading = false,
    this.isRefreshing = false,
    this.sakes = const <Sake>[],
    this.errorMessage,
    this.enviedIds = const <String>{},
    this.pendingEnvyIds = const <String>{},
    this.reportedSavedIds = const <String>{},
    this.pendingReportIds = const <String>{},
    this.nextCursor,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final bool isLoading;
  final bool isRefreshing;
  final List<Sake> sakes;
  final String? errorMessage;
  final Set<String> enviedIds;
  final Set<String> pendingEnvyIds;
  final Set<String> reportedSavedIds;
  final Set<String> pendingReportIds;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  TimelinePageState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<Sake>? sakes,
    Object? errorMessage = _stateSentinel,
    Set<String>? enviedIds,
    Set<String>? pendingEnvyIds,
    Set<String>? reportedSavedIds,
    Set<String>? pendingReportIds,
    Object? nextCursor = _stateSentinel,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return TimelinePageState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      sakes: sakes ?? this.sakes,
      errorMessage: identical(errorMessage, _stateSentinel)
          ? this.errorMessage
          : errorMessage as String?,
      enviedIds: enviedIds ?? this.enviedIds,
      pendingEnvyIds: pendingEnvyIds ?? this.pendingEnvyIds,
      reportedSavedIds: reportedSavedIds ?? this.reportedSavedIds,
      pendingReportIds: pendingReportIds ?? this.pendingReportIds,
      nextCursor: identical(nextCursor, _stateSentinel)
          ? this.nextCursor
          : nextCursor as String?,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class TimelinePageNotifier extends StateNotifier<TimelinePageState>
    with LocatorMixin {
  TimelinePageNotifier({this.feedType = TimelineFeedType.public})
      : _reportedSavedIds = <String>{},
        super(const TimelinePageState());

  final TimelineFeedType feedType;

  SavedSakeSyncRepository get _savedSakeSyncRepository =>
      read<SavedSakeSyncRepository>();
  AuthRepository get _authRepository => read<AuthRepository>();

  bool get isLoggedIn => _authRepository.currentUser != null;

  static const _reportedSavedIdsKey = 'timeline_reported_saved_ids';
  final Set<String> _reportedSavedIds;

  @override
  Future<void> initState() async {
    super.initState();
    await _loadReportedSavedIds();
    await fetchTimeline();
  }

  Future<void> _loadReportedSavedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list =
          prefs.getStringList(_reportedSavedIdsKey) ?? const <String>[];
      _reportedSavedIds
        ..clear()
        ..addAll(
            list.where((id) => id.trim().isNotEmpty).map((id) => id.trim()));
      state =
          state.copyWith(reportedSavedIds: Set<String>.from(_reportedSavedIds));
    } catch (error, stackTrace) {
      logger.warning('報告済み保存酒IDの読み込みに失敗しました: $error');
      logger.info(stackTrace.toString());
    }
  }

  Future<void> _persistReportedSavedIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _reportedSavedIdsKey, _reportedSavedIds.toList());
    } catch (error, stackTrace) {
      logger.warning('報告済み保存酒IDの保存に失敗しました: $error');
      logger.info(stackTrace.toString());
    }
  }

  Future<void> fetchTimeline({bool isRefresh = false}) async {
    if (state.isLoading && !isRefresh) {
      return;
    }

    if (feedType == TimelineFeedType.mine && !isLoggedIn) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        sakes: const <Sake>[],
        errorMessage: '自分の投稿を表示するにはログインしてください。',
      );
      return;
    }

    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final userId = feedType == TimelineFeedType.mine
          ? _authRepository.currentUser?.uid
          : null;
      final page = await _savedSakeSyncRepository.fetchTimelineSakes(
        userId: userId,
      );
      for (final sake in page.sakes) {
        logger.info(
          '[Timeline] fetched: savedId=${sake.savedId}, name=${sake.name}, '
          'impression="${sake.impression}", description="${sake.description}"',
        );
      }
      final filteredSakes = _filterReportedSakes(page.sakes);
      _syncStateWithSakes(
        filteredSakes,
        nextCursor: page.nextCursor,
        canLoadMore: page.canLoadMore,
      );
    } on SavedSakeTimelineUnauthorizedException {
      final message = isLoggedIn
          ? '認証の有効期限が切れました。再度ログインしてください。'
          : (feedType == TimelineFeedType.mine
              ? '自分の投稿を表示するにはログインしてください。'
              : 'タイムラインを表示するにはログインしてください。');
      state = state.copyWith(
        sakes: const <Sake>[],
        errorMessage: message,
        nextCursor: null,
        hasMore: false,
      );
    } catch (error, stackTrace) {
      logger.warning('タイムライン取得中に例外が発生しました: $error');
      logger.info(stackTrace.toString());
      state = state.copyWith(
        errorMessage: 'データの取得に失敗しました。通信環境をご確認ください。',
        nextCursor: null,
        hasMore: false,
      );
    } finally {
      if (isRefresh) {
        state = state.copyWith(isRefreshing: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<void> refresh() => fetchTimeline(isRefresh: true);

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoading || state.isRefreshing) {
      return;
    }
    if (!state.hasMore || state.nextCursor == null) {
      return;
    }
    if (feedType == TimelineFeedType.mine && !isLoggedIn) {
      return;
    }

    final cursor = state.nextCursor!;
    state = state.copyWith(isLoadingMore: true);
    try {
      final userId = feedType == TimelineFeedType.mine
          ? _authRepository.currentUser?.uid
          : null;
      final page = await _savedSakeSyncRepository.fetchTimelineSakes(
        userId: userId,
        cursor: cursor,
      );
      final filteredNew = _filterReportedSakes(page.sakes);
      final merged = List<Sake>.from(state.sakes);
      if (filteredNew.isNotEmpty) {
        final existingIds = <String>{
          for (final sake in merged)
            if (sake.savedId?.trim().isNotEmpty == true) sake.savedId!.trim(),
        };
        for (final sake in filteredNew) {
          final savedId = sake.savedId?.trim();
          if (savedId != null && savedId.isNotEmpty) {
            if (existingIds.contains(savedId)) {
              continue;
            }
            existingIds.add(savedId);
          }
          merged.add(sake);
        }
      }

      _syncStateWithSakes(
        merged,
        nextCursor: page.nextCursor,
        canLoadMore: page.canLoadMore,
      );
    } on SavedSakeTimelineUnauthorizedException {
      state = state.copyWith(
        hasMore: false,
        nextCursor: null,
      );
    } catch (error, stackTrace) {
      logger.warning('タイムライン追加取得中に例外が発生しました: $error');
      logger.info(stackTrace.toString());
    } finally {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  Future<EnvyResult> incrementEnvy(Sake sake) async {
    final key = envyKey(sake);
    if (key.isEmpty) {
      logger.warning('うらやま対象のキーが生成できませんでした');
      return EnvyResult.failed;
    }
    if (state.enviedIds.contains(key)) {
      logger.info('既にうらやま済みのためAPIリクエストをスキップします: $key');
      return EnvyResult.already;
    }
    if (state.pendingEnvyIds.contains(key)) {
      logger.info('うらやまリクエスト進行中のため二重送信を防止しました: $key');
      return EnvyResult.pending;
    }

    final savedId = sake.savedId?.trim();
    if (savedId == null || savedId.isEmpty) {
      logger.warning('うらやま対象の savedId が空です');
      return EnvyResult.failed;
    }

    final pending = Set<String>.from(state.pendingEnvyIds)..add(key);
    state = state.copyWith(pendingEnvyIds: pending);

    final success = await _savedSakeSyncRepository.incrementEnvyCount(
      userId: _authRepository.currentUser?.uid,
      savedId: savedId,
    );

    final nextPending = Set<String>.from(state.pendingEnvyIds)..remove(key);

    if (!success) {
      state = state.copyWith(pendingEnvyIds: nextPending);
      return EnvyResult.failed;
    }

    final updatedEnvied = Set<String>.from(state.enviedIds)..add(key);
    final updatedSakes = state.sakes.map((item) {
      if (item.savedId == savedId) {
        return item.copyWith(envyCount: item.envyCount + 1);
      }
      return item;
    }).toList();

    state = state.copyWith(
      enviedIds: updatedEnvied,
      pendingEnvyIds: nextPending,
      sakes: updatedSakes,
    );
    return EnvyResult.success;
  }

  Future<ReportResult> reportSavedSake(Sake sake) async {
    final savedId = sake.savedId?.trim();
    if (savedId == null || savedId.isEmpty) {
      logger.warning('報告対象の savedId が空です');
      return ReportResult.failed;
    }

    if (_reportedSavedIds.contains(savedId)) {
      logger.info('既に報告済みのため API リクエストをスキップします: $savedId');
      return ReportResult.already;
    }

    if (state.pendingReportIds.contains(savedId)) {
      logger.info('報告リクエスト進行中のため二重送信を防止しました: $savedId');
      return ReportResult.pending;
    }

    final user = _authRepository.currentUser;
    if (user == null) {
      logger.warning('報告に必要なログイン情報がありません');
      return ReportResult.unauthenticated;
    }

    final pending = Set<String>.from(state.pendingReportIds)..add(savedId);
    state = state.copyWith(pendingReportIds: pending);

    final success = await _savedSakeSyncRepository.reportSavedSake(
      userId: user.uid,
      savedId: savedId,
    );

    final nextPending = Set<String>.from(state.pendingReportIds)
      ..remove(savedId);

    if (!success) {
      state = state.copyWith(pendingReportIds: nextPending);
      return ReportResult.failed;
    }

    _reportedSavedIds.add(savedId);
    await _persistReportedSavedIds();

    final updatedSakes =
        state.sakes.where((item) => item.savedId?.trim() != savedId).toList();

    state = state.copyWith(
      pendingReportIds: nextPending,
      reportedSavedIds: Set<String>.from(_reportedSavedIds),
      sakes: updatedSakes,
    );
    return ReportResult.success;
  }

  List<Sake> _filterReportedSakes(List<Sake> sakes) {
    return sakes.where((sake) {
      final savedId = sake.savedId?.trim();
      if (savedId == null || savedId.isEmpty) {
        return true;
      }
      return !_reportedSavedIds.contains(savedId);
    }).toList();
  }

  void _syncStateWithSakes(
    List<Sake> updatedSakes, {
    required String? nextCursor,
    required bool canLoadMore,
  }) {
    final normalizedCursor =
        canLoadMore && nextCursor != null && nextCursor.trim().isNotEmpty
            ? nextCursor.trim()
            : null;

    final validKeys = <String>{
      for (final sake in updatedSakes) envyKey(sake),
    }..removeWhere((key) => key.isEmpty);
    final filteredEnvied =
        state.enviedIds.where((key) => validKeys.contains(key)).toSet();
    final filteredPending =
        state.pendingEnvyIds.where((key) => validKeys.contains(key)).toSet();
    final filteredPendingReports = state.pendingReportIds
        .where((savedId) =>
            updatedSakes.any((sake) => sake.savedId?.trim() == savedId))
        .toSet();

    state = state.copyWith(
      sakes: updatedSakes,
      enviedIds: filteredEnvied,
      pendingEnvyIds: filteredPending,
      reportedSavedIds: Set<String>.from(_reportedSavedIds),
      pendingReportIds: filteredPendingReports,
      nextCursor: normalizedCursor,
      hasMore: normalizedCursor != null && canLoadMore,
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
