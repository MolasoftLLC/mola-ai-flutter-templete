import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/sake_scan_repository.dart';
import 'saved_sake_detail_page.dart';
import '../common/widgets/primary_app_bar.dart';

/// 保存した表ラベルから候補を選び、同じ保存記録へマスターを紐付ける。
class UnlinkedSavedSakePage extends StatefulWidget {
  const UnlinkedSavedSakePage({super.key, required this.sake});
  final Sake sake;

  @override
  State<UnlinkedSavedSakePage> createState() => _UnlinkedSavedSakePageState();
}

class _UnlinkedSavedSakePageState extends State<UnlinkedSavedSakePage> {
  bool _busy = false;
  bool _failed = false;
  Sake? _linked;

  Future<File> _frontImage(String path) async {
    if (!path.startsWith('https://') && !path.startsWith('http://')) {
      final file = File(path);
      if (!await file.exists()) throw StateError('画像がありません');
      return file;
    }
    final client = HttpClient();
    try {
      final response = await (await client.getUrl(Uri.parse(path))).close();
      if (response.statusCode != 200) throw StateError('画像を取得できません');
      final bytes = await response.fold<List<int>>(
        [],
        (data, chunk) => data..addAll(chunk),
      );
      final directory = await getTemporaryDirectory();
      final file = File(
        '${directory.path}/sake-link-${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _link() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    File? downloaded;
    try {
      final savedId = widget.sake.savedId;
      final paths = widget.sake.imagePaths
          ?.where((path) => path.trim().isNotEmpty)
          .toList();
      if (savedId == null ||
          savedId.isEmpty ||
          paths == null ||
          paths.isEmpty) {
        throw StateError('表ラベルの画像がありません');
      }
      final repository = context.read<SakeScanRepository>();
      final notifier = context.read<SavedSakeNotifier>();
      final path = paths.first.trim();
      final image = await _frontImage(path);
      if (path.startsWith('http://') || path.startsWith('https://')) {
        downloaded = image;
      }
      final result = await repository.scanFront(image);
      if (!mounted) return;
      final candidates = result.candidates
          .where(
            (candidate) => candidate.sakeId > 0 || candidate.isLensDiscovery,
          )
          .toList();
      if (candidates.isEmpty || result.scanSessionId.isEmpty) {
        throw StateError('候補がありません');
      }
      final selected = await _selectCandidate(candidates);
      if (!mounted || selected == null) return;
      final SakeScanConfirmation confirmation;
      if (selected.isLensDiscovery) {
        if (repository is! LensDiscoveryRepository) {
          throw StateError('候補を確定できません');
        }
        confirmation = await (repository as LensDiscoveryRepository)
            .confirmDiscovery(result.scanSessionId, selected.candidateKey!);
      } else {
        confirmation = await repository.confirm(
          result.scanSessionId,
          selected.sakeId,
        );
      }
      if (confirmation.sakeId <= 0) throw StateError('マスターがありません');
      final overview = await repository.fetchOverview(confirmation.sakeId);
      if (!mounted) return;
      final linked = await notifier.reassignSavedSake(
        savedId: savedId,
        target: overview.sake,
      );
      if (linked == null || (linked.sakeId ?? 0) <= 0) {
        throw StateError('紐付けに失敗しました');
      }
      if (mounted) setState(() => _linked = linked);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (downloaded != null) {
        try {
          await downloaded.delete();
        } catch (_) {
          /* 一時画像の削除失敗は結果を変えない。 */
        }
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<SakeScanCandidate?> _selectCandidate(
    List<SakeScanCandidate> candidates,
  ) {
    var selectedIndex = 0;
    return showModalBottomSheet<SakeScanCandidate>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'どの日本酒ですか？',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF143861),
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(sheetContext).height * .5,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: candidates.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final candidate = candidates[index];
                      final image = candidate.imageUrl;
                      return ListTile(
                        selected: index == selectedIndex,
                        selectedTileColor: const Color(0xFFFFF8ED),
                        leading: image == null || image.isEmpty
                            ? null
                            : SizedBox(
                                width: 42,
                                height: 54,
                                child: Image.network(
                                  image,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.local_bar_outlined),
                                ),
                              ),
                        title: Text(candidate.displayProductName),
                        subtitle: candidate.brewery == null
                            ? null
                            : Text(candidate.brewery!),
                        trailing: Icon(
                          index == selectedIndex
                              ? Icons.check_circle
                              : Icons.chevron_right,
                          color: const Color(0xFFFF7A1A),
                        ),
                        onTap: () => update(() => selectedIndex = index),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(sheetContext, candidates[selectedIndex]),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F),
                    foregroundColor: const Color(0xFF143861),
                  ),
                  child: const Text('はい、この日本酒です'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    setState(() => _failed = true);
                  },
                  child: const Text('該当する日本酒がありません'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_linked != null) return SavedSakeDetailPage.forSake(_linked!);
    final paths = widget.sake.imagePaths;
    final path = paths == null || paths.isEmpty ? null : paths.first;
    Widget imageError(BuildContext context, Object error, StackTrace? stack) =>
        const Icon(
          Icons.local_bar_outlined,
          size: 72,
          color: Color(0xFF143861),
        );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PrimaryAppBar(title: 'お酒の詳細を確認'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (path != null)
              SizedBox(
                height: 200,
                child: path.startsWith('http://') || path.startsWith('https://')
                    ? Image.network(
                        path,
                        fit: BoxFit.contain,
                        errorBuilder: imageError,
                      )
                    : Image.file(
                        File(path),
                        fit: BoxFit.contain,
                        errorBuilder: imageError,
                      ),
              ),
            const SizedBox(height: 20),
            Text(
              widget.sake.name ?? '名称不明',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF143861),
              ),
            ),
            const SizedBox(height: 12),
            const Text('保存した写真からお酒を探します。候補から同じお酒を選ぶと、詳しい情報や味わいを確認できます。'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _busy ? null : _link,
              icon: _busy
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: Lottie.asset('assets/lottie/ai_loading.json'),
                    )
                  : const Icon(Icons.search),
              label: Text(_busy ? '写真からお酒を探しています…' : '写真からお酒を探す'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF143861),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            if (_failed)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'お酒の詳細を確認できませんでした。時間をおいて、もう一度お試しください。',
                  style: TextStyle(color: Color(0xFF647184)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
