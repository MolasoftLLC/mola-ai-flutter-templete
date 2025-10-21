import 'package:freezed_annotation/freezed_annotation.dart';

part 'sake_menu_recognition_response.freezed.dart';
part 'sake_menu_recognition_response.g.dart';

@freezed
class SakeMenuRecognitionResponse with _$SakeMenuRecognitionResponse {
  const factory SakeMenuRecognitionResponse({
    List<Sake>? sakes,
  }) = _SakeMenuRecognitionResponse;

  factory SakeMenuRecognitionResponse.fromJson(Map<String, dynamic> json) =>
      _$SakeMenuRecognitionResponseFromJson(json);
}

@JsonEnum(alwaysCreate: true)
enum SavedSakeSyncStatus {
  localOnly,
  serverSynced,
}

@freezed
class Sake with _$Sake {
  const factory Sake({
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
    List<String>? userTags,
    String? savedId,
    List<String>? imagePaths,
    @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
    @Default(SavedSakeSyncStatus.localOnly)
    SavedSakeSyncStatus syncStatus,
  }) = _Sake;

  factory Sake.fromJson(Map<String, dynamic> json) => _$SakeFromJson(json);
}
