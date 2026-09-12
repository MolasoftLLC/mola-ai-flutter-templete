import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';

import '../../common/localization/localization_extensions.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/auth_repository.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../../domain/repository/saved_sake_sync_repository.dart';
import '../../domain/services/sake_scan_services.dart';
import 'sake_scan_notifier.dart';

class SakeScanPage extends StatefulWidget {
  const SakeScanPage._();

  static Widget wrapped() {
    return Builder(
      builder: (context) {
        return StateNotifierProvider<SakeScanNotifier, SakeScanState>(
          create: (_) => SakeScanNotifier(
            scanRepository: context.read<SakeScanRepository>(),
            analysisService: DefaultSakeScanAnalysisService(
              context.read<SakeMenuRecognitionRepository>(),
              preferencesProvider: () =>
                  context.read<MyPageNotifier>().currentPreferences,
            ),
            persistenceService: DefaultSakeScanPersistenceService(
              savedSakeNotifier: context.read<SavedSakeNotifier>(),
              syncRepository: context.read<SavedSakeSyncRepository>(),
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          child: const SakeScanPage._(),
        );
      },
    );
  }

  @override
  State<SakeScanPage> createState() => _SakeScanPageState();
}

class _SakeScanPageState extends State<SakeScanPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _availableCameras = const [];
  Timer? _focusRingTimer;
  bool _initializingCamera = false;
  bool _capturing = false;
  bool _isCloseUpMode = false;
  Offset? _focusRingPosition;
  double _minZoomLevel = 1;
  double _maxZoomLevel = 1;
  double _currentZoomLevel = 1;
  double _zoomLevelAtScaleStart = 1;
  Sake? _lastResult;
  String? _promptedBackLabelSessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusRingTimer?.cancel();
    final controller = _cameraController;
    _cameraController = null;
    if (controller != null) unawaited(controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final controller = _cameraController;
      _cameraController = null;
      if (controller != null) unawaited(controller.dispose());
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_initializeCamera());
    }
  }

  Future<void> _initializeCamera() async {
    if (_initializingCamera || _cameraController != null || !mounted) return;
    _initializingCamera = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('CameraUnavailable', 'No camera is available');
      }
      _availableCameras = cameras;
      final closeUpCamera = selectCloseUpSakeScanCamera(cameras);
      final description = _isCloseUpMode && closeUpCamera != null
          ? closeUpCamera
          : selectPreferredSakeScanCamera(cameras);
      await _openCamera(description);
    } on CameraException catch (error) {
      _reportCameraInitializationError(error);
    } finally {
      _initializingCamera = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _openCamera(CameraDescription description) async {
    final previousController = _cameraController;
    _cameraController = null;
    _focusRingTimer?.cancel();
    _focusRingPosition = null;
    if (mounted) setState(() {});
    if (previousController != null) await previousController.dispose();

    final controller = CameraController(
      description,
      ResolutionPreset.max,
      enableAudio: false,
    );
    try {
      await controller.initialize();
      var minZoomLevel = 1.0;
      var maxZoomLevel = 1.0;
      try {
        minZoomLevel = await controller.getMinZoomLevel();
        // 端末によっては非常に大きい倍率（例: 50x以上）が返るため、
        // スライダーの低倍率域が使いにくくならないよう10xまでにする。
        maxZoomLevel = (await controller.getMaxZoomLevel()).clamp(1.0, 10.0);
      } on CameraException {
        // ズーム取得非対応の端末では等倍のまま利用する。
      }
      if (!mounted) {
        await controller.dispose();
        return;
      }
      _cameraController = controller;
      _isCloseUpMode = description.lensType == CameraLensType.ultraWide;
      _minZoomLevel = minZoomLevel;
      _maxZoomLevel = maxZoomLevel;
      _currentZoomLevel = clampSakeScanZoomLevel(
        requestedZoomLevel: 1,
        minZoomLevel: minZoomLevel,
        maxZoomLevel: maxZoomLevel,
      );
      _zoomLevelAtScaleStart = _currentZoomLevel;
      setState(() {});
    } on CameraException {
      await controller.dispose();
      rethrow;
    }
  }

  Future<void> _toggleCloseUpMode() async {
    if (_initializingCamera || _capturing) return;
    final currentDescription = _cameraController?.description;
    if (currentDescription == null) return;
    final targetDescription = _isCloseUpMode
        ? selectPreferredSakeScanCamera(_availableCameras)
        : selectCloseUpSakeScanCamera(_availableCameras);
    if (targetDescription == null ||
        targetDescription.name == currentDescription.name) {
      return;
    }

    _initializingCamera = true;
    try {
      await _openCamera(targetDescription);
      await HapticFeedback.selectionClick();
    } on CameraException catch (error) {
      try {
        await _openCamera(currentDescription);
      } on CameraException {
        _reportCameraInitializationError(error);
      }
    } finally {
      _initializingCamera = false;
      if (mounted) setState(() {});
    }
  }

  void _reportCameraInitializationError(CameraException error) {
    if (!mounted) return;
    final permissionDenied = <String>{
      'CameraAccessDenied',
      'CameraAccessDeniedWithoutPrompt',
      'CameraAccessRestricted',
    }.contains(error.code);
    context.read<SakeScanNotifier>().reportCameraError(
      SakeScanException(
        kind: permissionDenied
            ? SakeScanErrorKind.cameraPermission
            : SakeScanErrorKind.unknown,
        message: error.description ?? error.code,
      ),
    );
  }

  Future<void> _capture() async {
    final controller = _cameraController;
    final scanState = context.read<SakeScanNotifier>().currentState;
    if (_capturing ||
        scanState.isSubmitting ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }
    _capturing = true;
    if (mounted) setState(() {});
    try {
      final captured = await controller.takePicture();
      // ガイド枠は構図の目安にせず、プレビュー全体をそのままOCRへ渡す。
      final file = File(captured.path);
      if (!mounted) return;
      await HapticFeedback.mediumImpact();
      await _submitImage(file);
    } on CameraException catch (error) {
      if (!mounted) return;
      context.read<SakeScanNotifier>().reportCameraError(
        SakeScanException(
          kind: SakeScanErrorKind.unknown,
          message: error.description ?? error.code,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      context.read<SakeScanNotifier>().reportCameraError(
        SakeScanException(
          kind: SakeScanErrorKind.compression,
          message: error.toString(),
        ),
      );
    } finally {
      _capturing = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _focusAt(
    Offset tapPosition, {
    required Size viewportSize,
    required Size previewSize,
  }) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final supportsFocus = controller.value.focusPointSupported;
    final supportsExposure = controller.value.exposurePointSupported;
    if (!supportsFocus && !supportsExposure) return;

    final point = normalizeCameraPreviewPoint(
      tapPosition: tapPosition,
      viewportSize: viewportSize,
      previewSize: previewSize,
    );
    _showFocusRing(tapPosition);
    try {
      if (supportsFocus) {
        await controller.setFocusPoint(point);
      }
      if (supportsExposure) {
        await controller.setExposurePoint(point);
      }
    } on CameraException {
      // 端末が実行時にポイント指定を拒否しても、スキャン自体は継続する。
    }
  }

  void _showFocusRing(Offset position) {
    _focusRingTimer?.cancel();
    _focusRingPosition = position;
    if (mounted) setState(() {});
    _focusRingTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _focusRingPosition = null);
    });
  }

  Future<void> _setZoomLevel(double requestedZoomLevel) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    final zoomLevel = clampSakeScanZoomLevel(
      requestedZoomLevel: requestedZoomLevel,
      minZoomLevel: _minZoomLevel,
      maxZoomLevel: _maxZoomLevel,
    );
    if ((zoomLevel - _currentZoomLevel).abs() < 0.01) return;

    final previousZoomLevel = _currentZoomLevel;
    _currentZoomLevel = zoomLevel;
    if (mounted) setState(() {});
    try {
      await controller.setZoomLevel(zoomLevel);
    } on CameraException {
      if (!mounted || controller != _cameraController) return;
      if ((_currentZoomLevel - zoomLevel).abs() < 0.01) {
        setState(() => _currentZoomLevel = previousZoomLevel);
      }
    }
  }

  void _closeScan(SakeScanState state) {
    Navigator.of(
      context,
    ).maybePop<Sake>(state.savedSake ?? state.sake ?? _lastResult);
  }

  void _startNextScan(SakeScanState state) {
    _lastResult = state.savedSake ?? state.sake ?? _lastResult;
    context.read<SakeScanNotifier>().startNextScan();
    unawaited(HapticFeedback.selectionClick());
  }

  Future<void> _submitImage(File file) async {
    final notifier = context.read<SakeScanNotifier>();
    final state = notifier.currentState;
    final shouldSubmitBack =
        state.status == SakeScanViewStatus.backScanning ||
        (state.status == SakeScanViewStatus.error &&
            state.scanSessionId != null &&
            state.frontImage != null);
    if (shouldSubmitBack) {
      await notifier.submitBack(file);
    } else {
      await notifier.submitFront(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SakeScanState>();
    if (state.status == SakeScanViewStatus.backScanning &&
        state.backLabelReason != null &&
        state.scanSessionId != _promptedBackLabelSessionId) {
      _promptedBackLabelSessionId = state.scanSessionId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_showBackLabelPrompt(state.backLabelReason!));
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFF0A1428),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraSurface(state),
            const IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.black54,
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black54,
                    ],
                    stops: <double>[0, 0.22, 0.62, 1],
                  ),
                ),
              ),
            ),
            if (state.status == SakeScanViewStatus.frontScanning ||
                state.status == SakeScanViewStatus.backScanning)
              _buildCameraHeader(state),
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey<SakeScanViewStatus>(state.status),
                  child: _buildBottomPanel(state),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: () => _closeScan(state),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBackLabelPrompt(SakeScanBackLabelReason reason) async {
    final message = switch (reason) {
      SakeScanBackLabelReason.ocrUnreadable =>
        context.l10n.scanBackPromptOcrUnreadable,
      SakeScanBackLabelReason.noCatalogMatch =>
        context.l10n.scanBackPromptNoCatalogMatch,
      SakeScanBackLabelReason.lowConfidence =>
        context.l10n.scanBackPromptLowConfidence,
    };
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.scanBackPromptTitle),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.scanBackPromptAction),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomPanel(SakeScanState state) {
    return switch (state.status) {
      SakeScanViewStatus.frontScanning ||
      SakeScanViewStatus.backScanning => _buildCaptureControls(state),
      SakeScanViewStatus.searchingFront || SakeScanViewStatus.searchingBack =>
        _buildStatusPanel(context.l10n.searchingLabel),
      SakeScanViewStatus.confirmingCandidate => _buildCandidates(state),
      SakeScanViewStatus.loadingOverview => _buildStatusPanel(
        context.l10n.loadingSakeOverview,
      ),
      SakeScanViewStatus.identifyingFallback => _buildStatusPanel(
        '候補を絞りきれなかったため、表・裏ラベルを詳しく解析しています…',
      ),
      SakeScanViewStatus.aiAnalyzing ||
      SakeScanViewStatus.completed => _buildResultPanel(state),
      SakeScanViewStatus.error => _buildError(state),
    };
  }

  Widget _buildCameraSurface(SakeScanState state) {
    final capturedImage = switch (state.status) {
      SakeScanViewStatus.frontScanning ||
      SakeScanViewStatus.backScanning => null,
      _ => state.backImage ?? state.frontImage,
    };
    if (capturedImage != null) {
      return Image.file(
        capturedImage,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFFFFD54F)),
        ),
      );
    }
    final previewSize = controller.value.previewSize;
    if (previewSize == null) {
      return const ColoredBox(color: Colors.black);
    }
    final displayedPreviewSize = Size(previewSize.height, previewSize.width);
    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => unawaited(
                _focusAt(
                  details.localPosition,
                  viewportSize: constraints.biggest,
                  previewSize: displayedPreviewSize,
                ),
              ),
              onScaleStart: (_) {
                _zoomLevelAtScaleStart = _currentZoomLevel;
              },
              onScaleUpdate: (details) {
                if (details.pointerCount != 2) return;
                unawaited(
                  _setZoomLevel(_zoomLevelAtScaleStart * details.scale),
                );
              },
              child: ClipRect(
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  child: SizedBox.fromSize(
                    size: displayedPreviewSize,
                    child: CameraPreview(controller),
                  ),
                ),
              ),
            ),
          ),
          if (_focusRingPosition != null)
            Positioned(
              left: _focusRingPosition!.dx - 24,
              top: _focusRingPosition!.dy - 24,
              child: const IgnorePointer(child: _CameraFocusRing()),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraHeader(SakeScanState state) {
    final isBack = state.status == SakeScanViewStatus.backScanning;
    return Positioned(
      top: 72,
      left: 20,
      right: 20,
      child: Column(
        children: [
          Text(
            isBack
                ? context.l10n.backLabelScanTitle
                : context.l10n.frontLabelScanTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isBack
                ? context.l10n.backLabelScanDescription
                : context.l10n.frontLabelScanDescription,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureControls(SakeScanState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (selectCloseUpSakeScanCamera(_availableCameras) != null) ...[
                _CameraCloseUpButton(
                  label: context.l10n.closeUpMode,
                  selected: _isCloseUpMode,
                  onPressed: _initializingCamera
                      ? null
                      : () => unawaited(_toggleCloseUpMode()),
                ),
                const SizedBox(width: 12),
              ],
              const Icon(Icons.zoom_out, color: Colors.white70),
              Expanded(
                child: Slider(
                  value: _currentZoomLevel,
                  min: _minZoomLevel,
                  max: _maxZoomLevel,
                  divisions: ((_maxZoomLevel - _minZoomLevel) * 10)
                      .round()
                      .clamp(1, 90),
                  onChanged: _maxZoomLevel > _minZoomLevel
                      ? (value) => unawaited(_setZoomLevel(value))
                      : null,
                  activeColor: const Color(0xFFFFD54F),
                  inactiveColor: Colors.white30,
                ),
              ),
              const Icon(Icons.zoom_in, color: Colors.white70),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${_currentZoomLevel.toStringAsFixed(1)}×',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            button: true,
            label: context.l10n.captureLabel,
            child: SizedBox.square(
              dimension: 76,
              child: FilledButton(
                onPressed:
                    _capturing ||
                        state.isSubmitting ||
                        _cameraController == null ||
                        !_cameraController!.value.isInitialized
                    ? null
                    : _capture,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(
                    side: BorderSide(color: Colors.white, width: 4),
                  ),
                  backgroundColor: const Color(0xFFFFD54F),
                  foregroundColor: const Color(0xFF1D3567),
                ),
                child: const Icon(Icons.camera_alt_rounded, size: 34),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPanel(String message) {
    return _BottomCard(
      child: Row(
        children: [
          const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1D3567),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidates(SakeScanState state) {
    final candidate = state.selectedCandidate;
    if (candidate == null) return _buildError(state);
    return _BottomCard(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.68,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.whichSakeCandidate,
              style: const TextStyle(
                color: Color(0xFF1D3567),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE1E5EB)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Scrollbar(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: state.candidates.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final item = state.candidates[index];
                        final selected = index == state.selectedCandidateIndex;
                        final details =
                            [item.brewery?.trim(), item.type?.trim()]
                                .whereType<String>()
                                .where((value) => value.isNotEmpty);
                        return Material(
                          color: selected
                              ? const Color(0xFFFFF8ED)
                              : Colors.white,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 3,
                            ),
                            leading: _ScanCandidateThumbnail(
                              imageUrl: item.imageUrl,
                            ),
                            title: Text(
                              item.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF1D3567),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: details.isEmpty
                                ? null
                                : Text(
                                    details.join(' / '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                            trailing: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.chevron_right,
                              color: selected
                                  ? const Color(0xFFFF7A1A)
                                  : const Color(0xFF697386),
                            ),
                            onTap: state.isSubmitting
                                ? null
                                : () {
                                    context
                                        .read<SakeScanNotifier>()
                                        .selectCandidate(index);
                                    unawaited(HapticFeedback.selectionClick());
                                  },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: state.isSubmitting
                  ? null
                  : () {
                      unawaited(HapticFeedback.selectionClick());
                      unawaited(
                        context.read<SakeScanNotifier>().confirmCandidate(),
                      );
                    },
              icon: const Icon(Icons.check_circle_outline),
              label: Text(context.l10n.yesThisSake),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFFD54F),
                foregroundColor: const Color(0xFF1D3567),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              onPressed: state.isSubmitting
                  ? null
                  : () => unawaited(
                      context.read<SakeScanNotifier>().rejectCandidates(),
                    ),
              icon: const Icon(Icons.flip_camera_ios_outlined),
              label: Text(
                state.backImage == null
                    ? context.l10n.wrongTakeBackLabel
                    : context.l10n.wrongRetakeBackLabel,
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1D3567),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPanel(SakeScanState state) {
    final isAnalyzing = state.status == SakeScanViewStatus.aiAnalyzing;
    final sake = state.savedSake ?? state.sake;
    return _BottomCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                isAnalyzing ? Icons.auto_awesome : Icons.verified,
                color: const Color(0xFF1D3567),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isAnalyzing
                      ? context.l10n.scanAiAnalyzing
                      : context.l10n.scanCompleted,
                  style: const TextStyle(
                    color: Color(0xFF1D3567),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (isAnalyzing) ...[
            const SizedBox(height: 10),
            const LinearProgressIndicator(minHeight: 3),
          ],
          if (sake != null) ...[
            const SizedBox(height: 14),
            _CompactSakeSummary(sake: sake),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop<Sake>(sake),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1D3567),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(context.l10n.finishScan),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: state.savedSake == null
                        ? null
                        : () => _startNextScan(state),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(context.l10n.scanNextBottle),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFD54F),
                      foregroundColor: const Color(0xFF1D3567),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(SakeScanState state) {
    return _BottomCard(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.deepOrange, size: 36),
            const SizedBox(height: 10),
            Text(
              _errorText(state.error),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF1D3567), fontSize: 15),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                context.read<SakeScanNotifier>().retry();
                unawaited(_initializeCamera());
              },
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.retryScan),
            ),
          ],
        ),
      ),
    );
  }

  String _errorText(SakeScanException? error) {
    return switch (error?.kind) {
      SakeScanErrorKind.cameraPermission =>
        context.l10n.scanCameraPermissionDenied,
      SakeScanErrorKind.compression => context.l10n.scanErrorCompression,
      SakeScanErrorKind.timeout => context.l10n.scanErrorTimeout,
      SakeScanErrorKind.noCandidates => context.l10n.scanErrorNoCandidates,
      SakeScanErrorKind.sessionExpired => context.l10n.scanErrorSessionExpired,
      SakeScanErrorKind.rateLimited => context.l10n.scanErrorRateLimited,
      SakeScanErrorKind.server => context.l10n.scanErrorServer,
      SakeScanErrorKind.aiAnalysis => context.l10n.scanErrorAi,
      _ => context.l10n.scanErrorGeneric,
    };
  }
}

CameraDescription selectPreferredSakeScanCamera(
  List<CameraDescription> cameras,
) {
  if (cameras.isEmpty) {
    throw StateError('利用可能なカメラがありません');
  }
  final backCameras = cameras
      .where((camera) => camera.lensDirection == CameraLensDirection.back)
      .toList(growable: false);
  if (backCameras.isEmpty) return cameras.first;

  for (final lensType in <CameraLensType>[
    CameraLensType.wide,
    CameraLensType.unknown,
    CameraLensType.ultraWide,
    CameraLensType.telephoto,
  ]) {
    for (final camera in backCameras) {
      if (camera.lensType == lensType) return camera;
    }
  }
  return backCameras.first;
}

CameraDescription? selectCloseUpSakeScanCamera(
  List<CameraDescription> cameras,
) {
  for (final camera in cameras) {
    if (camera.lensDirection == CameraLensDirection.back &&
        camera.lensType == CameraLensType.ultraWide) {
      return camera;
    }
  }
  return null;
}

/// [BoxFit.cover] で切り取られたプレビュー上の座標をカメラの0〜1座標へ変換する。
Offset normalizeCameraPreviewPoint({
  required Offset tapPosition,
  required Size viewportSize,
  required Size previewSize,
}) {
  if (viewportSize.isEmpty || previewSize.isEmpty) {
    return const Offset(0.5, 0.5);
  }
  final fittedSizes = applyBoxFit(BoxFit.cover, previewSize, viewportSize);
  final sourceRect = Alignment.center.inscribe(
    fittedSizes.source,
    Offset.zero & previewSize,
  );
  final destinationRect = Alignment.center.inscribe(
    fittedSizes.destination,
    Offset.zero & viewportSize,
  );
  final normalizedDestinationX =
      ((tapPosition.dx - destinationRect.left) / destinationRect.width)
          .clamp(0.0, 1.0)
          .toDouble();
  final normalizedDestinationY =
      ((tapPosition.dy - destinationRect.top) / destinationRect.height)
          .clamp(0.0, 1.0)
          .toDouble();

  return Offset(
    (sourceRect.left + normalizedDestinationX * sourceRect.width) /
        previewSize.width,
    (sourceRect.top + normalizedDestinationY * sourceRect.height) /
        previewSize.height,
  );
}

double clampSakeScanZoomLevel({
  required double requestedZoomLevel,
  required double minZoomLevel,
  required double maxZoomLevel,
}) {
  if (!requestedZoomLevel.isFinite ||
      !minZoomLevel.isFinite ||
      !maxZoomLevel.isFinite ||
      minZoomLevel > maxZoomLevel) {
    return 1;
  }
  return requestedZoomLevel.clamp(minZoomLevel, maxZoomLevel).toDouble();
}

class _CameraFocusRing extends StatelessWidget {
  const _CameraFocusRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFFD54F), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}

class _CameraCloseUpButton extends StatelessWidget {
  const _CameraCloseUpButton({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: selected ? const Color(0xFFFFD54F) : Colors.black54,
          foregroundColor: selected ? const Color(0xFF1D3567) : Colors.white,
          disabledBackgroundColor: Colors.black26,
          disabledForegroundColor: Colors.white38,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.center_focus_strong, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _BottomCard extends StatelessWidget {
  const _BottomCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black38,
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ScanCandidateThumbnail extends StatelessWidget {
  const _ScanCandidateThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: ColoredBox(
      color: const Color(0xFFF0F2F5),
      child: SizedBox(
        width: 46,
        height: 46,
        child: imageUrl?.isNotEmpty ?? false
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.local_drink_outlined,
                  color: Color(0xFF1D3567),
                ),
              )
            : const Icon(Icons.local_drink_outlined, color: Color(0xFF1D3567)),
      ),
    ),
  );
}

class _CompactSakeSummary extends StatelessWidget {
  const _CompactSakeSummary({required this.sake});

  final Sake sake;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SakeThumbnail(imageUrl: sake.primaryImageUrl),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sake.name ?? context.l10n.unknownSake,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF1D3567),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (sake.type?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(sake.type!),
              ],
              if (sake.brewery?.isNotEmpty ?? false) ...[
                const SizedBox(height: 4),
                Text(
                  sake.brewery!,
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SakeThumbnail extends StatelessWidget {
  const _SakeThumbnail({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: const Color(0xFFF2F4F8),
        child: SizedBox(
          width: 76,
          height: 88,
          child: imageUrl?.isNotEmpty ?? false
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.wine_bar_outlined,
                    color: Color(0xFF1D3567),
                    size: 34,
                  ),
                )
              : const Icon(
                  Icons.wine_bar_outlined,
                  color: Color(0xFF1D3567),
                  size: 34,
                ),
        ),
      ),
    );
  }
}
