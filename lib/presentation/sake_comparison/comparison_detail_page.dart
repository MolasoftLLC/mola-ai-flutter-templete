import 'package:flutter/material.dart';

import '../../domain/eintities/preferences/taste_preference_profile.dart';
import '../common/widgets/primary_app_bar.dart';
import '../common/widgets/sake_taste_match_preview.dart';
import 'comparison_item.dart';

/// A local detail view for text-only discoveries, without creating a master.
class ComparisonDetailPage extends StatelessWidget {
  const ComparisonDetailPage({super.key, required this.item, this.preference});

  final ComparisonItem item;
  final TastePreferenceProfile? preference;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const PrimaryAppBar(title: 'お酒の簡易情報'),
    backgroundColor: const Color(0xFFF4F6F9),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          item.sake.name ?? '',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF143861),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          [item.sake.brewery, item.sake.type].whereType<String>().join(' / '),
        ),
        const SizedBox(height: 24),
        if (item.sample)
          const Text('架空の商品・デモデータです。')
        else
          const Text(
            'AIによる簡易解析です。味わいや説明は推定を含む参考情報です。',
            style: TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
        const SizedBox(height: 16),
        SakeTasteMatchPreview(
          percent: item.match(preference),
          profile: item.profile,
          preference: preference,
          radarSize: 140,
        ),
        if (preference == null)
          const Text(
            '好みを設定するとマッチ度を表示できます。',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        const SizedBox(height: 24),
        const Text('お酒の特徴', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(
          item.sake.description?.trim().isNotEmpty == true
              ? item.sake.description!
              : item.sample
              ? item.text
              : '情報を取得できませんでした。読み取った説明を参考にしてください。',
        ),
        if (item.text.isNotEmpty) ...[
          const SizedBox(height: 24),
          const Text('読み取った説明', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SelectableText(item.text),
        ],
      ],
    ),
  );
}
