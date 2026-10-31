import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../common/sake/personal_sake_record.dart';
import '../../../common/sake/sake_journey_progress.dart';
import '../../../domain/eintities/sake_catalog_browse.dart';
import '../../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../../domain/notifier/sake_stamp_store.dart';
import '../../../domain/repository/place_map_repository.dart';
import 'japan_sake_map.dart';

class SakeJourneyProgressBuilder extends StatefulWidget {
  const SakeJourneyProgressBuilder({
    super.key,
    required this.builder,
    this.compactStatus = false,
    this.showLegendDetails = true,
    this.includeEncounterStamps = false,
  });
  final bool compactStatus;
  final bool showLegendDetails;
  final bool includeEncounterStamps;
  final Widget Function(
    BuildContext context,
    SakeJourneyProgress progress,
    Widget legend,
    bool isReady,
  )
  builder;
  @override
  State<SakeJourneyProgressBuilder> createState() =>
      _SakeJourneyProgressBuilderState();
}

class _SakeJourneyProgressBuilderState
    extends State<SakeJourneyProgressBuilder> {
  String? _key;
  List<int> _ids = const [];
  List<Sake> _records = const [];
  Future<List<SakeProductOrigin>>? _future;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _records =
        (Provider.of<SavedSakeState?>(context)?.savedSakeList ?? const <Sake>[])
            .where(hasPersonalSakeRecord)
            .toList(growable: false);
    _ids =
        _records
            .map((record) => record.sakeId ?? 0)
            .where((id) => id > 0)
            .toSet()
            .toList()
          ..sort();
    final key = _ids.join(',');
    if (_key == key) return;
    _key = key;
    _reload();
  }

  void _reload() {
    _future = _ids.isEmpty
        ? Future.value(const [])
        : context.read<PlaceMapRepository>().fetchSakeOrigins(_ids);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<SakeProductOrigin>>(
    future: _future,
    builder: (context, snapshot) {
      var progress = aggregateSakeJourney(_records, snapshot.data ?? const []);
      final stamps = widget.includeEncounterStamps
          ? Provider.of<SakeStampStore?>(context)
          : null;
      if (stamps != null) {
        final brands = {
          for (final entry in progress.brandIdsByPrefecture.entries)
            entry.key: {...entry.value},
        };
        for (final entry in stamps.brandIdsByPrefecture.entries) {
          brands.putIfAbsent(entry.key, () => {}).addAll(entry.value);
        }
        progress = SakeJourneyProgress(
          counts: progress.counts,
          productsByPrefecture: progress.productsByPrefecture,
          productsByBrand: progress.productsByBrand,
          brandIdsByPrefecture: brands,
          unresolvedRecords: progress.unresolvedRecords,
        );
      }
      final english = Localizations.localeOf(context).languageCode == 'en';
      final loading =
          snapshot.connectionState != ConnectionState.done && _ids.isNotEmpty;
      final legend = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            english ? 'Products in your records' : '記録した商品数',
            style: const TextStyle(
              color: japanMapNavy,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 14,
            runSpacing: 8,
            children: [
              for (final tier in [1, 5, 10])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: sakeJourneyColor(tier),
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: japanMapNavy.withValues(alpha: .12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tier == 1
                          ? '1–4'
                          : tier == 5
                          ? '5–9'
                          : '10+',
                      style: const TextStyle(color: japanMapNavy, fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
          if (widget.showLegendDetails) ...[
            const SizedBox(height: 6),
            Text(
              english
                  ? 'Unique products · not repeat records or where you drank'
                  : '同じ商品は1つ。銘柄の産地で集計します。',
              style: const TextStyle(color: Color(0xFF687880), fontSize: 10),
            ),
          ],
          if (loading)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                english ? 'Checking origins…' : '産地を確認中…',
                style: const TextStyle(color: Color(0xFF687880), fontSize: 11),
              ),
            )
          else if (snapshot.hasError)
            TextButton(
              onPressed: () => setState(_reload),
              style: TextButton.styleFrom(foregroundColor: japanMapNavy),
              child: Text(
                english
                    ? 'Could not check origins. Retry'
                    : '産地を確認できませんでした。再試行',
              ),
            )
          else if (widget.showLegendDetails && progress.unresolvedRecords > 0)
            Text(
              english
                  ? '${progress.unresolvedRecords} records with unconfirmed origins'
                  : '産地未確認の記録 ${progress.unresolvedRecords}件',
              style: const TextStyle(color: Color(0xFF687880), fontSize: 11),
            ),
        ],
      );
      return widget.builder(
        context,
        progress,
        widget.compactStatus
            ? (snapshot.hasError
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: english ? 'Retry checking stamps' : '酒印を再確認',
                        onPressed: () => setState(_reload),
                        icon: const Icon(Icons.refresh, color: japanMapNavy),
                      ),
                    )
                  : const SizedBox.shrink())
            : legend,
        !loading && !snapshot.hasError && (stamps?.loaded ?? true),
      );
    },
  );
}
