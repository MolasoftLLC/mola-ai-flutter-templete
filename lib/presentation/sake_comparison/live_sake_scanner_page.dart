import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/place_map_repository.dart';
import 'comparison_item.dart';
import 'comparison_sketch_icon.dart';
import 'device_text_reader.dart';
import 'live_sake_search.dart';

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
    with WidgetsBindingObserver {
  final _reader = DeviceTextReader();
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
  String _reading = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.search.addListener(_changed);
    if (widget.imagePath != null) {
      unawaited(_readFile());
    } else {
      unawaited(_startCamera());
    }
  }

  void _changed() {
    if (mounted) setState(() {});
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
        _editing ||
        _saving ||
        camera == null ||
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
          ? sensor
          : (sensor -
                    (orientations[camera.value.deviceOrientation] ?? 0) +
                    360) %
                360;
      final text = await _reader.frame(image, rotation);
      if (!mounted || _closed || camera != _camera || _editing || _saving) {
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
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('カートを保存できませんでした。もう一度お試しください。')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
    final camera = _camera;
    _camera = null;
    if (camera != null) unawaited(camera.dispose());
    super.dispose();
  }

  Widget _preview() => LayoutBuilder(
    builder: (_, viewport) {
      final height = viewport.maxWidth * _camera!.value.aspectRatio;
      return ClipRect(
        child: OverflowBox(
          minWidth: viewport.maxWidth,
          maxWidth: viewport.maxWidth,
          minHeight: height,
          maxHeight: height,
          child: SizedBox(
            width: viewport.maxWidth,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  onTapDown: (tap) async {
                    final camera = _camera;
                    if (camera == null || !camera.value.focusPointSupported) {
                      return;
                    }
                    try {
                      await camera.setFocusPoint(
                        Offset(
                          (tap.localPosition.dx / viewport.maxWidth).clamp(
                            0,
                            1,
                          ),
                          (tap.localPosition.dy / height).clamp(0, 1),
                        ),
                      );
                    } catch (_) {
                      /* Focus is optional. */
                    }
                  },
                  child: CameraPreview(_camera!),
                ),
                IgnorePointer(
                  child: Center(
                    child: FractionallySizedBox(
                      widthFactor: .88,
                      heightFactor: .44,
                      child: DecoratedBox(
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
          child: widget.search.candidates.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      widget.search.error ??
                          (widget.search.searching
                              ? '候補を探しています…'
                              : widget.search.text.isEmpty
                              ? '文字を読み取ると候補が出ます'
                              : '該当するお酒が見つかりませんでした'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
                    final image =
                        candidate.thumbnailImageUrl ??
                        candidate.primaryImageUrl;
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _saving || added || _count >= 20
                            ? null
                            : () => _add(candidate),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 48,
                                height: 64,
                                child: image == null
                                    ? const Icon(Icons.liquor, color: _navy)
                                    : Image.network(
                                        image,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, _, _) => const Icon(
                                          Icons.liquor,
                                          color: _navy,
                                        ),
                                      ),
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
                                added
                                    ? Icons.check_circle
                                    : Icons.add_circle_outline,
                                color: added ? Colors.green : _navy,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
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
