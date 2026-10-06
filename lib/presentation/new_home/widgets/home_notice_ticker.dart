import 'dart:async';
import 'package:flutter/material.dart';
import '../../../domain/eintities/app_content.dart';

/// ホームのお知らせを一定速度で右から左へ繰り返し流す。
class HomeNoticeTicker extends StatefulWidget {
  const HomeNoticeTicker({super.key, required this.notices});

  final List<AppHomeNotice> notices;

  @override
  State<HomeNoticeTicker> createState() => _HomeNoticeTickerState();
}

class _HomeNoticeTickerState extends State<HomeNoticeTicker>
    with SingleTickerProviderStateMixin {
  static const _gap = 48.0;
  static const _speed = 28.0;
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  Timer? _scheduleTimer;

  @override
  void initState() {
    super.initState();
    _scheduleNextChange();
  }

  @override
  void didUpdateWidget(covariant HomeNoticeTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleNextChange();
  }

  void _scheduleNextChange() {
    _scheduleTimer?.cancel();
    final now = DateTime.now();
    final dates =
        widget.notices
            .expand((notice) => [notice.startsAt, notice.endsAt])
            .whereType<DateTime>()
            .where((date) => date.isAfter(now))
            .toList()
          ..sort();
    if (dates.isEmpty) return;
    _scheduleTimer = Timer(dates.first.difference(now), () {
      if (!mounted) return;
      setState(() {});
      _scheduleNextChange();
    });
  }

  @override
  void dispose() {
    _scheduleTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final message = widget.notices
        .where((notice) => notice.isVisibleAt(now))
        .take(3)
        .map((notice) => notice.message.trim().replaceAll(RegExp(r'\s+'), ' '))
        .join('　　　／　　　');
    if (message.isEmpty) {
      _controller.stop();
      return const SizedBox.shrink();
    }
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final text = TextPainter(
      text: TextSpan(
        text: message,
        style: const TextStyle(fontSize: 12, color: Color(0xFF143861)),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final duration = Duration(
      milliseconds: ((text.width + _gap) / _speed * 1000).round(),
    );
    if (reducedMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating || _controller.duration != duration) {
      _controller.repeat(period: duration);
      _controller.duration = duration;
    }

    return Semantics(
      label: message,
      excludeSemantics: true,
      child: Container(
        height: 30,
        color: const Color(0xFFEAF0F7),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            const Icon(
              Icons.campaign_outlined,
              size: 16,
              color: Color(0xFF143861),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRect(
                child: CustomPaint(
                  painter: _NoticePainter(
                    text: text,
                    animation: _controller,
                    gap: _gap,
                  ),
                  size: const Size(double.infinity, 30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoticePainter extends CustomPainter {
  _NoticePainter({
    required this.text,
    required this.animation,
    required this.gap,
  }) : super(repaint: animation);

  final TextPainter text;
  final Animation<double> animation;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final stride = text.width + gap;
    final start = -animation.value * stride;
    for (var x = start; x < size.width; x += stride) {
      text.paint(canvas, Offset(x, (size.height - text.height) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _NoticePainter oldDelegate) =>
      oldDelegate.text != text || oldDelegate.gap != gap;
}
