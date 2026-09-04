import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as image;

Future<Uint8List> encodeSilentCameraFrame(
  CameraImage frame, {
  required int sensorOrientation,
}) {
  if (frame.planes.isEmpty) {
    throw StateError('カメラ映像のデータがありません');
  }
  return compute<Map<String, Object>, Uint8List>(
    encodeSilentCameraFrameData,
    <String, Object>{
      'width': frame.width,
      'height': frame.height,
      'format': frame.format.group.name,
      'bytes': Uint8List.fromList(frame.planes.first.bytes),
      'bytesPerRow': frame.planes.first.bytesPerRow,
      'rotation': sensorOrientation,
    },
  );
}

@visibleForTesting
Uint8List encodeSilentCameraFrameData(Map<String, Object> data) {
  final width = data['width']! as int;
  final height = data['height']! as int;
  final format = data['format']! as String;
  final bytes = data['bytes']! as Uint8List;
  final bytesPerRow = data['bytesPerRow']! as int;
  final rotation = data['rotation']! as int;

  image.Image decoded;
  switch (format) {
    case 'bgra8888':
      decoded = image.Image.fromBytes(
        width: width,
        height: height,
        bytes: bytes.buffer,
        bytesOffset: bytes.offsetInBytes,
        rowStride: bytesPerRow,
        numChannels: 4,
        order: image.ChannelOrder.bgra,
      );
    case 'nv21':
      decoded = _decodeNv21(
        bytes,
        width: width,
        height: height,
        rowStride: bytesPerRow,
      );
    default:
      throw UnsupportedError('未対応のカメラ映像形式です: $format');
  }

  final normalizedRotation = rotation % 360;
  final rotated = normalizedRotation == 0
      ? decoded
      : image.copyRotate(decoded, angle: normalizedRotation);
  return image.encodeJpg(rotated, quality: 90);
}

image.Image _decodeNv21(
  Uint8List bytes, {
  required int width,
  required int height,
  required int rowStride,
}) {
  final yPlaneSize = rowStride * height;
  final requiredBytes = yPlaneSize + rowStride * ((height + 1) ~/ 2);
  if (bytes.length < requiredBytes) {
    throw StateError('カメラ映像のサイズが不正です');
  }

  final rgb = Uint8List(width * height * 3);
  var rgbIndex = 0;
  for (var y = 0; y < height; y++) {
    final yRow = y * rowStride;
    final uvRow = yPlaneSize + (y >> 1) * rowStride;
    for (var x = 0; x < width; x++) {
      final yValue = bytes[yRow + x].toDouble();
      final uvIndex = uvRow + (x & ~1);
      final v = bytes[uvIndex].toDouble() - 128;
      final u = bytes[uvIndex + 1].toDouble() - 128;

      rgb[rgbIndex++] = (yValue + 1.402 * v).round().clamp(0, 255);
      rgb[rgbIndex++] = (yValue - 0.344136 * u - 0.714136 * v).round().clamp(
        0,
        255,
      );
      rgb[rgbIndex++] = (yValue + 1.772 * u).round().clamp(0, 255);
    }
  }

  return image.Image.fromBytes(
    width: width,
    height: height,
    bytes: rgb.buffer,
    numChannels: 3,
    order: image.ChannelOrder.rgb,
  );
}
