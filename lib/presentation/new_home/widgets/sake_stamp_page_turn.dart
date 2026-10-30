import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Turns the currently painted paper, without rebuilding a front cover.
class SakeStampPageTurnController {
  _SakeStampPageTurnState? _state;
  bool get isBusy => _state?._busy ?? false;

  void turn(VoidCallback change, {bool backwards = false}) {
    if (_state == null) {
      change();
    } else {
      _state!._begin(change, backwards: backwards, autoFinish: true);
    }
  }

  void begin(VoidCallback change, {required bool backwards}) {
    if (_state == null) {
      change();
    } else {
      _state!._begin(change, backwards: backwards, autoFinish: false);
    }
  }

  void update(double progress) => _state?._update(progress);

  void finish({required bool commit, VoidCallback? onCancel}) {
    if (_state == null) {
      if (!commit) onCancel?.call();
    } else {
      _state!._finish(commit, onCancel);
    }
  }
}

class SakeStampPageTurn extends StatefulWidget {
  const SakeStampPageTurn({
    super.key,
    required this.controller,
    required this.child,
  });
  final SakeStampPageTurnController controller;
  final Widget child;

  @override
  State<SakeStampPageTurn> createState() => _SakeStampPageTurnState();
}

class _SakeStampPageTurnState extends State<SakeStampPageTurn>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _turn;
  ui.Image? _paper;
  bool _backwards = false;
  bool _preparing = false;
  bool _settling = false;
  double _desiredProgress = 0;
  bool? _pendingFinish;
  VoidCallback? _onCancel;
  int _generation = 0;
  bool get _busy => _preparing || _paper != null;

  @override
  void initState() {
    super.initState();
    _turn = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    widget.controller._state = this;
  }

  @override
  void didUpdateWidget(covariant SakeStampPageTurn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller._state == this) {
        oldWidget.controller._state = null;
      }
      widget.controller._state = this;
    }
  }

  void _begin(
    VoidCallback change, {
    required bool backwards,
    required bool autoFinish,
  }) {
    final generation = ++_generation;
    _turn.stop();
    _preparing = true;
    _settling = false;
    _desiredProgress = 0;
    _pendingFinish = autoFinish ? true : null;
    _onCancel = null;
    void capture() {
      if (!mounted || generation != _generation) return;
      ui.Image? image;
      if (!MediaQuery.disableAnimationsOf(context)) {
        final boundary = _boundary.currentContext?.findRenderObject();
        if (boundary is RenderRepaintBoundary && boundary.hasSize) {
          try {
            image = boundary.toImageSync(
              pixelRatio: MediaQuery.devicePixelRatioOf(context).clamp(1, 2),
            );
          } catch (_) {
            // A missing painted layer must never prevent navigation.
          }
        }
      }
      final old = _paper;
      setState(() {
        _paper = image;
        _backwards = backwards;
        _preparing = false;
        _turn.value = _desiredProgress;
      });
      _release(old);
      change();
      final finish = _pendingFinish;
      if (finish != null) _finish(finish, _onCancel);
    }

    final render = _boundary.currentContext?.findRenderObject();
    if (render is RenderRepaintBoundary && render.debugNeedsPaint) {
      WidgetsBinding.instance.addPostFrameCallback((_) => capture());
      WidgetsBinding.instance.ensureVisualUpdate();
    } else {
      capture();
    }
  }

  void _update(double progress) {
    if (_settling) return;
    _desiredProgress = progress.clamp(0, 1);
    if (!_preparing) _turn.value = _desiredProgress;
  }

  Future<void> _finish(bool commit, VoidCallback? onCancel) async {
    _pendingFinish = commit;
    _onCancel = onCancel;
    if (_preparing) return;
    final generation = _generation;
    _settling = true;
    if (_paper != null && !MediaQuery.disableAnimationsOf(context)) {
      try {
        await _turn
            .animateTo(
              commit ? 1 : 0,
              duration: Duration(
                milliseconds: (360 * ((commit ? 1 : 0) - _turn.value).abs())
                    .round()
                    .clamp(100, 360),
              ),
              curve: Curves.easeOutCubic,
            )
            .orCancel;
      } on TickerCanceled {
        return;
      }
    }
    if (!mounted || generation != _generation) return;
    final old = _paper;
    setState(() {
      _paper = null;
      _settling = false;
      _pendingFinish = null;
      _onCancel = null;
    });
    _release(old);
    if (!commit) onCancel?.call();
  }

  void _release(ui.Image? image) {
    if (image == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => image.dispose());
  }

  @override
  void dispose() {
    _generation++;
    if (widget.controller._state == this) widget.controller._state = null;
    _turn.dispose();
    _release(_paper);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: _boundary,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        ExcludeSemantics(
          excluding: _busy,
          child: IgnorePointer(ignoring: _busy, child: widget.child),
        ),
        if (_paper != null)
          Positioned.fill(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: LayoutBuilder(
                  builder: (context, constraints) => AnimatedBuilder(
                    animation: _turn,
                    builder: (context, child) {
                      final p = _turn.value;
                      final shade = math.sin(math.pi * p) * .24;
                      return Transform(
                        key: const ValueKey('stamp-page-turn-sheet'),
                        alignment: _backwards
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, .08 / constraints.maxWidth)
                          ..rotateY((_backwards ? -1 : 1) * math.pi / 2 * p),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            RawImage(
                              key: const ValueKey('stamp-turning-paper'),
                              image: _paper,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.medium,
                            ),
                            Positioned.fill(
                              top: 12,
                              bottom: 12,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: _backwards
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                    end: _backwards
                                        ? Alignment.centerLeft
                                        : Alignment.centerRight,
                                    colors: [
                                      Colors.black.withValues(alpha: shade),
                                      Colors.transparent,
                                      Colors.black.withValues(
                                        alpha: shade * .5,
                                      ),
                                    ],
                                    stops: const [0, .15, 1],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
