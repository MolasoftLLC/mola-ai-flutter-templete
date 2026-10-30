import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/analytics/app_analytics.dart';
import '../../common/prefecture.dart';
import '../../domain/repository/place_map_repository.dart';
import '../new_home/sake_stamp_book_page.dart';
import '../new_home/widgets/sake_stamp_collection_label.dart';

/// A quiet link to the product's home prefecture, without another stamp grid.
class PrefectureStampLink extends StatefulWidget {
  const PrefectureStampLink({super.key, required this.prefectureCode});
  final int? prefectureCode;

  @override
  State<PrefectureStampLink> createState() => _PrefectureStampLinkState();
}

class _PrefectureStampLinkState extends State<PrefectureStampLink> {
  // Share in-flight requests while browsing products of the same prefecture.
  static final _counts =
      Expando<Map<int, ({DateTime at, Future<int> value})>>();
  Future<int>? _count;
  int? _code;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(covariant PrefectureStampLink oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  void _load() {
    final code = widget.prefectureCode;
    if (code == _code) return;
    _code = code;
    _count = null;
    if (code == null || code < 1 || code > 47) return;
    final repository = context.read<PlaceMapRepository>();
    final cache = _counts[repository] ??= {};
    final cached = cache[code];
    if (cached != null &&
        DateTime.now().difference(cached.at) < const Duration(minutes: 5)) {
      _count = cached.value;
      return;
    }
    final future = _fetchCount(repository, code);
    cache[code] = (at: DateTime.now(), value: future);
    _count = future;
    // Failed requests must not poison the cache for subsequent visits.
    future.then<void>(
      (_) {},
      onError: (Object error, StackTrace stack) {
        if (identical(cache[code]?.value, future)) cache.remove(code);
      },
    );
  }

  Future<int> _fetchCount(PlaceMapRepository repository, int code) async {
    final ids = <int>{};
    int? cursor;
    do {
      final page = await repository.fetchPrefectureBrands(
        code,
        afterId: cursor,
      );
      ids.addAll(page.items.map((brand) => brand.brandId));
      if (page.nextCursor != null &&
          cursor != null &&
          page.nextCursor! <= cursor) {
        throw StateError('Catalog cursor did not advance');
      }
      cursor = page.nextCursor;
    } while (cursor != null);
    return ids.length;
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.prefectureCode;
    if (code == null || code < 1 || code > 47) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Semantics(
        button: true,
        label: '${prefectures[code]}のご酒印帳を開く',
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            AppAnalytics.instance.event('sake_detail', 'sake_stamp_book');
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SakeStampBookPage(initialPrefectureCode: code),
              ),
            );
          },
          child: FutureBuilder<int>(
            future: _count,
            builder: (context, snapshot) => SakeStampCollectionLabel(
              prefecture: prefectures[code],
              count: snapshot.data ?? 0,
              ready: snapshot.hasData,
              catalogLink: true,
            ),
          ),
        ),
      ),
    );
  }
}
