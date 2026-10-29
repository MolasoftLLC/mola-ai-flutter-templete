import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A decorative goshuin-style mark for a product with a personal record.
class RecordedSakeSeal extends StatelessWidget {
  const RecordedSakeSeal({super.key});

  static const ink = Color(0xFFB73927);

  @override
  Widget build(BuildContext context) => Semantics(
    label: Localizations.localeOf(context).languageCode == 'en'
        ? 'Drinking record added'
        : '飲んだ記録あり',
    child: ExcludeSemantics(
      child: Transform.rotate(
        angle: -.12,
        child: const SizedBox.square(
          dimension: 40,
          child: CustomPaint(
            painter: _RoundSealPainter(),
            child: Center(
              child: Text(
                '済',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: 'SakeSeal',
                  fontSize: 27,
                  height: 1,
                  color: ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _RoundSealPainter extends CustomPainter {
  const _RoundSealPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 2;
    final random = math.Random(7);
    final edge = Path();
    for (var i = 0; i <= 96; i++) {
      final angle = i / 96 * math.pi * 2;
      final r = radius + (random.nextDouble() - .5) * .8;
      final p = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
      if (i == 0) {
        edge.moveTo(p.dx, p.dy);
      } else {
        edge.lineTo(p.dx, p.dy);
      }
    }
    edge.close();
    canvas.drawPath(
      edge,
      Paint()
        ..color = RecordedSakeSeal.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
    final innerInk = Paint()
      ..color = RecordedSakeSeal.ink.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65;
    // Small gaps give the inner ring the feel of unevenly pressed ink.
    final inner = Rect.fromCircle(center: center, radius: radius - 3);
    for (var i = 0; i < 7; i++) {
      canvas.drawArc(inner, i * .9, .82, false, innerInk);
    }
  }

  @override
  bool shouldRepaint(covariant _RoundSealPainter oldDelegate) => false;
}
