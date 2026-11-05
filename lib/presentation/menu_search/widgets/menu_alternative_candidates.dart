import 'menu_action_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/eintities/menu_sake_resolution.dart';
import '../../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../../domain/eintities/sake_label_scan.dart';
import '../../../domain/repository/sake_scan_repository.dart';
import '../../common/widgets/sake_card_rail.dart';

/// Collapsed by default; browsing alternatives never changes the selected product.
class MenuAlternativeCandidates extends StatefulWidget {
  const MenuAlternativeCandidates({
    super.key,
    required this.sakeId,
    required this.onSelected,
    this.dark = false,
    this.loadPage,
  });
  final int sakeId;
  final ValueChanged<MenuSakeCandidate> onSelected;
  final bool dark;
  final Future<RelatedSakeProductsPage> Function(int? cursor)? loadPage;
  @override
  State<MenuAlternativeCandidates> createState() =>
      _MenuAlternativeCandidatesState();
}

class _MenuAlternativeCandidatesState extends State<MenuAlternativeCandidates> {
  bool _open = false, _loading = false, _loaded = false, _failed = false;
  int? _cursor;
  final _sakes = <int, Sake>{};
  final _profiles = <int, SakeTasteProfileDetails>{};

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final repository = widget.loadPage == null
          ? context.read<SakeScanRepository>()
          : null;
      final page = widget.loadPage != null
          ? await widget.loadPage!(_cursor)
          : await (repository as RelatedSakeProductsRepository)
                .fetchRelatedProducts(widget.sakeId, beforeId: _cursor);
      if (!mounted) return;
      // Profiles are optional; the catalog remains selectable if they fail.
      Map<int, SakeTasteProfileDetails> profiles = {};
      if (repository != null) {
        try {
          profiles = await repository.fetchTasteProfiles(
            page.sakes.map((s) => s.sakeId).whereType<int>().toList(),
          );
        } catch (_) {
          /* Preserve the candidates. */
        }
      }
      if (!mounted) return;
      setState(() {
        for (final sake in page.sakes) {
          if ((sake.sakeId ?? 0) > 0 && sake.sakeId != widget.sakeId) {
            _sakes[sake.sakeId!] = sake;
          }
        }
        _profiles.addAll(profiles);
        _cursor = page.nextCursor;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      MenuActionButton(
        dark: widget.dark,
        label: 'この銘柄の他の候補',
        icon: Icons.grid_view_rounded,
        trailing: _open ? Icons.expand_less : Icons.expand_more,
        onPressed: () {
          setState(() => _open = !_open);
          if (_open && !_loaded) _load();
        },
      ),
      if (_open)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (_sakes.isNotEmpty)
                SakeCardRail(
                  compact: true,
                  nameMaxLines: 3,
                  sakes: _sakes.values.toList(),
                  profilesFuture: Future.value(_profiles),
                  subtitleBuilder: (s) => s.type,
                  actionBuilder: (_) => const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF143861),
                  ),
                  analyticsTarget: 'menu_alternative',
                  analyticsScreen: 'menu',
                  onTap: (s) => widget.onSelected(
                    MenuSakeCandidate(
                      sake: s,
                      tasteProfile: _profiles[s.sakeId],
                    ),
                  ),
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: LinearProgressIndicator(),
                ),
              if (_failed)
                TextButton(
                  onPressed: _load,
                  child: const Text('取得できませんでした。再試行'),
                ),
              if (_loaded && _sakes.isEmpty && !_loading && !_failed)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    '同じ銘柄の他の商品はまだありません',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
              if (_cursor != null && !_loading && !_failed)
                TextButton(onPressed: _load, child: const Text('もっと見る')),
            ],
          ),
        ),
    ],
  );
}
