/// A collected encounter is separate from drinking records and map counts.
class CollectedSakeStamp {
  const CollectedSakeStamp({
    required this.brandId,
    required this.prefectureCode,
    required this.sakeId,
    required this.source,
    required this.observedAt,
    this.originalBrandId,
  });
  final int brandId, prefectureCode, sakeId;
  final int? originalBrandId;
  final String source;
  final DateTime observedAt;
  bool get valid =>
      brandId > 0 && sakeId > 0 && prefectureCode >= 1 && prefectureCode <= 47;
  Map<String, dynamic> toJson() => {
    'brandId': brandId,
    'prefectureCode': prefectureCode,
    'sakeId': sakeId,
    'source': source,
    'observedAt': observedAt.toIso8601String(),
  };
  factory CollectedSakeStamp.fromJson(Map<String, dynamic> json) =>
      CollectedSakeStamp(
        brandId: json['brandId'] as int,
        prefectureCode: json['prefectureCode'] as int,
        sakeId: json['sakeId'] as int,
        source: json['source'] as String,
        observedAt: DateTime.parse(json['observedAt'] as String),
        originalBrandId: json['originalBrandId'] as int?,
      );
}
