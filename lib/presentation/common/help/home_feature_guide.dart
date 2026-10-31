import 'dart:async';

import '../../new_home/widgets/capture_radial_menu.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ホームの撮影・検索・メニュー解析などを案内するフォーカスガイド。
class HomeFeatureGuide {
  final headerScanKey = GlobalKey();
  final bottomScanKey = GlobalKey();
  final searchKey = GlobalKey();
  final menuAnalysisKey = GlobalKey();
  final mapKey = GlobalKey();
  final myPageKey = GlobalKey();
  final recommendationsKey = GlobalKey();
  final timelineKey = GlobalKey();
  final japanSakeKey = GlobalKey();
  final homeScrollController = ScrollController();
  bool _showing = false;
  static const _preferenceKey = 'home_feature_guide_shown_v5';

  void dispose() => homeScrollController.dispose();

  Future<Rect?> _scrollToSection(GlobalKey targetKey) async {
    if (!homeScrollController.hasClients) return null;
    // Rebuild earlier sections as well when the user goes back through the guide.
    if (targetKey.currentContext == null && homeScrollController.offset > 0) {
      homeScrollController.jumpTo(
        homeScrollController.position.minScrollExtent,
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!homeScrollController.hasClients) return null;
    }
    // ListView の画面外の子が構築されるまで少しずつ進める。
    for (var i = 0; targetKey.currentContext == null && i < 12; i++) {
      final position = homeScrollController.position;
      final next = (position.pixels + position.viewportDimension * .6).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (next == position.pixels) break;
      await homeScrollController.animateTo(
        next,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
      );
      await WidgetsBinding.instance.endOfFrame;
      if (!homeScrollController.hasClients) return null;
    }
    final targetContext = targetKey.currentContext;
    if (targetContext == null || !targetContext.mounted) return null;
    await Scrollable.ensureVisible(
      targetContext,
      alignment: .08,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
    await WidgetsBinding.instance.endOfFrame;
    final box = targetKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> showIfNeeded(
    BuildContext context,
    bool Function() isHome, {
    bool force = false,
  }) async {
    if (_showing) return;
    _showing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!force && prefs.getBool(_preferenceKey) == true) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted ||
          !isHome() ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      if (homeScrollController.hasClients) {
        await homeScrollController.animateTo(
          homeScrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
        await WidgetsBinding.instance.endOfFrame;
      }
      if (!context.mounted ||
          !isHome() ||
          ModalRoute.of(context)?.isCurrent != true) {
        return;
      }
      Rect? bounds(GlobalKey key) {
        final targetContext = key.currentContext;
        final box = targetContext?.findRenderObject();
        if (box is! RenderBox || !box.attached || !box.hasSize) return null;
        final rect = box.localToGlobal(Offset.zero) & box.size;
        if ((key == recommendationsKey ||
                key == timelineKey ||
                key == japanSakeKey) &&
            targetContext != null) {
          final viewport = Scrollable.maybeOf(
            targetContext,
          )?.context.findRenderObject();
          if (viewport is RenderBox && viewport.attached && viewport.hasSize) {
            return rect.intersect(
              viewport.localToGlobal(Offset.zero) & viewport.size,
            );
          }
        }
        return rect;
      }

      final targetKeys = [
        [bottomScanKey],
        [searchKey],
        [menuAnalysisKey],
        [mapKey],
        [myPageKey],
        [recommendationsKey],
        [timelineKey],
        [japanSakeKey],
      ];
      if (targetKeys
          .take(5)
          .expand((keys) => keys)
          .any((key) => bounds(key) == null)) {
        return;
      }
      final completed = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => FeatureGuideOverlay(
          bottomMessageSteps: const {5, 6, 7},
          capturePreviewAnchor: () => bounds(bottomScanKey)?.center,
          titles: const [
            'まずは「解析」から',
            '名前や条件で探す',
            '出会った銘柄を酒印に',
            'みんなのマップ',
            'マイページ',
            '好みに合う一本を見つける',
            'タイムライン',
            '日本酒を旅する',
          ],
          messages: const [
            '「ラベルを撮る」はボトル、「メニューを撮る」はお店のメニューへ。保存済みの写真は「写真から選ぶ」を使います。今は案内用の表示です。',
            'ホームの検索欄から、お酒の名前や条件で探せます。気になる一本の詳細を見てみましょう。',
            '自分で解析したお酒の詳細や、飲んだ記録から酒印を集められます。全国・県別で見返せます。',
            'お酒が登録されたお店を地図で探せます。「すべての店舗」と「自分の登録」を切り替え、お酒の名前でも絞り込めます。',
            '保存したお酒・お気に入り・メニュー解析履歴をまとめて確認。飲んだ感想や場所を残したり、好みの設定を変更したりできます。',
            'マイページで好きなお酒の傾向を設定すると、おすすめや好みマッチ度の参考になります。新しい一本を探すきっかけに。',
            'みんなのお酒との出会いを見てみましょう。気になる投稿はタップして詳細へ。「もっと見る」で一覧を開けます。',
            '地図をピンチで拡大して県をタップ。銘柄・商品や県別の記録一覧を見られます。記録した商品数で県の色が変わり、10商品以上でオレンジになります。',
          ],
          stepIcons: const [
            Icons.camera_alt_outlined,
            Icons.search,
            Icons.menu_book_outlined,
            Icons.public,
            Icons.person_outline,
            Icons.favorite_border,
            Icons.forum_outlined,
            Icons.explore_outlined,
          ],
          circleSteps: const {0},
          outlineSteps: const {2, 3, 4, 7},
          prepareStep: (step) async {
            if (step < 5 && homeScrollController.hasClients) {
              await homeScrollController.animateTo(
                homeScrollController.position.minScrollExtent,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOutCubic,
              );
            }
            if (step == 5) await _scrollToSection(recommendationsKey);
            if (step == 6) await _scrollToSection(timelineKey);
            if (step == 7) await _scrollToSection(japanSakeKey);
          },
          readTargets: (step) => [
            for (final key in targetKeys[step])
              if (bounds(key) case final Rect rect) rect,
          ],
        ),
      );
      if (completed == true) await prefs.setBool(_preferenceKey, true);
    } finally {
      _showing = false;
    }
  }
}

class FeatureGuideOverlay extends StatefulWidget {
  const FeatureGuideOverlay({
    super.key,
    required this.readTargets,
    required this.prepareStep,
    required this.titles,
    required this.messages,
    this.circleSteps = const {},
    this.outlineSteps = const {},
    this.welcomeTitle = '一杯の出会いを、日々の思い出に',
    this.welcomeMessage = '撮って調べる。記録する。次の一本に出会う。\nSAKEPEDIAの使い方を、画面に沿ってご案内します。',
    this.stepIcons = const [],
    this.capturePreviewAnchor,
    this.bottomMessageSteps = const {},
  });
  final Future<void> Function(int step) prepareStep;
  final Offset? Function()? capturePreviewAnchor;
  final List<IconData> stepIcons;
  final List<String> titles;
  final List<String> messages;
  final Set<int> circleSteps;
  final Set<int> outlineSteps;
  final String welcomeTitle;
  final String welcomeMessage;
  final Set<int> bottomMessageSteps;
  final List<Rect> Function(int step) readTargets;

  @override
  State<FeatureGuideOverlay> createState() => FeatureGuideOverlayState();
}

class FeatureGuideOverlayState extends State<FeatureGuideOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focusPulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  int _step = -1;
  bool _scrolling = false;
  final GlobalKey _overlayKey = GlobalKey();
  List<Rect> _focusRects = const [];
  Timer? _focusTimer;

  @override
  void initState() {
    super.initState();
    // Track late-loading content and viewport changes only while the guide is open.
    _focusTimer = Timer.periodic(
      const Duration(milliseconds: 200),
      (_) => _refreshFocus(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshFocus());
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _focusPulse.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _focusPulse.stop();
      _focusPulse.value = 0;
    }
  }

  void _refreshFocus() {
    if (!mounted) return;
    final overlay = _overlayKey.currentContext?.findRenderObject();
    if (overlay is! RenderBox || !overlay.attached || !overlay.hasSize) return;
    final viewport = Offset.zero & overlay.size;
    final rects = <Rect>[];
    if (!_scrolling && _step >= 0) {
      for (final globalRect in widget.readTargets(_step)) {
        final localRect = Rect.fromPoints(
          overlay.globalToLocal(globalRect.topLeft),
          overlay.globalToLocal(globalRect.bottomRight),
        );
        final visible = localRect.intersect(viewport);
        if (!visible.isEmpty) rects.add(visible);
      }
    }
    if (!listEquals(_focusRects, rects)) setState(() => _focusRects = rects);
  }

  Future<void> _next() async {
    if (_scrolling) return;
    if (_step == widget.titles.length - 1) {
      Navigator.of(context).pop(true);
      return;
    }
    await _goTo(_step + 1);
  }

  Future<void> _goTo(int step) async {
    if (_scrolling) return;
    setState(() => _scrolling = true);
    try {
      if (step >= 0) await widget.prepareStep(step);
      if (!mounted) return;
      setState(() => _step = step);
      _focusPulse.stop();
      _focusPulse.value = 0;
      if (!MediaQuery.disableAnimationsOf(context)) {
        _focusPulse.repeat(reverse: true, count: 4);
      }
    } finally {
      if (mounted) setState(() => _scrolling = false);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshFocus());
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Stack(
      key: _overlayKey,
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _next,
          child: CustomPaint(
            painter: _HomeGuideFocusPainter(
              pulse: _focusPulse,
              targets: _scrolling ? const [] : _focusRects,
              circles: widget.circleSteps.contains(_step),
              outline: widget.outlineSteps.contains(_step),
            ),
          ),
        ),
        if (!_scrolling && _step == 0 && widget.capturePreviewAnchor != null)
          IgnorePointer(
            child: ExcludeSemantics(
              child: TweenAnimationBuilder<double>(
                key: const ValueKey('guide-expanded-capture-menu'),
                tween: Tween(begin: 0, end: 1),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                builder: (context, progress, _) => CaptureRadialMenu(
                  anchor:
                      widget.capturePreviewAnchor!() ??
                      Offset(
                        MediaQuery.sizeOf(context).width / 2,
                        MediaQuery.sizeOf(context).height -
                            MediaQuery.paddingOf(context).bottom -
                            48,
                      ),
                  progress: progress,
                  english: false,
                  onSelected: (_) {},
                  onClose: () {},
                ),
              ),
            ),
          ),
        if (!_scrolling)
          SafeArea(
            child: Align(
              alignment: _step == 0 && widget.capturePreviewAnchor != null
                  ? Alignment.topCenter
                  : widget.bottomMessageSteps.contains(_step)
                  ? Alignment.bottomCenter
                  : Alignment.center,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  56,
                  20,
                  _step == 0 && widget.capturePreviewAnchor != null
                      ? 310
                      : widget.bottomMessageSteps.contains(_step)
                      ? 88
                      : 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFCF5),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF143861),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  _step >= 0 && _step < widget.stepIcons.length
                                      ? widget.stepIcons[_step]
                                      : Icons.menu_book_outlined,
                                  color: const Color(0xFFFFD166),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _step < 0
                                      ? 'SAKEPEDIA GUIDE'
                                      : '${_step + 1} / ${widget.titles.length}',
                                  style: const TextStyle(
                                    color: Color(0xFF687880),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_step >= 0) ...[
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (_step + 1) / widget.titles.length,
                                minHeight: 4,
                                color: const Color(0xFF143861),
                                backgroundColor: const Color(0xFFE4E9ED),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            _step < 0
                                ? widget.welcomeTitle
                                : widget.titles[_step],
                            style: const TextStyle(
                              color: Color(0xFF143861),
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _step < 0
                                ? widget.welcomeMessage
                                : widget.messages[_step],
                            style: const TextStyle(
                              color: Color(0xFF42566A),
                              fontSize: 14,
                              height: 1.7,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              if (_step >= 0)
                                TextButton(
                                  onPressed: () => _goTo(_step - 1),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF143861),
                                  ),
                                  child: const Text('戻る'),
                                ),
                              const Spacer(),
                              FilledButton(
                                onPressed: _next,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF143861),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(112, 48),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _step == widget.titles.length - 1
                                      ? 'はじめる'
                                      : _step < 0
                                      ? '使い方を見る'
                                      : '次へ',
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
          ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 16,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('スキップ', style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    ),
  );
}

class _HomeGuideFocusPainter extends CustomPainter {
  _HomeGuideFocusPainter({
    required this.pulse,
    required this.targets,
    required this.circles,
    this.outline = false,
  }) : super(repaint: pulse);
  final Animation<double> pulse;
  final List<Rect> targets;
  final bool circles;
  final bool outline;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the dimming into its own layer, then erase each focus area.
    // This keeps the cutout transparent on every renderer and also handles
    // overlapping targets without depending on Path.combine's fill rule.
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = Colors.black.withValues(alpha: .68),
    );
    final expansion = 8 + 6 * Curves.easeInOut.transform(pulse.value);
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    for (final target in targets) {
      final rect = target.inflate(expansion);
      if (circles) {
        canvas.drawOval(rect, clearPaint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(14)),
          clearPaint,
        );
      }
    }
    canvas.restore();
    if (outline) {
      for (final target in targets) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            target.inflate(expansion),
            const Radius.circular(14),
          ),
          Paint()
            ..color = const Color(0xFFFFD166)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 + pulse.value,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HomeGuideFocusPainter oldDelegate) =>
      oldDelegate.targets != targets ||
      oldDelegate.circles != circles ||
      oldDelegate.outline != outline;
}
