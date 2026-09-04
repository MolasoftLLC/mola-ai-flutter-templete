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
  });

  factory SakeOverview.fromJson(Map<String, dynamic> json) {
    final sakeJson = _asStringMap(json['sake']);
    final analysisJson = _asStringMap(json['analysis']);
    final brandJson = _asStringMap(json['brand']);
    final breweryJson = _asStringMap(json['brewery']);
    final recentPublicPosts = json['recentPublicPosts'] is List
        ? List<dynamic>.from(json['recentPublicPosts'] as List)
        : const <dynamic>[];
    final communityJson = <String, dynamic>{
      'publicSavedSakeCount': _asInt(json['publicSavedSakeCount']) ?? 0,
      'recentPublicPosts': recentPublicPosts,
    };
    final sameBrandRaw = json['relatedProducts'];
    final sameBrandSakes = sameBrandRaw is List
        ? sameBrandRaw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false)
        : const <Map<String, dynamic>>[];

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
    );
  }

  final Sake sake;
  final bool analysisCompleted;
  final Map<String, dynamic>? analysisPayload;
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
