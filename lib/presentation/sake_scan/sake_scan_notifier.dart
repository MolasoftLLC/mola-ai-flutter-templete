import 'dart:io';

import 'package:state_notifier/state_notifier.dart';

import '../../common/logger.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../../domain/services/sake_scan_services.dart';

enum SakeScanViewStatus {
  frontScanning,
  searchingFront,
  confirmingCandidate,
  backScanning,
  searchingBack,
  loadingOverview,
  identifyingFallback,
  loadingDetails,
  completed,
  error,
}

class SakeScanState {
  const SakeScanState({
    this.status = SakeScanViewStatus.frontScanning,
    this.scanSessionId,
    this.candidates = const <SakeScanCandidate>[],
    this.selectedCandidateIndex = 0,
    this.frontImage,
    this.backImage,
    this.sake,
    this.savedSake,
    this.error,
    this.backLabelReason,
    this.isSubmitting = false,
  });

  final SakeScanViewStatus status;
  final String? scanSessionId;
  final List<SakeScanCandidate> candidates;
  final int selectedCandidateIndex;
  final File? frontImage;
  final File? backImage;
  final Sake? sake;
  final Sake? savedSake;
  final SakeScanException? error;
  final SakeScanBackLabelReason? backLabelReason;
  final bool isSubmitting;

  SakeScanCandidate? get selectedCandidate => candidates.isEmpty
      ? null
      : candidates[selectedCandidateIndex.clamp(0, candidates.length - 1)];

  SakeScanState copyWith({
    SakeScanViewStatus? status,
    String? scanSessionId,
    List<SakeScanCandidate>? candidates,
    int? selectedCandidateIndex,
    File? frontImage,
    File? backImage,
    Sake? sake,
    Sake? savedSake,
    SakeScanException? error,
    SakeScanBackLabelReason? backLabelReason,
    bool clearError = false,
    bool clearBackLabelReason = false,
    bool? isSubmitting,
  }) {
    return SakeScanState(
      status: status ?? this.status,
      scanSessionId: scanSessionId ?? this.scanSessionId,
      candidates: candidates ?? this.candidates,
      selectedCandidateIndex:
          selectedCandidateIndex ?? this.selectedCandidateIndex,
      frontImage: frontImage ?? this.frontImage,
      backImage: backImage ?? this.backImage,
      sake: sake ?? this.sake,
      savedSake: savedSake ?? this.savedSake,
      error: clearError ? null : error ?? this.error,
      backLabelReason: clearBackLabelReason
          ? null
          : backLabelReason ?? this.backLabelReason,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class SakeScanNotifier extends StateNotifier<SakeScanState> {
  SakeScanNotifier({
    required SakeScanRepository scanRepository,
    required SakeScanAnalysisService analysisService,
    required SakeScanPersistenceService persistenceService,
  }) : _scanRepository = scanRepository,
       _analysisService = analysisService,
       _persistenceService = persistenceService,
       super(const SakeScanState());

  final SakeScanRepository _scanRepository;
  final SakeScanAnalysisService _analysisService;
  final SakeScanPersistenceService _persistenceService;
  bool _disposed = false;
  int _operation = 0;

  SakeScanState get currentState => state;

  void updateSavedRecord(Sake sake) {
    if (_disposed || sake.savedId == null || sake.savedId!.isEmpty) return;
    state = state.copyWith(savedSake: sake);
  }

  Future<void> submitFront(
    File image, {
    SakeFrontScanMethod method = SakeFrontScanMethod.googleLens,
  }) async {
    if (!_beginSubmission()) return;
    final operation = ++_operation;
    _emit(
      state.copyWith(
        status: SakeScanViewStatus.searchingFront,
        frontImage: image,
        candidates: const <SakeScanCandidate>[],
        selectedCandidateIndex: 0,
        clearError: true,
        clearBackLabelReason: true,
      ),
    );
    try {
      final result = await _scanRepository.scanFront(image, method: method);
      if (!_isCurrent(operation)) return;
      _applyScanResult(result);
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, operation);
    }
  }

  Future<void> submitBack(File image) async {
    if (!_beginSubmission()) return;
    final sessionId = state.scanSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      _fail(
        const SakeScanException(
          kind: SakeScanErrorKind.sessionExpired,
          message: 'スキャンセッションの有効期限が切れています',
        ),
      );
      return;
    }
    final operation = ++_operation;
    _emit(
      state.copyWith(
        status: SakeScanViewStatus.searchingBack,
        backImage: image,
        clearError: true,
      ),
    );
    try {
      final result = await _scanRepository.scanBack(sessionId, image);
      if (!_isCurrent(operation)) return;
      if (result.status == SakeScanApiStatus.aiRequired) {
        if (result.candidates.isNotEmpty) {
          _applyScanResult(result);
        } else {
          await _identifyFallbackCandidates(result.scanSessionId, operation);
        }
      } else {
        _applyScanResult(result);
      }
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, operation);
    }
  }

  void selectCandidate(int index) {
    if (state.isSubmitting || index < 0 || index >= state.candidates.length) {
      return;
    }
    state = state.copyWith(selectedCandidateIndex: index);
  }

  void showNextCandidate() {
    if (state.candidates.length < 2 || state.isSubmitting) return;
    final next = (state.selectedCandidateIndex + 1) % state.candidates.length;
    state = state.copyWith(selectedCandidateIndex: next);
  }

  Future<void> rejectCandidates() async {
    if (state.isSubmitting) return;
    final sessionId = state.scanSessionId;
    final candidateIds = state.candidates
        .map((candidate) => candidate.sakeId)
        .where((sakeId) => sakeId > 0)
        .toList(growable: false);
    if (sessionId == null || sessionId.isEmpty || candidateIds.isEmpty) {
      retry();
      return;
    }
    final operation = ++_operation;
    _emit(state.copyWith(isSubmitting: true, clearError: true));
    try {
      await _scanRepository.rejectCandidates(sessionId, candidateIds);
      if (!_isCurrent(operation)) return;
      if (state.backImage != null) {
        _emit(
          state.copyWith(
            candidates: const <SakeScanCandidate>[],
            selectedCandidateIndex: 0,
            isSubmitting: false,
            clearError: true,
          ),
        );
        await _identifyFallbackCandidates(sessionId, operation);
        return;
      }
      _emit(
        state.copyWith(
          status: SakeScanViewStatus.backScanning,
          candidates: const <SakeScanCandidate>[],
          selectedCandidateIndex: 0,
          isSubmitting: false,
          clearError: true,
          clearBackLabelReason: true,
        ),
      );
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, operation);
    }
  }

  void startNextScan() {
    if (_disposed || state.savedSake == null) return;
    ++_operation;
    state = const SakeScanState();
  }

  Future<Sake?> confirmCandidate() async {
    final candidate = state.selectedCandidate;
    final sessionId = state.scanSessionId;
    if (candidate == null || sessionId == null || !_beginSubmission()) {
      return null;
    }
    final operation = ++_operation;
    _emit(
      state.copyWith(
        status: SakeScanViewStatus.loadingOverview,
        sake: candidate.toSake(),
        clearError: true,
      ),
    );
    try {
      if (candidate.sakeId <= 0) {
        await _runAiAnalysis(operation);
        return state.savedSake ?? state.sake;
      }
      final confirmation = await _scanRepository.confirm(
        sessionId,
        candidate.sakeId,
      );
      if (!_isCurrent(operation)) return null;

      final confirmedSake = candidate.toSake().copyWith(
        sakeId: confirmation.sakeId,
      );

      final primaryImage = state.frontImage ?? state.backImage;
      if (primaryImage == null) {
        throw const SakeScanException(
          kind: SakeScanErrorKind.compression,
          message: '保存する撮影画像がありません',
        );
      }
      final secondaryImage = state.backImage?.path == primaryImage.path
          ? null
          : state.backImage;
      final saved = await _persistenceService.saveInitial(
        confirmedSake,
        primaryImage,
        secondaryImage: secondaryImage,
        isPublic: false,
      );
      if (!_isCurrent(operation)) return null;
      _emit(state.copyWith(sake: confirmedSake, savedSake: saved));

      if (confirmation.status == SakeScanApiStatus.cacheHit) {
        final completed = await _persistenceService.saveCompleted(
          saved,
          confirmedSake,
          primaryImage,
          isPublic: false,
        );
        if (!_isCurrent(operation)) return null;
        _emit(
          state.copyWith(
            status: SakeScanViewStatus.completed,
            sake: confirmedSake,
            savedSake: completed,
            isSubmitting: false,
          ),
        );
        return completed;
      }
      // 登録済みマスターはここで外部解析やoverview取得を待たない。
      // 詳細画面自身がマスター情報を一度だけ取得する。
      _emit(
        state.copyWith(
          status: SakeScanViewStatus.completed,
          sake: confirmedSake,
          savedSake: saved,
          isSubmitting: false,
        ),
      );
      return confirmedSake;
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, operation);
      return null;
    }
  }

  Future<void> identifyFallbackCandidates() async {
    if (state.isSubmitting) return;
    final scanSessionId = state.scanSessionId;
    if (scanSessionId == null || scanSessionId.isEmpty) {
      _fail(
        const SakeScanException(
          kind: SakeScanErrorKind.sessionExpired,
          message: 'スキャンセッションの有効期限が切れています',
        ),
      );
      return;
    }
    final operation = ++_operation;
    try {
      await _identifyFallbackCandidates(scanSessionId, operation);
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, operation);
    }
  }

  Future<void> _identifyFallbackCandidates(
    String scanSessionId,
    int operation,
  ) async {
    final image = state.frontImage ?? state.backImage;
    if (image == null) {
      throw const SakeScanException(
        kind: SakeScanErrorKind.aiAnalysis,
        message: 'AI候補特定用の画像がありません',
      );
    }
    _emit(
      state.copyWith(
        status: SakeScanViewStatus.identifyingFallback,
        isSubmitting: true,
      ),
    );
    final identified = await _analysisService.identifyCandidates(
      image,
      scanSessionId: scanSessionId,
      secondaryImage:
          state.backImage == null || state.backImage!.path == image.path
          ? null
          : state.backImage,
    );
    if (!_isCurrent(operation)) return;
    if (identified.isEmpty) {
      throw const SakeScanException(
        kind: SakeScanErrorKind.noCandidates,
        message: '候補の日本酒が見つかりませんでした',
      );
    }
    _emit(
      state.copyWith(
        status: SakeScanViewStatus.confirmingCandidate,
        scanSessionId: scanSessionId,
        candidates: identified
            .map(
              (candidate) => SakeScanCandidate(
                sakeId: candidate.sakeId ?? 0,
                brandId: candidate.brandId,
                name: candidate.name ?? '',
                type: candidate.type,
                brewery: candidate.brewery,
                imageUrl:
                    candidate.thumbnailImageUrl ?? candidate.primaryImageUrl,
              ),
            )
            .toList(growable: false),
        selectedCandidateIndex: 0,
        isSubmitting: false,
      ),
    );
  }

  void retry() {
    if (state.isSubmitting) return;
    ++_operation;
    state = const SakeScanState();
  }

  void reportCameraError(SakeScanException exception) {
    if (_disposed || state.isSubmitting) return;
    _fail(exception);
  }

  void _applyScanResult(SakeScanResult result) {
    if (result.status == SakeScanApiStatus.needBackLabel) {
      _emit(
        state.copyWith(
          status: SakeScanViewStatus.backScanning,
          scanSessionId: result.scanSessionId,
          backLabelReason: result.backLabelReason,
          isSubmitting: false,
        ),
      );
      return;
    }
    if (result.candidates.isEmpty) {
      _fail(
        const SakeScanException(
          kind: SakeScanErrorKind.noCandidates,
          message: '候補の日本酒が見つかりませんでした',
        ),
      );
      return;
    }
    _emit(
      state.copyWith(
        status: SakeScanViewStatus.confirmingCandidate,
        scanSessionId: result.scanSessionId,
        candidates: result.candidates,
        selectedCandidateIndex: 0,
        isSubmitting: false,
      ),
    );
  }

  Future<void> _runAiAnalysis(int operation) async {
    final basicSake = state.sake;
    if (basicSake == null) {
      throw const SakeScanException(
        kind: SakeScanErrorKind.aiAnalysis,
        message: '選択した日本酒の情報がありません',
      );
    }
    final hasMasterSake = (basicSake.sakeId ?? 0) > 0;
    // DBで特定できなかった場合、裏ラベルはOCRの補助に使い、既存の
    // 画像認識には商品を識別しやすい表ラベルを渡す。
    final image = hasMasterSake
        ? state.backImage ?? state.frontImage
        : state.frontImage ?? state.backImage;
    if (image == null) {
      throw const SakeScanException(
        kind: SakeScanErrorKind.aiAnalysis,
        message: 'AI解析用の画像がありません',
      );
    }
    final scanSessionId = state.scanSessionId;
    final primaryImage = state.frontImage ?? image;
    final secondaryImage = state.backImage?.path == primaryImage.path
        ? null
        : state.backImage;
    _emit(
      state.copyWith(
        status: SakeScanViewStatus.loadingDetails,
        isSubmitting: true,
      ),
    );

    Sake? saved = state.savedSake;
    if (saved == null && hasMasterSake) {
      saved = await _persistenceService.saveInitial(
        basicSake,
        primaryImage,
        secondaryImage: secondaryImage,
        isPublic: false,
      );
      if (_isCurrent(operation)) {
        _emit(state.copyWith(savedSake: saved));
      }
    }

    try {
      final analyzed = await _analysisService.analyze(
        image,
        sakeId: hasMasterSake ? basicSake.sakeId : null,
        scanSessionId: scanSessionId,
        confirmedSake: hasMasterSake ? null : basicSake,
      );
      final completedSake = _mergeBasicAndAnalysis(
        basicSake,
        analyzed,
        preferAnalyzedIdentity: !hasMasterSake,
      );
      saved ??= await _persistenceService.saveInitial(
        completedSake,
        primaryImage,
        secondaryImage: secondaryImage,
        isPublic: false,
      );
      final completed = await _persistenceService.saveCompleted(
        saved,
        completedSake,
        image,
        isPublic: false,
      );
      if (!_isCurrent(operation)) return;
      _emit(
        state.copyWith(
          status: SakeScanViewStatus.completed,
          sake: completed,
          savedSake: completed,
          isSubmitting: false,
        ),
      );
    } catch (error) {
      throw SakeScanException(
        kind: SakeScanErrorKind.aiAnalysis,
        message: error.toString(),
      );
    }
  }

  Sake _mergeBasicAndAnalysis(
    Sake? basic,
    Sake analyzed, {
    bool preferAnalyzedIdentity = false,
  }) {
    if (basic == null) return analyzed;
    return analyzed.copyWith(
      // An existing master remains authoritative. For an AI-only candidate,
      // use the detailed Perplexity identity returned by the API.
      sakeId: basic.sakeId ?? analyzed.sakeId,
      brandId: basic.brandId ?? analyzed.brandId,
      name: preferAnalyzedIdentity
          ? analyzed.name ?? basic.name
          : basic.name ?? analyzed.name,
      brewery: preferAnalyzedIdentity
          ? analyzed.brewery ?? basic.brewery
          : basic.brewery ?? analyzed.brewery,
      type: preferAnalyzedIdentity
          ? analyzed.type ?? basic.type
          : basic.type ?? analyzed.type,
      prefectureCode: basic.prefectureCode ?? analyzed.prefectureCode,
      primaryImageUrl: basic.primaryImageUrl ?? analyzed.primaryImageUrl,
      thumbnailImageUrl: basic.thumbnailImageUrl ?? analyzed.thumbnailImageUrl,
      community: basic.community ?? analyzed.community,
      sameBrandSakes: basic.sameBrandSakes ?? analyzed.sameBrandSakes,
    );
  }

  bool _beginSubmission() {
    if (_disposed || state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true);
    return true;
  }

  bool _isCurrent(int operation) => !_disposed && operation == _operation;

  void _handleError(Object error, StackTrace stackTrace, int operation) {
    logger.warning('日本酒ラベルスキャンに失敗しました: $error');
    logger.info(stackTrace.toString());
    if (!_isCurrent(operation)) return;
    _fail(SakeScanException.fromError(error));
  }

  void _fail(SakeScanException exception) {
    _emit(
      state.copyWith(
        status: SakeScanViewStatus.error,
        error: exception,
        isSubmitting: false,
      ),
    );
  }

  void _emit(SakeScanState next) {
    if (!_disposed) state = next;
  }

  @override
  void dispose() {
    _disposed = true;
    ++_operation;
    super.dispose();
  }
}
