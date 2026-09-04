import 'package:freezed_annotation/freezed_annotation.dart';

part 'sake_menu_recognition_response.freezed.dart';
part 'sake_menu_recognition_response.g.dart';

@freezed
class SakeMenuRecognitionResponse with _$SakeMenuRecognitionResponse {
  const factory SakeMenuRecognitionResponse({List<Sake>? sakes}) =
      _SakeMenuRecognitionResponse;

  factory SakeMenuRecognitionResponse.fromJson(Map<String, dynamic> json) =>
      _$SakeMenuRecognitionResponseFromJson(json);
}

@JsonEnum(alwaysCreate: true)
enum SavedSakeSyncStatus { localOnly, serverSynced }

@JsonEnum(alwaysCreate: true)
enum PlaceVisibility {
  @JsonValue('private')
  private,
  @JsonValue('public')
  public,
}

@freezed
class DrinkingPlace with _$DrinkingPlace {
  const factory DrinkingPlace({
    String? venueId,
    String? providerPlaceId,
    required String displayName,
    String? formattedAddress,
    double? latitude,
    double? longitude,
    @Default(PlaceVisibility.private) PlaceVisibility visibility,
  }) = _DrinkingPlace;

  factory DrinkingPlace.fromJson(Map<String, dynamic> json) =>
      _$DrinkingPlaceFromJson(json);
}

@freezed
class Sake with _$Sake {
  const factory Sake({
    int? sakeId,
    int? brandId,
    String? name,
    String? brewery,
    List<String>? types,
    String? taste,
    int? sakeMeterValue,
    String? type,
    String? price,
    String? description,
    int? recommendationScore,
    String? impression,
    String? place,
    DrinkingPlace? drinkingPlace,
    List<String>? userTags,
    String? savedId,
    List<String>? imagePaths,
    String? username,
    String? displayName,
    String? iconUrl,
    String? prefectureCode,
    String? primaryImageUrl,
    Map<String, dynamic>? community,
    List<Map<String, dynamic>>? sameBrandSakes,
    @Default(0) int envyCount,
    @JsonKey(name: 'is_public') @Default(false) bool isPublic,
    @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
    @Default(SavedSakeSyncStatus.localOnly)
    SavedSakeSyncStatus syncStatus,
  }) = _Sake;

  factory Sake.fromJson(Map<String, dynamic> json) => _$SakeFromJson(json);
}
