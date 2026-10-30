import 'package:flutter/material.dart';
import '../../common/analytics/app_analytics.dart';
import '../../domain/eintities/sake_catalog_browse.dart';
import '../common/widgets/primary_app_bar.dart';
import 'japan_sake_page.dart';
import 'widgets/japan_sake_map.dart';
import 'widgets/prefecture_stamp_catalog.dart';
import 'widgets/sake_journey_progress.dart';
import 'widgets/sake_stamp_acquisition_demo.dart';
import 'widgets/sake_stamp_preferences.dart';

bool _english(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

JapanSakePrefecture _previewPrefecture(
  List<JapanSakePrefecture> prefectures,
  Map<int, Set<int>> recordedBrands,
) {
  var selected = prefectures.first;
  for (final prefecture in prefectures) {
    if ((recordedBrands[prefecture.code]?.length ?? 0) >
        (recordedBrands[selected.code]?.length ?? 0)) {
      selected = prefecture;
    }
  }
  return selected;
}

void _openBrand(BuildContext context, SakeBrandSummary brand) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JapanSakeBrandProductsPage(brand: brand),
      ),
    );

class SakeStampBookSection extends StatefulWidget {
  const SakeStampBookSection({super.key});

  @override
  State<SakeStampBookSection> createState() => _SakeStampBookSectionState();
}

class _SakeStampBookSectionState extends State<SakeStampBookSection> {
  int? _rememberedCode;
  late final _map = _loadMap();

  Future<List<JapanSakePrefecture>> _loadMap() async {
    _rememberedCode = await SakeStampPreferences.lastPrefecture();
    return JapanSakeMapData.load();
  }

  Future<void> _open(JapanSakePrefecture prefecture) async {
    AppAnalytics.instance.event('home', 'sake_stamp_book');
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            SakeStampBookPage(initialPrefectureCode: prefecture.code),
      ),
    );
    final code = await SakeStampPreferences.lastPrefecture();
    if (mounted) setState(() => _rememberedCode = code);
  }

  @override
  Widget build(BuildContext context) => SakeJourneyProgressBuilder(
    builder: (context, progress, legend, ready) => FutureBuilder(
      future: _map,
      builder: (context, snapshot) {
        final prefectures = snapshot.data;
        if (prefectures == null) return const SizedBox.shrink();
        final prefecture = prefectures.firstWhere(
          (p) => p.code == _rememberedCode,
          orElse: () =>
              _previewPrefecture(prefectures, progress.brandIdsByPrefecture),
        );
        return Padding(
          key: const ValueKey('home-sake-stamp-section'),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _english(context) ? 'My sake stamp book' : '日本酒ご酒印帳',
                      style: const TextStyle(
                        color: japanMapNavy,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SakeStampDemoButton(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _english(context)
                    ? 'Collect a stamp for each brand you record.'
                    : '飲んだお酒の記録を、銘柄の酒印に。',
                style: const TextStyle(color: Color(0xFF687880), fontSize: 13),
              ),
              const SizedBox(height: 8),
              _NationwideStampCount(
                progress.brandIdsByPrefecture,
                ready: ready,
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  key: const ValueKey('open-sake-stamp-book'),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _open(prefecture),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PrefectureStampCatalog(
                        prefecture: prefecture,
                        recordedBrandIds:
                            progress.brandIdsByPrefecture[prefecture.code] ??
                            const {},
                        recordsReady: ready,
                        preview: true,
                        onBrandTap: (_) => _open(prefecture),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _english(context)
                                  ? 'Open my stamp book'
                                  : 'ご酒印帳をひらく',
                              style: const TextStyle(
                                color: japanMapNavy,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward,
                              color: japanMapNavy,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

class SakeStampBookPage extends StatefulWidget {
  const SakeStampBookPage({super.key, this.initialPrefectureCode});
  final int? initialPrefectureCode;

  @override
  State<SakeStampBookPage> createState() => _SakeStampBookPageState();
}

class _SakeStampBookPageState extends State<SakeStampBookPage> {
  int? _selectedCode;
  bool _earnedOnly = false;
  int? _persistedCode;
  late final _map = _loadMap();

  Future<List<JapanSakePrefecture>> _loadMap() async {
    _selectedCode =
        widget.initialPrefectureCode ??
        await SakeStampPreferences.lastPrefecture();
    return JapanSakeMapData.load();
  }

  void _select(int code) {
    setState(() => _selectedCode = code);
    _persistedCode = code;
    SakeStampPreferences.rememberPrefecture(code);
  }

  @override
  Widget build(BuildContext context) => SakeJourneyProgressBuilder(
    builder: (context, progress, legend, ready) => Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: PrimaryAppBar(
        title: _english(context) ? 'My sake stamp book' : '日本酒ご酒印帳',
      ),
      body: FutureBuilder(
        future: _map,
        builder: (context, snapshot) {
          final prefectures = snapshot.data;
          if (prefectures == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final selected = prefectures.firstWhere(
            (p) => p.code == (_selectedCode ?? widget.initialPrefectureCode),
            orElse: () =>
                _previewPrefecture(prefectures, progress.brandIdsByPrefecture),
          );
          final earned =
              progress.brandIdsByPrefecture[selected.code] ?? const {};
          if (_selectedCode != selected.code) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ready) _select(selected.code);
            });
          } else if (_persistedCode != selected.code) {
            _persistedCode = selected.code;
            SakeStampPreferences.rememberPrefecture(selected.code);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            children: [
              Text(
                _english(context)
                    ? 'A collection of the sake you have enjoyed.'
                    : '飲んだ一杯を、旅のしるしに。',
                style: const TextStyle(
                  color: japanMapNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _NationwideStampCount(
                progress.brandIdsByPrefecture,
                ready: ready,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                key: const ValueKey('stamp-prefecture-picker'),
                initialValue: selected.code,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: _english(context) ? 'Prefecture' : '都道府県',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: [
                  for (final prefecture in prefectures)
                    DropdownMenuItem(
                      value: prefecture.code,
                      child: Text(prefecture.label(context)),
                    ),
                ],
                onChanged: (code) {
                  if (code != null) _select(code);
                },
              ),
              const SizedBox(height: 16),
              Text(
                ready
                    ? (_english(context)
                          ? '${earned.length} brands recorded in ${selected.label(context)}'
                          : '${selected.name}で集めた酒印 ${earned.length}銘柄')
                    : (_english(context) ? 'Records unconfirmed' : '記録未確認'),
                style: const TextStyle(color: Color(0xFFB73927)),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  key: const ValueKey('stamp-earned-only'),
                  label: Text(
                    _english(context) ? 'Earned stamps only' : '押印済みだけ表示',
                  ),
                  selected: _earnedOnly,
                  selectedColor: const Color(0xFFFFF0CF),
                  checkmarkColor: const Color(0xFFB73927),
                  onSelected: (value) => setState(() => _earnedOnly = value),
                ),
              ),
              PrefectureStampCatalog(
                prefecture: selected,
                earnedOnly: _earnedOnly,
                recordedBrandIds: earned,
                recordsReady: ready,
                onBrandTap: (brand) => _openBrand(context, brand),
              ),
              const SizedBox(height: 8),
              Text(
                _english(context)
                    ? 'Record a sake to earn its brand stamp. Tap a stamp to explore that brand’s products.'
                    : 'お酒の記録をつけると、銘柄の酒印が朱色になります。酒印をタップすると、その銘柄の商品を見られます。',
                style: const TextStyle(
                  color: Color(0xFF687880),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              Text(
                _english(context)
                    ? 'Bookmarks alone do not earn stamps. Based on records loaded on this device and verified brewery origins.'
                    : '保存だけでは押印されません。この端末に読み込まれた記録と、確認できた銘柄の産地が対象です。',
                style: const TextStyle(
                  color: Color(0xFF687880),
                  fontSize: 11,
                  height: 1.6,
                ),
              ),
              if (!ready || progress.unresolvedRecords > 0) ...[
                const SizedBox(height: 16),
                legend,
              ],
            ],
          );
        },
      ),
    ),
  );
}

class _NationwideStampCount extends StatelessWidget {
  const _NationwideStampCount(this.brandIdsByPrefecture, {required this.ready});
  final Map<int, Set<int>> brandIdsByPrefecture;
  final bool ready;

  @override
  Widget build(BuildContext context) {
    final total = brandIdsByPrefecture.values
        .expand((ids) => ids)
        .toSet()
        .length;
    return Text(
      ready
          ? (_english(context)
                ? '$total brands collected nationwide'
                : '全国で集めた酒印 $total銘柄')
          : (_english(context) ? 'Checking collected stamps…' : '全国の酒印を確認中…'),
      key: const ValueKey('nationwide-stamp-count'),
      style: const TextStyle(
        color: Color(0xFFB73927),
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
