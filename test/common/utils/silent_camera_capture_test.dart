import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:mola_gemini_flutter_template/common/utils/silent_camera_capture.dart';

void main() {
  group('encodeSilentCameraFrameData', () {
    test('BGRAフレームを回転してJPEGへ変換する', () {
      final bytes = Uint8List.fromList(<int>[
        0,
        0,
        255,
        255,
        0,
        255,
        0,
        255,
        255,
        0,
        0,
        255,
        255,
        255,
        255,
        255,
        0,
        0,
        0,
        255,
        128,
        128,
        128,
        255,
      ]);

      final encoded = encodeSilentCameraFrameData(<String, Object>{
        'width': 2,
        'height': 3,
        'format': 'bgra8888',
        'bytes': bytes,
        'bytesPerRow': 8,
        'rotation': 90,
      });
      final decoded = image.decodeJpg(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.width, 3);
      expect(decoded.height, 2);
    });

    test('NV21フレームをJPEGへ変換する', () {
      final encoded = encodeSilentCameraFrameData(<String, Object>{
        'width': 2,
        'height': 2,
        'format': 'nv21',
        'bytes': Uint8List.fromList(<int>[128, 128, 128, 128, 128, 128]),
        'bytesPerRow': 2,
        'rotation': 0,
      });
      final decoded = image.decodeJpg(encoded);

      expect(decoded, isNotNull);
      expect(decoded!.width, 2);
      expect(decoded.height, 2);
    });
  });
}
