import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  Rect _selection = const Rect.fromLTWH(0, 0, 1, 1);
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
      final bytes = await encodeMenuCrop(image, _selection);
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
    decoration: BoxDecoration(
      color: MenuPhotoStyle.deep,
      borderRadius: BorderRadius.circular(18),
    ),
    padding: const EdgeInsets.all(18),
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
              final imageSize = Size(
                _image!.width.toDouble(),
                _image!.height.toDouble(),
              );
              final fitted = applyBoxFit(
                BoxFit.contain,
                imageSize,
                constraints.biggest,
              ).destination;
              final origin = Offset(
                (constraints.maxWidth - fitted.width) / 2,
                (constraints.maxHeight - fitted.height) / 2,
              );
              final rect = Rect.fromLTRB(
                origin.dx + _selection.left * fitted.width,
                origin.dy + _selection.top * fitted.height,
                origin.dx + _selection.right * fitted.width,
                origin.dy + _selection.bottom * fitted.height,
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: RawImage(image: _image, fit: BoxFit.contain),
                  ),
                  Positioned.fromRect(
                    rect: rect,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: MenuPhotoStyle.pale,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: rect.inflate(8),
                    child: const IgnorePointer(child: _CropFrame()),
                  ),
                  for (final corner in MenuCropCorner.values)
                    Positioned(
                      left:
                          (corner == MenuCropCorner.topLeft ||
                                  corner == MenuCropCorner.bottomLeft
                              ? rect.left
                              : rect.right) -
                          22,
                      top:
                          (corner == MenuCropCorner.topLeft ||
                                  corner == MenuCropCorner.topRight
                              ? rect.top
                              : rect.bottom) -
                          22,
                      child: GestureDetector(
                        key: ValueKey('crop-${corner.name}'),
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: _saving
                            ? null
                            : (details) {
                                final box =
                                    context.findRenderObject()! as RenderBox;
                                final local =
                                    box.globalToLocal(details.globalPosition) -
                                    origin;
                                setState(
                                  () => _selection = adjustMenuCrop(
                                    _selection,
                                    Offset(
                                      local.dx / fitted.width,
                                      local.dy / fitted.height,
                                    ),
                                    corner,
                                  ),
                                );
                              },
                        child: const SizedBox(width: 44, height: 44),
                      ),
                    ),
                ],
              );
            },
          ),
  );
}

// The Figma corner asset has a 262 × 420 viewport. Stretch this decorative
// overlay to the selected rectangle; the photo itself always uses contain.
class _CropFrame extends StatelessWidget {
  const _CropFrame();
  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.fill,
    child: SvgPicture.asset(
      'assets/icons/menu_analysis/crop_frame.svg',
      width: 262,
      height: 420,
      excludeFromSemantics: true,
    ),
  );
}
