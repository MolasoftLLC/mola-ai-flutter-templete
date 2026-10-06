import 'dart:math' as math;

import 'package:flutter/material.dart';

const _navy = Color(0xFF143861);

class SakePreferenceMatchSection extends StatelessWidget {
  const SakePreferenceMatchSection({
    super.key,
    required this.percent,
    required this.fullWidth,
  });

  final int percent;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    key: const Key('taste-preference-match'),
    duration: const Duration(milliseconds: 900),
    curve: Curves.easeOutCubic,
    tween: Tween<double>(begin: 0, end: percent.clamp(0, 100).toDouble()),
    builder: (context, value, _) {
      final shownPercent = percent.clamp(0, 100);
      return Semantics(
        label: 'あなたの好みマッチ度 $shownPercent%',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: Column(
            crossAxisAlignment: fullWidth
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Text(
                'あなたの好みマッチ度',
                textAlign: fullWidth ? TextAlign.left : TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '$shownPercent%',
                style: const TextStyle(
                  color: Color(0xFFFFB347),
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 9),
              LayoutBuilder(
                builder: (context, constraints) => Container(
                  key: const Key('sake-match-gauge'),
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: constraints.maxWidth * value / 100,
                    height: 8,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class SakeTasteAxis {
  const SakeTasteAxis(this.label, this.value);

  final String label;
  final double value;
}

class SakeTasteChartLegend extends StatelessWidget {
  const SakeTasteChartLegend({super.key});

  @override
  Widget build(BuildContext context) => const Wrap(
    spacing: 16,
    runSpacing: 8,
    children: [
      _TasteChartLegendItem(
        colors: [Color(0xFFFFA13C), Color(0xFFE95C9A)],
        label: '橙・紫：このお酒',
      ),
      _TasteChartLegendItem(
        colors: [Color(0xFF2E8BFF), Color(0xFF65C7FF)],
        label: '青：あなたの好きな傾向',
      ),
    ],
  );
}

class _TasteChartLegendItem extends StatelessWidget {
  const _TasteChartLegendItem({required this.colors, required this.label});

  final List<Color> colors;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 22,
        height: 8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: LinearGradient(colors: colors),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(color: Color(0xFF647184), fontSize: 12),
      ),
    ],
  );
}

class SakeTasteRadarChart extends StatelessWidget {
  const SakeTasteRadarChart({
    super.key,
    required this.axes,
    this.preferenceAxes,
    this.maxSize = 248,
  });

  final List<SakeTasteAxis> axes;
  final List<SakeTasteAxis>? preferenceAxes;
  final double maxSize;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 700),
    curve: Curves.easeOutCubic,
    builder: (context, progress, _) => LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, maxSize);
        final radius = size * .31;
        return SizedBox(
          key: const Key('sake-taste-radar-chart'),
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _SakeTasteRadarPainter(
                  axes: axes,
                  preferenceAxes: preferenceAxes,
                  radius: radius,
                  progress: progress,
                ),
              ),
              for (var index = 0; index < axes.length; index++)
                _RadarLabel(
                  axis: axes[index],
                  index: index,
                  total: axes.length,
                  size: size,
                  radius: radius,
                ),
            ],
          ),
        );
      },
    ),
  );
}

class _RadarLabel extends StatelessWidget {
  const _RadarLabel({
    required this.axis,
    required this.index,
    required this.total,
    required this.size,
    required this.radius,
  });

  final SakeTasteAxis axis;
  final int index;
  final int total;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final angle = -math.pi / 2 + (2 * math.pi * index) / total;
    final labelRadius = radius + 34;
    const labelWidth = 62.0;
    final left = (size / 2 + math.cos(angle) * labelRadius - labelWidth / 2)
        .clamp(0.0, size - labelWidth);
    final top = (size / 2 + math.sin(angle) * labelRadius - 14).clamp(
      0.0,
      size - 28,
    );
    return Positioned(
      left: left,
      top: top,
      width: labelWidth,
      child: Text(
        axis.label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _navy,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SakeTasteRadarPainter extends CustomPainter {
  const _SakeTasteRadarPainter({
    required this.axes,
    required this.preferenceAxes,
    required this.radius,
    required this.progress,
  });

  final List<SakeTasteAxis> axes;
  final List<SakeTasteAxis>? preferenceAxes;
  final double radius;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angleStep = 2 * math.pi / axes.length;
    final gridPaint = Paint()
      ..color = const Color(0xFFDCE5EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axisPaint = Paint()
      ..color = const Color(0xFFE8EDF4)
      ..strokeWidth = 1;

    for (var level = 1; level <= 4; level++) {
      canvas.drawPath(
        _polygonPath(
          center: center,
          count: axes.length,
          radius: radius * level / 4,
        ),
        gridPaint,
      );
    }
    for (var index = 0; index < axes.length; index++) {
      canvas.drawLine(
        center,
        _point(center, radius, index, angleStep),
        axisPaint,
      );
    }

    final bounds = Rect.fromCircle(center: center, radius: radius);
    final userAxes = preferenceAxes;
    if (userAxes != null && userAxes.length == axes.length) {
      final userPath = _tastePath(
        center: center,
        axes: userAxes,
        radius: radius,
        angleStep: angleStep,
      );
      final userFillPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF65C7FF).withValues(alpha: .42),
            const Color(0xFF2E8BFF).withValues(alpha: .16),
          ],
        ).createShader(bounds);
      final userStrokePaint = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF65C7FF), Color(0xFF2E8BFF)],
        ).createShader(bounds)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      canvas.drawPath(userPath, userFillPaint);
      canvas.drawPath(userPath, userStrokePaint);
    }

    final path = _tastePath(
      center: center,
      axes: axes,
      radius: radius,
      angleStep: angleStep,
    );
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD96A).withValues(alpha: .72),
          const Color(0xFFFF8B5A).withValues(alpha: .38),
          const Color(0xFFBE6DE0).withValues(alpha: .24),
        ],
      ).createShader(bounds);
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFA13C), Color(0xFFE95C9A), Color(0xFF8D6CDB)],
      ).createShader(bounds)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  Path _tastePath({
    required Offset center,
    required List<SakeTasteAxis> axes,
    required double radius,
    required double angleStep,
  }) {
    final path = Path();
    for (var index = 0; index < axes.length; index++) {
      final value = axes[index].value.clamp(0.0, 1.0) * progress;
      final point = _point(center, radius * value, index, angleStep);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Path _polygonPath({
    required Offset center,
    required int count,
    required double radius,
  }) {
    final path = Path();
    final angleStep = 2 * math.pi / count;
    for (var index = 0; index < count; index++) {
      final point = _point(center, radius, index, angleStep);
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  Offset _point(Offset center, double radius, int index, double angleStep) {
    final angle = -math.pi / 2 + angleStep * index;
    return Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
  }

  @override
  bool shouldRepaint(covariant _SakeTasteRadarPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.axes != axes ||
      oldDelegate.preferenceAxes != preferenceAxes;
}
