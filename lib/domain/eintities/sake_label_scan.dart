import 'response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

enum SakeScanApiStatus {
  candidates,
  needBackLabel,
  aiRequired,
  cacheHit,
  analysisRequired,
}

enum SakeScanBackLabelReason { ocrUnreadable, noCatalogMatch, lowConfidence }

class SakeScanCandidate {
  const SakeScanCandidate({
    required this.sakeId,
    required this.name,
    this.brandId,
    this.type,
    this.brewery,
    this.imageUrl,
    this.imageScore,
    this.ocrScore,
    this.confidence,
  });

  factory SakeScanCandidate.fromJson(Map<String, dynamic> json) {
    return SakeScanCandidate(
      sakeId: _asInt(json['sakeId']) ?? 0,
      brandId: _asInt(json['brandId']),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString(),
      brewery: json['brewery']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      imageScore: _asDouble(json['imageScore']),
      ocrScore: _asDouble(json['ocrScore']),
      confidence: _asDouble(json['confidence']),
    );
  }

  final int sakeId;
  final int? brandId;
  final String name;
  final String? type;
  final String? brewery;
  final String? imageUrl;
  final double? imageScore;
  final double? ocrScore;
  final double? confidence;

  Sake toSake() => Sake(
    sakeId: sakeId > 0 ? sakeId : null,
    brandId: brandId,
    name: name,
    type: type,
    brewery: brewery,
    primaryImageUrl: imageUrl,
  );
}

class SakeScanResult {
  const SakeScanResult({
    required this.status,
    required this.scanSessionId,
    this.candidates = const <SakeScanCandidate>[],
    this.backLabelReason,
  });

  factory SakeScanResult.fromJson(Map<String, dynamic> json) {
    final rawCandidates = json['candidates'];
    final candidates = rawCandidates is List
        ? rawCandidates
              .whereType<Map>()
              .map(
                (item) =>
                    SakeScanCandidate.fromJson(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.sakeId > 0 && item.name.isNotEmpty)
              .toList(growable: false)
        : const <SakeScanCandidate>[];
    return SakeScanResult(
      status: parseSakeScanApiStatus(json['status']),
      scanSessionId: json['scanSessionId']?.toString() ?? '',
      candidates: candidates,
      backLabelReason: parseSakeScanBackLabelReason(json['backLabelReason']),
    );
  }

  final SakeScanApiStatus status;
  final String scanSessionId;
  final List<SakeScanCandidate> candidates;
  final SakeScanBackLabelReason? backLabelReason;
}

class SakeScanConfirmation {
  const SakeScanConfirmation({required this.status, required this.sakeId});

  factory SakeScanConfirmation.fromJson(Map<String, dynamic> json) {
    return SakeScanConfirmation(
      status: parseSakeScanApiStatus(json['status']),
      sakeId: _asInt(json['sakeId']) ?? 0,
    );
  }

  final SakeScanApiStatus status;
  final int sakeId;
}

class SakeOverview {
  const SakeOverview({
    required this.sake,
    required this.analysisCompleted,
    this.analysisPayload,
    this.masterEnrichmentPending = false,
    this.master = const SakeMasterDetails(),
    this.brand = const SakeBrandDetails(),
    this.brewery = const SakeBreweryDetails(),
    this.publicSavedSakeCount = 0,
    this.relatedProducts = const <RelatedSakeProduct>[],
  });

  factory SakeOverview.fromJson(Map<String, dynamic> json) {
    final sakeJson = _asStringMap(json['sake']);
    final analysisJson = _asStringMap(json['analysis']);
    final brandJson = _asStringMap(json['brand']);
    final breweryJson = _asStringMap(json['brewery']);
    final enrichmentJson = _asStringMap(json['masterEnrichment']);
    final recentPublicPosts = json['recentPublicPosts'] is List
        ? List<dynamic>.from(json['recentPublicPosts'] as List)
        : const <dynamic>[];
    final communityJson = <String, dynamic>{
      'publicSavedSakeCount': _asInt(json['publicSavedSakeCount']) ?? 0,
      'recentPublicPosts': recentPublicPosts,
    };
    final sameBrandRaw = json['relatedProducts'];
    final relatedProducts = sameBrandRaw is List
        ? sameBrandRaw
              .whereType<Map>()
              .map(
                (item) => RelatedSakeProduct.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList(growable: false)
        : const <RelatedSakeProduct>[];
    final sameBrandSakes = relatedProducts
        .map((item) => item.toJson())
        .toList(growable: false);

    final embeddedSake = _asStringMap(analysisJson['sakeInfo']);
    final analysisSakeJson = embeddedSake.isNotEmpty
        ? embeddedSake
        : analysisJson;
    final merged = <String, dynamic>{...analysisSakeJson, ...sakeJson};
    merged['sakeId'] = _asInt(sakeJson['sakeId']) ?? _asInt(sakeJson['id']);
    merged['brandId'] = _asInt(sakeJson['brandId']) ?? _asInt(brandJson['id']);
    merged['brewery'] =
        sakeJson['brewery']?.toString() ?? breweryJson['name']?.toString();
    merged['prefectureCode'] =
        sakeJson['prefectureCode']?.toString() ??
        breweryJson['prefectureCode']?.toString();
    merged['primaryImageUrl'] =
        sakeJson['primaryImageUrl']?.toString() ??
        sakeJson['imageUrl']?.toString();
    merged['community'] = communityJson;
    merged['sameBrandSakes'] = sameBrandSakes;

    return SakeOverview(
      sake: Sake.fromJson(merged),
      analysisCompleted: analysisJson.isNotEmpty,
      analysisPayload: analysisJson.isEmpty ? null : analysisJson,
      masterEnrichmentPending: enrichmentJson['status'] == 'pending',
      master: SakeMasterDetails.fromJson(sakeJson),
      brand: SakeBrandDetails.fromJson(brandJson),
      brewery: SakeBreweryDetails.fromJson(breweryJson),
      publicSavedSakeCount: _asInt(json['publicSavedSakeCount']) ?? 0,
      relatedProducts: relatedProducts,
    );
  }

  final Sake sake;
  final bool analysisCompleted;
  final Map<String, dynamic>? analysisPayload;
  final bool masterEnrichmentPending;
  final SakeMasterDetails master;
  final SakeBrandDetails brand;
  final SakeBreweryDetails brewery;
  final int publicSavedSakeCount;
  final List<RelatedSakeProduct> relatedProducts;
}

class SakeMasterDetails {
  const SakeMasterDetails({
    this.categoryCode,
    this.imageSource,
    this.imageProductUrl,
    this.imagePrice,
    this.imageCurrency,
    this.detailViewCount = 0,
    this.category,
    this.specialDesignation,
    this.seriesName,
    this.riceVariety,
    this.riceOrigin,
    this.polishingRatio,
    this.alcoholPercentage,
    this.sakeMeterValue,
    this.acidity,
    this.aminoAcid,
    this.sweetnessLevel,
    this.bodyLevel,
    this.aromaLevel,
    this.tasteTags = const <String>[],
    this.aromaTags = const <String>[],
    this.recommendedTemperatures = const <String>[],
    this.pasteurizationType,
    this.availabilityType,
    this.releaseSeason,
    this.dataSource,
    this.sourceUrl,
    this.verifiedAt,
    this.officialUrl,
    this.status,
    this.styles = const <SakeStyleDetails>[],
    this.variants = const <SakeProductVariant>[],
    this.tasteProfile,
  });

  factory SakeMasterDetails.fromJson(Map<String, dynamic> json) {
    final styles = json['styles'];
    final variants = json['variants'];
    final tasteProfile = _asStringMap(json['tasteProfile']);
    return SakeMasterDetails(
      categoryCode: _asNonEmptyString(json['categoryCode']),
      imageSource: _asNonEmptyString(json['imageSource']),
      imageProductUrl: _asNonEmptyString(json['imageProductUrl']),
      imagePrice: _asDouble(json['imagePrice']),
      imageCurrency: _asNonEmptyString(json['imageCurrency']),
      detailViewCount: _asInt(json['detailViewCount']) ?? 0,
      category: _asNonEmptyString(json['category']),
      specialDesignation: _asNonEmptyString(json['specialDesignation']),
      seriesName: _asNonEmptyString(json['seriesName']),
      riceVariety: _asNonEmptyString(json['riceVariety']),
      riceOrigin: _asNonEmptyString(json['riceOrigin']),
      polishingRatio: _asDouble(json['polishingRatio']),
      alcoholPercentage: _asDouble(json['alcoholPercentage']),
      sakeMeterValue: _asDouble(json['sakeMeterValue']),
      acidity: _asDouble(json['acidity']),
      aminoAcid: _asDouble(json['aminoAcid']),
      sweetnessLevel: _asDouble(json['sweetnessLevel']),
      bodyLevel: _asDouble(json['bodyLevel']),
      aromaLevel: _asDouble(json['aromaLevel']),
      tasteTags: _asStringList(json['tasteTags']),
      aromaTags: _asStringList(json['aromaTags']),
      recommendedTemperatures: _asStringList(json['recommendedTemperatures']),
      pasteurizationType: _asNonEmptyString(json['pasteurizationType']),
      availabilityType: _asNonEmptyString(json['availabilityType']),
      releaseSeason: _asNonEmptyString(json['releaseSeason']),
      dataSource: _asNonEmptyString(json['dataSource']),
      sourceUrl: _asNonEmptyString(json['sourceUrl']),
      verifiedAt: DateTime.tryParse(json['verifiedAt']?.toString() ?? ''),
      officialUrl: _asNonEmptyString(json['officialUrl']),
      status: _asNonEmptyString(json['status']),
      styles: styles is List
          ? styles
                .whereType<Map>()
                .map(
                  (item) => SakeStyleDetails.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <SakeStyleDetails>[],
      variants: variants is List
          ? variants
                .whereType<Map>()
                .map(
                  (item) => SakeProductVariant.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList(growable: false)
          : const <SakeProductVariant>[],
      tasteProfile: tasteProfile.isEmpty
          ? null
          : SakeTasteProfileDetails.fromJson(tasteProfile),
    );
  }

  final String? categoryCode;
  final String? imageSource;
  final String? imageProductUrl;
  final double? imagePrice;
  final String? imageCurrency;
  final int detailViewCount;
  final String? category;
  final String? specialDesignation;
  final String? seriesName;
  final String? riceVariety;
  final String? riceOrigin;
  final double? polishingRatio;
  final double? alcoholPercentage;
  final double? sakeMeterValue;
  final double? acidity;
  final double? aminoAcid;
  final double? sweetnessLevel;
  final double? bodyLevel;
  final double? aromaLevel;
  final List<String> tasteTags;
  final List<String> aromaTags;
  final List<String> recommendedTemperatures;
  final String? pasteurizationType;
  final String? availabilityType;
  final String? releaseSeason;
  final String? dataSource;
  final String? sourceUrl;
  final DateTime? verifiedAt;
  final String? officialUrl;
  final String? status;
  final List<SakeStyleDetails> styles;
  final List<SakeProductVariant> variants;
  final SakeTasteProfileDetails? tasteProfile;
}

class SakeStyleDetails {
  const SakeStyleDetails({required this.code, required this.name});

  factory SakeStyleDetails.fromJson(Map<String, dynamic> json) =>
      SakeStyleDetails(
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );

  final String code;
  final String name;
}

class SakeProductVariant {
  const SakeProductVariant({
    this.variantId,
    this.volumeMl,
    this.suggestedPrice,
    this.taxIncluded,
    this.currency,
    this.priceBand,
  });

  factory SakeProductVariant.fromJson(Map<String, dynamic> json) =>
      SakeProductVariant(
        variantId: _asInt(json['variantId']),
        volumeMl: _asInt(json['volumeMl']),
        suggestedPrice: _asDouble(json['suggestedPrice']),
        taxIncluded: json['taxIncluded'] as bool?,
        currency: _asNonEmptyString(json['currency']),
        priceBand: _asNonEmptyString(json['priceBand']),
      );

  final int? variantId;
  final int? volumeMl;
  final double? suggestedPrice;
  final bool? taxIncluded;
  final String? currency;
  final String? priceBand;
}

class SakeTasteProfileDetails {
  const SakeTasteProfileDetails({
    required this.fruity,
    required this.sweetness,
    required this.acidity,
    required this.umami,
    required this.kire,
    required this.dryness,
    this.body,
    this.aroma,
    this.sourceType,
    this.confidence,
  });

  factory SakeTasteProfileDetails.fromJson(Map<String, dynamic> json) =>
      SakeTasteProfileDetails(
        fruity: _asDouble(json['fruity']) ?? 0,
        sweetness: _asDouble(json['sweetness']) ?? 0,
        acidity: _asDouble(json['acidity']) ?? 0,
        umami: _asDouble(json['umami']) ?? 0,
        kire: _asDouble(json['kire']) ?? 0,
        dryness: _asDouble(json['dryness']) ?? 0,
        body: _asDouble(json['body']),
        aroma: _asDouble(json['aroma']),
        sourceType: _asNonEmptyString(json['sourceType']),
        confidence: _asDouble(json['confidence']),
      );

  final double fruity;
  final double sweetness;
  final double acidity;
  final double umami;
  final double kire;
  final double dryness;
  final double? body;
  final double? aroma;
  final String? sourceType;
  final double? confidence;
}

class SakeBrandDetails {
  const SakeBrandDetails({this.id, this.name, this.description, this.imageUrl});

  factory SakeBrandDetails.fromJson(Map<String, dynamic> json) =>
      SakeBrandDetails(
        id: _asInt(json['id']),
        name: _asNonEmptyString(json['name']),
        description: _asNonEmptyString(json['description']),
        imageUrl: _asNonEmptyString(json['imageUrl']),
      );

  final int? id;
  final String? name;
  final String? description;
  final String? imageUrl;
}

class SakeBreweryDetails {
  const SakeBreweryDetails({
    this.id,
    this.name,
    this.prefectureCode,
    this.officialUrl,
  });

  factory SakeBreweryDetails.fromJson(Map<String, dynamic> json) =>
      SakeBreweryDetails(
        id: _asInt(json['id']),
        name: _asNonEmptyString(json['name']),
        prefectureCode: _asNonEmptyString(json['prefectureCode']),
        officialUrl: _asNonEmptyString(json['officialUrl']),
      );

  final int? id;
  final String? name;
  final String? prefectureCode;
  final String? officialUrl;
}

class RelatedSakeProduct {
  const RelatedSakeProduct({
    required this.sakeId,
    required this.name,
    this.type,
    this.imageUrl,
  });

  factory RelatedSakeProduct.fromJson(Map<String, dynamic> json) =>
      RelatedSakeProduct(
        sakeId: _asInt(json['sakeId']) ?? 0,
        name: json['name']?.toString() ?? '',
        type: _asNonEmptyString(json['type']),
        imageUrl: _asNonEmptyString(json['imageUrl']),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'sakeId': sakeId,
    'name': name,
    if (type != null) 'type': type,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  final int sakeId;
  final String name;
  final String? type;
  final String? imageUrl;
}

SakeScanApiStatus parseSakeScanApiStatus(dynamic value) {
  return switch (value?.toString()) {
    'candidates' => SakeScanApiStatus.candidates,
    'need_back_label' => SakeScanApiStatus.needBackLabel,
    'ai_required' => SakeScanApiStatus.aiRequired,
    'cache_hit' => SakeScanApiStatus.cacheHit,
    'analysis_required' => SakeScanApiStatus.analysisRequired,
    _ => throw FormatException('不明なスキャンステータスです: $value'),
  };
}

SakeScanBackLabelReason? parseSakeScanBackLabelReason(dynamic value) {
  return switch (value?.toString()) {
    'ocr_unreadable' => SakeScanBackLabelReason.ocrUnreadable,
    'no_catalog_match' => SakeScanBackLabelReason.noCatalogMatch,
    'low_confidence' => SakeScanBackLabelReason.lowConfidence,
    _ => null,
  };
}

Map<String, dynamic> _asStringMap(dynamic value) {
  return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}

double? _asDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

String? _asNonEmptyString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

List<String> _asStringList(dynamic value) {
  if (value is! List) return const <String>[];
  return value
      .map(_asNonEmptyString)
      .whereType<String>()
      .toList(growable: false);
}
