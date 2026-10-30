import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'japan_sake_map.dart';

/// A cover that lifts around the left binding, like Coffee AI's passport.
/// Once opened, the existing stamp pager owns horizontal gestures as before.
class SakeStampBookOpening extends StatefulWidget {
  const SakeStampBookOpening({
    super.key,
    required this.child,
    this.initiallyOpen = false,
    this.onOpened,
  });
  final Widget child;
  final bool initiallyOpen;
  final VoidCallback? onOpened;

  @override
  State<SakeStampBookOpening> createState() => _SakeStampBookOpeningState();
}

class _SakeStampBookOpeningState extends State<SakeStampBookOpening>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn;
  late bool _opened = widget.initiallyOpen;
  bool _settling = false;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  Future<void> _finish(bool open) async {
    if (_opened || _settling || (!open && _turn.value == 0)) return;
    _settling = true;
    if (!MediaQuery.disableAnimationsOf(context)) {
      try {
        await _turn
            .animateTo(
              open ? 1 : 0,
              duration: Duration(
                milliseconds: (300 * ((open ? 1 : 0) - _turn.value).abs())
                    .round()
                    .clamp(120, 300),
              ),
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _opened = open;
      _settling = false;
      _turn.value = open ? 1 : 0;
    });
    if (open) widget.onOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 236),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ExcludeSemantics(
            excluding: !_opened,
            child: IgnorePointer(ignoring: !_opened, child: widget.child),
          ),
          if (!_opened)
            Positioned.fill(
              top: 12,
              bottom: 12,
              child: LayoutBuilder(
                builder: (context, constraints) => Semantics(
                  button: true,
                  label: english ? 'Open sake stamp book' : '日本酒ご酒印帳をひらく',
                  onTap: () => _finish(true),
                  child: GestureDetector(
                    key: const ValueKey('stamp-book-cover'),
                    behavior: HitTestBehavior.opaque,
                    excludeFromSemantics: true,
                    onTap: () => _finish(true),
                    onHorizontalDragUpdate: (details) {
                      if (_settling) return;
                      _turn.value =
                          (_turn.value -
                                  details.delta.dx / constraints.maxWidth)
                              .clamp(0, 1);
                    },
                    onHorizontalDragEnd: (details) {
                      final speed = details.primaryVelocity ?? 0;
                      _finish(
                        speed.abs() > 650 ? speed < 0 : _turn.value > .24,
                      );
                    },
                    onHorizontalDragCancel: () => _finish(false),
                    child: AnimatedBuilder(
                      animation: _turn,
                      builder: (context, child) {
                        final p = MediaQuery.disableAnimationsOf(context)
                            ? 0.0
                            : _turn.value;
                        final shade = math.sin(math.pi * p) * .22;
                        return Transform(
                          key: const ValueKey('stamp-opening-sheet'),
                          alignment: Alignment.centerLeft,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, .08 / constraints.maxWidth)
                            ..rotateY(math.pi / 2 * p),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: .12 + shade,
                                  ),
                                  blurRadius: 10,
                                  offset: Offset(4 + 4 * p, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  child!,
                                  IgnorePointer(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withValues(
                                              alpha: .12 + shade,
                                            ),
                                            Colors.transparent,
                                            Colors.white.withValues(
                                              alpha: shade * .8,
                                            ),
                                          ],
                                          stops: const [0, .06, 1],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      child: CustomPaint(
                        painter: const _StampCoverPainter(),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(32, 24, 24, 24),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'SAKEPEDIA',
                                    style: TextStyle(
                                      color: Color(0xFFE3D3AC),
                                      fontSize: 11,
                                      letterSpacing: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    english ? 'Sake stamp book' : '日本酒ご酒印帳',
                                    style: TextStyle(
                                      fontFamily: english ? null : 'SakeSeal',
                                      color: const Color(0xFFFFE8AD),
                                      fontSize: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE3D3AC),
                                      ),
                                    ),
                                    child: const Text(
                                      '酒',
                                      style: TextStyle(
                                        fontFamily: 'SakeSeal',
                                        fontSize: 22,
                                        color: Color(0xFFE3D3AC),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StampCoverPainter extends CustomPainter {
  const _StampCoverPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = japanMapNavy);
    final grain = Paint()
      ..color = const Color(0xFFE3D3AC).withValues(alpha: .07)
      ..strokeWidth = .6;
    for (var i = 0; i < 150; i++) {
      final x = (i * 37.7) % size.width;
      final y = (i * 19.3) % size.height;
      canvas.drawLine(Offset(x, y), Offset(x + 3, y + .8), grain);
    }
    final thread = Paint()
      ..color = const Color(0xFFE3D3AC).withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24, 12, size.width - 36, size.height - 24),
        const Radius.circular(6),
      ),
      thread,
    );
    canvas.drawLine(const Offset(14, 0), Offset(14, size.height), thread);
    for (final y in [.2, .5, .8]) {
      canvas.drawLine(
        Offset(0, size.height * y),
        Offset(10, size.height * y - 3),
        thread..strokeWidth = 1.8,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StampCoverPainter oldDelegate) => false;
}
