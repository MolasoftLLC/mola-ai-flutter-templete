import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/journey/sake_journey.dart';
import '../../../domain/notifier/auth/auth_notifier.dart';
import '../../../domain/notifier/favorite/favorite_notifier.dart';
import '../../../domain/notifier/my_page/my_page_notifier.dart';
import '../../../domain/eintities/preferences/taste_preference_profile.dart';
import '../../../infrastructure/local_database/menu_analysis_history_repository.dart';
import '../../app_page_notifier.dart';
import '../../my_page/my_page.dart';
import '../../common/dialogs/sake_preferences_dialog.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomeTasteJourney extends StatefulWidget {
  const HomeTasteJourney({
    super.key,
    required this.onSearch,
    required this.onScan,
    required this.onRecommendations,
  });
  final Future<void> Function() onSearch, onScan;
  final VoidCallback onRecommendations;
  @override
  State<HomeTasteJourney> createState() => _HomeTasteJourneyState();
}

class _HomeTasteJourneyState extends State<HomeTasteJourney> {
  final _store = SakeJourneyStore.instance;
  String _owner = '', _facts = '';
  Future<JourneySnapshot>? _future;
  String? _impression;
  String? _offeredCompletion;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _store.revision.addListener(_reload);
  }

  void _reload() {
    if (mounted && _owner.isNotEmpty) {
      setState(() {
        _future = _store.load(_owner);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final owner = context.watch<AuthState?>()?.user?.uid ?? 'guest';
    final active = context.watch<AppPageState>().currentIndex == 0;
    if (!active && _offeredCompletion != null) {
      unawaited(_store.acknowledgeCompletion(_offeredCompletion!));
      _offeredCompletion = null;
    }
    final page = context.watch<MyPageState>();
    final likes = context.watch<FavoriteState>().myFavoriteList.length;
    final preference =
        page.tasteProfile != null ||
        (page.preferences?.trim().isNotEmpty ?? false);
    final legacyDiagnosis =
        page.tasteProfile != null &&
        (page.preferences?.trim().isNotEmpty ?? false) &&
        TastePreferenceProfile.fromSelections(
              page.preferences!.split('、').map((s) => s.trim()),
            ) ==
            null;
    final diagnosed =
        (page.sakePreferenceAnalysis?.trim().isNotEmpty ?? false) &&
        page.sakePreferenceAnalysisError == null;
    final scan =
        (page.achievementCounts['analyzedBottle'] ?? 0) > 0 ||
        (page.achievementCounts['menuAnalysis'] ?? 0) > 0;
    final facts = '$owner/$preference/$likes/$diagnosed/$legacyDiagnosis/$scan';
    if (_facts == facts) return;
    final ownerChanged = owner != _owner;
    if (ownerChanged && _offeredCompletion != null) {
      unawaited(_store.acknowledgeCompletion(_offeredCompletion!));
      _offeredCompletion = null;
    }
    _owner = owner;
    _facts = facts;
    _impression = null;
    _future = () async {
      var usedScan = scan;
      if (ownerChanged && !scan) {
        try {
          final history = await MenuAnalysisHistoryRepository(
            ownerId: owner == 'guest' ? null : owner,
          ).load();
          usedScan = history.any(
            (h) => h.analysisStatus == 'complete' && h.sakes.isNotEmpty,
          );
        } catch (_) {
          /* Existing server achievements remain valid. */
        }
      }
      await _store.reconcile(
        owner,
        preference: preference,
        likes: likes,
        scan: usedScan,
        diagnosed: diagnosed || legacyDiagnosis,
      );
      return _store.load(owner);
    }();
  }

  @override
  void dispose() {
    _store.revision.removeListener(_reload);
    if (_offeredCompletion != null)
      unawaited(_store.acknowledgeCompletion(_offeredCompletion!));
    super.dispose();
  }

  Future<void> _act(JourneyAction action) async {
    if (_busy) return;
    final owner = _owner;
    setState(() => _busy = true);
    SakeJourneyStore.track(action.name, 'tap');
    try {
      switch (action) {
        case JourneyAction.preference:
          await showSakePreferencesSelectionDialog(
            context: context,
            myPageNotifier: context.read<MyPageNotifier>(),
          );
        case JourneyAction.firstLike:
        case JourneyAction.moreLikes:
          await widget.onSearch();
        case JourneyAction.diagnosis:
          await Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => MyPage.wrapped(focusPreferences: true),
            ),
          );
        case JourneyAction.scan:
          await widget.onScan();
        case JourneyAction.complete:
          await _store.acknowledgeCompletion(owner);
          if (mounted) widget.onRecommendations();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guide = context.read<AppPageNotifier>().homeFeatureGuide;
    final active = context.select((AppPageState s) => s.currentIndex == 0);
    final likes = context.select((FavoriteState s) => s.myFavoriteList.length);
    return ValueListenableBuilder<bool>(
      valueListenable: guide.visibility,
      builder: (_, tutorial, _) {
        if (tutorial || !active) return const SizedBox.shrink();
        return FutureBuilder<JourneySnapshot>(
          future: _future,
          builder: (context, snapshot) {
            // Do not expose a previous account's FutureBuilder data while loading.
            if (snapshot.connectionState != ConnectionState.done ||
                !snapshot.hasData) {
              return const SizedBox.shrink();
            }
            final progress = snapshot.data!;
            if (!progress.visible(DateTime.now())) {
              return const SizedBox.shrink();
            }
            final action = progress.action(likes);
            return VisibilityDetector(
              key: ValueKey('journey-$_owner-${action.name}'),
              onVisibilityChanged: (info) {
                if (info.visibleFraction < .25 ||
                    !mounted ||
                    ModalRoute.of(context)?.isCurrent != true) {
                  return;
                }
                final key = '$_owner/${action.name}';
                if (_impression != key) {
                  _impression = key;
                  if (action == JourneyAction.complete)
                    _offeredCompletion = _owner;
                  SakeJourneyStore.track(action.name, 'impression');
                }
              },
              child: HomeTasteJourneyCard(
                progress: progress,
                likes: likes,
                busy: _busy,
                onAction: () => _act(action),
                onLater: () {
                  SakeJourneyStore.track(action.name, 'cancel');
                  if (action == JourneyAction.complete) {
                    unawaited(_store.acknowledgeCompletion(_owner));
                  } else {
                    unawaited(_store.dismiss(_owner));
                  }
                },
                onHide: () {
                  SakeJourneyStore.track(action.name, 'cancel');
                  unawaited(_store.dismiss(_owner, forever: true));
                },
              ),
            );
          },
        );
      },
    );
  }
}

class HomeTasteJourneyCard extends StatelessWidget {
  const HomeTasteJourneyCard({
    super.key,
    required this.progress,
    required this.likes,
    required this.onAction,
    required this.onLater,
    required this.onHide,
    this.busy = false,
  });
  final JourneySnapshot progress;
  final int likes;
  final bool busy;
  final VoidCallback onAction, onLater, onHide;
  @override
  Widget build(BuildContext context) {
    final action = progress.action(likes);
    final (message, button) = switch (action) {
      JourneyAction.preference => (
        'どんなお酒がお好きですか？甘口・辛口など、まずは簡単に教えてください。',
        '好みを選ぶ',
      ),
      JourneyAction.firstLike => ('好きだったお酒があれば、♡をつけてみましょう。', 'お酒を探す'),
      JourneyAction.moreLikes => (
        '好きなお酒が少しずつ集まってきました。あと${favoriteDiagnosisMinimum - likes}件で、お気に入りから診断できます。',
        'もう少し探す',
      ),
      JourneyAction.diagnosis => ('集めたお気に入りから、好みの傾向を見てみましょう。', 'お気に入りから診断'),
      JourneyAction.scan => (
        '目の前のお酒は好みに合いそう？ラベル・メニュー・文字スキャンで比べられます。',
        '解析してみる',
      ),
      JourneyAction.complete => (
        'お酒えらびの準備ができました。気になるお酒は保存、飲んで好きだったお酒には♡を。',
        'おすすめを見る',
      ),
    };
    const ink = Color(0xFF143861);
    return Container(
      key: const ValueKey('home-taste-journey'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9DEC1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: ink, size: 20),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'お酒えらびのヒント',
                  style: TextStyle(color: ink, fontWeight: FontWeight.bold),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '案内の表示設定',
                onSelected: (_) => onHide(),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'hide', child: Text('この案内を表示しない')),
                ],
              ),
            ],
          ),
          Text(
            'お酒えらびの準備 ${progress.steps.length} / 4',
            style: const TextStyle(color: ink, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: JourneyStep.values.map((step) {
              final done = progress.steps.contains(step);
              final label = const [
                '好みを選ぶ',
                '好きに♡',
                '傾向を確認',
                '解析で比較',
              ][step.index];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: done ? ink : const Color(0xFFDED9CC),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (done)
                            const Icon(Icons.check, size: 11, color: ink),
                          Flexible(
                            child: Text(
                              label,
                              style: const TextStyle(fontSize: 10, color: ink),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            style: const TextStyle(color: ink, fontSize: 14, height: 1.55),
          ),
          if (action == JourneyAction.diagnosis)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'いいねだけでは好みは更新されません。診断で見直せます。',
                style: TextStyle(fontSize: 11, color: Colors.blueGrey),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed: busy ? null : onAction,
                style: FilledButton.styleFrom(
                  backgroundColor: ink,
                  foregroundColor: Colors.white,
                ),
                child: Text(button),
              ),
              TextButton(
                onPressed: busy ? null : onLater,
                child: Text(
                  action == JourneyAction.complete ? '閉じる' : 'あとで',
                  style: const TextStyle(color: ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
