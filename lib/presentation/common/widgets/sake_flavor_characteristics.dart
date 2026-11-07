import 'package:flutter/material.dart';
import '../../../common/sake/flavor_characteristics.dart';

class SakeFlavorAvoidanceChoices extends StatelessWidget {
  const SakeFlavorAvoidanceChoices({
    super.key,
    required this.selected,
    required this.onChanged,
  });
  final List<String> selected;
  final ValueChanged<List<String>>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('苦手な風味（任意）', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final feature in SakeFlavorCharacteristic.values)
            FilterChip(
              label: Text(feature.preference),
              selected: selected.contains(feature.preference),
              onSelected: onChanged == null
                  ? null
                  : (checked) {
                      final next = List<String>.of(selected)
                        ..remove(feature.preference);
                      if (checked) next.add(feature.preference);
                      onChanged!(next);
                    },
            ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        '記載を確認できるお酒の表示順に反映します。情報が不明なお酒にも、苦手な風味がある可能性があります。',
        style: TextStyle(fontSize: 12),
      ),
    ],
  );
}

class SakeFlavorCharacteristics extends StatelessWidget {
  const SakeFlavorCharacteristics({
    super.key,
    required this.evidence,
    this.preferences,
    this.compact = false,
  });
  final SakeFlavorEvidence evidence;
  final String? preferences;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final caution = evidence.caution(preferences);
    if (compact && caution == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: caution == null
            ? const Color(0xFFEAF0F7)
            : const Color(0xFFFFF3DE),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caution == null ? '香り・口当たり・余韻' : '苦手な風味の確認',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF143861),
            ),
          ),
          const SizedBox(height: 6),
          if (caution != null)
            Text(caution, style: const TextStyle(color: Color(0xFF62420D))),
          if (!compact) ...[
            for (final feature in SakeFlavorCharacteristic.values)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${feature.label}：${evidence.evidence[feature] == null ? '不明' : '記載あり'}',
                ),
              ),
            if (evidence.evidence.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final phrase in evidence.evidence.values.toSet())
                Text(
                  '「$phrase」',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF404A56),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            const Text(
              '登録タグ・商品説明の記載による参考情報です。記載がない場合は不明です。飲む一本ごとの保存状態による風味の違いは判定できません。',
              style: TextStyle(fontSize: 12, color: Color(0xFF596675)),
            ),
          ],
        ],
      ),
    );
  }
}
