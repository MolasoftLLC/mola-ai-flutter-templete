import 'package:flutter/material.dart';
import '../../../common/localization/localization_extensions.dart';
import '../../../domain/eintities/menu_analysis_history.dart';
import 'menu_history_tile.dart';
import 'menu_photo_style.dart';

/// The rows are built lazily, with older cloud payloads requested near the end.
/// A failed page keeps existing rows and retries the same cursor explicitly.
class MenuHistoryList extends StatefulWidget {
  const MenuHistoryList({
    super.key,
    required this.history,
    required this.onOpen,
    required this.loadMore,
  });
  final List<MenuAnalysisHistoryItem> history;
  final ValueChanged<String> onOpen;
  final Future<bool> Function() loadMore;
  @override
  State<MenuHistoryList> createState() => _MenuHistoryListState();
}

class _MenuHistoryListState extends State<MenuHistoryList> {
  final _scroll = ScrollController();
  bool _loading = false;
  bool _hasMore = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoad);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNext());
  }

  void _maybeLoad() {
    if (mounted &&
        _scroll.hasClients &&
        _scroll.position.extentAfter < 240 &&
        !_failed) {
      _loadNext();
    }
  }

  Future<void> _loadNext() async {
    if (!mounted || _loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final more = await widget.loadMore();
      if (mounted) setState(() => _hasMore = more);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoad());
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListView.builder(
    key: const PageStorageKey('all-menu-history'),
    controller: _scroll,
    padding: const EdgeInsets.all(24),
    itemCount: widget.history.length + 1,
    itemBuilder: (context, index) {
      if (index < widget.history.length) {
        final item = widget.history[index];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 14),
          child: MenuHistoryTile(
            item: item,
            onTap: () => widget.onOpen(item.id),
          ),
        );
      }
      if (_failed) {
        return Column(
          children: [
            Text(
              context.l10n.menuHistoryLoadFailed,
              style: MenuPhotoStyle.text(13),
            ),
            TextButton(
              onPressed: _loadNext,
              child: Text(
                context.l10n.retryLoad,
                style: MenuPhotoStyle.text(14, bold: true),
              ),
            ),
          ],
        );
      }
      if (_loading || _hasMore) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(color: Colors.white70),
          ),
        );
      }
      if (widget.history.isEmpty) {
        return Text(context.l10n.noMenuHistory, style: MenuPhotoStyle.text(13));
      }
      return const SizedBox(height: 16);
    },
  );
}
