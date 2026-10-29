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

class SakeProductOrigin {
  const SakeProductOrigin({
    required this.sakeId,
    required this.canonicalSakeId,
    required this.brandId,
    required this.prefectureCode,
  });
  factory SakeProductOrigin.fromJson(Map<String, dynamic> json) {
    final id = json['sakeId'];
    final canonical = json['canonicalSakeId'];
    final brand = json['brandId'];
    final code = int.tryParse(json['prefectureCode']?.toString() ?? '');
    if (id is! int ||
        id < 1 ||
        canonical is! int ||
        canonical < 1 ||
        brand is! int ||
        brand < 1 ||
        code == null ||
        code < 1 ||
        code > 47) {
      throw const FormatException('商品の産地情報が不正です。');
    }
    return SakeProductOrigin(
      sakeId: id,
      canonicalSakeId: canonical,
      brandId: brand,
      prefectureCode: code,
    );
  }
  final int sakeId;
  final int canonicalSakeId;
  final int brandId;
  final int prefectureCode;
}
