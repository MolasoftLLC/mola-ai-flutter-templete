import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:state_notifier/state_notifier.dart';

import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/saved_sake_sync_repository.dart';

const _errorSentinel = Object();

enum EnvyResult { success, already, pending, failed }

enum ReportResult { success, already, pending, failed, unauthenticated }

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
  });

  final bool isLoading;
  final bool isRefreshing;
  final List<Sake> sakes;
  final String? errorMessage;
  final Set<String> enviedIds;
  final Set<String> pendingEnvyIds;
  final Set<String> reportedSavedIds;
  final Set<String> pendingReportIds;

  TimelinePageState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    List<Sake>? sakes,
    Object? errorMessage = _errorSentinel,
    Set<String>? enviedIds,
    Set<String>? pendingEnvyIds,
    Set<String>? reportedSavedIds,
    Set<String>? pendingReportIds,
  }) {
    return TimelinePageState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      sakes: sakes ?? this.sakes,
      errorMessage: identical(errorMessage, _errorSentinel)
          ? this.errorMessage
          : errorMessage as String?,
      enviedIds: enviedIds ?? this.enviedIds,
      pendingEnvyIds: pendingEnvyIds ?? this.pendingEnvyIds,
      reportedSavedIds: reportedSavedIds ?? this.reportedSavedIds,
      pendingReportIds: pendingReportIds ?? this.pendingReportIds,
    );
  }
}

class TimelinePageNotifier extends StateNotifier<TimelinePageState>
    with LocatorMixin {
  TimelinePageNotifier()
      : _reportedSavedIds = <String>{},
        super(const TimelinePageState());

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

    if (isRefresh) {
      state = state.copyWith(isRefreshing: true, errorMessage: null);
    } else {
      state = state.copyWith(isLoading: true, errorMessage: null);
    }

    try {
      final fetchedSakes = await _savedSakeSyncRepository.fetchTimelineSakes();
      for (final sake in fetchedSakes) {
        logger.info(
          '[Timeline] fetched: savedId=${sake.savedId}, name=${sake.name}, '
          'impression="${sake.impression}", description="${sake.description}"',
        );
      }
      final filteredSakes = fetchedSakes.where((sake) {
        final savedId = sake.savedId?.trim();
        if (savedId == null || savedId.isEmpty) {
          return true;
        }
        return !_reportedSavedIds.contains(savedId);
      }).toList();
      final validKeys = <String>{
        for (final sake in filteredSakes) envyKey(sake),
      }..removeWhere((key) => key.isEmpty);
      final filteredEnvied =
          state.enviedIds.where((key) => validKeys.contains(key)).toSet();
      final filteredPending =
          state.pendingEnvyIds.where((key) => validKeys.contains(key)).toSet();
      final filteredPendingReports = state.pendingReportIds
          .where((savedId) =>
              filteredSakes.any((sake) => sake.savedId?.trim() == savedId))
          .toSet();
      state = state.copyWith(
        sakes: filteredSakes,
        enviedIds: filteredEnvied,
        pendingEnvyIds: filteredPending,
        reportedSavedIds: Set<String>.from(_reportedSavedIds),
        pendingReportIds: filteredPendingReports,
      );
    } on SavedSakeTimelineUnauthorizedException {
      final message = isLoggedIn
          ? '認証の有効期限が切れました。再度ログインしてください。'
          : 'タイムラインを表示するにはログインしてください。';
      state = state.copyWith(
        sakes: const <Sake>[],
        errorMessage: message,
      );
    } catch (error, stackTrace) {
      logger.warning('タイムライン取得中に例外が発生しました: $error');
      logger.info(stackTrace.toString());
      state = state.copyWith(
        errorMessage: 'データの取得に失敗しました。通信環境をご確認ください。',
      );
    } finally {
      if (isRefresh) {
        state = state.copyWith(isRefreshing: false);
      } else {
        state = state.copyWith(isLoading: false);
      }
    }
  }

  Future<void> refresh() => fetchTimeline(isRefresh: true);

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
