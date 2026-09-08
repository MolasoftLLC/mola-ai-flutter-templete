import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _canvasWidth = 144;
const _canvasHeight = 164;
const _center = Offset(72, 64);
const _outerRadius = 58.0;
const _imageRadius = 49.0;

Future<BitmapDescriptor> createCircularSakeMarker(Uint8List imageBytes) async {
  final codec = await ui.instantiateImageCodec(imageBytes);
  final frame = await codec.getNextFrame();
  final sourceImage = frame.image;

  try {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final pinPaint = Paint()..color = const Color(0xFF143861);
    final borderPaint = Paint()..color = Colors.white;

    final pointer = Path()
      ..moveTo(47, 104)
      ..lineTo(72, 158)
      ..lineTo(97, 104)
      ..close();
    canvas.drawShadow(pointer, Colors.black54, 5, false);
    canvas.drawPath(pointer, pinPaint);
    canvas.drawCircle(_center, _outerRadius + 2, pinPaint);
    canvas.drawCircle(_center, _outerRadius - 5, borderPaint);

    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: _center, radius: _imageRadius)),
    );
    canvas.drawImageRect(
      sourceImage,
      _coverSourceRect(sourceImage.width, sourceImage.height),
      Rect.fromCircle(center: _center, radius: _imageRadius),
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    final renderedImage = await recorder.endRecording().toImage(
      _canvasWidth,
      _canvasHeight,
    );
    try {
      final png = await renderedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (png == null) throw StateError('マップピン画像を生成できませんでした');
      return BitmapDescriptor.bytes(
        png.buffer.asUint8List(),
        width: 60,
        height: 68,
      );
    } finally {
      renderedImage.dispose();
    }
  } finally {
    sourceImage.dispose();
    codec.dispose();
  }
}

Rect _coverSourceRect(int width, int height) {
  final side = width < height ? width.toDouble() : height.toDouble();
  return Rect.fromLTWH((width - side) / 2, (height - side) / 2, side, side);
}
