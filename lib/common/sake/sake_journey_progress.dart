import '../../domain/eintities/sake_catalog_browse.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'personal_sake_record.dart';

class SakeJourneyProgress {
  const SakeJourneyProgress({
    this.counts = const {},
    this.productsByPrefecture = const {},
    this.productsByBrand = const {},
    this.brandIdsByPrefecture = const {},
    this.unresolvedRecords = 0,
  });
  final Map<int, int> counts;

  /// One representative record per product, using its current canonical ID.
  final Map<int, List<Sake>> productsByPrefecture;

  /// Recorded products grouped only by the catalog-confirmed brand.
  final Map<int, List<Sake>> productsByBrand;
  final Map<int, Set<int>> brandIdsByPrefecture;
  final int unresolvedRecords;
}

/// Count catalog products once, including verified duplicate IDs as one product.
SakeJourneyProgress aggregateSakeJourney(
  Iterable<Sake> records,
  Iterable<SakeProductOrigin> origins,
) {
  final byId = {for (final origin in origins) origin.sakeId: origin};
  final products = <int, Map<int, Sake>>{};
  final brands = <int, Set<int>>{};
  final brandProducts = <int, Map<int, Sake>>{};
  var unresolved = 0;
  for (final record in records.where(hasPersonalSakeRecord)) {
    final origin = byId[record.sakeId];
    if (origin == null) {
      unresolved++;
      continue;
    }
    products
        .putIfAbsent(origin.prefectureCode, () => {})
        .putIfAbsent(
          origin.canonicalSakeId,
          () => record.copyWith(sakeId: origin.canonicalSakeId),
        );
    brands.putIfAbsent(origin.prefectureCode, () => {}).add(origin.brandId);
    brandProducts
        .putIfAbsent(origin.brandId, () => {})
        .putIfAbsent(
          origin.canonicalSakeId,
          () => record.copyWith(sakeId: origin.canonicalSakeId),
        );
  }
  return SakeJourneyProgress(
    counts: {
      for (final entry in products.entries) entry.key: entry.value.length,
    },
    productsByPrefecture: {
      for (final entry in products.entries)
        entry.key: entry.value.values.toList(growable: false),
    },
    productsByBrand: {
      for (final entry in brandProducts.entries)
        entry.key: entry.value.values.toList(growable: false),
    },
    brandIdsByPrefecture: brands,
    unresolvedRecords: unresolved,
  );
}
