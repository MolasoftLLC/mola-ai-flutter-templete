import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/eintities/sake_catalog_browse.dart';
import '../../../domain/repository/place_map_repository.dart';
import 'japan_sake_map.dart';
import 'sake_stamp_book.dart';

/// Loads only the selected prefecture; further pages are requested by the book.
class PrefectureStampCatalog extends StatefulWidget {
  const PrefectureStampCatalog({
    super.key,
    required this.prefecture,
    required this.recordedBrandIds,
    required this.recordsReady,
    required this.onBrandTap,
    this.preview = false,
    this.pageResetVersion = 0,
    this.onNextSection,
    this.onReturnToCover,
    this.onPreviousSection,
    this.startAtEnd = false,
    this.earnedOnly = false,
  });
  final JapanSakePrefecture prefecture;
  final Set<int> recordedBrandIds;
  final bool recordsReady;
  final ValueChanged<SakeBrandSummary> onBrandTap;
  final bool preview;

  /// Resets the pager while keeping the loaded catalog in memory.
  final int pageResetVersion;
  final VoidCallback? onNextSection;
  final VoidCallback? onReturnToCover;
  final VoidCallback? onPreviousSection;
  final bool startAtEnd;
  final bool earnedOnly;

  @override
  State<PrefectureStampCatalog> createState() => _PrefectureStampCatalogState();
}

class _PrefectureStampCatalogState extends State<PrefectureStampCatalog> {
  final _brands = <int, SakeBrandSummary>{};
  int? _cursor;
  bool _loading = false;
  bool _loaded = false;
  bool _failed = false;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant PrefectureStampCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prefecture.code != widget.prefecture.code) {
      _generation++;
      _brands.clear();
      _loaded = false;
      _cursor = null;
      _loading = false;
      _load();
    } else if (!_failed &&
        ((!_loaded && !widget.earnedOnly) ||
            (widget.earnedOnly &&
                (_needsFilteredPage ||
                    (!_loaded && widget.recordedBrandIds.isNotEmpty))))) {
      _load();
    }
  }

  bool get _needsFilteredPage =>
      _cursor != null &&
      widget.recordsReady &&
      widget.recordedBrandIds.any((id) => !_brands.containsKey(id));

  Future<void> _load() async {
    if (_loading ||
        (widget.earnedOnly &&
            widget.recordsReady &&
            widget.recordedBrandIds.isEmpty)) {
      return;
    }
    final generation = _generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      do {
        final previousCursor = _cursor;
        final page = await context
            .read<PlaceMapRepository>()
            .fetchPrefectureBrands(widget.prefecture.code, afterId: _cursor);
        if (!mounted || generation != _generation) return;
        if (page.nextCursor != null && page.nextCursor == previousCursor) {
          throw StateError('Catalog pagination did not advance');
        }
        setState(() {
          _loaded = true;
          for (final brand in page.items) {
            _brands[brand.brandId] = brand;
          }
          _cursor = page.nextCursor;
        });
      } while ((widget.startAtEnd && _cursor != null) ||
          (widget.earnedOnly && _needsFilteredPage));
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _failed = true);
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final visible = _brands.values
        .where(
          (brand) =>
              !widget.earnedOnly ||
              (widget.recordsReady &&
                  widget.recordedBrandIds.contains(brand.brandId)),
        )
        .toList(growable: false);
    if (visible.isNotEmpty &&
        !(widget.startAtEnd && (_loading || _cursor != null))) {
      return IgnorePointer(
        ignoring: widget.preview,
        child: ExcludeSemantics(
          excluding: widget.preview,
          child: SakeStampBook(
            key: ValueKey(
              'stamp-catalog-${widget.pageResetVersion}-${widget.prefecture.code}-${widget.earnedOnly ? (widget.recordedBrandIds.toList()..sort()).join(',') : 'all'}',
            ),
            prefectureName: widget.prefecture.label(context),
            brands: widget.preview ? visible.take(9).toList() : visible,
            preview: widget.preview,
            recordedBrandIds: widget.recordedBrandIds,
            recordsReady: widget.recordsReady,
            onBrandTap: widget.onBrandTap,
            onNextSection: widget.onNextSection,
            onReturnToCover: widget.onReturnToCover,
            onPreviousSection: widget.onPreviousSection,
            startAtEnd: widget.startAtEnd,
            hasMore:
                !widget.preview &&
                (widget.earnedOnly ? _needsFilteredPage : _cursor != null),
            loading: _loading,
            failed: _failed,
            loadMore: _load,
          ),
        ),
      );
    }
    return SizedBox(
      height: 236,
      child: Center(
        child: _loading
            ? const CircularProgressIndicator(color: japanMapNavy)
            : _failed
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(english ? 'Could not load stamps.' : '酒印帳を読み込めませんでした。'),
                  TextButton(
                    key: const ValueKey('stamp-catalog-retry'),
                    onPressed: _load,
                    child: Text(english ? 'Retry' : '再読み込み'),
                  ),
                ],
              )
            : Text(
                widget.earnedOnly
                    ? (!widget.recordsReady
                          ? (english ? 'Records unconfirmed' : '記録未確認')
                          : (english
                                ? 'No earned stamps in this prefecture yet.'
                                : 'この県には押印済みの酒印がまだありません。'))
                    : (english
                          ? 'No brands found yet.'
                          : 'この県の銘柄はまだ登録されていません。'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: japanMapNavy),
              ),
      ),
    );
  }
}
