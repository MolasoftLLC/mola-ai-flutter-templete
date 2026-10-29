import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/analytics/app_analytics.dart';
import '../../common/sake/personal_sake_record.dart';
import '../../common/utils/sake_image_utils.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../common/widgets/primary_app_bar.dart';
import '../sake_map/sake_master_detail_page.dart';
import 'saved_sake_detail_page.dart';

const _navy = Color(0xFF143861);

class MyRecordsPage extends StatefulWidget {
  const MyRecordsPage({super.key});

  @override
  State<MyRecordsPage> createState() => _MyRecordsPageState();
}

class _MyRecordsPageState extends State<MyRecordsPage> {
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _refresh() =>
      context.read<SavedSakeNotifier>().refreshFromServer();

  Future<void> _delete(Sake sake) async {
    final id = sake.savedId;
    if (id == null || _deleting.contains(id)) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('この記録を削除しますか？'),
        content: const Text('保存したお酒と、写真・場所・感想などの記録を削除します。この操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _deleting.add(id));
    var success = false;
    try {
      success = await context.read<SavedSakeNotifier>().deleteRecord(id);
    } catch (_) {
      success = false;
    } finally {
      if (mounted) setState(() => _deleting.remove(id));
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? '記録を削除しました。' : '削除できませんでした。通信状態を確認してもう一度お試しください。',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final records = context
        .select((SavedSakeState state) => state.savedSakeList)
        .where((sake) => sake.savedId?.isNotEmpty == true)
        .where(hasPersonalSakeRecord)
        .toList(growable: false);
    return AnalyticsScreen(
      name: 'my_records',
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: const PrimaryAppBar(title: 'あなたの記録'),
        body: RefreshIndicator(
          color: _navy,
          onRefresh: _refresh,
          child: records.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 160),
                    Icon(Icons.edit_note, size: 48, color: _navy),
                    SizedBox(height: 16),
                    Center(
                      child: Text('まだ記録がありません', style: TextStyle(color: _navy)),
                    ),
                    SizedBox(height: 8),
                    Center(child: Text('感想や場所、味わいを記録すると、ここで振り返れます。')),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final sake = records[index];
                    final busy = _deleting.contains(sake.savedId);
                    return _RecordCard(
                      key: ValueKey(sake.savedId),
                      sake: sake,
                      busy: busy,
                      onOpen: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SavedSakeDetailPage.forSake(sake),
                        ),
                      ),
                      onEdit: () => showSakeRecordEditorSheet(
                        context,
                        notifier: context.read<SavedSakeNotifier>(),
                        sake: sake,
                      ),
                      onDelete: () => _delete(sake),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    super.key,
    required this.sake,
    required this.busy,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Sake sake;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final place = (sake.drinkingPlace?.displayName ?? sake.place)?.trim();
    final impression = sake.impression?.trim();
    final tags = sake.userTags ?? const <String>[];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: busy ? null : onOpen,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(width: 64, height: 84, child: _image()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sake.name ?? '名称不明の日本酒',
                          style: const TextStyle(
                            color: _navy,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (sake.brewery?.isNotEmpty == true)
                          Text(
                            sake.brewery!,
                            style: const TextStyle(
                              color: Color(0xFF647184),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: _navy),
                ],
              ),
            ),
            if (place?.isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 18, color: _navy),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(place!, style: const TextStyle(color: _navy)),
                  ),
                ],
              ),
            ],
            if (impression?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text(
                impression!,
                style: const TextStyle(color: Color(0xFF46566A), height: 1.5),
              ),
            ],
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in tags)
                    Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            if (sake.personalTasteRatings?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                _tasteSummary(sake.personalTasteRatings!),
                style: const TextStyle(color: Color(0xFF647184), fontSize: 12),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: busy ? null : onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('編集'),
                ),
                TextButton.icon(
                  onPressed: busy ? null : onDelete,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline, size: 18),
                  label: const Text('削除'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    final path = preferredSakeImagePath(
      personalImagePaths: sake.imagePaths,
      thumbnailImageUrl: sake.thumbnailImageUrl,
      primaryImageUrl: sake.primaryImageUrl,
    );
    Widget placeholder() => Container(
      color: const Color(0xFFF1F3F5),
      child: const Icon(Icons.local_bar, color: _navy),
    );
    if (path == null) return placeholder();
    if (path.startsWith('https://') || path.startsWith('http://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => placeholder(),
      );
    }
    return File(path).existsSync()
        ? Image.file(File(path), fit: BoxFit.cover, cacheWidth: 200)
        : placeholder();
  }
}

String _tasteSummary(Map<String, int> ratings) {
  const labels = {
    'fruity': 'フルーティ',
    'sweetness': '甘み',
    'acidity': '酸味',
    'umami': 'コク',
    'kire': 'キレ',
    'spiciness': '辛さ',
  };
  return ratings.entries
      .where((entry) => labels.containsKey(entry.key))
      .map((entry) => '${labels[entry.key]} ${entry.value}/5')
      .join('  ');
}
