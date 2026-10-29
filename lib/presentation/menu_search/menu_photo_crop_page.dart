import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/gestures.dart';
import '../../common/localization/localization_extensions.dart';
import 'widgets/menu_photo_style.dart';

enum MenuCropCorner { topLeft, topRight, bottomLeft, bottomRight }

/// Coordinates are normalized to the oriented image, excluding letterboxing.
Rect adjustMenuCrop(Rect rect, Offset point, MenuCropCorner corner) {
  final left =
      corner == MenuCropCorner.topLeft || corner == MenuCropCorner.bottomLeft;
  final top =
      corner == MenuCropCorner.topLeft || corner == MenuCropCorner.topRight;
  return Rect.fromLTRB(
    left ? point.dx.clamp(0.0, rect.right - .08) : rect.left,
    top ? point.dy.clamp(0.0, rect.bottom - .08) : rect.top,
    left ? rect.right : point.dx.clamp(rect.left + .08, 1.0),
    top ? rect.bottom : point.dy.clamp(rect.top + .08, 1.0),
  );
}

Future<Uint8List> encodeMenuCrop(ui.Image image, Rect selection) async {
  final source = Rect.fromLTRB(
    (selection.left * image.width).roundToDouble(),
    (selection.top * image.height).roundToDouble(),
    (selection.right * image.width).roundToDouble(),
    (selection.bottom * image.height).roundToDouble(),
  );
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawImageRect(
    image,
    source,
    Rect.fromLTWH(0, 0, source.width, source.height),
    Paint(),
  );
  final picture = recorder.endRecording();
  final cropped = await picture.toImage(
    source.width.toInt(),
    source.height.toInt(),
  );
  try {
    final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) throw StateError('Unable to encode crop');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    cropped.dispose();
    picture.dispose();
  }
}

class MenuPhotoCropPage extends StatefulWidget {
  const MenuPhotoCropPage({super.key, required this.image});
  final File image;
  @override
  State<MenuPhotoCropPage> createState() => _MenuPhotoCropPageState();
}

class _MenuPhotoCropPageState extends State<MenuPhotoCropPage> {
  ui.Image? _image;
  final _selection = ValueNotifier(const Rect.fromLTWH(0, 0, 1, 1));
  int? _pointer;
  _CropDragTarget? _dragTarget;
  Offset _dragStart = Offset.zero;
  Rect _dragSelection = Rect.zero;
  bool _saving = false;
  bool _loadFailed = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final codec = await ui.instantiateImageCodec(
        await widget.image.readAsBytes(),
      );
      ui.Image image;
      try {
        image = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() => _image = image);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  void dispose() {
    _selection.dispose();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final image = _image;
    if (image == null || _saving) return;
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      final bytes = await encodeMenuCrop(image, _selection.value);
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        '${dir.path}/menu_crop_${DateTime.now().microsecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      if (mounted) Navigator.of(context).pop(file);
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      backgroundColor: MenuPhotoStyle.blue,
      appBar: MenuPhotoStyle.appBar(
        context.l10n.menuCropPhoto,
        onBack: _saving ? null : () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n.menuCropHeading,
                      style: MenuPhotoStyle.text(16, bold: true),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: (constraints.maxHeight - 304).clamp(200.0, 440.0),
                      child: _preview(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.menuCropHint,
                      style: MenuPhotoStyle.text(12),
                    ),
                    if (_saveFailed)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          context.l10n.menuCropFailed,
                          style: MenuPhotoStyle.text(13),
                        ),
                      ),
                    const SizedBox(height: 40),
                    MenuPhotoButton(
                      label: context.l10n.menuConfirmCrop,
                      icon: 'check',
                      color: Colors.white,
                      height: 56,
                      fontSize: 17,
                      onPressed: _image == null || _saving ? null : _confirm,
                    ),
                    if (_saving) const LinearProgressIndicator(),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        context.l10n.cancel,
                        style: MenuPhotoStyle.text(15, bold: true),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.menuOriginalPreserved,
                      style: MenuPhotoStyle.text(11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _preview() => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: MenuPhotoStyle.deep,
      borderRadius: BorderRadius.circular(18),
    ),
    child: _image == null
        ? Center(
            child: _loadFailed
                ? Text(
                    context.l10n.menuPhotoLoadFailed,
                    style: MenuPhotoStyle.text(13),
                  )
                : const CircularProgressIndicator(color: MenuPhotoStyle.yellow),
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final fitted = applyBoxFit(
                BoxFit.contain,
                Size(_image!.width.toDouble(), _image!.height.toDouble()),
                Size(constraints.maxWidth - 36, constraints.maxHeight - 36),
              ).destination;
              final imageRect = Rect.fromCenter(
                center: constraints.biggest.center(Offset.zero),
                width: fitted.width,
                height: fitted.height,
              );
              return Stack(
                children: [
                  Positioned.fromRect(
                    rect: imageRect,
                    child: RepaintBoundary(child: RawImage(image: _image)),
                  ),
                  Positioned.fill(
                    child: RawGestureDetector(
                      // Claim crop touches immediately. A pan recognizer waits
                      // for slop and can compete with the enclosing page scroll.
                      behavior: HitTestBehavior.opaque,
                      gestures: {
                        EagerGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                              EagerGestureRecognizer
                            >(EagerGestureRecognizer.new, (_) {}),
                      },
                      child: Listener(
                        key: const ValueKey('crop-gesture-surface'),
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: (event) {
                          if (_saving || _pointer != null) return;
                          final rect = _displaySelection(
                            imageRect,
                            _selection.value,
                          );
                          final target = _cropTargetAt(
                            rect,
                            event.localPosition,
                          );
                          if (target == null) return;
                          _pointer = event.pointer;
                          _dragTarget = target;
                          _dragStart = event.localPosition;
                          _dragSelection = _selection.value;
                        },
                        onPointerMove: (event) {
                          if (_saving || event.pointer != _pointer) return;
                          final delta = event.localPosition - _dragStart;
                          _selection.value = _dragCrop(
                            _dragSelection,
                            Offset(
                              delta.dx / fitted.width,
                              delta.dy / fitted.height,
                            ),
                            _dragTarget!,
                          );
                        },
                        onPointerUp: (event) {
                          if (event.pointer == _pointer) _pointer = null;
                        },
                        onPointerCancel: (event) {
                          if (event.pointer == _pointer) _pointer = null;
                        },
                        child: RepaintBoundary(
                          child: ValueListenableBuilder<Rect>(
                            valueListenable: _selection,
                            builder: (context, selection, _) {
                              final rect = _displaySelection(
                                imageRect,
                                selection,
                              );
                              return Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _CropSelectionPainter(rect),
                                    ),
                                  ),
                                  Positioned.fromRect(
                                    rect: rect,
                                    child: const IgnorePointer(
                                      child: SizedBox(
                                        key: ValueKey('crop-selection'),
                                      ),
                                    ),
                                  ),
                                  for (final entry in _cropHandles(
                                    rect,
                                  ).entries)
                                    Positioned(
                                      left: entry.value.dx - 28,
                                      top: entry.value.dy - 28,
                                      child: IgnorePointer(
                                        child: SizedBox(
                                          key: ValueKey(
                                            'crop-${entry.key.name}',
                                          ),
                                          width: 56,
                                          height: 56,
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
  );
}

enum _CropDragTarget {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  right,
  bottom,
  left,
  move,
}

Rect _displaySelection(Rect image, Rect selection) => Rect.fromLTWH(
  image.left + selection.left * image.width,
  image.top + selection.top * image.height,
  selection.width * image.width,
  selection.height * image.height,
);

Map<_CropDragTarget, Offset> _cropHandles(Rect rect) => {
  _CropDragTarget.topLeft: rect.topLeft,
  _CropDragTarget.topRight: rect.topRight,
  _CropDragTarget.bottomLeft: rect.bottomLeft,
  _CropDragTarget.bottomRight: rect.bottomRight,
  _CropDragTarget.top: rect.topCenter,
  _CropDragTarget.right: rect.centerRight,
  _CropDragTarget.bottom: rect.bottomCenter,
  _CropDragTarget.left: rect.centerLeft,
};

_CropDragTarget? _cropTargetAt(Rect rect, Offset point) {
  final corners = _cropHandles(rect).entries.take(4).toList()
    ..sort(
      (a, b) => (a.value - point).distanceSquared.compareTo(
        (b.value - point).distanceSquared,
      ),
    );
  for (final entry in corners) {
    final delta = point - entry.value;
    if (delta.dx.abs() <= 32 && delta.dy.abs() <= 32) return entry.key;
  }
  if (point.dx >= rect.left && point.dx <= rect.right) {
    if ((point.dy - rect.top).abs() <= 24) return _CropDragTarget.top;
    if ((point.dy - rect.bottom).abs() <= 24) return _CropDragTarget.bottom;
  }
  if (point.dy >= rect.top && point.dy <= rect.bottom) {
    if ((point.dx - rect.left).abs() <= 24) return _CropDragTarget.left;
    if ((point.dx - rect.right).abs() <= 24) return _CropDragTarget.right;
  }
  return rect.contains(point) ? _CropDragTarget.move : null;
}

Rect _dragCrop(Rect rect, Offset delta, _CropDragTarget target) {
  if (target == _CropDragTarget.move) {
    return Rect.fromLTWH(
      (rect.left + delta.dx).clamp(0.0, 1.0 - rect.width),
      (rect.top + delta.dy).clamp(0.0, 1.0 - rect.height),
      rect.width,
      rect.height,
    );
  }
  final left =
      target == _CropDragTarget.topLeft ||
      target == _CropDragTarget.bottomLeft ||
      target == _CropDragTarget.left;
  final right =
      target == _CropDragTarget.topRight ||
      target == _CropDragTarget.bottomRight ||
      target == _CropDragTarget.right;
  final top =
      target == _CropDragTarget.topLeft ||
      target == _CropDragTarget.topRight ||
      target == _CropDragTarget.top;
  final bottom =
      target == _CropDragTarget.bottomLeft ||
      target == _CropDragTarget.bottomRight ||
      target == _CropDragTarget.bottom;
  return Rect.fromLTRB(
    left ? (rect.left + delta.dx).clamp(0.0, rect.right - .08) : rect.left,
    top ? (rect.top + delta.dy).clamp(0.0, rect.bottom - .08) : rect.top,
    right ? (rect.right + delta.dx).clamp(rect.left + .08, 1.0) : rect.right,
    bottom ? (rect.bottom + delta.dy).clamp(rect.top + .08, 1.0) : rect.bottom,
  );
}

class _CropSelectionPainter extends CustomPainter {
  const _CropSelectionPainter(this.rect);
  final Rect rect;
  @override
  void paint(Canvas canvas, Size size) {
    final mask = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(rect);
    canvas.drawPath(mask, Paint()..color = const Color(0x66000000));
    final grid = Paint()
      ..color = Colors.white38
      ..strokeWidth = 1;
    for (final fraction in [1 / 3, 2 / 3]) {
      final x = rect.left + rect.width * fraction;
      final y = rect.top + rect.height * fraction;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), grid);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), grid);
    }
    canvas.drawRect(
      rect,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final grip = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final corner in [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ]) {
      final dx = corner.dx == rect.left ? 18.0 : -18.0;
      final dy = corner.dy == rect.top ? 18.0 : -18.0;
      canvas.drawLine(corner, corner + Offset(dx, 0), grip);
      canvas.drawLine(corner, corner + Offset(0, dy), grip);
    }
    for (final center in [rect.topCenter, rect.bottomCenter]) {
      canvas.drawLine(
        center - const Offset(12, 0),
        center + const Offset(12, 0),
        grip,
      );
    }
    for (final center in [rect.centerLeft, rect.centerRight]) {
      canvas.drawLine(
        center - const Offset(0, 12),
        center + const Offset(0, 12),
        grip,
      );
    }
  }

  @override
  bool shouldRepaint(_CropSelectionPainter oldDelegate) =>
      rect != oldDelegate.rect;
}
