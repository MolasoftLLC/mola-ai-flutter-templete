import 'package:flutter/material.dart';

/// Small, vector-drawn illustrations with gently uneven ink outlines.
/// Labels and tap semantics are supplied by the surrounding capture action.
class CaptureSketchIcon extends StatelessWidget {
  const CaptureSketchIcon({super.key, required this.isMenu});

  final bool isMenu;

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox.square(
      dimension: 48,
      child: CustomPaint(painter: _CaptureSketchPainter(isMenu: isMenu)),
    ),
  );
}

class _CaptureSketchPainter extends CustomPainter {
  const _CaptureSketchPainter({required this.isMenu});

  final bool isMenu;
  static const ink = Color(0xFF143861);
  static const paper = Color(0xFFFFF6DE);
  static const vermilion = Color(0xFFC15A3D);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 48, size.height / 48);
    final pen = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    void shape(Path path, Color fill) {
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(path, pen);
    }

    if (isMenu) {
      // A softly bowed sheet, two columns of menu entries, and a red seal.
      shape(
        Path()
          ..moveTo(10, 5)
          ..quadraticBezierTo(25, 3.8, 38, 6)
          ..lineTo(39, 41)
          ..quadraticBezierTo(24, 43.3, 9, 41)
          ..close(),
        paper,
      );
      canvas.drawPath(
        Path()
          ..moveTo(14, 11)
          ..quadraticBezierTo(24, 10, 33, 11)
          ..moveTo(23.5, 16)
          ..lineTo(24, 34)
          ..moveTo(14, 18)
          ..lineTo(20, 17.5)
          ..moveTo(14, 24)
          ..lineTo(19, 24.4)
          ..moveTo(14, 30)
          ..lineTo(20, 29.7)
          ..moveTo(28, 18)
          ..lineTo(33, 18.3)
          ..moveTo(28, 24)
          ..lineTo(33, 23.8),
        pen..strokeWidth = 1.5,
      );
      canvas.drawPath(
        Path()
          ..moveTo(29, 31)
          ..lineTo(34, 30.5)
          ..lineTo(34.5, 36)
          ..lineTo(29, 36.5)
          ..close(),
        Paint()
          ..color = vermilion
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round,
      );
    } else {
      // Bottle silhouette and a paper label are legible even at button size.
      shape(
        Path()
          ..moveTo(20, 7)
          ..lineTo(28, 7)
          ..lineTo(28.3, 16)
          ..cubicTo(28.3, 21, 33.5, 22, 33.5, 28)
          ..lineTo(33, 41)
          ..quadraticBezierTo(24, 43.5, 15, 41)
          ..lineTo(14.5, 28)
          ..cubicTo(14.5, 22, 20, 21, 19.8, 16)
          ..close(),
        const Color(0xFFD8E3CE),
      );
      shape(
        Path()
          ..moveTo(19, 5)
          ..lineTo(28.8, 4.7)
          ..lineTo(29, 9)
          ..lineTo(19, 9.3)
          ..close(),
        paper,
      );
      shape(
        Path()
          ..moveTo(15, 26)
          ..quadraticBezierTo(24, 27, 33.4, 25.8)
          ..lineTo(33.2, 37)
          ..quadraticBezierTo(24, 38.2, 14.8, 37)
          ..close(),
        paper,
      );
      canvas.drawPath(
        Path()
          ..moveTo(24, 29.5)
          ..quadraticBezierTo(23, 31, 24.4, 33)
          ..lineTo(23.5, 35),
        pen..strokeWidth = 2,
      );
      // Four imperfect viewfinder corners distinguish shooting from collecting.
      canvas.drawPath(
        Path()
          ..moveTo(5, 15)
          ..lineTo(5.3, 9)
          ..lineTo(11, 8.7)
          ..moveTo(37, 9)
          ..lineTo(43, 9.3)
          ..lineTo(43, 15)
          ..moveTo(5, 34)
          ..lineTo(5.3, 40)
          ..lineTo(10, 40)
          ..moveTo(38, 40)
          ..lineTo(43, 39.7)
          ..lineTo(43, 34),
        pen
          ..color = paper
          ..strokeWidth = 2,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CaptureSketchPainter oldDelegate) =>
      oldDelegate.isMenu != isMenu;
}
