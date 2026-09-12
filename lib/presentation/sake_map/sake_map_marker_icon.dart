import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

const _canvasWidth = 144;
const _canvasHeight = 164;
const _center = Offset(72, 64);
const _outerRadius = 58.0;
const _imageRadius = 49.0;
const _badgeCenter = Offset(116, 31);
const _badgeRadius = 25.0;

String formatSakeMarkerCount(int count) => count > 99 ? '99+' : '$count';

Future<BitmapDescriptor> createCircularSakeMarker(
  Uint8List? imageBytes, {
  required int recordCount,
}) async {
  ui.Codec? codec;
  ui.Image? sourceImage;
  if (imageBytes != null) {
    codec = await ui.instantiateImageCodec(imageBytes, targetWidth: 256);
    final frame = await codec.getNextFrame();
    sourceImage = frame.image;
  }

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

    if (sourceImage == null) {
      _drawFallbackSakeIcon(canvas);
    } else {
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
    }

    _drawCountBadge(canvas, recordCount);

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
    sourceImage?.dispose();
    codec?.dispose();
  }
}

void _drawFallbackSakeIcon(Canvas canvas) {
  canvas.drawCircle(
    _center,
    _imageRadius,
    Paint()..color = const Color(0xFFF3F6FA),
  );

  final bottlePaint = Paint()..color = const Color(0xFF143861);
  final bottle = RRect.fromRectAndRadius(
    const Rect.fromLTWH(51, 51, 42, 59),
    const Radius.circular(8),
  );
  canvas.drawRRect(bottle, bottlePaint);
  canvas.drawRect(const Rect.fromLTWH(61, 37, 22, 20), bottlePaint);
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      const Rect.fromLTWH(57, 70, 30, 23),
      const Radius.circular(4),
    ),
    Paint()..color = Colors.white,
  );
}

void _drawCountBadge(Canvas canvas, int count) {
  final badgePaint = Paint()..color = const Color(0xFFFF7A00);
  canvas.drawShadow(
    Path()
      ..addOval(Rect.fromCircle(center: _badgeCenter, radius: _badgeRadius)),
    Colors.black45,
    4,
    false,
  );
  canvas.drawCircle(_badgeCenter, _badgeRadius, badgePaint);
  canvas.drawCircle(
    _badgeCenter,
    _badgeRadius,
    Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4,
  );

  final label = formatSakeMarkerCount(count);
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: TextStyle(
        color: Colors.white,
        fontSize: label.length >= 3 ? 23 : 29,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(
    canvas,
    _badgeCenter - Offset(painter.width / 2, painter.height / 2),
  );
}

Rect _coverSourceRect(int width, int height) {
  final side = width < height ? width.toDouble() : height.toDouble();
  return Rect.fromLTWH((width - side) / 2, (height - side) / 2, side, side);
}
