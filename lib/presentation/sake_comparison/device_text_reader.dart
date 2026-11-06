import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Frames stay on this device; the channel only runs the platform's text OCR.
class DeviceTextReader {
  static const channel = MethodChannel('okinawa.molasoft.sakepedia/text_ocr');
  Future<String> frame(CameraImage image, int rotation, Rect region) async {
    final android = defaultTargetPlatform == TargetPlatform.android;
    if (image.planes.length != 1 ||
        (android && image.format.group != ImageFormatGroup.nv21) ||
        (!android && image.format.group != ImageFormatGroup.bgra8888)) {
      throw PlatformException(
        code: 'OCR_FORMAT',
        message: 'このカメラの映像形式に対応していません。',
      );
    }
    return await channel.invokeMethod<String>('recognizeFrame', {
          'bytes': image.planes.first.bytes,
          'width': image.width,
          'height': image.height,
          'bytesPerRow': image.planes.first.bytesPerRow,
          'rotation': rotation,
          'region': {
            'x': region.left,
            'y': region.top,
            'width': region.width,
            'height': region.height,
          },
        }) ??
        '';
  }

  Future<String> file(String path) async =>
      await channel.invokeMethod<String>('recognizeFile', {'path': path}) ?? '';
}
