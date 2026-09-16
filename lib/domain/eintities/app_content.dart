class AppReleaseSetting {
  const AppReleaseSetting({
    required this.minimumVersion,
    this.storeUrl,
    this.message,
    this.messageUrl,
  });

  factory AppReleaseSetting.fromJson(Map<String, dynamic> json) =>
      AppReleaseSetting(
        minimumVersion:
            json['minimumVersion'] as String? ??
            json['version'] as String? ??
            '0.0.0',
        storeUrl: _text(json['storeUrl']),
        message: _text(json['message']),
        messageUrl: _text(json['messageUrl']),
      );

  final String minimumVersion;
  final String? storeUrl;
  final String? message;
  final String? messageUrl;
}

class AppPromotion {
  const AppPromotion({
    required this.id,
    required this.placement,
    required this.title,
    required this.imageUrl,
    required this.linkType,
    this.body,
    this.linkTarget,
  });

  factory AppPromotion.fromJson(Map<String, dynamic> json) => AppPromotion(
    id: (json['id'] as num).toInt(),
    placement: json['placement'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: _text(json['body']),
    imageUrl: json['imageUrl'] as String? ?? '',
    linkType: json['linkType'] as String? ?? 'external',
    linkTarget: _text(json['linkTarget']),
  );

  final int id;
  final String placement;
  final String title;
  final String? body;
  final String imageUrl;
  final String linkType;
  final String? linkTarget;
}

class AppContent {
  const AppContent({
    required this.release,
    required this.startupPromotions,
    required this.homeBanners,
  });

  factory AppContent.fromJson(Map<String, dynamic> json) => AppContent(
    release: AppReleaseSetting.fromJson(
      Map<String, dynamic>.from(json['release'] as Map? ?? const {}),
    ),
    startupPromotions: _promotions(json['startupPromotions']),
    homeBanners: _promotions(json['homeBanners']),
  );

  final AppReleaseSetting release;
  final List<AppPromotion> startupPromotions;
  final List<AppPromotion> homeBanners;
}

class HomeSakeRecommendation {
  const HomeSakeRecommendation({
    required this.sakeId,
    required this.name,
    required this.score,
    this.type,
    this.brand,
    this.brewery,
    this.imageUrl,
  });

  factory HomeSakeRecommendation.fromJson(Map<String, dynamic> json) =>
      HomeSakeRecommendation(
        sakeId: (json['sakeId'] as num).toInt(),
        name: json['name'] as String? ?? '',
        score: (json['score'] as num?)?.round() ?? 0,
        type: _text(json['type']),
        brand: _text(json['brand']),
        brewery: _text(json['brewery']),
        imageUrl: _text(json['imageUrl']),
      );

  final int sakeId;
  final String name;
  final int score;
  final String? type;
  final String? brand;
  final String? brewery;
  final String? imageUrl;
}

List<AppPromotion> _promotions(dynamic value) => value is List
    ? value
          .whereType<Map>()
          .map((item) => AppPromotion.fromJson(Map<String, dynamic>.from(item)))
          .toList(growable: false)
    : const [];

String? _text(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}
