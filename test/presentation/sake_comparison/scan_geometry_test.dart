import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/presentation/sake_comparison/scan_geometry.dart';

void main() {
  test(
    'portrait camera crop maps visible guide back to exactly the same pixels',
    () {
      final g = ScanGeometry(
        viewport: const Size(390, 321),
        imageSize: const Size(1080, 1920),
      );
      expect(g.preview.width, 390);
      expect(g.preview.height, closeTo(693.333333, .00001));
      expect(g.region.left, closeTo(.06, .00001));
      expect(g.region.top, closeTo(.29628846, .00001));
      expect(g.region.width, closeTo(.88, .00001));
      expect(g.region.height, closeTo(.40742307, .00001));
      // Text above the visible viewport must never enter the scan region.
      expect(g.region.contains(const Offset(.5, .15)), isFalse);
      expect(g.region.contains(const Offset(.5, .5)), isTrue);
    },
  );

  test(
    'guide inverse transform matches OCR region in portrait, landscape and wide crops',
    () {
      for (final image in [const Size(1080, 1920), const Size(1920, 1080)]) {
        for (final viewport in [
          const Size(390, 321),
          const Size(844, 300),
          const Size(320, 500),
        ]) {
          final g = ScanGeometry(viewport: viewport, imageSize: image);
          final crop = Offset(
            (g.preview.width - viewport.width) / 2,
            (g.preview.height - viewport.height) / 2,
          );
          final mapped = Rect.fromLTRB(
            g.region.left * g.preview.width - crop.dx,
            g.region.top * g.preview.height - crop.dy,
            g.region.right * g.preview.width - crop.dx,
            g.region.bottom * g.preview.height - crop.dy,
          );
          expect(mapped.left, closeTo(g.guide.left, .00001));
          expect(mapped.top, closeTo(g.guide.top, .00001));
          expect(mapped.right, closeTo(g.guide.right, .00001));
          expect(mapped.bottom, closeTo(g.guide.bottom, .00001));
          expect(g.region.left, greaterThanOrEqualTo(0));
          expect(g.region.right, lessThanOrEqualTo(1));
        }
      }
    },
  );
}
