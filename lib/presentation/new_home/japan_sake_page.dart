import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/analytics/app_analytics.dart';
import '../../common/sake/personal_sake_record.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/repository/place_map_repository.dart';
import '../../domain/eintities/sake_catalog_browse.dart';
import 'widgets/japan_catalog_list.dart';
import 'widgets/sake_catalog_thumbnail.dart';
import '../sake_map/sake_master_detail_page.dart';
import '../sake_map/prefecture_stamp_link.dart';
import 'widgets/japan_sake_map.dart';
import 'widgets/sake_journey_progress.dart';
import '../my_page/saved_sake_detail_page.dart';
import '../common/widgets/primary_app_bar.dart';
import 'widgets/japan_sake_feedback_button.dart';
import 'widgets/recorded_sake_seal.dart';
import 'widgets/home_section_title.dart';

bool _english(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

class JapanSakeSection extends StatefulWidget {
  const JapanSakeSection({super.key});
  @override
  State<JapanSakeSection> createState() => _JapanSakeSectionState();
}

class _JapanSakeSectionState extends State<JapanSakeSection> {
  late final _map = JapanSakeMapData.load();
  void _open([JapanSakePrefecture? prefecture]) {
    AppAnalytics.instance.event('home', 'japan_sake_map');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JapanSakePage(initialPrefectureCode: prefecture?.code),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SakeJourneyProgressBuilder(
    builder: (context, progress, legend, ready) => Padding(
      key: const ValueKey('home-japan-sake-section'),
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionTitle(
            title: _english(context) ? 'A journey through sake' : '日本酒を旅する',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  _english(context)
                      ? 'Discover sake from 47 prefectures.'
                      : '47の産地から、気になる一本に出会う。',
                  style: const TextStyle(
                    color: Color(0xFF687880),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 18),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 300,
                          child: FutureBuilder<List<JapanSakePrefecture>>(
                            future: _map,
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                  child: Icon(
                                    Icons.map_outlined,
                                    size: 60,
                                    color: japanMapNavy,
                                  ),
                                );
                              }
                              return JapanSakeMap(
                                prefectures: snapshot.data!,
                                productCounts: progress.counts,
                                onSelected: _open,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        legend,
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _open,
                            style: FilledButton.styleFrom(
                              backgroundColor: japanMapNavy,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: const Icon(Icons.explore_outlined),
                            label: Text(
                              _english(context)
                                  ? 'Explore the sake map'
                                  : '地図からお酒を探す',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class JapanSakePage extends StatefulWidget {
  const JapanSakePage({super.key, this.initialPrefectureCode});
  final int? initialPrefectureCode;
  @override
  State<JapanSakePage> createState() => _JapanSakePageState();
}

class _JapanSakePageState extends State<JapanSakePage> {
  late final _map = JapanSakeMapData.load();
  List<JapanSakePrefecture> _prefectures = const [];
  JapanSakePrefecture? _selected;
  Future<SakeCatalogPage<SakeBrandSummary>>? _results;
  final _cache = <int, Future<SakeCatalogPage<SakeBrandSummary>>>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _map;
    if (!mounted) return;
    setState(() => _prefectures = data);
    final code = widget.initialPrefectureCode;
    if (code != null) {
      _select(data.firstWhere((p) => p.code == code, orElse: () => data.first));
    }
  }

  void _select(JapanSakePrefecture prefecture) {
    setState(() {
      _selected = prefecture;
      _results = _cache.putIfAbsent(
        prefecture.code,
        () => context.read<PlaceMapRepository>().fetchPrefectureBrands(
          prefecture.code,
        ),
      );
      // Observe errors immediately, before the next frame mounts the list.
      // Keep the original future so the list can still display its error state.
      _results!.then<void>(
        (_) {},
        onError: (Object _, StackTrace __) {
          _cache.remove(prefecture.code);
        },
      );
    });
    AppAnalytics.instance.event(
      'search',
      'prefecture',
      source: 'japan_sake_map',
    );
  }

  void _openBrand(SakeBrandSummary brand) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => JapanSakeBrandProductsPage(brand: brand),
    ),
  );

  Future<void> _choosePrefecture() async {
    final selected = await showModalBottomSheet<JapanSakePrefecture>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: ListView(
            children: [
              for (final prefecture in _prefectures)
                ListTile(
                  key: ValueKey('prefecture-${prefecture.code}'),
                  title: Text(prefecture.label(context)),
                  trailing: _selected?.code == prefecture.code
                      ? const Icon(Icons.check, color: japanMapNavy)
                      : null,
                  onTap: () => Navigator.pop(context, prefecture),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && mounted) _select(selected);
  }

  @override
  Widget build(BuildContext context) => SakeJourneyProgressBuilder(
    showLegendDetails: false,
    builder: (context, progress, legend, ready) => Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: PrimaryAppBar(
        title: _english(context) ? 'Sake map of Japan' : '日本酒を旅する',
        actions: const [JapanSakeFeedbackButton()],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Text(
            _english(context)
                ? 'Zoom in and tap a prefecture to explore its brands.'
                : '地図を拡大して、気になる県の銘柄を探そう。',
            style: const TextStyle(color: Color(0xFF687880), height: 1.6),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: ((MediaQuery.sizeOf(context).width - 48) * 1.12).clamp(
              340.0,
              480.0,
            ),
            child: _prefectures.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ZoomableJapanSakeMap(
                    showControls: false,
                    productCounts: progress.counts,
                    prefectures: _prefectures,
                    selectedCode: _selected?.code,
                    onSelected: _select,
                  ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Natural Earth',
              style: TextStyle(
                fontSize: 10,
                color: japanMapNavy.withValues(alpha: .45),
              ),
            ),
          ),
          const SizedBox(height: 12),
          legend,
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey('choose-japan-prefecture'),
            onPressed: _prefectures.isEmpty ? null : _choosePrefecture,
            style: OutlinedButton.styleFrom(
              foregroundColor: japanMapNavy,
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFD3DDDF)),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.location_on_outlined),
            label: Text(
              _selected?.label(context) ??
                  (_english(context) ? 'Choose a prefecture' : '都道府県から選ぶ'),
            ),
          ),
          const SizedBox(height: 12),
          if (_selected != null && ready)
            OutlinedButton(
              key: const ValueKey('open-prefecture-records'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => JapanSakeRecordsPage(prefecture: _selected!),
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: japanMapNavy,
                backgroundColor: const Color(0xFFFFF4D0),
                side: const BorderSide(color: Color(0xFFF2D47E)),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _english(context)
                          ? '${_selected!.label(context)}: ${progress.counts[_selected!.code] ?? 0} products in your records'
                          : '${_selected!.name}：記録したお酒 ${progress.counts[_selected!.code] ?? 0}商品',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_selected == null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _english(context)
                    ? 'You can also choose from the prefecture list.'
                    : '小さな県は、一覧からも選べます。',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF687880)),
              ),
            )
          else ...[
            Text(
              _english(context)
                  ? 'Sake brands from ${_selected!.label(context)}'
                  : '${_selected!.name}の銘柄',
              style: const TextStyle(
                color: japanMapNavy,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            JapanCatalogList<SakeBrandSummary>(
              key: ValueKey('prefecture-brands-${_selected!.code}'),
              firstPage: _results,
              loadPage: (cursor) => context
                  .read<PlaceMapRepository>()
                  .fetchPrefectureBrands(_selected!.code, afterId: cursor),
              itemId: (brand) => brand.brandId,
              headerBuilder: (brands, hasMore, loading, failed, loadMore) =>
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        _english(context)
                            ? 'Choose a brand to see its sake.'
                            : '銘柄を選ぶと、登録されている商品を見られます。',
                        style: const TextStyle(
                          color: Color(0xFF687880),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
              emptyText: _english(context)
                  ? 'No catalog brands found for this prefecture yet.'
                  : 'この県の銘柄は、まだカタログに見つかりませんでした。',
              itemBuilder: (brand) => _CatalogCard(
                rowKey: ValueKey('japan-brand-${brand.brandId}'),
                title: brand.name,
                subtitle:
                    '${brand.brewery} · ${brand.productCount}${_english(context) ? ' products' : '商品'}',
                thumbnail: SakeCatalogThumbnail(
                  thumbnailImageUrl: brand.thumbnailImageUrl,
                  primaryImageUrl: brand.primaryImageUrl,
                ),
                onTap: () => _openBrand(brand),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class JapanSakeRecordsPage extends StatelessWidget {
  const JapanSakeRecordsPage({super.key, required this.prefecture});
  final JapanSakePrefecture prefecture;

  @override
  Widget build(BuildContext context) => SakeJourneyProgressBuilder(
    builder: (context, progress, legend, ready) {
      final records =
          progress.productsByPrefecture[prefecture.code] ?? const [];
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9F8),
        appBar: PrimaryAppBar(
          title: _english(context)
              ? 'Your sake from ${prefecture.label(context)}'
              : '${prefecture.name}のお酒の記録',
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            if (!ready)
              legend
            else ...[
              PrefectureStampLink(prefectureCode: prefecture.code),
              if (records.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(
                    _english(context)
                        ? 'No sake recorded from this prefecture yet.'
                        : 'この県のお酒の記録はまだありません。',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: japanMapNavy),
                  ),
                ),
              for (final sake in records)
                _CatalogCard(
                  rowKey: ValueKey('japan-record-${sake.sakeId}'),
                  title: sake.name ?? (_english(context) ? 'Sake' : '名称不明の日本酒'),
                  subtitle: [
                    sake.brewery,
                    sake.type,
                  ].whereType<String>().join(' ・ '),
                  thumbnail: SakeCatalogThumbnail(
                    thumbnailImageUrl: sake.thumbnailImageUrl,
                    primaryImageUrl: sake.primaryImageUrl,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SavedSakeDetailPage.forSake(
                        sake,
                        recordRecentView: true,
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      );
    },
  );
}

class JapanSakeBrandProductsPage extends StatelessWidget {
  const JapanSakeBrandProductsPage({super.key, required this.brand});
  final SakeBrandSummary brand;
  @override
  Widget build(BuildContext context) => SakeJourneyProgressBuilder(
    builder: (context, progress, legend, ready) {
      // Exact product IDs work even when origin lookup is unavailable. Only use
      // verified canonical IDs after the current account's lookup completes.
      final recordedIds = <int>{
        for (final record
            in Provider.of<SavedSakeState?>(context)?.savedSakeList ?? const [])
          if (hasPersonalSakeRecord(record) && (record.sakeId ?? 0) > 0)
            record.sakeId!,
        if (ready)
          for (final records in progress.productsByPrefecture.values)
            for (final record in records) record.sakeId!,
      };
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9F8),
        appBar: PrimaryAppBar(title: brand.name),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            Text(
              brand.brewery,
              style: const TextStyle(color: Color(0xFF687880)),
            ),
            const SizedBox(height: 16),
            JapanCatalogList<SakeMapSearchResult>(
              leadingItems: [
                if (ready)
                  for (final record
                      in progress.productsByBrand[brand.brandId] ??
                          const <Sake>[])
                    SakeMapSearchResult(
                      sakeId: record.sakeId,
                      name: record.name?.trim().isNotEmpty == true
                          ? record.name!
                          : (_english(context)
                                ? '${brand.name} (recorded sake)'
                                : '${brand.name}（記録したお酒）'),
                      brewery: record.brewery,
                      type: record.type,
                      primaryImageUrl: record.primaryImageUrl,
                      thumbnailImageUrl: record.thumbnailImageUrl,
                      isMaster: true,
                    ),
              ],
              isPreferred: (sake) => recordedIds.contains(sake.sakeId),
              loadPage: (cursor) => context
                  .read<PlaceMapRepository>()
                  .fetchBrandProducts(brand.brandId, beforeId: cursor),
              itemId: (sake) => sake.sakeId ?? sake.searchToken ?? sake.name,
              emptyText: _english(context)
                  ? 'No catalog products found yet.'
                  : '登録された商品はまだありません。',
              itemBuilder: (sake) => _CatalogCard(
                rowKey: ValueKey('japan-product-${sake.sakeId}'),
                recorded: recordedIds.contains(sake.sakeId),
                title: sake.name,
                subtitle: [
                  sake.brewery,
                  sake.type,
                ].whereType<String>().join(' ・ '),
                thumbnail: SakeCatalogThumbnail(
                  thumbnailImageUrl: sake.thumbnailImageUrl,
                  primaryImageUrl: sake.primaryImageUrl,
                ),
                onTap: (sake.sakeId ?? 0) > 0
                    ? () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => SakeMasterDetailPage(
                            recordRecentView: true,
                            venueSake: VenueSake(
                              sakeId: sake.sakeId,
                              searchToken: sake.searchToken,
                              name: sake.name,
                              brewery: sake.brewery,
                              type: sake.type,
                              recordCount: 0,
                              thumbnailImageUrl: sake.thumbnailImageUrl,
                              primaryImageUrl: sake.primaryImageUrl,
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _CatalogCard extends StatelessWidget {
  const _CatalogCard({
    required this.rowKey,
    required this.title,
    required this.subtitle,
    required this.thumbnail,
    required this.onTap,
    this.recorded = false,
  });
  final bool recorded;
  final Key rowKey;
  final String title;
  final String subtitle;
  final Widget thumbnail;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    key: rowKey,
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: recorded
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            thumbnail,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: japanMapNavy,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF687880),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            if (recorded)
              const SizedBox(
                width: 42,
                height: 76,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RecordedSakeSeal(),
                    Icon(Icons.chevron_right, color: japanMapNavy),
                  ],
                ),
              )
            else
              const Icon(Icons.chevron_right, color: japanMapNavy),
          ],
        ),
      ),
    ),
  );
}
