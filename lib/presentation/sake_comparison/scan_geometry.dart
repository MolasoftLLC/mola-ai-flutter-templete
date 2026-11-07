import 'dart:math' as math;
import 'dart:ui';

/// The visible guide and native OCR share one region after the preview's crop.
class ScanGeometry {
  ScanGeometry({required this.viewport, required Size imageSize}) {
    final scale = math.max(
      viewport.width / imageSize.width,
      viewport.height / imageSize.height,
    );
    preview = Size(imageSize.width * scale, imageSize.height * scale);
    guide = Rect.fromLTWH(
      viewport.width * .06,
      viewport.height * .06,
      viewport.width * .88,
      viewport.height * .88,
    );
    final left = (preview.width - viewport.width) / 2;
    final top = (preview.height - viewport.height) / 2;
    region = Rect.fromLTRB(
      (guide.left + left) / preview.width,
      (guide.top + top) / preview.height,
      (guide.right + left) / preview.width,
      (guide.bottom + top) / preview.height,
    );
  }

  final Size viewport;
  late final Size preview;
  late final Rect guide;

  /// Normalized, top-left origin, in the upright camera frame.
  late final Rect region;
}
