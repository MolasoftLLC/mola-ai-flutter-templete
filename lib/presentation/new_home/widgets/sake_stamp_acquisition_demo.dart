import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'sake_stamp_book.dart';

const _ink = Color(0xFFB73927);
const _navy = Color(0xFF143861);

bool _english(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

/// Visual preview only: it has no dependency on records or award persistence.
class SakeStampDemoButton extends StatelessWidget {
  const SakeStampDemoButton({super.key});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    key: const ValueKey('sake-stamp-demo-button'),
    onPressed: () => showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: const Color(0xFF071C35).withValues(alpha: .88),
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 180),
      transitionBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      pageBuilder: (_, __, ___) => const SakeStampAcquisitionDemo(),
    ),
    icon: const Icon(Icons.play_arrow_rounded, size: 18),
    label: Text(_english(context) ? 'Demo' : 'デモ'),
    style: OutlinedButton.styleFrom(
      foregroundColor: _ink,
      side: BorderSide(color: _ink.withValues(alpha: .4)),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      minimumSize: const Size(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  );
}

/// A self-contained, replayable stamp animation. The sample brand is fixed.
class SakeStampAcquisitionDemo extends StatefulWidget {
  const SakeStampAcquisitionDemo({super.key});

  @override
  State<SakeStampAcquisitionDemo> createState() =>
      _SakeStampAcquisitionDemoState();
}

class _SakeStampAcquisitionDemoState extends State<SakeStampAcquisitionDemo>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..addListener(_onTick);
  bool _started = false;
  bool _pressed = false;
  bool _reduceMotion = false;

  void _onTick() {
    if (!_pressed && !_reduceMotion && _controller.value >= .44) {
      _pressed = true;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _controller.value = 1;
    } else if (!_started) {
      _controller.forward();
    }
    _started = true;
  }

  void _replay() {
    _pressed = false;
    if (_reduceMotion) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _phase(double start, double end, {Curve curve = Curves.linear}) =>
      curve.transform(
        ((_controller.value - start) / (end - start)).clamp(0, 1),
      );

  @override
  Widget build(BuildContext context) {
    final english = _english(context);
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _controller.stop();
      },
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 350),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      english ? 'STAMP ANIMATION · DEMO' : '酒印獲得アニメーション · デモ',
                      style: const TextStyle(
                        color: Color(0xFFE6D6B6),
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final paper = _phase(
                          0,
                          .25,
                          curve: Curves.easeOutCubic,
                        );
                        final approach = _phase(
                          .27,
                          .44,
                          curve: Curves.easeInCubic,
                        );
                        final settle = _phase(
                          .44,
                          .58,
                          curve: Curves.easeOutBack,
                        );
                        final reveal = _phase(.59, .81, curve: Curves.easeOut);
                        final pulse = _phase(
                          .44,
                          .67,
                          curve: Curves.easeOutCubic,
                        );
                        final scale = approach < 1
                            ? 1.85 - .93 * approach
                            : .92 + .08 * settle;
                        final bounce = math.sin(_phase(.44, .58) * math.pi) * 3;
                        return Opacity(
                          opacity: paper,
                          child: Transform.translate(
                            offset: Offset(0, 30 * (1 - paper) + bounce),
                            child: Transform.rotate(
                              angle: -.04 * (1 - paper),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: .22,
                                      ),
                                      blurRadius: 28,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: CustomPaint(
                                  painter: const SakeStampPaperPainter(),
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      28,
                                      24,
                                      24,
                                      26,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          '日本酒 ご酒印',
                                          style: TextStyle(
                                            fontFamily: 'SakeSeal',
                                            color: _navy,
                                            fontSize: 25,
                                            letterSpacing: 3,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          english
                                              ? 'A new sake encounter'
                                              : '一杯の出会いを、旅のしるしに。',
                                          style: const TextStyle(
                                            color: Color(0xFF83765F),
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        SizedBox.square(
                                          dimension: 190,
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              if (pulse > 0 && pulse < 1)
                                                Transform.scale(
                                                  scale: 1 + pulse * .35,
                                                  child: Opacity(
                                                    opacity: (1 - pulse) * .3,
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: _ink,
                                                          width: 1.3,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              Opacity(
                                                opacity: _phase(.27, .34),
                                                child: Transform.translate(
                                                  offset: Offset(
                                                    0,
                                                    -65 * (1 - approach),
                                                  ),
                                                  child: Transform.scale(
                                                    key: const ValueKey(
                                                      'acquisition-demo-seal',
                                                    ),
                                                    scale: scale,
                                                    child: Transform.rotate(
                                                      angle:
                                                          -.19 + .12 * approach,
                                                      child: RepaintBoundary(
                                                        child: Opacity(
                                                          opacity:
                                                              .78 +
                                                              .22 *
                                                                  _phase(
                                                                    .44,
                                                                    .65,
                                                                  ),
                                                          child:
                                                              const _DemoSeal(),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        Opacity(
                                          opacity: reveal,
                                          child: Transform.translate(
                                            offset: Offset(0, 8 * (1 - reveal)),
                                            child: Column(
                                              children: [
                                                Text(
                                                  english
                                                      ? 'A new stamp!'
                                                      : '新しい酒印を獲得！',
                                                  key: const ValueKey(
                                                    'acquisition-demo-title',
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: _ink,
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  english
                                                      ? 'Dewazakura · Yamagata'
                                                      : '出羽桜  ·  山形県',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: _navy,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
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
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      english
                          ? 'Preview only. No stamp or record is saved.'
                          : 'デモのため、酒印・飲んだ記録は追加されません',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFCCD5DF),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            key: const ValueKey('replay-stamp-demo'),
                            onPressed: _replay,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFFDF90),
                              side: const BorderSide(color: Color(0xFF8D8166)),
                              minimumSize: const Size(0, 48),
                            ),
                            icon: const Icon(Icons.replay, size: 19),
                            label: Text(english ? 'Replay' : 'もう一度'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: const ValueKey('close-stamp-demo'),
                            onPressed: () => Navigator.of(context).pop(),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFFDC72),
                              foregroundColor: _navy,
                              minimumSize: const Size(0, 48),
                            ),
                            child: Text(english ? 'Close' : '閉じる'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoSeal extends StatelessWidget {
  const _DemoSeal();

  @override
  Widget build(BuildContext context) => Semantics(
    label: '出羽桜・山形県、デモの酒印',
    child: const ExcludeSemantics(
      child: CustomPaint(
        painter: SakeStampSealPainter(1, _ink),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                '酒\n之\n縁',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: 'SakeSeal',
                  fontSize: 19,
                  height: 1.4,
                  color: _ink,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '出\n羽\n桜',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: 'SakeSeal',
                  fontSize: 46,
                  height: 1.03,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '山\n形\n県',
                textScaler: TextScaler.noScaling,
                style: TextStyle(
                  fontFamily: 'SakeSeal',
                  fontSize: 18,
                  height: 1.4,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
