import 'dart:io';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../../domain/repository/place_map_repository.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import 'saved_sake_detail_page.dart';
import '../common/widgets/primary_app_bar.dart';

/// 保存した写真または名前から候補を選び、同じ保存記録へ紐付ける。
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
  bool _photoUnavailable = false;

  String? get _photoPath {
    if (_photoUnavailable) return null;
    for (final value in widget.sake.imagePaths ?? const <String>[]) {
      final path = value.trim();
      if (path.isEmpty) continue;
      if (path.startsWith('https://') ||
          path.startsWith('http://') ||
          File(path).existsSync()) {
        return path;
      }
    }
    return null;
  }

  Future<void> _saveSelection(String savedId, Sake target) async {
    final linked = await context.read<SavedSakeNotifier>().reassignSavedSake(
      savedId: savedId,
      target: target,
    );
    if (linked == null || (linked.sakeId ?? 0) <= 0) {
      throw StateError('紐付けに失敗しました');
    }
    if (mounted) setState(() => _linked = linked);
  }

  Future<void> _linkByName(String savedId) async {
    final query = widget.sake.name?.trim() ?? '';
    if (query.isEmpty) throw StateError('お酒の名前がありません');
    final repository = context.read<PlaceMapRepository>();
    var results = await repository.searchSakeMasters(query);
    if (!mounted) return;
    if (results.isEmpty) {
      results = await repository.searchSakeMastersByAi(query);
      if (!mounted) return;
    }
    final candidates = results
        .where(
          (result) =>
              (result.sakeId ?? 0) > 0 ||
              (result.searchToken?.isNotEmpty ?? false),
        )
        .map(
          (result) => SakeScanCandidate(
            sakeId: result.sakeId ?? 0,
            name: result.name,
            type: result.type,
            brewery: result.brewery,
            imageUrl: result.thumbnailImageUrl ?? result.primaryImageUrl,
            candidateKey: result.searchToken,
          ),
        )
        .toList();
    if (candidates.isEmpty) throw StateError('候補がありません');
    final selected = await _selectCandidate(candidates);
    if (!mounted || selected == null) return;
    final overview = selected.sakeId > 0
        ? await context.read<SakeScanRepository>().fetchOverview(
            selected.sakeId,
          )
        : await context
              .read<SakeMenuRecognitionRepository>()
              .resolveSakeCandidateOverview(selected.candidateKey!);
    if (!mounted) return;
    if (overview == null) throw StateError('詳細を取得できません');
    await _saveSelection(savedId, overview.sake);
  }

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
      if (savedId == null || savedId.isEmpty) {
        throw StateError('保存記録がありません');
      }
      final path = _photoPath;
      if (path == null) {
        await _linkByName(savedId);
        return;
      }
      final repository = context.read<SakeScanRepository>();
      final File image;
      try {
        image = await _frontImage(path);
      } catch (_) {
        if (!mounted) return;
        setState(() => _photoUnavailable = true);
        await _linkByName(savedId);
        return;
      }
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
      await _saveSelection(savedId, overview.sake);
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
    final path = _photoPath;
    final useNameSearch = path == null;
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
            Text(
              useNameSearch
                  ? '保存した名前からお酒を探します。候補から同じお酒を選ぶと、詳しい情報や味わいを確認できます。'
                  : '保存した写真からお酒を探します。候補から同じお酒を選ぶと、詳しい情報や味わいを確認できます。',
            ),
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
              label: Text(
                _busy
                    ? (useNameSearch ? '名前からお酒を探しています…' : '写真からお酒を探しています…')
                    : (useNameSearch ? '名前からお酒を探す' : '写真からお酒を探す'),
              ),
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
