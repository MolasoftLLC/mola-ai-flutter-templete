import 'dart:async';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/place_map_repository.dart';
import '../new_home/widgets/sake_catalog_thumbnail.dart';
import 'comparison_item.dart';
import 'comparison_sketch_icon.dart';
import 'device_text_reader.dart';
import 'live_sake_search.dart';
import 'scan_geometry.dart';

const _navy = Color(0xFF143861);

class LiveSakeScannerPage extends StatefulWidget {
  const LiveSakeScannerPage({
    super.key,
    required this.search,
    required this.onAdd,
    required this.initialIds,
    required this.initialCount,
    this.preference,
    this.imagePath,
  });
  final LiveSakeSearch search;
  final Future<bool> Function(ComparisonItem) onAdd;
  final Set<int> initialIds;
  final int initialCount;
  final TastePreferenceProfile? preference;
  final String? imagePath;
  @override
  State<LiveSakeScannerPage> createState() => _LiveSakeScannerPageState();
}

class _LiveSakeScannerPageState extends State<LiveSakeScannerPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _reader = DeviceTextReader();
  final _cartKey = GlobalKey();
  final _sheetUpdates = ValueNotifier<int>(0);
  late final AnimationController _flight;
  OverlayEntry? _flyingCard;
  Offset? _flightFrom;
  BuildContext? _sheetContext;
  bool _sheetOpen = false;
  bool _animating = false;
  final _manualField = TextEditingController();
  CameraController? _camera;
  CameraDescription? _description;
  late final Set<int> _added = {...widget.initialIds};
  late int _count = widget.initialCount;
  DateTime _lastFrame = DateTime.fromMillisecondsSinceEpoch(0);
  bool _processing = false,
      _saving = false,
      _editing = false,
      _starting = true,
      _closed = false;
  int _cameraGeneration = 0;
  ScanGeometry? _geometry;
  String _reading = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _flight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    WidgetsBinding.instance.addObserver(this);
    widget.search.addListener(_changed);
    if (widget.imagePath != null) {
      unawaited(_readFile());
    } else {
      unawaited(_startCamera());
    }
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    _sheetUpdates.value++;
    if (!_sheetOpen &&
        !_animating &&
        !_editing &&
        widget.search.candidates.isNotEmpty) {
      _sheetOpen =
          true; // Gate frames immediately, including an OCR already in flight.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_closed) unawaited(_showCandidates());
      });
    }
  }

  Future<void> _readFile() async {
    try {
      final text = await _reader.file(widget.imagePath!);
      if (!mounted) return;
      setState(() {
        _reading = text;
        _starting = false;
      });
      await widget.search.find(text);
    } catch (_) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = '文字を読み取れませんでした。';
        });
      }
    }
  }

  Future<void> _startCamera() async {
    final generation = ++_cameraGeneration;
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      setState(() {
        _starting = false;
        _error = '文字スキャンはiOS・Androidで使えます。';
      });
      return;
    }
    CameraController? camera;
    try {
      final descriptions = await availableCameras();
      if (!mounted || generation != _cameraGeneration) return;
      final back = descriptions
          .where((c) => c.lensDirection == CameraLensDirection.back)
          .toList();
      if (back.isEmpty) throw StateError('No back camera');
      final description = back.firstWhere(
        (c) => c.lensType == CameraLensType.wide,
        orElse: () => back.first,
      );
      camera = CameraController(
        description,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.android
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      await camera.initialize();
      if (!mounted || generation != _cameraGeneration) {
        await camera.dispose();
        return;
      }
      _camera = camera;
      _description = description;
      await camera.setFlashMode(FlashMode.off);
      await camera.startImageStream(_frame);
      if (mounted && generation == _cameraGeneration) {
        setState(() {
          _starting = false;
          _error = null;
        });
      }
    } catch (_) {
      if (camera != null) {
        if (camera == _camera) _camera = null;
        await camera.dispose();
      }
      if (mounted && generation == _cameraGeneration) {
        setState(() {
          _starting = false;
          _error = 'カメラを開始できませんでした。カメラの許可を確認してください。';
        });
      }
    }
  }

  Future<void> _frame(CameraImage image) async {
    final camera = _camera;
    final now = DateTime.now();
    if (_closed ||
        _processing ||
        _sheetOpen ||
        _animating ||
        _editing ||
        _saving ||
        camera == null ||
        _geometry == null ||
        now.difference(_lastFrame).inMilliseconds < 450) {
      return;
    }
    _processing = true;
    _lastFrame = now;
    try {
      const orientations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };
      final sensor = _description!.sensorOrientation;
      final rotation = defaultTargetPlatform == TargetPlatform.iOS
          // camera_avfoundation already rotates stream buffers upright.
          ? 0
          : (sensor -
                    (orientations[camera.value.deviceOrientation] ?? 0) +
                    360) %
                360;
      final text = await _reader.frame(image, rotation, _geometry!.region);
      if (!mounted ||
          _closed ||
          camera != _camera ||
          _editing ||
          _saving ||
          _sheetOpen ||
          _animating) {
        return;
      }
      setState(() {
        _reading = text;
        _error = null;
      });
      widget.search.observe(text);
    } catch (_) {
      if (mounted && camera == _camera) {
        setState(() => _error = '文字を読み取れませんでした。名前を枠に合わせてください。');
      }
    } finally {
      _processing = false;
    }
  }

  Future<void> _add(SakeMapSearchResult candidate) async {
    final id = candidate.sakeId!;
    if (_saving || _added.contains(id) || _count >= 20) return;
    setState(() => _saving = true);
    _sheetUpdates.value++;
    try {
      final item = ComparisonItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        sake: Sake(
          sakeId: id,
          name: candidate.name,
          type: candidate.type,
          brewery: candidate.brewery,
          primaryImageUrl: candidate.primaryImageUrl,
          thumbnailImageUrl: candidate.thumbnailImageUrl,
        ),
        text: widget.search.text,
        profile: widget.search.profiles[id],
        estimated:
            widget.search.profiles[id]?.sourceType?.contains('ai') ?? false,
      );
      final saved = await widget.onAdd(item);
      if (saved && mounted) {
        setState(() {
          _added.add(id);
          _count++;
        });
        unawaited(HapticFeedback.mediumImpact());
        _sheetUpdates.value++;
        final sheet = _sheetContext;
        if (sheet != null && sheet.mounted) Navigator.of(sheet).pop(true);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('カートを保存できませんでした。もう一度お試しください。')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _sheetUpdates.value++;
      }
    }
  }

  Future<void> _manualSearch() async {
    if (_editing || _saving) return;
    _editing = true;
    final field = _manualField;
    field.text = liveSakeQueries(_reading).firstOrNull ?? '';
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('名前で探す'),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLength: 64,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: const Text('検索'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (query?.trim().isNotEmpty == true) {
      await widget.search.find(query!.trim());
    }
    _editing = false;
    if (mounted) _changed();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.imagePath != null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraGeneration++;
      final camera = _camera;
      _camera = null;
      if (camera != null) unawaited(camera.dispose());
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      setState(() => _starting = true);
      unawaited(_startCamera());
    }
  }

  @override
  void dispose() {
    _closed = true;
    _cameraGeneration++;
    WidgetsBinding.instance.removeObserver(this);
    widget.search.removeListener(_changed);
    widget.search.dispose();
    _manualField.dispose();
    _flight.dispose();
    _flyingCard?.remove();
    _flyingCard = null;
    _sheetUpdates.dispose();
    final camera = _camera;
    _camera = null;
    if (camera != null) unawaited(camera.dispose());
    super.dispose();
  }

  Widget _preview() => ValueListenableBuilder<CameraValue>(
    valueListenable: _camera!,
    builder: (_, value, _) => LayoutBuilder(
      builder: (_, viewport) {
        final landscape = {
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        }.contains(value.lockedCaptureOrientation ?? value.deviceOrientation);
        final size = value.previewSize!;
        final geometry = ScanGeometry(
          viewport: Size(viewport.maxWidth, viewport.maxHeight),
          imageSize: landscape ? size : Size(size.height, size.width),
        );
        _geometry = geometry;
        return Stack(
          key: const ValueKey('scan-viewport'),
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: OverflowBox(
                minWidth: geometry.preview.width,
                maxWidth: geometry.preview.width,
                minHeight: geometry.preview.height,
                maxHeight: geometry.preview.height,
                child: SizedBox(
                  width: geometry.preview.width,
                  height: geometry.preview.height,
                  child: GestureDetector(
                    onTapDown: (tap) async {
                      final camera = _camera;
                      if (camera == null || !camera.value.focusPointSupported) {
                        return;
                      }
                      try {
                        await camera.setFocusPoint(
                          Offset(
                            (tap.localPosition.dx / geometry.preview.width)
                                .clamp(0, 1),
                            (tap.localPosition.dy / geometry.preview.height)
                                .clamp(0, 1),
                          ),
                        );
                      } catch (_) {
                        /* Focus is optional. */
                      }
                    },
                    child: CameraPreview(_camera!),
                  ),
                ),
              ),
            ),
            Positioned.fromRect(
              rect: geometry.guide,
              child: IgnorePointer(
                child: DecoratedBox(
                  key: const ValueKey('scan-guide'),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFFD84D),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Future<void> _showCandidates() async {
    var added = false;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    unawaited(HapticFeedback.mediumImpact());
    try {
      added =
          await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: const Color(0xFFF5F8F7),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            clipBehavior: Clip.antiAlias,
            sheetAnimationStyle: reduceMotion
                ? AnimationStyle.noAnimation
                : const AnimationStyle(
                    duration: Duration(milliseconds: 360),
                    curve: Curves.easeOutBack,
                    reverseCurve: Curves.easeInCubic,
                    reverseDuration: Duration(milliseconds: 180),
                  ),
            builder: (context) {
              _sheetContext = context;
              return PopScope(
                canPop: !_saving,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    key: const ValueKey('sake-candidate-sheet'),
                    height: MediaQuery.sizeOf(context).height * .65,
                    child: AnimatedBuilder(
                      animation: Listenable.merge([
                        widget.search,
                        _sheetUpdates,
                      ]),
                      builder: (_, _) => Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '読み取ったお酒',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.search.displayText,
                                        key: const ValueKey(
                                          'recognized-sake-name',
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: _navy,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: const ValueKey('close-sake-candidates'),
                                  tooltip: '選ばずに撮影へ戻る',
                                  onPressed: _saving
                                      ? null
                                      : () => Navigator.of(context).pop(false),
                                  icon: const Icon(Icons.close, color: _navy),
                                ),
                              ],
                            ),
                          ),
                          if (widget.search.searching)
                            const LinearProgressIndicator(minHeight: 2),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '候補をタップしてカートに追加',
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          Expanded(child: _candidates()),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ) ??
          false;
      _sheetContext = null;
      // Remain gated until the sheet is no longer visible, including on ×.
      if (!reduceMotion) {
        await Future<void>.delayed(const Duration(milliseconds: 180));
      }
      if (added && mounted && !_closed) {
        _animating = true;
        if (mounted && !_closed) await _animateIntoCart();
      }
    } finally {
      _sheetContext = null;
      if (mounted && !_closed) {
        // Clear while still gated so a late catalog response cannot open a sheet.
        widget.search.resumeScanning();
        setState(() {
          _sheetOpen = false;
          _animating = false;
          _reading = '';
        });
      }
    }
  }

  Future<void> _animateIntoCart() async {
    if (MediaQuery.disableAnimationsOf(context)) return;
    final target = _cartKey.currentContext?.findRenderObject();
    if (target is! RenderBox) return;
    final from = _flightFrom ?? MediaQuery.sizeOf(context).center(Offset.zero);
    final to = target.localToGlobal(target.size.center(Offset.zero));
    _flyingCard = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: _flight,
        builder: (_, _) {
          final t = Curves.easeInOut.transform(_flight.value);
          final point =
              Offset.lerp(from, to, t)! +
              Offset(0, -math.sin(t * math.pi) * 60);
          return Positioned(
            left: point.dx - 22,
            top: point.dy - 22,
            child: IgnorePointer(
              child: Transform.scale(
                scale: 1 - t * .5,
                child: Material(
                  key: const ValueKey('flying-sake-to-cart'),
                  elevation: 8,
                  color: const Color(0xFFE6EDF6),
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Icon(Icons.description_outlined, color: _navy),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_flyingCard!);
    try {
      await _flight.forward(from: 0).orCancel;
    } on TickerCanceled {
      // Closing the scanner cancels its animation.
    } finally {
      _flyingCard?.remove();
      _flyingCard = null;
    }
  }

  Widget _candidates() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    itemCount: widget.search.candidates.length,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (_, index) {
      final candidate = widget.search.candidates[index];
      final added = _added.contains(candidate.sakeId);
      final profile = widget.search.profiles[candidate.sakeId];
      final percent = ComparisonItem(
        id: '',
        sake: const Sake(),
        text: '',
        profile: profile,
      ).match(widget.preference);
      return Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTapDown: (details) => _flightFrom = details.globalPosition,
          onTap: _saving || added || _count >= 20
              ? null
              : () => _add(candidate),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SakeCatalogThumbnail(
                  thumbnailImageUrl: candidate.thumbnailImageUrl,
                  primaryImageUrl: candidate.primaryImageUrl,
                  size: 64,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate.name,
                        style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        [
                          candidate.type,
                          candidate.brewery,
                        ].whereType<String>().join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                      ),
                      if (percent != null)
                        Text(
                          'マッチ度 $percent%',
                          style: const TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  added ? Icons.check_circle : Icons.add_circle_outline,
                  color: added ? Colors.green : _navy,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8F7),
    appBar: AppBar(
      title: const Text('文字でお酒えらび', style: TextStyle(fontSize: 18)),
      backgroundColor: _navy,
      foregroundColor: Colors.white,
      actions: [
        TextButton(
          onPressed: _manualSearch,
          child: const Text('名前で探す', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
    body: Column(
      children: [
        if (widget.imagePath == null)
          SizedBox(
            height: MediaQuery.sizeOf(context).height * .38,
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: _camera != null && _camera!.value.isInitialized
                    ? _preview()
                    : _starting
                    ? const CircularProgressIndicator()
                    : const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 48,
                      ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _error ?? (_reading.isEmpty ? 'お酒の名前を枠に合わせてください' : _reading),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _error == null ? _navy : Colors.red,
                  fontSize: 14,
                ),
              ),
              if (widget.search.searching)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.document_scanner_outlined,
                    color: _navy,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.search.error ??
                        (widget.search.searching
                            ? '候補を探しています…'
                            : 'お酒の名前にかざしてください'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '見つかると振動して候補が開きます。\nカートに追加したら、そのまま次のお酒へ。',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey, height: 1.7),
                  ),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: _cartKey,
                onPressed: () => Navigator.pop(context),
                icon: const ComparisonSketchIcon(size: 24),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFFD84D),
                  foregroundColor: _navy,
                  minimumSize: const Size(0, 52),
                ),
                label: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Text('カートを見る（$_count）', key: ValueKey(_count)),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
