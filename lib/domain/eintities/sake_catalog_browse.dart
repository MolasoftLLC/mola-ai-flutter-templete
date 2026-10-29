class SakeBrandSummary {
  const SakeBrandSummary({
    required this.brandId,
    required this.name,
    required this.brewery,
    required this.productCount,
    this.primaryImageUrl,
    this.thumbnailImageUrl,
  });
  factory SakeBrandSummary.fromJson(Map<String, dynamic> json) =>
      SakeBrandSummary(
        brandId: (json['brandId'] as num).toInt(),
        name: json['name'] as String,
        brewery: json['brewery'] as String? ?? '',
        productCount: (json['productCount'] as num).toInt(),
        primaryImageUrl: json['primaryImageUrl'] as String?,
        thumbnailImageUrl: json['thumbnailImageUrl'] as String?,
      );
  final int brandId;
  final String name;
  final String brewery;
  final int productCount;
  final String? primaryImageUrl;
  final String? thumbnailImageUrl;
}

class SakeCatalogPage<T> {
  const SakeCatalogPage({required this.items, this.nextCursor});
  final List<T> items;
  final int? nextCursor;
}
