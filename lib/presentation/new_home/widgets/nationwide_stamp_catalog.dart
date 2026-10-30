import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/eintities/sake_catalog_browse.dart';
import '../../../domain/repository/place_map_repository.dart';
import 'japan_sake_map.dart';
import 'sake_stamp_book.dart';

/// Collects earned brands only, querying prefectures with confirmed records.
class NationwideStampCatalog extends StatefulWidget {
  const NationwideStampCatalog({
    super.key,
    required this.recordedBrands,
    required this.recordsReady,
    required this.onBrandTap,
    this.preview = false,
  });
  final Map<int, Set<int>> recordedBrands;
  final bool recordsReady;
  final ValueChanged<SakeBrandSummary> onBrandTap;
  final bool preview;

  @override
  State<NationwideStampCatalog> createState() => _NationwideStampCatalogState();
}

class _NationwideStampCatalogState extends State<NationwideStampCatalog> {
  final _brands = <int, SakeBrandSummary>{};
  final _cursors = <int, int?>{};
  final _complete = <int>{};
  final _seenCursors = <int, Set<int?>>{};
  String _signature = '';
  int _generation = 0;
  bool _loading = false;
  bool _failed = false;

  Map<int, Set<int>> get _targets => {
    for (final entry in widget.recordedBrands.entries)
      if (entry.value.isNotEmpty) entry.key: {...entry.value},
  };

  @override
  void initState() {
    super.initState();
    _resetIfChanged();
  }

  @override
  void didUpdateWidget(covariant NationwideStampCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resetIfChanged();
  }

  void _resetIfChanged() {
    final targets = _targets;
    final codes = targets.keys.toList()..sort();
    final signature =
        '${widget.recordsReady}:${codes.map((code) => '$code:${(targets[code]!.toList()..sort()).join(',')}').join(';')}';
    if (_signature == signature) return;
    _signature = signature;
    _generation++;
    _brands.clear();
    _cursors.clear();
    _complete.clear();
    _seenCursors.clear();
    _loading = false;
    _failed = false;
    _load();
  }

  Future<void> _load() async {
    if (_loading || !widget.recordsReady) return;
    final targets = _targets;
    if (targets.isEmpty) return;
    final generation = _generation;
    final repo = context.read<PlaceMapRepository>();
    final codes = targets.keys.toList()..sort();
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      for (final code in codes) {
        while (!_complete.contains(code) &&
            targets[code]!.any((id) => !_brands.containsKey(id))) {
          final cursor = _cursors[code];
          final page = await repo.fetchPrefectureBrands(code, afterId: cursor);
          if (!mounted || generation != _generation) return;
          final seen = _seenCursors.putIfAbsent(code, () => {});
          if (page.nextCursor != null &&
              (page.nextCursor == cursor || seen.contains(page.nextCursor))) {
            throw StateError('Catalog pagination did not advance');
          }
          setState(() {
            seen.add(cursor);
            for (final brand in page.items) {
              if (targets[code]!.contains(brand.brandId)) {
                _brands[brand.brandId] = brand;
              }
            }
            _cursors[code] = page.nextCursor;
            if (page.nextCursor == null) _complete.add(code);
          });
        }
      }
    } catch (_) {
      if (mounted && generation == _generation) setState(() => _failed = true);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final earned = _targets.values.expand((ids) => ids).toSet();
    final missing = earned.length - _brands.length;
    return Column(
      children: [
        if (_brands.isNotEmpty)
          IgnorePointer(
            ignoring: widget.preview,
            child: ExcludeSemantics(
              excluding: widget.preview,
              child: SakeStampBook(
                key: ValueKey('national-stamp-book-$_signature'),
                prefectureName: english ? 'Nationwide' : '全国',
                brands: _brands.values.toList(),
                recordedBrandIds: earned,
                recordsReady: widget.recordsReady,
                onBrandTap: widget.onBrandTap,
                hasMore: false,
                loading: _loading,
                failed: _failed,
                loadMore: _load,
              ),
            ),
          )
        else
          SizedBox(
            height: 236,
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator(color: japanMapNavy)
                  : Text(
                      !widget.recordsReady
                          ? (english ? 'Records unconfirmed' : '記録未確認')
                          : _failed
                          ? (english
                                ? 'Could not load stamps.'
                                : '酒印帳を読み込めませんでした。')
                          : earned.isEmpty
                          ? (english
                                ? 'No earned stamps yet.'
                                : '押印済みの酒印がまだありません。')
                          : (english
                                ? 'Could not find these brands.'
                                : '記録した銘柄の情報が見つかりませんでした。'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: japanMapNavy),
                    ),
            ),
          ),
        if (_loading && _brands.isNotEmpty)
          const LinearProgressIndicator(color: japanMapNavy),
        if (_failed)
          TextButton(
            key: const ValueKey('national-stamp-retry'),
            onPressed: _load,
            child: Text(english ? 'Retry loading stamps' : '酒印を再読み込み'),
          )
        else if (!_loading &&
            widget.recordsReady &&
            missing > 0 &&
            _brands.isNotEmpty)
          Text(
            english
                ? '$missing brands could not be found.'
                : '$missing銘柄の情報を取得できませんでした。',
            style: const TextStyle(color: Color(0xFF687880), fontSize: 12),
          ),
      ],
    );
  }
}
