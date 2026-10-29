import 'package:flutter/material.dart';

/// Composition guide only; it never crops or changes the captured image.
class LabelCaptureGuide extends StatelessWidget {
  const LabelCaptureGuide({super.key, required this.isBackLabel});

  final bool isBackLabel;

  @override
  Widget build(BuildContext context) => Padding(
    // The front bottle is intentionally large and extends behind the floating
    // controls. This is a visual overlay only; it must not intercept touch.
    padding: isBackLabel
        ? const EdgeInsets.fromLTRB(20, 136, 20, 166)
        : EdgeInsets.fromLTRB(
            12,
            128 + (MediaQuery.textScalerOf(context).scale(12) - 12) * 5,
            12,
            12,
          ),
    child: Center(
      child: AspectRatio(
        aspectRatio: isBackLabel ? 0.80 : 0.34,
        child: CustomPaint(painter: _LabelCaptureGuidePainter(isBackLabel)),
      ),
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
      // A four-go/issho sake bottle: short cap, slim neck, long sloping
      // shoulders and a tall cylindrical body, rather than a broad wine shape.
      path
        ..moveTo(width * 0.37, height * 0.02)
        ..lineTo(width * 0.63, height * 0.02)
        ..quadraticBezierTo(
          width * 0.65,
          height * 0.02,
          width * 0.65,
          height * 0.03,
        )
        ..lineTo(width * 0.65, height * 0.06)
        ..lineTo(width * 0.63, height * 0.07)
        ..lineTo(width * 0.63, height * 0.18)
        ..cubicTo(
          width * 0.63,
          height * 0.23,
          width * 0.85,
          height * 0.27,
          width * 0.90,
          height * 0.32,
        )
        ..quadraticBezierTo(
          width * 0.92,
          height * 0.34,
          width * 0.92,
          height * 0.38,
        )
        ..lineTo(width * 0.92, height * 0.95)
        ..quadraticBezierTo(
          width * 0.92,
          height * 0.98,
          width * 0.85,
          height * 0.98,
        )
        ..lineTo(width * 0.15, height * 0.98)
        ..quadraticBezierTo(
          width * 0.08,
          height * 0.98,
          width * 0.08,
          height * 0.95,
        )
        ..lineTo(width * 0.08, height * 0.38)
        ..quadraticBezierTo(
          width * 0.08,
          height * 0.34,
          width * 0.10,
          height * 0.32,
        )
        ..cubicTo(
          width * 0.15,
          height * 0.27,
          width * 0.37,
          height * 0.23,
          width * 0.37,
          height * 0.18,
        )
        ..lineTo(width * 0.37, height * 0.07)
        ..lineTo(width * 0.35, height * 0.06)
        ..lineTo(width * 0.35, height * 0.03)
        ..quadraticBezierTo(
          width * 0.35,
          height * 0.02,
          width * 0.37,
          height * 0.02,
        )
        ..close();
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x80FFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_LabelCaptureGuidePainter oldDelegate) =>
      isBackLabel != oldDelegate.isBackLabel;
}
