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
  aiAnalyzing,
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
    this.shareToTimeline = false,
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
  final bool shareToTimeline;

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
    bool? shareToTimeline,
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
      shareToTimeline: shareToTimeline ?? this.shareToTimeline,
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

  void setShareToTimeline(bool value) {
    if (_disposed || state.isSubmitting) return;
    state = state.copyWith(shareToTimeline: value);
  }

  Future<void> submitFront(File image) async {
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
      final result = await _scanRepository.scanFront(image);
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
          await _identifyFallbackCandidate(result, operation);
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
    state = SakeScanState(shareToTimeline: state.shareToTimeline);
  }

  Future<void> confirmCandidate() async {
    final candidate = state.selectedCandidate;
    final sessionId = state.scanSessionId;
    if (candidate == null || sessionId == null || !_beginSubmission()) return;
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
        return;
      }
      final confirmation = await _scanRepository.confirm(
        sessionId,
        candidate.sakeId,
      );
      final overview = await _scanRepository.fetchOverview(confirmation.sakeId);
      if (!_isCurrent(operation)) return;

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
        overview.sake,
        primaryImage,
        secondaryImage: secondaryImage,
        isPublic: state.shareToTimeline,
      );
      if (!_isCurrent(operation)) return;
      _emit(state.copyWith(sake: overview.sake, savedSake: saved));

      // confirm時点で解析キャッシュを確認済み。Overviewの表示用ペイロードが
      // 空でも、既解析の酒に画像解析を重ねて走らせない。
      if (overview.analysisCompleted ||
          confirmation.status == SakeScanApiStatus.cacheHit) {
        final completed = await _persistenceService.saveCompleted(
          saved,
          overview.sake,
          primaryImage,
          isPublic: state.shareToTimeline,
        );
        if (!_isCurrent(operation)) return;
        _emit(
          state.copyWith(
            status: SakeScanViewStatus.completed,
            sake: overview.sake,
            savedSake: completed,
            isSubmitting: false,
          ),
        );
        return;
      }
      await _runAiAnalysis(operation);
    } catch (error, stackTrace) {
      _handleError(error, stackTrace, operation);
    }
  }

  Future<void> _identifyFallbackCandidate(
    SakeScanResult result,
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
        scanSessionId: result.scanSessionId,
        candidates: identified
            .map(
              (candidate) => SakeScanCandidate(
                sakeId: 0,
                name: candidate.name ?? '',
                type: candidate.type,
                brewery: candidate.brewery,
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
    state = SakeScanState(shareToTimeline: state.shareToTimeline);
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
    final hasMasterSake = (basicSake?.sakeId ?? 0) > 0;
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
    final shareToTimeline = state.shareToTimeline;
    final primaryImage = state.frontImage ?? image;
    final secondaryImage = state.backImage?.path == primaryImage.path
        ? null
        : state.backImage;
    _emit(
      state.copyWith(
        status: SakeScanViewStatus.aiAnalyzing,
        isSubmitting: true,
      ),
    );

    Sake? saved = state.savedSake;
    if (saved == null && hasMasterSake) {
      saved = await _persistenceService.saveInitial(
        basicSake!,
        primaryImage,
        secondaryImage: secondaryImage,
        isPublic: shareToTimeline,
      );
      if (_isCurrent(operation)) {
        _emit(state.copyWith(savedSake: saved));
      }
    }

    try {
      final analyzed = await _analysisService.analyze(
        image,
        sakeId: hasMasterSake ? basicSake!.sakeId : null,
        scanSessionId: scanSessionId,
      );
      saved ??= await _persistenceService.saveInitial(
        analyzed,
        primaryImage,
        secondaryImage: secondaryImage,
        isPublic: shareToTimeline,
      );
      final completed = await _persistenceService.saveCompleted(
        saved,
        _mergeBasicAndAnalysis(basicSake, analyzed),
        image,
        isPublic: shareToTimeline,
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

  Sake _mergeBasicAndAnalysis(Sake? basic, Sake analyzed) {
    if (basic == null) return analyzed;
    return analyzed.copyWith(
      sakeId: analyzed.sakeId ?? basic.sakeId,
      brandId: analyzed.brandId ?? basic.brandId,
      name: analyzed.name ?? basic.name,
      brewery: analyzed.brewery ?? basic.brewery,
      type: analyzed.type ?? basic.type,
      prefectureCode: analyzed.prefectureCode ?? basic.prefectureCode,
      primaryImageUrl: analyzed.primaryImageUrl ?? basic.primaryImageUrl,
      community: analyzed.community ?? basic.community,
      sameBrandSakes: analyzed.sameBrandSakes ?? basic.sameBrandSakes,
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
