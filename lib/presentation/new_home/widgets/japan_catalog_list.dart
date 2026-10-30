import 'package:flutter/material.dart';
import '../../../domain/eintities/sake_catalog_browse.dart';
import 'japan_sake_map.dart';

/// Both catalog levels load bounded pages and retain loaded rows on a retry.
class JapanCatalogList<T> extends StatefulWidget {
  const JapanCatalogList({
    super.key,
    required this.loadPage,
    required this.itemId,
    required this.itemBuilder,
    required this.emptyText,
    this.firstPage,
    this.headerBuilder,
    this.leadingItems = const [],
    this.isPreferred,
  });
  final Future<SakeCatalogPage<T>> Function(int? cursor) loadPage;
  final Future<SakeCatalogPage<T>>? firstPage;
  final Object Function(T item) itemId;
  final Widget Function(T item) itemBuilder;
  final String emptyText;

  /// Known items shown before pagination reaches them; fetched data wins by ID.
  final List<T> leadingItems;
  final bool Function(T item)? isPreferred;
  final Widget Function(
    List<T> items,
    bool hasMore,
    bool loading,
    bool failed,
    VoidCallback loadMore,
  )?
  headerBuilder;
  @override
  State<JapanCatalogList<T>> createState() => _JapanCatalogListState<T>();
}

class _JapanCatalogListState<T> extends State<JapanCatalogList<T>> {
  final _items = <Object, T>{};
  int? _next;
  bool _loading = true;
  bool _failed = false;
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    _load(widget.firstPage);
  }

  Future<void> _load([Future<SakeCatalogPage<T>>? first]) async {
    if (_loading && first == null && _loaded) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await (first ?? widget.loadPage(_loaded ? _next : null));
      if (!mounted) return;
      setState(() {
        for (final item in page.items) {
          _items[widget.itemId(item)] = item;
        }
        _next = page.nextCursor;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    final merged = <Object, T>{
      for (final item in widget.leadingItems) widget.itemId(item): item,
      ..._items,
    }.values.toList(growable: false);
    final preferred = widget.isPreferred;
    final visible = preferred == null
        ? merged
        : [
            ...merged.where(preferred),
            ...merged.where((item) => !preferred(item)),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.headerBuilder != null)
          widget.headerBuilder!(
            _items.values.toList(growable: false),
            _next != null,
            _loading,
            _failed,
            () => _load(),
          ),
        for (final item in visible) widget.itemBuilder(item),
        if (_loading)
          const Padding(
            padding: EdgeInsets.all(28),
            child: Center(
              child: CircularProgressIndicator(color: japanMapNavy),
            ),
          )
        else if (_failed)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  english ? 'Could not load the catalog.' : '一覧を取得できませんでした。',
                ),
                TextButton(
                  onPressed: _load,
                  child: Text(english ? 'Retry' : '再読み込み'),
                ),
              ],
            ),
          )
        else if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.emptyText,
              style: const TextStyle(color: Color(0xFF687880)),
            ),
          )
        else if (_next != null)
          OutlinedButton(
            onPressed: _load,
            style: OutlinedButton.styleFrom(foregroundColor: japanMapNavy),
            child: Text(english ? 'Load more' : 'もっと見る'),
          ),
      ],
    );
  }
}
