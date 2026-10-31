import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_feature_guide.dart';

/// マイページの見出しを実際の位置に合わせて案内する。
class MyPageFeatureGuide {
  final accountKey = GlobalKey();
  final savedKey = GlobalKey();
  final historyKey = GlobalKey();
  final favoritesKey = GlobalKey();
  final myMapKey = GlobalKey();
  final preferencesKey = GlobalKey();
  final scrollController = ScrollController();
  bool _showing = false;
  static const _preferenceKey = 'my_page_feature_guide_shown_v2';

  List<GlobalKey> get _keys => [
    accountKey,
    savedKey,
    historyKey,
    favoritesKey,
    preferencesKey,
  ];

  void dispose() => scrollController.dispose();

  Rect? _bounds(int step, List<GlobalKey> keys) {
    final targetContext = keys[step].currentContext;
    final box = targetContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    // 長い一覧全体ではなく、機能を示す見出しをフォーカスする。
    var rect =
        box.localToGlobal(Offset.zero) &
        Size(
          box.size.width,
          box.size.height.clamp(0, step == 0 ? 120 : 64).toDouble(),
        );
    final viewport = targetContext == null
        ? null
        : Scrollable.maybeOf(targetContext)?.context.findRenderObject();
    if (viewport is RenderBox && viewport.attached && viewport.hasSize) {
      rect = rect.intersect(
        viewport.localToGlobal(Offset.zero) & viewport.size,
      );
    }
    return rect.isEmpty ? null : rect;
  }

  Future<void> showIfNeeded(BuildContext context, {bool force = false}) async {
    if (_showing) return;
    _showing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!force && prefs.getBool(_preferenceKey) == true) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) return;
      if (_keys.any((key) => key.currentContext == null)) return;
      final includeMap = myMapKey.currentContext != null;
      final keys = [..._keys];
      if (includeMap) keys.insert(3, myMapKey);
      FocusScope.of(context).unfocus();
      final completed = await showGeneralDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (_, __, ___) => FeatureGuideOverlay(
          welcomeTitle: 'マイページの使い方',
          welcomeMessage: '保存した一本も、好きな味も。\nあなたのお酒の記録を、ここにまとめます。',
          stepIcons: [
            Icons.person_outline,
            Icons.bookmark_border,
            Icons.receipt_long_outlined,
            if (includeMap) Icons.map_outlined,
            Icons.favorite_border,
            Icons.tune,
          ],
          titles: [
            'プロフィール・ポイント',
            '保存したお酒',
            'メニュー解析履歴',
            if (includeMap) 'あなたの地図',
            'お気に入りのお酒',
            '好きなお酒の傾向',
          ],
          messages: [
            'プロフィールの設定やログインはこちらから。うらやま・マップ貢献ポイントやバッジは、タップすると詳しく確認できます。',
            'スキャンして保存したお酒を振り返れます。お酒をタップして、写真や飲んだ場所などの記録を確認しましょう。',
            '撮影・解析したメニューを見返せます。履歴を開くと、お酒の詳細や好みマッチ度を確認できます。',
            if (includeMap)
              '場所を登録したお酒を、自分の地図で振り返れます。地図をタップすると「自分の登録」に絞った大きなマップが開きます。',
            '気になるお酒はハートでお気に入りに。好きな一本をまとめて見返せます。',
            'お気に入りを２つ以上登録すると「お気に入りからお酒診断」を使えます。好きな味を自分で入力することもでき、マッチ度やおすすめに反映されます。',
          ],
          outlineSteps: {for (var i = 0; i < keys.length; i++) i},
          readTargets: (step) => [
            if (_bounds(step, keys) case final Rect rect) rect,
          ],
          prepareStep: (step) async {
            final target = keys[step].currentContext;
            if (target == null || !target.mounted) return;
            await Scrollable.ensureVisible(
              target,
              alignment: .03,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
            );
            await WidgetsBinding.instance.endOfFrame;
          },
        ),
      );
      if (completed == true) await prefs.setBool(_preferenceKey, true);
    } finally {
      _showing = false;
    }
  }
}
