import 'package:flutter/material.dart';

import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../common/widgets/primary_app_bar.dart';
import '../common/widgets/sake_taste_match_preview.dart';
import 'comparison_item.dart';

const _navy = Color(0xFF143861);
const _paleBlue = Color(0xFFE6EDF6);

/// The cart stays central; buying preferences are chosen only when needed.
class ComparisonCartView extends StatelessWidget {
  const ComparisonCartView({
    super.key,
    required this.items,
    required this.recommended,
    required this.preference,
    required this.mood,
    required this.ready,
    required this.busy,
    required this.progress,
    required this.error,
    required this.scrollController,
    required this.cartKey,
    required this.readKey,
    required this.onCamera,
    required this.onGallery,
    required this.onSamples,
    required this.onRecommend,
    required this.onReset,
    required this.onHelp,
    required this.onDetail,
    required this.onRemove,
  });

  final List<ComparisonItem> items;
  final Set<String> recommended;
  final TastePreferenceProfile? preference;
  final ComparisonMood mood;
  final bool ready;
  final bool busy;
  final String progress;
  final String? error;
  final ScrollController scrollController;
  final GlobalKey cartKey;
  final GlobalKey readKey;
  final VoidCallback onCamera,
      onGallery,
      onSamples,
      onRecommend,
      onReset,
      onHelp;
  final ValueChanged<ComparisonItem> onDetail, onRemove;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF3F5F9),
    appBar: PrimaryAppBar(
      title: 'お酒えらび',
      actions: [
        IconButton(
          tooltip: '使い方',
          onPressed: onHelp,
          icon: const Icon(Icons.help_outline),
        ),
        IconButton(
          key: cartKey,
          tooltip: '比較カート',
          onPressed: () {
            if (scrollController.hasClients) {
              scrollController.animateTo(
                0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          },
          icon: Badge(
            backgroundColor: _paleBlue,
            textColor: _navy,
            label: Text('${items.length}'),
            child: const Icon(Icons.shopping_basket_outlined),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: !ready
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  children: [
                    if (items.isEmpty) _emptyState(),
                    if (items.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_basket_outlined,
                            color: _navy,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '気になるお酒',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                            ),
                          ),
                          Text(
                            '${items.length}本',
                            style: const TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'タップで詳しく',
                        style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (recommended.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                        decoration: BoxDecoration(
                          color: _paleBlue,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: _navy),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '今のおすすめ ${recommended.length}本',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: _navy,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: onReset,
                              child: const Text('解除'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          error!,
                          style: const TextStyle(color: Colors.deepOrange),
                        ),
                      ),
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _item(context, item),
                      ),
                  ],
                ),
              ),
              _footer(context),
            ],
          ),
  );

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        SizedBox(
          height: 166,
          width: 240,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 146,
                height: 146,
                decoration: const BoxDecoration(
                  color: Color(0xFFE6EDF6),
                  shape: BoxShape.circle,
                ),
              ),
              Positioned(
                left: 28,
                top: 18,
                child: Transform.rotate(
                  angle: -.15,
                  child: Container(
                    width: 92,
                    height: 116,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x12233757),
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.article_outlined, size: 48, color: _navy),
                        SizedBox(height: 8),
                        Text(
                          'メニュー',
                          style: TextStyle(color: _navy, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 23,
                bottom: 14,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: _paleBlue,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.shopping_basket_outlined,
                    size: 52,
                    color: _navy,
                  ),
                ),
              ),
              const Positioned(
                right: 24,
                top: 9,
                child: Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF6B8DB3),
                  size: 29,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          '気になるお酒を撮ろう',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: _navy,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          '説明カードも、メニューも。',
          style: TextStyle(color: Colors.blueGrey, fontSize: 15),
        ),
        const SizedBox(height: 28),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Step(icon: Icons.document_scanner_outlined, label: '撮る'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.chevron_right, color: Colors.blueGrey),
            ),
            _Step(icon: Icons.add_shopping_cart, label: '集める'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.chevron_right, color: Colors.blueGrey),
            ),
            _Step(icon: Icons.auto_awesome, label: '選ぶ'),
          ],
        ),
        const SizedBox(height: 26),
        TextButton(
          onPressed: busy ? null : onSamples,
          child: const Text('サンプルで試す'),
        ),
      ],
    ),
  );

  Widget _item(BuildContext context, ComparisonItem item) {
    final selected = recommended.contains(item.id);
    final target = preference ?? mood.preference;
    final profile = item.profile;
    final tags = <String>[
      if (item.sake.type?.isNotEmpty == true) item.sake.type!,
      if (profile != null && profile.fruity >= .65) 'フルーティ',
      if (profile != null && profile.dryness >= .65) '辛口',
      if (profile != null && profile.sweetness >= .65) '甘み',
      if (profile != null && profile.umami >= .65) '旨み',
      if (profile != null && profile.kire >= .7) 'キレ',
    ].take(3).toList();
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? const Color(0xFF527BA7) : const Color(0xFFE6EAF0),
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onDetail(item),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selected) ...[
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: _navy),
                    SizedBox(width: 6),
                    Text(
                      '今のおすすめ',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.sake.name ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: PopupMenuButton<String>(
                      tooltip: 'お酒の操作',
                      padding: EdgeInsets.zero,
                      onSelected: (_) => onRemove(item),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'remove',
                          enabled: !busy,
                          child: const Text('カートから外す'),
                        ),
                      ],
                      icon: const Icon(
                        Icons.more_horiz,
                        color: Colors.blueGrey,
                      ),
                    ),
                  ),
                ],
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final tag in tags) _Tag(tag)],
                ),
              ],
              const SizedBox(height: 12),
              SakeTasteMatchPreview(
                label: preference != null ? '好みマッチ度' : '今日の気分マッチ度',
                percent: item.match(target),
                profile: profile,
                preference: target,
                radarSize: 110,
                percentFontSize: 34,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (item.sample) const _Tag('サンプル'),
                  if (!item.sample && item.estimated) const _Tag('AI推定'),
                  if (item.profile == null)
                    const Text(
                      '味わい未取得',
                      style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                    )
                  else if (target == null)
                    const Text(
                      '気分を選ぶとマッチ度を表示',
                      style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                    ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward, color: _navy, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer(BuildContext context) => DecoratedBox(
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(top: BorderSide(color: Color(0xFFE6EAF0))),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy) ...[
              const LinearProgressIndicator(
                minHeight: 3,
                color: _navy,
                backgroundColor: Color(0xFFE6EDF6),
              ),
              const SizedBox(height: 8),
              Text(
                progress.isEmpty ? 'カートを更新中…' : progress,
                style: const TextStyle(fontSize: 12, color: _navy),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                if (items.isEmpty)
                  Expanded(
                    child: FilledButton.icon(
                      key: readKey,
                      onPressed: busy ? null : onCamera,
                      style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 54),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: const Text('撮影して追加'),
                    ),
                  )
                else ...[
                  OutlinedButton.icon(
                    key: readKey,
                    onPressed: busy ? null : onCamera,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _navy,
                      minimumSize: const Size(0, 54),
                    ),
                    icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                    label: const Text('追加'),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: busy ? null : onRecommend,
                      style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 54),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      icon: const Icon(Icons.tune, size: 19),
                      label: Text(
                        MediaQuery.sizeOf(context).width < 360
                            ? '絞り込む'
                            : 'こだわりで絞り込む',
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '写真から追加',
                  onPressed: busy ? null : onGallery,
                  icon: const Icon(Icons.photo_library_outlined, color: _navy),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: _navy, size: 28),
      const SizedBox(height: 8),
      Text(
        label,
        style: const TextStyle(
          color: _navy,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFFEEF3F8),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(text, style: const TextStyle(fontSize: 11, color: _navy)),
  );
}

typedef ComparisonChoice = ({int bottles, ComparisonMood mood, bool limited});

class ComparisonPreferenceSheet extends StatefulWidget {
  const ComparisonPreferenceSheet({
    super.key,
    required this.initial,
    required this.maxBottles,
    required this.hasPreference,
  });
  final ComparisonChoice initial;
  final int maxBottles;
  final bool hasPreference;
  @override
  State<ComparisonPreferenceSheet> createState() =>
      _ComparisonPreferenceSheetState();
}

class _ComparisonPreferenceSheetState extends State<ComparisonPreferenceSheet> {
  late int bottles = widget.initial.bottles.clamp(1, widget.maxBottles);
  late ComparisonMood mood = widget.initial.mood;
  late bool limited = widget.initial.limited;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'どんなお酒を選びたい？',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _navy,
            ),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in ComparisonMood.values)
                ChoiceChip(
                  avatar: Icon(switch (option) {
                    ComparisonMood.any => Icons.favorite_outline,
                    ComparisonMood.fruity => Icons.local_florist_outlined,
                    ComparisonMood.crisp => Icons.air,
                    ComparisonMood.rich => Icons.local_fire_department_outlined,
                    ComparisonMood.sweet => Icons.cake_outlined,
                    ComparisonMood.fresh => Icons.water_drop_outlined,
                  }, size: 18),
                  label: Text(switch (option) {
                    ComparisonMood.any => 'おまかせ',
                    ComparisonMood.fruity => 'フルーティ',
                    ComparisonMood.crisp => 'すっきり辛口',
                    ComparisonMood.rich => 'しっかり旨み',
                    ComparisonMood.sweet => 'やさしい甘み',
                    ComparisonMood.fresh => '爽やかな酸味',
                  }),
                  selected: mood == option,
                  showCheckmark: false,
                  selectedColor: const Color(0xFFE3ECF8),
                  onSelected: (_) => setState(() => mood = option),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '何本選ぶ？',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _navy,
                  ),
                ),
              ),
              IconButton(
                tooltip: '1本減らす',
                onPressed: bottles > 1 ? () => setState(() => bottles--) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text(
                '$bottles本',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                ),
              ),
              IconButton(
                tooltip: '1本増やす',
                onPressed: bottles < widget.maxBottles
                    ? () => setState(() => bottles++)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilterChip(
            avatar: const Icon(Icons.diamond_outlined, size: 18),
            label: const Text('限定ものも気になる'),
            selected: limited,
            selectedColor: _paleBlue,
            checkmarkColor: _navy,
            onSelected: (value) => setState(() => limited = value),
          ),
          const SizedBox(height: 24),
          if (!widget.hasPreference && mood == ComparisonMood.any && !limited)
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text(
                '飲みたい気分をひとつ選んでね',
                style: TextStyle(fontSize: 12, color: Colors.blueGrey),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  !widget.hasPreference &&
                      mood == ComparisonMood.any &&
                      !limited
                  ? null
                  : () => Navigator.pop(context, (
                      bottles: bottles,
                      mood: mood,
                      limited: limited,
                    )),
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 54),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('この条件でおすすめを見る'),
            ),
          ),
        ],
      ),
    ),
  );
}
