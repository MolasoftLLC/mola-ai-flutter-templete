import '../../domain/eintities/sake_catalog_browse.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'personal_sake_record.dart';

class SakeJourneyProgress {
  const SakeJourneyProgress({
    this.counts = const {},
    this.unresolvedRecords = 0,
  });
  final Map<int, int> counts;
  final int unresolvedRecords;
}

/// Count catalog products once, including verified duplicate IDs as one product.
SakeJourneyProgress aggregateSakeJourney(
  Iterable<Sake> records,
  Iterable<SakeProductOrigin> origins,
) {
  final byId = {for (final origin in origins) origin.sakeId: origin};
  final products = <int, Set<int>>{};
  var unresolved = 0;
  for (final record in records.where(hasPersonalSakeRecord)) {
    final origin = byId[record.sakeId];
    if (origin == null) {
      unresolved++;
      continue;
    }
    products
        .putIfAbsent(origin.prefectureCode, () => {})
        .add(origin.canonicalSakeId);
  }
  return SakeJourneyProgress(
    counts: {
      for (final entry in products.entries) entry.key: entry.value.length,
    },
    unresolvedRecords: unresolved,
  );
}
