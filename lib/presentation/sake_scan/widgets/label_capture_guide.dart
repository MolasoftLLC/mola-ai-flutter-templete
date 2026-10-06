import 'package:flutter/material.dart';

/// Composition guide only; it never crops or changes the captured image.
class LabelCaptureGuide extends StatelessWidget {
  const LabelCaptureGuide({super.key, required this.isBackLabel});

  final bool isBackLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: AspectRatio(
      aspectRatio: isBackLabel ? 0.85 : 0.48,
      child: CustomPaint(painter: _LabelCaptureGuidePainter(isBackLabel)),
    ),
  );
}

class _LabelCaptureGuidePainter extends CustomPainter {
  const _LabelCaptureGuidePainter(this.isBackLabel);

  final bool isBackLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final path = Path();
    if (isBackLabel) {
      path.addRRect(
        RRect.fromRectAndRadius(bounds.deflate(5), const Radius.circular(16)),
      );
    } else {
      final width = size.width;
      final height = size.height;
      path
        ..moveTo(width * 0.37, height * 0.02)
        ..lineTo(width * 0.63, height * 0.02)
        ..quadraticBezierTo(
          width * 0.66,
          height * 0.02,
          width * 0.66,
          height * 0.05,
        )
        ..lineTo(width * 0.66, height * 0.23)
        ..cubicTo(
          width * 0.66,
          height * 0.31,
          width * 0.94,
          height * 0.32,
          width * 0.94,
          height * 0.43,
        )
        ..lineTo(width * 0.94, height * 0.94)
        ..quadraticBezierTo(
          width * 0.94,
          height * 0.98,
          width * 0.85,
          height * 0.98,
        )
        ..lineTo(width * 0.15, height * 0.98)
        ..quadraticBezierTo(
          width * 0.06,
          height * 0.98,
          width * 0.06,
          height * 0.94,
        )
        ..lineTo(width * 0.06, height * 0.43)
        ..cubicTo(
          width * 0.06,
          height * 0.32,
          width * 0.34,
          height * 0.31,
          width * 0.34,
          height * 0.23,
        )
        ..lineTo(width * 0.34, height * 0.05)
        ..quadraticBezierTo(
          width * 0.34,
          height * 0.02,
          width * 0.37,
          height * 0.02,
        )
        ..close();
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black54
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_LabelCaptureGuidePainter oldDelegate) =>
      isBackLabel != oldDelegate.isBackLabel;
}
