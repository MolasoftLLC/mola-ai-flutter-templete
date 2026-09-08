import '../../common/localization/app_locale_resolver.dart';
import '../../infrastructure/api_client/api_client.dart';
import '../eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';

class PlaceCandidate {
  const PlaceCandidate({
    required this.providerPlaceId,
    required this.displayName,
    this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
  });

  factory PlaceCandidate.fromJson(Map<String, dynamic> json) => PlaceCandidate(
    providerPlaceId: json['providerPlaceId'] as String,
    displayName: json['displayName'] as String,
    formattedAddress: json['formattedAddress'] as String?,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
  );

  final String providerPlaceId;
  final String displayName;
  final String? formattedAddress;
  final double latitude;
  final double longitude;
  final double? distanceMeters;

  DrinkingPlace toDrinkingPlace() => DrinkingPlace(
    providerPlaceId: providerPlaceId,
    displayName: displayName,
    formattedAddress: formattedAddress,
    latitude: latitude,
    longitude: longitude,
  );
}

class MapContributionSaveResult {
  const MapContributionSaveResult({
    required this.drinkingPlace,
    required this.pointsAwarded,
    required this.totalMapContributionPoints,
  });

  final DrinkingPlace drinkingPlace;
  final int pointsAwarded;
  final int totalMapContributionPoints;
}

class MapVenue {
  const MapVenue({
    required this.venueId,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.sakeCount,
    required this.recordCount,
    this.ownRecordCount = 0,
    this.latestImageUrl,
  });

  factory MapVenue.fromJson(Map<String, dynamic> json) {
    final latestRecord = json['latestRecord'];
    final latestRecordJson = latestRecord is Map
        ? Map<String, dynamic>.from(latestRecord)
        : const <String, dynamic>{};
    return MapVenue(
      venueId: json['venueId'] as String,
      displayName: json['displayName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      sakeCount: (json['sakeCount'] as num?)?.toInt() ?? 0,
      recordCount: (json['recordCount'] as num?)?.toInt() ?? 0,
      ownRecordCount: (json['ownRecordCount'] as num?)?.toInt() ?? 0,
      latestImageUrl:
          _nonEmptyString(json['latestImageUrl']) ??
          _nonEmptyString(latestRecordJson['imageUrl']),
    );
  }

  final String venueId;
  final String displayName;
  final double latitude;
  final double longitude;
  final int sakeCount;
  final int recordCount;
  final int ownRecordCount;
  final String? latestImageUrl;
}

class VenueSake {
  const VenueSake({
    this.sakeId,
    this.searchToken,
    required this.name,
    this.brewery,
    this.type,
    required this.recordCount,
    String? primaryImageUrl,
    this.thumbnailImageUrl,
    String? imageUrl,
  }) : primaryImageUrl = primaryImageUrl ?? imageUrl;
  factory VenueSake.fromJson(Map<String, dynamic> json) => VenueSake(
    sakeId: (json['sakeId'] as num?)?.toInt(),
    searchToken: json['searchToken'] as String?,
    name: json['name'] as String? ?? '名称不明',
    brewery: json['brewery'] as String?,
    type: json['type'] as String?,
    recordCount: (json['recordCount'] as num?)?.toInt() ?? 0,
    thumbnailImageUrl: _nonEmptyString(json['thumbnailImageUrl']),
    primaryImageUrl:
        _nonEmptyString(json['primaryImageUrl']) ??
        _nonEmptyString(json['imageUrl']),
  );
  final int? sakeId;
  final String? searchToken;
  final String name;
  final String? brewery;
  final String? type;
  final int recordCount;
  final String? primaryImageUrl;

  final String? thumbnailImageUrl;

  // 旧レスポンスと既存利用箇所との互換性を維持する。
  String? get imageUrl => primaryImageUrl;
}

class SakeMapSearchResult {
  const SakeMapSearchResult({
    this.sakeId,
    this.searchToken,
    required this.name,
    this.brewery,
    this.type,
    this.primaryImageUrl,
    this.thumbnailImageUrl,
    required this.isMaster,
    this.venueCount = 0,
  });
  factory SakeMapSearchResult.fromJson(Map<String, dynamic> json) =>
      SakeMapSearchResult(
        sakeId: (json['sakeId'] as num?)?.toInt(),
        searchToken: json['searchToken'] as String?,
        name: json['name'] as String? ?? '',
        brewery: json['brewery'] as String?,
        type: json['type'] as String?,
        primaryImageUrl:
            _nonEmptyString(json['primaryImageUrl']) ??
            _nonEmptyString(json['imageUrl']),
        thumbnailImageUrl: _nonEmptyString(json['thumbnailImageUrl']),
        isMaster: json['source'] == 'master',
        venueCount: (json['venueCount'] as num?)?.toInt() ?? 0,
      );
  final int? sakeId;
  final String? searchToken;
  final String name;
  final String? brewery;
  final String? type;
  final String? primaryImageUrl;
  final bool isMaster;
  final String? thumbnailImageUrl;
  final int venueCount;
}

String? _nonEmptyString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

abstract interface class SakeMapDataSource {
  Future<List<MapVenue>> fetchVenues({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    required double zoom,
    int? sakeId,
    String? sakeToken,
    int? sinceDays,
  });

  Future<List<VenueSake>> fetchVenueSakes(String venueId);

  Future<List<SakeMapSearchResult>> searchSakes(String query);
}

class PlaceMapRepository implements SakeMapDataSource {
  PlaceMapRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<PlaceCandidate>> searchNearby({
    required double latitude,
    required double longitude,
    int radiusMeters = 1000,
  }) async {
    final response = await _apiClient.searchNearbyPlaces({
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'locale': await resolveAppLocaleLanguageCode(),
    });
    return _parseList(response.body, 'places', PlaceCandidate.fromJson);
  }

  Future<List<PlaceCandidate>> searchByName(
    String query, {
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{
      'query': query,
      'locale': await resolveAppLocaleLanguageCode(),
    };
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
    }
    final response = await _apiClient.searchTextPlaces(body);
    return _parseList(response.body, 'places', PlaceCandidate.fromJson);
  }

  Future<MapContributionSaveResult?> savePlace({
    required String savedId,
    required DrinkingPlace place,
  }) async {
    final response = await _apiClient.saveSavedSakePlace(savedId, {
      'providerPlaceId': place.providerPlaceId,
      'mapPhotoPublic': place.mapPhotoPublic,
      'locale': await resolveAppLocaleLanguageCode(),
    });
    if (!response.isSuccessful || response.body is! Map) return null;
    final raw = Map<String, dynamic>.from(response.body as Map);
    final result = raw['drinkingPlace'];
    if (result is! Map) return null;
    return MapContributionSaveResult(
      drinkingPlace: DrinkingPlace.fromJson(Map<String, dynamic>.from(result)),
      pointsAwarded: (raw['pointsAwarded'] as num?)?.toInt() ?? 0,
      totalMapContributionPoints:
          (raw['totalMapContributionPoints'] as num?)?.toInt() ?? 0,
    );
  }

  Future<bool> deletePlace(String savedId) async =>
      (await _apiClient.deleteSavedSakePlace(savedId)).isSuccessful;

  Future<MapContributionSaveResult?> updateMapPhotoVisibility({
    required String savedId,
    required bool mapPhotoPublic,
  }) async {
    final response = await _apiClient.updateSavedSakeMapPhotoVisibility(
      savedId,
      {'mapPhotoPublic': mapPhotoPublic},
    );
    if (!response.isSuccessful || response.body is! Map) return null;
    final raw = Map<String, dynamic>.from(response.body as Map);
    final place = raw['drinkingPlace'];
    if (place is! Map) return null;
    return MapContributionSaveResult(
      drinkingPlace: DrinkingPlace.fromJson(Map<String, dynamic>.from(place)),
      pointsAwarded: (raw['pointsAwarded'] as num?)?.toInt() ?? 0,
      totalMapContributionPoints:
          (raw['totalMapContributionPoints'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<MapVenue>> fetchVenues({
    required double swLat,
    required double swLng,
    required double neLat,
    required double neLng,
    required double zoom,
    int? sakeId,
    String? sakeToken,
    int? sinceDays,
  }) async {
    final response = await _apiClient.fetchMapVenues(
      swLat: swLat,
      swLng: swLng,
      neLat: neLat,
      neLng: neLng,
      zoom: zoom,
      sakeId: sakeId,
      sakeToken: sakeToken,
      sinceDays: sinceDays,
    );
    return _parseList(response.body, 'venues', MapVenue.fromJson);
  }

  @override
  Future<List<VenueSake>> fetchVenueSakes(String venueId) async {
    final response = await _apiClient.fetchVenueSakes(venueId);
    return _parseList(response.body, 'sakes', VenueSake.fromJson);
  }

  @override
  Future<List<SakeMapSearchResult>> searchSakes(String query) async {
    final response = await _apiClient.searchSakesForMap(query);
    return _parseList(
      response.body,
      'sakes',
      SakeMapSearchResult.fromJson,
    ).where((sake) => sake.venueCount > 0).toList(growable: false);
  }

  Future<List<SakeMapSearchResult>> searchSakeMasters(String query) async {
    final response = await _apiClient.searchSakeMasters(query);
    return _parseList(response.body, 'sakes', SakeMapSearchResult.fromJson);
  }

  Future<List<SakeMapSearchResult>> discoverSakeMasters({
    String? prefecture,
    List<String>? flavors,
    List<String>? tastes,
    List<String>? designs,
  }) async {
    final response = await _apiClient.discoverSakeMasters({
      if (prefecture != null) 'prefecture': prefecture,
      if (flavors != null && flavors.isNotEmpty) 'flavors': flavors,
      if (tastes != null && tastes.isNotEmpty) 'tastes': tastes,
      if (designs != null && designs.isNotEmpty) 'designs': designs,
      'limit': 50,
    });
    if (!response.isSuccessful) {
      throw StateError('日本酒の条件検索に失敗しました。');
    }
    return _parseList(response.body, 'sakes', SakeMapSearchResult.fromJson);
  }

  List<T> _parseList<T>(
    dynamic body,
    String key,
    T Function(Map<String, dynamic>) parser,
  ) {
    if (body is! Map || body[key] is! List) return const [];
    return (body[key] as List)
        .whereType<Map>()
        .map((item) => parser(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }
}
