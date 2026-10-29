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
  });
  final JapanSakePrefecture prefecture;
  final Set<int> recordedBrandIds;
  final bool recordsReady;
  final ValueChanged<SakeBrandSummary> onBrandTap;
  final bool preview;

  @override
  State<PrefectureStampCatalog> createState() => _PrefectureStampCatalogState();
}

class _PrefectureStampCatalogState extends State<PrefectureStampCatalog> {
  final _brands = <int, SakeBrandSummary>{};
  int? _cursor;
  bool _loading = false;
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
      _cursor = null;
      _loading = false;
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    final generation = _generation;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await context
          .read<PlaceMapRepository>()
          .fetchPrefectureBrands(widget.prefecture.code, afterId: _cursor);
      if (!mounted || generation != _generation) return;
      setState(() {
        for (final brand in page.items) {
          _brands[brand.brandId] = brand;
        }
        _cursor = page.nextCursor;
      });
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
    if (_brands.isNotEmpty) {
      return IgnorePointer(
        ignoring: widget.preview,
        child: ExcludeSemantics(
          excluding: widget.preview,
          child: SakeStampBook(
            key: ValueKey('stamp-catalog-${widget.prefecture.code}'),
            prefectureName: widget.prefecture.label(context),
            brands: _brands.values.toList(growable: false),
            recordedBrandIds: widget.recordedBrandIds,
            recordsReady: widget.recordsReady,
            onBrandTap: widget.onBrandTap,
            hasMore: _cursor != null,
            loading: _loading,
            failed: _failed,
            loadMore: _load,
            height: widget.preview
                ? 212
                : (MediaQuery.sizeOf(context).width - 48).clamp(260, 400),
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
                english ? 'No brands found yet.' : 'この県の銘柄はまだ登録されていません。',
                textAlign: TextAlign.center,
                style: const TextStyle(color: japanMapNavy),
              ),
      ),
    );
  }
}
