import 'package:flutter/material.dart';
import '../../common/analytics/app_analytics.dart';
import '../../domain/eintities/sake_catalog_browse.dart';
import '../common/widgets/primary_app_bar.dart';
import 'japan_sake_page.dart';
import 'widgets/japan_sake_map.dart';
import 'widgets/prefecture_stamp_catalog.dart';
import 'widgets/nationwide_stamp_catalog.dart';
import 'widgets/sake_journey_progress.dart';
import 'widgets/sake_stamp_preferences.dart';
import 'widgets/sake_stamp_collection_label.dart';
import 'widgets/sake_stamp_book_opening.dart';
import 'widgets/sake_stamp_page_turn.dart';
import 'widgets/home_section_title.dart';

bool _english(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

JapanSakePrefecture _previewPrefecture(
  List<JapanSakePrefecture> prefectures,
  Map<int, Set<int>> recordedBrands,
) {
  var selected = prefectures.firstWhere(
    (p) => p.code == 35,
    orElse: () => prefectures.first,
  );
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
  late final _map = JapanSakeMapData.load();

  Future<void> _open(int initialCode) async {
    AppAnalytics.instance.event('home', 'sake_stamp_book');
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SakeStampBookPage(initialPrefectureCode: initialCode),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SakeJourneyProgressBuilder(
    includeEncounterStamps: true,
    builder: (context, progress, legend, ready) => FutureBuilder(
      future: _map,
      builder: (context, snapshot) {
        final prefectures = snapshot.data;
        if (prefectures == null) return const SizedBox.shrink();
        final nationwide =
            !ready ||
            progress.unresolvedRecords > 0 ||
            progress.brandIdsByPrefecture.values.any((ids) => ids.isNotEmpty);
        final prefecture = prefectures.firstWhere((p) => p.code == 35);
        return Padding(
          key: const ValueKey('home-sake-stamp-section'),
          padding: const EdgeInsets.only(top: 12, bottom: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeSectionTitle(
                title: _english(context) ? 'My sake stamp book' : '日本酒ご酒印帳',
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      _english(context)
                          ? 'Turn each sake encounter into an everyday memory.'
                          : '一杯の出会いを、日々の思い出に',
                      style: const TextStyle(
                        color: Color(0xFF687880),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: const ValueKey('open-sake-stamp-book'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _open(nationwide ? 0 : prefecture.code),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (nationwide)
                              NationwideStampCatalog(
                                recordedBrands: progress.brandIdsByPrefecture,
                                recordsReady: ready,
                                preview: true,
                                onBrandTap: (_) => _open(0),
                              )
                            else
                              PrefectureStampCatalog(
                                prefecture: prefecture,
                                recordedBrandIds:
                                    progress.brandIdsByPrefecture[prefecture
                                        .code] ??
                                    const {},
                                recordsReady: ready,
                                preview: true,
                                onBrandTap: (_) => _open(prefecture.code),
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
              ),
            ],
          ),
        );
      },
    ),
  );
}

class SakeStampBookPage extends StatefulWidget {
  const SakeStampBookPage({
    super.key,
    this.initialPrefectureCode,
    this.initiallyOpen = false,
    this.isTab = false,
  });
  final bool isTab;
  final bool initiallyOpen;
  final int? initialPrefectureCode;

  @override
  State<SakeStampBookPage> createState() => _SakeStampBookPageState();
}

class _SakeStampBookPageState extends State<SakeStampBookPage> {
  int? _selectedCode;
  bool _earnedOnly = false;
  late bool _bookOpened = widget.initiallyOpen;
  int _pageResetVersion = 0;
  bool _startAtEnd = false;
  final _catalogTurn = SakeStampPageTurnController();
  final _opening = SakeStampBookOpeningController();
  int? _persistedCode;
  late final _map = _loadMap();

  Future<List<JapanSakePrefecture>> _loadMap() async {
    _selectedCode =
        widget.initialPrefectureCode ??
        await SakeStampPreferences.lastPrefecture();
    return JapanSakeMapData.load();
  }

  void _select(
    int code, {
    bool animate = true,
    bool? backwards,
    bool startAtEnd = false,
  }) {
    void change() {
      if (!mounted) return;
      setState(() {
        _selectedCode = code;
        _startAtEnd = startAtEnd;
      });
      _persistedCode = code;
      SakeStampPreferences.rememberPrefecture(code);
    }

    if (animate && _bookOpened && _selectedCode != code) {
      _catalogTurn.turn(
        change,
        backwards: backwards ?? code < (_selectedCode ?? code),
      );
    } else {
      change();
      if (animate && !_bookOpened) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _opening.open();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => SakeJourneyProgressBuilder(
    includeEncounterStamps: true,
    compactStatus: true,
    builder: (context, progress, legend, ready) => Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),
      appBar: PrimaryAppBar(
        title: _english(context) ? 'My sake stamp book' : '日本酒ご酒印帳',
        automaticallyImplyLeading: !widget.isTab,
      ),
      body: FutureBuilder(
        future: _map,
        builder: (context, snapshot) {
          final prefectures = snapshot.data;
          if (prefectures == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final ordered = [...prefectures]
            ..sort((a, b) => a.code.compareTo(b.code));
          final nationwide = _selectedCode == 0;
          final selected = ordered.firstWhere(
            (p) => p.code == (_selectedCode ?? widget.initialPrefectureCode),
            orElse: () =>
                _previewPrefecture(prefectures, progress.brandIdsByPrefecture),
          );
          final index = ordered.indexWhere((p) => p.code == selected.code);
          // Nationwide sits between the last and first prefecture in the loop.
          final previous = nationwide
              ? ordered.last
              : index > 0
              ? ordered[index - 1]
              : null;
          final next = nationwide
              ? ordered.first
              : index + 1 < ordered.length
              ? ordered[index + 1]
              : null;
          final nationwideLabel = _english(context) ? 'Nationwide' : '全国';
          final earned =
              progress.brandIdsByPrefecture[selected.code] ?? const {};
          final selectedCode = nationwide ? 0 : selected.code;
          final total = progress.brandIdsByPrefecture.values
              .expand((ids) => ids)
              .toSet()
              .length;
          if (_selectedCode != selectedCode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && ready) _select(selectedCode, animate: false);
            });
          } else if (_persistedCode != selectedCode) {
            _persistedCode = selectedCode;
            SakeStampPreferences.rememberPrefecture(selectedCode);
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            children: [
              Text(
                _english(context)
                    ? 'Turn each sake encounter into an everyday memory.'
                    : '一杯の出会いを、日々の思い出に',
                style: const TextStyle(
                  color: japanMapNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: const ValueKey('stamp-prefecture-picker'),
                menuMaxHeight: (MediaQuery.sizeOf(context).height * .4)
                    .clamp(0.0, 300.0)
                    .toDouble(),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                initialValue: selectedCode,
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
                  DropdownMenuItem(
                    value: 0,
                    child: Text(_english(context) ? 'Nationwide' : '全国'),
                  ),
                  for (final prefecture in ordered)
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
              SakeStampCollectionLabel(
                prefecture: nationwide ? null : selected.label(context),
                count: earned.length,
                nationwideCount: total,
                ready: ready,
              ),
              if (!nationwide)
                Align(
                  alignment: Alignment.centerRight,
                  child: Semantics(
                    toggled: _earnedOnly,
                    child: TextButton.icon(
                      key: const ValueKey('stamp-earned-only'),
                      style: TextButton.styleFrom(
                        foregroundColor: _earnedOnly
                            ? const Color(0xFFB73927)
                            : const Color(0xFF687880),
                        textStyle: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(fontSize: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      icon: Icon(
                        _earnedOnly
                            ? Icons.check_circle_outline
                            : Icons.circle_outlined,
                        size: 15,
                      ),
                      label: Text(
                        _english(context) ? 'Earned stamps only' : '押印済みだけ表示',
                      ),
                      onPressed: () =>
                          setState(() => _earnedOnly = !_earnedOnly),
                    ),
                  ),
                ),
              SakeStampBookOpening(
                key: const ValueKey('stamp-book-opening'),
                controller: _opening,
                onClosed: () => setState(() {
                  _bookOpened = false;
                  _startAtEnd = false;
                  _pageResetVersion++;
                }),
                initiallyOpen: _bookOpened,
                onOpened: () => setState(() => _bookOpened = true),
                child: SakeStampPageTurn(
                  controller: _catalogTurn,
                  child: nationwide
                      ? NationwideStampCatalog(
                          pageResetVersion: _pageResetVersion,
                          startAtEnd: _startAtEnd,
                          recordedBrands: progress.brandIdsByPrefecture,
                          recordsReady: ready,
                          onBrandTap: (brand) => _openBrand(context, brand),
                          onNextSection: () =>
                              _select(next?.code ?? 0, backwards: false),
                          onReturnToCover: _opening.close,
                        )
                      : PrefectureStampCatalog(
                          pageResetVersion: _pageResetVersion,
                          startAtEnd: _startAtEnd,
                          prefecture: selected,
                          earnedOnly: _earnedOnly,
                          recordedBrandIds: earned,
                          recordsReady: ready,
                          onBrandTap: (brand) => _openBrand(context, brand),
                          onNextSection: () =>
                              _select(next?.code ?? 0, backwards: false),
                          onPreviousSection: () => _select(
                            previous?.code ?? 0,
                            backwards: true,
                            startAtEnd: true,
                          ),
                        ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _PrefectureStepButton(
                      key: const ValueKey('stamp-previous-prefecture'),
                      label: previous?.label(context) ?? nationwideLabel,
                      onPressed: () => _select(
                        previous?.code ?? 0,
                        backwards: true,
                        startAtEnd: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PrefectureStepButton(
                      key: const ValueKey('stamp-next-prefecture'),
                      label: next?.label(context) ?? nationwideLabel,
                      forward: true,
                      onPressed: () =>
                          _select(next?.code ?? 0, backwards: false),
                    ),
                  ),
                ],
              ),
              if (!ready) legend,
            ],
          );
        },
      ),
    ),
  );
}

class _PrefectureStepButton extends StatelessWidget {
  const _PrefectureStepButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.forward = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool forward;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: japanMapNavy,
      backgroundColor: Colors.white,
      disabledForegroundColor: const Color(0xFFBAC1C4),
      side: BorderSide(
        color: japanMapNavy.withValues(alpha: onPressed == null ? .08 : .2),
      ),
      minimumSize: const Size(0, 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!forward) ...[
          const Icon(Icons.arrow_back_rounded, size: 32),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
        if (forward) ...[
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_rounded, size: 32),
        ],
      ],
    ),
  );
}
