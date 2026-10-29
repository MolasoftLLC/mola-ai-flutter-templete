import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../common/analytics/app_analytics.dart';
import '../../domain/repository/place_map_repository.dart';
import '../sake_map/sake_master_detail_page.dart';
import 'widgets/japan_sake_map.dart';

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
  Widget build(BuildContext context) => Padding(
    key: const ValueKey('home-japan-sake-section'),
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _english(context) ? 'A journey through sake' : '日本酒を旅する',
          style: const TextStyle(
            color: japanMapNavy,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _english(context)
              ? 'Discover sake from 47 prefectures.'
              : '47の産地から、気になる一本に出会う。',
          style: const TextStyle(color: Color(0xFF687880), fontSize: 13),
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
                        onSelected: _open,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
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
                      _english(context) ? 'Explore the sake map' : '地図からお酒を探す',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
  Future<List<SakeMapSearchResult>>? _results;
  final _cache = <int, Future<List<SakeMapSearchResult>>>{};

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

  void _select(JapanSakePrefecture prefecture, {bool retry = false}) {
    if (retry) _cache.remove(prefecture.code);
    setState(() {
      _selected = prefecture;
      _results = _cache.putIfAbsent(
        prefecture.code,
        () => context.read<PlaceMapRepository>().discoverSakeMasters(
          prefecture: prefecture.name,
        ),
      );
    });
    AppAnalytics.instance.event(
      'search',
      'prefecture',
      source: 'japan_sake_map',
    );
  }

  void _openSake(SakeMapSearchResult sake) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SakeMasterDetailPage(
        venueSake: VenueSake(
          sakeId: sake.sakeId,
          searchToken: sake.searchToken,
          name: sake.name,
          brewery: sake.brewery,
          type: sake.type,
          recordCount: 0,
          primaryImageUrl: sake.primaryImageUrl,
          thumbnailImageUrl: sake.thumbnailImageUrl,
        ),
      ),
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F9F8),
    appBar: AppBar(
      title: Text(_english(context) ? 'Sake map of Japan' : '日本酒を旅する'),
      backgroundColor: Colors.white,
      foregroundColor: japanMapNavy,
      surfaceTintColor: Colors.transparent,
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
              ? 'Tap a prefecture to explore its sake.'
              : '気になる県をタップして、お酒を探そう。',
          style: const TextStyle(color: Color(0xFF687880), height: 1.6),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 330,
          child: _prefectures.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : JapanSakeMap(
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
        const SizedBox(height: 24),
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
                ? 'Sake from ${_selected!.label(context)}'
                : '${_selected!.name}のお酒',
            style: const TextStyle(
              color: japanMapNavy,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _english(context)
                ? 'From the SAKEPEDIA catalog · up to 50 products'
                : 'SAKEPEDIAに登録された商品から表示・最大50件',
            style: const TextStyle(color: Color(0xFF687880), fontSize: 12),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<SakeMapSearchResult>>(
            future: _results,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  children: [
                    Text(
                      _english(context)
                          ? 'Could not load sake. Please try again.'
                          : 'お酒を取得できませんでした。もう一度お試しください。',
                    ),
                    TextButton(
                      onPressed: () => _select(_selected!, retry: true),
                      child: Text(_english(context) ? 'Retry' : '再読み込み'),
                    ),
                  ],
                );
              }
              final results = snapshot.data ?? const [];
              if (results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    _english(context)
                        ? 'No catalog products found for this prefecture yet.'
                        : 'この県のお酒は、まだカタログに見つかりませんでした。',
                    style: const TextStyle(color: Color(0xFF687880)),
                  ),
                );
              }
              return Column(
                children: [
                  for (final sake in results)
                    Card(
                      elevation: 0,
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        title: Text(
                          sake.name,
                          style: const TextStyle(
                            color: japanMapNavy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          [sake.brewery, sake.type]
                              .whereType<String>()
                              .where((s) => s.isNotEmpty)
                              .join(' ・ '),
                          style: const TextStyle(color: Color(0xFF687880)),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: japanMapNavy,
                        ),
                        onTap:
                            ((sake.sakeId ?? 0) > 0 ||
                                sake.searchToken?.isNotEmpty == true)
                            ? () => _openSake(sake)
                            : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    ),
  );
}
