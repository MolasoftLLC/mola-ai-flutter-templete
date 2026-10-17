import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/analytics/app_analytics.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/eintities/sake_label_scan.dart';
import '../../domain/repository/sake_scan_repository.dart';
import '../common/widgets/sake_card_rail.dart';
import 'same_brand_sake_list_page.dart';

class SameBrandSakeSection extends StatefulWidget {
  const SameBrandSakeSection({
    super.key,
    required this.overview,
    required this.onOpen,
  });
  final SakeOverview overview;
  final ValueChanged<Sake> onOpen;
  @override
  State<SameBrandSakeSection> createState() => _SameBrandSakeSectionState();
}

class _SameBrandSakeSectionState extends State<SameBrandSakeSection> {
  late Future<RelatedSakeProductsPage> _future;
  bool _openingList = false;
  final Map<String, Future<Map<int, SakeTasteProfileDetails>>> _profiles = {};

  @override
  void initState() {
    super.initState();
    _future = _loadPage();
  }

  @override
  void didUpdateWidget(covariant SameBrandSakeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.overview.sake.sakeId != widget.overview.sake.sakeId) {
      _profiles.clear();
      _future = _loadPage();
    }
  }

  Future<RelatedSakeProductsPage> _loadPage({int? beforeId}) {
    final repository = context.read<SakeScanRepository>();
    final id = widget.overview.sake.sakeId;
    if (repository is RelatedSakeProductsRepository && id != null) {
      return (repository as RelatedSakeProductsRepository).fetchRelatedProducts(
        id,
        beforeId: beforeId,
      );
    }
    return Future.value(
      RelatedSakeProductsPage(
        sakes: [
          for (final product in widget.overview.relatedProducts)
            if (product.sakeId > 0 && product.sakeId != id)
              Sake(
                sakeId: product.sakeId,
                name: product.name,
                type: product.type,
                brewery: widget.overview.brewery.name,
                primaryImageUrl: product.imageUrl,
              ),
        ],
      ),
    );
  }

  Future<List<Sake>> _loadAllProducts() async {
    // Capture the repository before awaiting so closing the page during loading is safe.
    final repository = context.read<SakeScanRepository>();
    final id = widget.overview.sake.sakeId;
    if (repository is! RelatedSakeProductsRepository || id == null) {
      return (await _loadPage()).sakes;
    }
    final catalog = repository as RelatedSakeProductsRepository;
    var page = await catalog.fetchRelatedProducts(id);
    final sakes = <int, Sake>{};
    while (true) {
      for (final sake in page.sakes) {
        sakes[sake.sakeId!] = sake;
      }
      final cursor = page.nextCursor;
      if (cursor == null) break;
      page = await catalog.fetchRelatedProducts(id, beforeId: cursor);
    }
    return sakes.values.toList(growable: false);
  }

  Future<void> _openList() async {
    if (_openingList) return;
    setState(() => _openingList = true);
    AppAnalytics.instance.event('sake_detail', 'same_brand_more');
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SameBrandSakeListPage(
            brandName: widget.overview.brand.name,
            loadSakes: _loadAllProducts,
            onOpen: widget.onOpen,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingList = false);
    }
  }

  Future<Map<int, SakeTasteProfileDetails>> _profilesFor(List<Sake> sakes) {
    final ids = sakes.map((sake) => sake.sakeId!).toList();
    return _profiles.putIfAbsent(
      ids.join(','),
      () => context.read<SakeScanRepository>().fetchTasteProfiles(ids),
    );
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  '同じ銘柄の商品',
                  style: TextStyle(
                    color: Color(0xFF143861),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: _openingList ? null : _openList,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xFF143861),
                  minimumSize: const Size(60, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'もっと見る',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<RelatedSakeProductsPage>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: TextButton(
                  onPressed: () => setState(() => _future = _loadPage()),
                  child: const Text('商品を取得できませんでした。再試行'),
                ),
              );
            }
            final sakes = (snapshot.data?.sakes ?? const <Sake>[])
                .take(10)
                .toList(growable: false);
            if (sakes.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '同じ銘柄のほかの商品はまだありません',
                  style: TextStyle(color: Color(0xFF647184)),
                ),
              );
            }
            return SakeCardRail(
              compact: true,
              analyticsTarget: 'same_brand_product',
              analyticsScreen: 'sake_detail',
              sakes: sakes,
              profilesFuture: _profilesFor(sakes),
              subtitleBuilder: (sake) => sake.type,
              actionBuilder: (_) => const SizedBox.shrink(),
              onTap: widget.onOpen,
            );
          },
        ),
      ],
    ),
  );
}
