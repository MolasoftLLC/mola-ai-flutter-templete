import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../common/localization/localization_extensions.dart';
import '../../common/logger.dart';
import 'widgets/menu_photo_style.dart';

/// Returns the full photograph immediately after the shutter. Photo review,
/// cropping and retakes belong to MenuPhotoFlowPage, not the system picker.
class MenuCameraPage extends StatefulWidget {
  const MenuCameraPage({super.key});
  @override
  State<MenuCameraPage> createState() => _MenuCameraPageState();
}

class _MenuCameraPageState extends State<MenuCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  Future<void> _cameraWork = Future<void>.value();
  int _generation = 0;
  bool _capturing = false;
  bool _opening = true;
  bool _flashOn = false;
  String? _error;
  double _minZoom = 1, _maxZoom = 1, _zoom = 1, _startZoom = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _configure(active: true);
  }

  // Serialize native camera allocation/disposal, including backgrounding while
  // permission or initialization is pending. Late initialization is discarded.
  void _configure({required bool active}) {
    final generation = ++_generation;
    if (mounted) {
      setState(() {
        _opening = active;
        _error = null;
      });
    }
    _cameraWork = _cameraWork
        .then((_) async {
          final previous = _controller;
          _controller = null;
          if (previous != null) await previous.dispose();
          if (!active || !mounted || generation != _generation) return;
          CameraController? candidate;
          try {
            final cameras = await availableCameras();
            if (!mounted || generation != _generation) return;
            if (cameras.isEmpty) {
              throw CameraException('CameraUnavailable', 'No camera');
            }
            final back = cameras.where(
              (camera) => camera.lensDirection == CameraLensDirection.back,
            );
            final description =
                back
                    .where((camera) => camera.lensType == CameraLensType.wide)
                    .firstOrNull ??
                back.firstOrNull ??
                cameras.first;
            candidate = CameraController(
              description,
              ResolutionPreset.max,
              enableAudio: false,
            );
            await candidate.initialize();
            var min = 1.0, max = 1.0;
            try {
              min = await candidate.getMinZoomLevel();
              max = (await candidate.getMaxZoomLevel()).clamp(min, 10.0);
              await candidate.setFlashMode(FlashMode.off);
            } on CameraException {
              /* Some devices do not support zoom/flash. */
            }
            if (!mounted || generation != _generation) {
              await candidate.dispose();
              return;
            }
            _controller = candidate;
            setState(() {
              _opening = false;
              _minZoom = min;
              _maxZoom = max;
              _zoom = 1.0.clamp(min, max);
              _flashOn = false;
            });
          } catch (error) {
            if (candidate != null) await candidate.dispose();
            if (!mounted || generation != _generation) return;
            logger.warning('メニュー撮影のカメラを開始できませんでした: $error');
            final denied =
                error is CameraException &&
                {
                  'CameraAccessDenied',
                  'CameraAccessDeniedWithoutPrompt',
                  'CameraAccessRestricted',
                }.contains(error.code);
            setState(() {
              _opening = false;
              _error = denied
                  ? context.l10n.scanCameraPermissionDenied
                  : context.l10n.scanCameraUnavailable;
            });
          }
        })
        .catchError((Object error) {
          logger.warning('メニュー撮影のカメラを終了できませんでした: $error');
          if (mounted && generation == _generation) {
            setState(() {
              _opening = false;
              _error = context.l10n.scanCameraUnavailable;
            });
          }
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _configure(active: false);
    }
    if (state == AppLifecycleState.resumed) _configure(active: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _generation++;
    _cameraWork = _cameraWork
        .then((_) async {
          final controller = _controller;
          _controller = null;
          if (controller != null) await controller.dispose();
        })
        .catchError((Object error) {
          logger.warning('メニュー撮影のカメラ解放: $error');
        });
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    final generation = _generation;
    if (_capturing ||
        _opening ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final photo = await controller.takePicture();
      if (mounted && generation == _generation) {
        Navigator.of(context).pop(File(photo.path));
      }
    } catch (error) {
      logger.warning('メニューを撮影できませんでした: $error');
      if (mounted && generation == _generation) {
        setState(() => _error = context.l10n.menuPhotoCaptureFailed);
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _flash() async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    try {
      final on = !_flashOn;
      await controller.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      if (mounted && controller == _controller) setState(() => _flashOn = on);
    } on CameraException {
      /* Keep capture available on cameras without a flash. */
    }
  }

  Future<void> _focus(Offset point) async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    try {
      await controller.setFocusPoint(point);
      await controller.setExposurePoint(point);
    } on CameraException {
      /* Focus/exposure points are optional device features. */
    }
  }

  Future<void> _setZoom(double scale) async {
    final controller = _controller;
    if (controller == null || _capturing) return;
    final zoom = (_startZoom * scale).clamp(_minZoom, _maxZoom);
    try {
      await controller.setZoomLevel(zoom);
      if (mounted && controller == _controller) _zoom = zoom;
    } on CameraException {
      /* Keep the last working zoom level. */
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final ready = !_opening && controller?.value.isInitialized == true;
    return PopScope(
      canPop: !_capturing,
      child: Scaffold(
        backgroundColor: MenuPhotoStyle.blue,
        appBar: MenuPhotoStyle.appBar(
          context.l10n.menuCapturePhoto,
          onBack: _capturing ? null : () => Navigator.of(context).pop(),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _opening
                      ? const CircularProgressIndicator(color: Colors.white)
                      : ready
                      ? CameraPreview(
                          controller!,
                          child: LayoutBuilder(
                            builder: (context, box) => GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapUp: (details) => _focus(
                                Offset(
                                  (details.localPosition.dx / box.maxWidth)
                                      .clamp(0, 1),
                                  (details.localPosition.dy / box.maxHeight)
                                      .clamp(0, 1),
                                ),
                              ),
                              onScaleStart: (_) => _startZoom = _zoom,
                              onScaleUpdate: (details) {
                                if (details.pointerCount > 1) {
                                  unawaited(_setZoom(details.scale));
                                }
                              },
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.no_photography_outlined,
                          size: 56,
                          color: Colors.white70,
                        ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Text(
                    _error!,
                    style: MenuPhotoStyle.text(14),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!ready && !_opening)
                TextButton(
                  onPressed: () => _configure(active: true),
                  child: Text(
                    context.l10n.retryLoad,
                    style: MenuPhotoStyle.text(15, bold: true),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 64),
                    const Spacer(),
                    SizedBox.square(
                      dimension: 80,
                      child: OutlinedButton(
                        key: const ValueKey('menu-camera-shutter'),
                        onPressed: ready && !_capturing ? _capture : null,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: MenuPhotoStyle.ink,
                          disabledBackgroundColor: Colors.white24,
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                          side: const BorderSide(
                            color: MenuPhotoStyle.yellow,
                            width: 5,
                          ),
                        ),
                        child: _capturing
                            ? const CircularProgressIndicator()
                            : const MenuPhotoIcon('camera', size: 36),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 64,
                      child: IconButton(
                        tooltip: context.l10n.menuCameraFlash,
                        onPressed: ready && !_capturing ? _flash : null,
                        icon: Icon(
                          _flashOn ? Icons.flash_on : Icons.flash_off,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
