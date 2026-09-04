// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sake_menu_recognition_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SakeMenuRecognitionResponseImpl _$$SakeMenuRecognitionResponseImplFromJson(
  Map<String, dynamic> json,
) => _$SakeMenuRecognitionResponseImpl(
  sakes: (json['sakes'] as List<dynamic>?)
      ?.map((e) => Sake.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$SakeMenuRecognitionResponseImplToJson(
  _$SakeMenuRecognitionResponseImpl instance,
) => <String, dynamic>{'sakes': instance.sakes};

_$DrinkingPlaceImpl _$$DrinkingPlaceImplFromJson(Map<String, dynamic> json) =>
    _$DrinkingPlaceImpl(
      venueId: json['venueId'] as String?,
      providerPlaceId: json['providerPlaceId'] as String?,
      displayName: json['displayName'] as String,
      formattedAddress: json['formattedAddress'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      visibility:
          $enumDecodeNullable(_$PlaceVisibilityEnumMap, json['visibility']) ??
          PlaceVisibility.private,
    );

Map<String, dynamic> _$$DrinkingPlaceImplToJson(_$DrinkingPlaceImpl instance) =>
    <String, dynamic>{
      'venueId': instance.venueId,
      'providerPlaceId': instance.providerPlaceId,
      'displayName': instance.displayName,
      'formattedAddress': instance.formattedAddress,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'visibility': _$PlaceVisibilityEnumMap[instance.visibility]!,
    };

const _$PlaceVisibilityEnumMap = {
  PlaceVisibility.private: 'private',
  PlaceVisibility.public: 'public',
};

_$SakeImpl _$$SakeImplFromJson(Map<String, dynamic> json) => _$SakeImpl(
  sakeId: (json['sakeId'] as num?)?.toInt(),
  brandId: (json['brandId'] as num?)?.toInt(),
  name: json['name'] as String?,
  brewery: json['brewery'] as String?,
  types: (json['types'] as List<dynamic>?)?.map((e) => e as String).toList(),
  taste: json['taste'] as String?,
  sakeMeterValue: (json['sakeMeterValue'] as num?)?.toInt(),
  type: json['type'] as String?,
  price: json['price'] as String?,
  description: json['description'] as String?,
  recommendationScore: (json['recommendationScore'] as num?)?.toInt(),
  impression: json['impression'] as String?,
  place: json['place'] as String?,
  drinkingPlace: json['drinkingPlace'] == null
      ? null
      : DrinkingPlace.fromJson(json['drinkingPlace'] as Map<String, dynamic>),
  userTags: (json['userTags'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  savedId: json['savedId'] as String?,
  imagePaths: (json['imagePaths'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  username: json['username'] as String?,
  displayName: json['displayName'] as String?,
  iconUrl: json['iconUrl'] as String?,
  prefectureCode: json['prefectureCode'] as String?,
  primaryImageUrl: json['primaryImageUrl'] as String?,
  community: json['community'] as Map<String, dynamic>?,
  sameBrandSakes: (json['sameBrandSakes'] as List<dynamic>?)
      ?.map((e) => e as Map<String, dynamic>)
      .toList(),
  envyCount: (json['envyCount'] as num?)?.toInt() ?? 0,
  isPublic: json['is_public'] as bool? ?? false,
  syncStatus:
      $enumDecodeNullable(
        _$SavedSakeSyncStatusEnumMap,
        json['syncStatus'],
        unknownValue: SavedSakeSyncStatus.localOnly,
      ) ??
      SavedSakeSyncStatus.localOnly,
);

Map<String, dynamic> _$$SakeImplToJson(_$SakeImpl instance) =>
    <String, dynamic>{
      'sakeId': instance.sakeId,
      'brandId': instance.brandId,
      'name': instance.name,
      'brewery': instance.brewery,
      'types': instance.types,
      'taste': instance.taste,
      'sakeMeterValue': instance.sakeMeterValue,
      'type': instance.type,
      'price': instance.price,
      'description': instance.description,
      'recommendationScore': instance.recommendationScore,
      'impression': instance.impression,
      'place': instance.place,
      'drinkingPlace': instance.drinkingPlace,
      'userTags': instance.userTags,
      'savedId': instance.savedId,
      'imagePaths': instance.imagePaths,
      'username': instance.username,
      'displayName': instance.displayName,
      'iconUrl': instance.iconUrl,
      'prefectureCode': instance.prefectureCode,
      'primaryImageUrl': instance.primaryImageUrl,
      'community': instance.community,
      'sameBrandSakes': instance.sameBrandSakes,
      'envyCount': instance.envyCount,
      'is_public': instance.isPublic,
      'syncStatus': _$SavedSakeSyncStatusEnumMap[instance.syncStatus]!,
    };

const _$SavedSakeSyncStatusEnumMap = {
  SavedSakeSyncStatus.localOnly: 'localOnly',
  SavedSakeSyncStatus.serverSynced: 'serverSynced',
};
