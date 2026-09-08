// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sake_menu_recognition_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SakeMenuRecognitionResponse _$SakeMenuRecognitionResponseFromJson(
  Map<String, dynamic> json,
) {
  return _SakeMenuRecognitionResponse.fromJson(json);
}

/// @nodoc
mixin _$SakeMenuRecognitionResponse {
  List<Sake>? get sakes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SakeMenuRecognitionResponseCopyWith<SakeMenuRecognitionResponse>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SakeMenuRecognitionResponseCopyWith<$Res> {
  factory $SakeMenuRecognitionResponseCopyWith(
    SakeMenuRecognitionResponse value,
    $Res Function(SakeMenuRecognitionResponse) then,
  ) =
      _$SakeMenuRecognitionResponseCopyWithImpl<
        $Res,
        SakeMenuRecognitionResponse
      >;
  @useResult
  $Res call({List<Sake>? sakes});
}

/// @nodoc
class _$SakeMenuRecognitionResponseCopyWithImpl<
  $Res,
  $Val extends SakeMenuRecognitionResponse
>
    implements $SakeMenuRecognitionResponseCopyWith<$Res> {
  _$SakeMenuRecognitionResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sakes = freezed}) {
    return _then(
      _value.copyWith(
            sakes: freezed == sakes
                ? _value.sakes
                : sakes // ignore: cast_nullable_to_non_nullable
                      as List<Sake>?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SakeMenuRecognitionResponseImplCopyWith<$Res>
    implements $SakeMenuRecognitionResponseCopyWith<$Res> {
  factory _$$SakeMenuRecognitionResponseImplCopyWith(
    _$SakeMenuRecognitionResponseImpl value,
    $Res Function(_$SakeMenuRecognitionResponseImpl) then,
  ) = __$$SakeMenuRecognitionResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Sake>? sakes});
}

/// @nodoc
class __$$SakeMenuRecognitionResponseImplCopyWithImpl<$Res>
    extends
        _$SakeMenuRecognitionResponseCopyWithImpl<
          $Res,
          _$SakeMenuRecognitionResponseImpl
        >
    implements _$$SakeMenuRecognitionResponseImplCopyWith<$Res> {
  __$$SakeMenuRecognitionResponseImplCopyWithImpl(
    _$SakeMenuRecognitionResponseImpl _value,
    $Res Function(_$SakeMenuRecognitionResponseImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? sakes = freezed}) {
    return _then(
      _$SakeMenuRecognitionResponseImpl(
        sakes: freezed == sakes
            ? _value._sakes
            : sakes // ignore: cast_nullable_to_non_nullable
                  as List<Sake>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SakeMenuRecognitionResponseImpl
    implements _SakeMenuRecognitionResponse {
  const _$SakeMenuRecognitionResponseImpl({final List<Sake>? sakes})
    : _sakes = sakes;

  factory _$SakeMenuRecognitionResponseImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$SakeMenuRecognitionResponseImplFromJson(json);

  final List<Sake>? _sakes;
  @override
  List<Sake>? get sakes {
    final value = _sakes;
    if (value == null) return null;
    if (_sakes is EqualUnmodifiableListView) return _sakes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'SakeMenuRecognitionResponse(sakes: $sakes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SakeMenuRecognitionResponseImpl &&
            const DeepCollectionEquality().equals(other._sakes, _sakes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_sakes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SakeMenuRecognitionResponseImplCopyWith<_$SakeMenuRecognitionResponseImpl>
  get copyWith =>
      __$$SakeMenuRecognitionResponseImplCopyWithImpl<
        _$SakeMenuRecognitionResponseImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SakeMenuRecognitionResponseImplToJson(this);
  }
}

abstract class _SakeMenuRecognitionResponse
    implements SakeMenuRecognitionResponse {
  const factory _SakeMenuRecognitionResponse({final List<Sake>? sakes}) =
      _$SakeMenuRecognitionResponseImpl;

  factory _SakeMenuRecognitionResponse.fromJson(Map<String, dynamic> json) =
      _$SakeMenuRecognitionResponseImpl.fromJson;

  @override
  List<Sake>? get sakes;
  @override
  @JsonKey(ignore: true)
  _$$SakeMenuRecognitionResponseImplCopyWith<_$SakeMenuRecognitionResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}

DrinkingPlace _$DrinkingPlaceFromJson(Map<String, dynamic> json) {
  return _DrinkingPlace.fromJson(json);
}

/// @nodoc
mixin _$DrinkingPlace {
  String? get venueId => throw _privateConstructorUsedError;
  String? get providerPlaceId => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get formattedAddress => throw _privateConstructorUsedError;
  double? get latitude => throw _privateConstructorUsedError;
  double? get longitude => throw _privateConstructorUsedError;
  PlaceVisibility get visibility => throw _privateConstructorUsedError;
  bool get mapPhotoPublic => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DrinkingPlaceCopyWith<DrinkingPlace> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DrinkingPlaceCopyWith<$Res> {
  factory $DrinkingPlaceCopyWith(
    DrinkingPlace value,
    $Res Function(DrinkingPlace) then,
  ) = _$DrinkingPlaceCopyWithImpl<$Res, DrinkingPlace>;
  @useResult
  $Res call({
    String? venueId,
    String? providerPlaceId,
    String displayName,
    String? formattedAddress,
    double? latitude,
    double? longitude,
    PlaceVisibility visibility,
    bool mapPhotoPublic,
  });
}

/// @nodoc
class _$DrinkingPlaceCopyWithImpl<$Res, $Val extends DrinkingPlace>
    implements $DrinkingPlaceCopyWith<$Res> {
  _$DrinkingPlaceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? venueId = freezed,
    Object? providerPlaceId = freezed,
    Object? displayName = null,
    Object? formattedAddress = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? visibility = null,
    Object? mapPhotoPublic = null,
  }) {
    return _then(
      _value.copyWith(
            venueId: freezed == venueId
                ? _value.venueId
                : venueId // ignore: cast_nullable_to_non_nullable
                      as String?,
            providerPlaceId: freezed == providerPlaceId
                ? _value.providerPlaceId
                : providerPlaceId // ignore: cast_nullable_to_non_nullable
                      as String?,
            displayName: null == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String,
            formattedAddress: freezed == formattedAddress
                ? _value.formattedAddress
                : formattedAddress // ignore: cast_nullable_to_non_nullable
                      as String?,
            latitude: freezed == latitude
                ? _value.latitude
                : latitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            longitude: freezed == longitude
                ? _value.longitude
                : longitude // ignore: cast_nullable_to_non_nullable
                      as double?,
            visibility: null == visibility
                ? _value.visibility
                : visibility // ignore: cast_nullable_to_non_nullable
                      as PlaceVisibility,
            mapPhotoPublic: null == mapPhotoPublic
                ? _value.mapPhotoPublic
                : mapPhotoPublic // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$DrinkingPlaceImplCopyWith<$Res>
    implements $DrinkingPlaceCopyWith<$Res> {
  factory _$$DrinkingPlaceImplCopyWith(
    _$DrinkingPlaceImpl value,
    $Res Function(_$DrinkingPlaceImpl) then,
  ) = __$$DrinkingPlaceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? venueId,
    String? providerPlaceId,
    String displayName,
    String? formattedAddress,
    double? latitude,
    double? longitude,
    PlaceVisibility visibility,
    bool mapPhotoPublic,
  });
}

/// @nodoc
class __$$DrinkingPlaceImplCopyWithImpl<$Res>
    extends _$DrinkingPlaceCopyWithImpl<$Res, _$DrinkingPlaceImpl>
    implements _$$DrinkingPlaceImplCopyWith<$Res> {
  __$$DrinkingPlaceImplCopyWithImpl(
    _$DrinkingPlaceImpl _value,
    $Res Function(_$DrinkingPlaceImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? venueId = freezed,
    Object? providerPlaceId = freezed,
    Object? displayName = null,
    Object? formattedAddress = freezed,
    Object? latitude = freezed,
    Object? longitude = freezed,
    Object? visibility = null,
    Object? mapPhotoPublic = null,
  }) {
    return _then(
      _$DrinkingPlaceImpl(
        venueId: freezed == venueId
            ? _value.venueId
            : venueId // ignore: cast_nullable_to_non_nullable
                  as String?,
        providerPlaceId: freezed == providerPlaceId
            ? _value.providerPlaceId
            : providerPlaceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        displayName: null == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        formattedAddress: freezed == formattedAddress
            ? _value.formattedAddress
            : formattedAddress // ignore: cast_nullable_to_non_nullable
                  as String?,
        latitude: freezed == latitude
            ? _value.latitude
            : latitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        longitude: freezed == longitude
            ? _value.longitude
            : longitude // ignore: cast_nullable_to_non_nullable
                  as double?,
        visibility: null == visibility
            ? _value.visibility
            : visibility // ignore: cast_nullable_to_non_nullable
                  as PlaceVisibility,
        mapPhotoPublic: null == mapPhotoPublic
            ? _value.mapPhotoPublic
            : mapPhotoPublic // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$DrinkingPlaceImpl implements _DrinkingPlace {
  const _$DrinkingPlaceImpl({
    this.venueId,
    this.providerPlaceId,
    required this.displayName,
    this.formattedAddress,
    this.latitude,
    this.longitude,
    this.visibility = PlaceVisibility.private,
    this.mapPhotoPublic = false,
  });

  factory _$DrinkingPlaceImpl.fromJson(Map<String, dynamic> json) =>
      _$$DrinkingPlaceImplFromJson(json);

  @override
  final String? venueId;
  @override
  final String? providerPlaceId;
  @override
  final String displayName;
  @override
  final String? formattedAddress;
  @override
  final double? latitude;
  @override
  final double? longitude;
  @override
  @JsonKey()
  final PlaceVisibility visibility;
  @override
  @JsonKey()
  final bool mapPhotoPublic;

  @override
  String toString() {
    return 'DrinkingPlace(venueId: $venueId, providerPlaceId: $providerPlaceId, displayName: $displayName, formattedAddress: $formattedAddress, latitude: $latitude, longitude: $longitude, visibility: $visibility, mapPhotoPublic: $mapPhotoPublic)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DrinkingPlaceImpl &&
            (identical(other.venueId, venueId) || other.venueId == venueId) &&
            (identical(other.providerPlaceId, providerPlaceId) ||
                other.providerPlaceId == providerPlaceId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.formattedAddress, formattedAddress) ||
                other.formattedAddress == formattedAddress) &&
            (identical(other.latitude, latitude) ||
                other.latitude == latitude) &&
            (identical(other.longitude, longitude) ||
                other.longitude == longitude) &&
            (identical(other.visibility, visibility) ||
                other.visibility == visibility) &&
            (identical(other.mapPhotoPublic, mapPhotoPublic) ||
                other.mapPhotoPublic == mapPhotoPublic));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    venueId,
    providerPlaceId,
    displayName,
    formattedAddress,
    latitude,
    longitude,
    visibility,
    mapPhotoPublic,
  );

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DrinkingPlaceImplCopyWith<_$DrinkingPlaceImpl> get copyWith =>
      __$$DrinkingPlaceImplCopyWithImpl<_$DrinkingPlaceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DrinkingPlaceImplToJson(this);
  }
}

abstract class _DrinkingPlace implements DrinkingPlace {
  const factory _DrinkingPlace({
    final String? venueId,
    final String? providerPlaceId,
    required final String displayName,
    final String? formattedAddress,
    final double? latitude,
    final double? longitude,
    final PlaceVisibility visibility,
    final bool mapPhotoPublic,
  }) = _$DrinkingPlaceImpl;

  factory _DrinkingPlace.fromJson(Map<String, dynamic> json) =
      _$DrinkingPlaceImpl.fromJson;

  @override
  String? get venueId;
  @override
  String? get providerPlaceId;
  @override
  String get displayName;
  @override
  String? get formattedAddress;
  @override
  double? get latitude;
  @override
  double? get longitude;
  @override
  PlaceVisibility get visibility;
  @override
  bool get mapPhotoPublic;
  @override
  @JsonKey(ignore: true)
  _$$DrinkingPlaceImplCopyWith<_$DrinkingPlaceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Sake _$SakeFromJson(Map<String, dynamic> json) {
  return _Sake.fromJson(json);
}

/// @nodoc
mixin _$Sake {
  int? get sakeId => throw _privateConstructorUsedError;
  int? get brandId => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get brewery => throw _privateConstructorUsedError;
  List<String>? get types => throw _privateConstructorUsedError;
  String? get taste => throw _privateConstructorUsedError;
  int? get sakeMeterValue => throw _privateConstructorUsedError;
  String? get type => throw _privateConstructorUsedError;
  String? get price => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int? get recommendationScore => throw _privateConstructorUsedError;
  String? get impression => throw _privateConstructorUsedError;
  String? get place => throw _privateConstructorUsedError;
  DrinkingPlace? get drinkingPlace => throw _privateConstructorUsedError;
  List<String>? get userTags => throw _privateConstructorUsedError;
  String? get savedId => throw _privateConstructorUsedError;
  List<String>? get imagePaths => throw _privateConstructorUsedError;
  String? get username => throw _privateConstructorUsedError;
  String? get displayName => throw _privateConstructorUsedError;
  String? get iconUrl => throw _privateConstructorUsedError;
  String? get prefectureCode => throw _privateConstructorUsedError;
  String? get primaryImageUrl => throw _privateConstructorUsedError;
  Map<String, dynamic>? get community => throw _privateConstructorUsedError;
  List<Map<String, dynamic>>? get sameBrandSakes =>
      throw _privateConstructorUsedError;
  int get envyCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_public')
  bool get isPublic => throw _privateConstructorUsedError;
  @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
  SavedSakeSyncStatus get syncStatus => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SakeCopyWith<Sake> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SakeCopyWith<$Res> {
  factory $SakeCopyWith(Sake value, $Res Function(Sake) then) =
      _$SakeCopyWithImpl<$Res, Sake>;
  @useResult
  $Res call({
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
    int envyCount,
    @JsonKey(name: 'is_public') bool isPublic,
    @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
    SavedSakeSyncStatus syncStatus,
  });

  $DrinkingPlaceCopyWith<$Res>? get drinkingPlace;
}

/// @nodoc
class _$SakeCopyWithImpl<$Res, $Val extends Sake>
    implements $SakeCopyWith<$Res> {
  _$SakeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sakeId = freezed,
    Object? brandId = freezed,
    Object? name = freezed,
    Object? brewery = freezed,
    Object? types = freezed,
    Object? taste = freezed,
    Object? sakeMeterValue = freezed,
    Object? type = freezed,
    Object? price = freezed,
    Object? description = freezed,
    Object? recommendationScore = freezed,
    Object? impression = freezed,
    Object? place = freezed,
    Object? drinkingPlace = freezed,
    Object? userTags = freezed,
    Object? savedId = freezed,
    Object? imagePaths = freezed,
    Object? username = freezed,
    Object? displayName = freezed,
    Object? iconUrl = freezed,
    Object? prefectureCode = freezed,
    Object? primaryImageUrl = freezed,
    Object? community = freezed,
    Object? sameBrandSakes = freezed,
    Object? envyCount = null,
    Object? isPublic = null,
    Object? syncStatus = null,
  }) {
    return _then(
      _value.copyWith(
            sakeId: freezed == sakeId
                ? _value.sakeId
                : sakeId // ignore: cast_nullable_to_non_nullable
                      as int?,
            brandId: freezed == brandId
                ? _value.brandId
                : brandId // ignore: cast_nullable_to_non_nullable
                      as int?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            brewery: freezed == brewery
                ? _value.brewery
                : brewery // ignore: cast_nullable_to_non_nullable
                      as String?,
            types: freezed == types
                ? _value.types
                : types // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            taste: freezed == taste
                ? _value.taste
                : taste // ignore: cast_nullable_to_non_nullable
                      as String?,
            sakeMeterValue: freezed == sakeMeterValue
                ? _value.sakeMeterValue
                : sakeMeterValue // ignore: cast_nullable_to_non_nullable
                      as int?,
            type: freezed == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as String?,
            price: freezed == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as String?,
            description: freezed == description
                ? _value.description
                : description // ignore: cast_nullable_to_non_nullable
                      as String?,
            recommendationScore: freezed == recommendationScore
                ? _value.recommendationScore
                : recommendationScore // ignore: cast_nullable_to_non_nullable
                      as int?,
            impression: freezed == impression
                ? _value.impression
                : impression // ignore: cast_nullable_to_non_nullable
                      as String?,
            place: freezed == place
                ? _value.place
                : place // ignore: cast_nullable_to_non_nullable
                      as String?,
            drinkingPlace: freezed == drinkingPlace
                ? _value.drinkingPlace
                : drinkingPlace // ignore: cast_nullable_to_non_nullable
                      as DrinkingPlace?,
            userTags: freezed == userTags
                ? _value.userTags
                : userTags // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            savedId: freezed == savedId
                ? _value.savedId
                : savedId // ignore: cast_nullable_to_non_nullable
                      as String?,
            imagePaths: freezed == imagePaths
                ? _value.imagePaths
                : imagePaths // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
            username: freezed == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String?,
            displayName: freezed == displayName
                ? _value.displayName
                : displayName // ignore: cast_nullable_to_non_nullable
                      as String?,
            iconUrl: freezed == iconUrl
                ? _value.iconUrl
                : iconUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            prefectureCode: freezed == prefectureCode
                ? _value.prefectureCode
                : prefectureCode // ignore: cast_nullable_to_non_nullable
                      as String?,
            primaryImageUrl: freezed == primaryImageUrl
                ? _value.primaryImageUrl
                : primaryImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            community: freezed == community
                ? _value.community
                : community // ignore: cast_nullable_to_non_nullable
                      as Map<String, dynamic>?,
            sameBrandSakes: freezed == sameBrandSakes
                ? _value.sameBrandSakes
                : sameBrandSakes // ignore: cast_nullable_to_non_nullable
                      as List<Map<String, dynamic>>?,
            envyCount: null == envyCount
                ? _value.envyCount
                : envyCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isPublic: null == isPublic
                ? _value.isPublic
                : isPublic // ignore: cast_nullable_to_non_nullable
                      as bool,
            syncStatus: null == syncStatus
                ? _value.syncStatus
                : syncStatus // ignore: cast_nullable_to_non_nullable
                      as SavedSakeSyncStatus,
          )
          as $Val,
    );
  }

  @override
  @pragma('vm:prefer-inline')
  $DrinkingPlaceCopyWith<$Res>? get drinkingPlace {
    if (_value.drinkingPlace == null) {
      return null;
    }

    return $DrinkingPlaceCopyWith<$Res>(_value.drinkingPlace!, (value) {
      return _then(_value.copyWith(drinkingPlace: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SakeImplCopyWith<$Res> implements $SakeCopyWith<$Res> {
  factory _$$SakeImplCopyWith(
    _$SakeImpl value,
    $Res Function(_$SakeImpl) then,
  ) = __$$SakeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
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
    int envyCount,
    @JsonKey(name: 'is_public') bool isPublic,
    @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
    SavedSakeSyncStatus syncStatus,
  });

  @override
  $DrinkingPlaceCopyWith<$Res>? get drinkingPlace;
}

/// @nodoc
class __$$SakeImplCopyWithImpl<$Res>
    extends _$SakeCopyWithImpl<$Res, _$SakeImpl>
    implements _$$SakeImplCopyWith<$Res> {
  __$$SakeImplCopyWithImpl(_$SakeImpl _value, $Res Function(_$SakeImpl) _then)
    : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sakeId = freezed,
    Object? brandId = freezed,
    Object? name = freezed,
    Object? brewery = freezed,
    Object? types = freezed,
    Object? taste = freezed,
    Object? sakeMeterValue = freezed,
    Object? type = freezed,
    Object? price = freezed,
    Object? description = freezed,
    Object? recommendationScore = freezed,
    Object? impression = freezed,
    Object? place = freezed,
    Object? drinkingPlace = freezed,
    Object? userTags = freezed,
    Object? savedId = freezed,
    Object? imagePaths = freezed,
    Object? username = freezed,
    Object? displayName = freezed,
    Object? iconUrl = freezed,
    Object? prefectureCode = freezed,
    Object? primaryImageUrl = freezed,
    Object? community = freezed,
    Object? sameBrandSakes = freezed,
    Object? envyCount = null,
    Object? isPublic = null,
    Object? syncStatus = null,
  }) {
    return _then(
      _$SakeImpl(
        sakeId: freezed == sakeId
            ? _value.sakeId
            : sakeId // ignore: cast_nullable_to_non_nullable
                  as int?,
        brandId: freezed == brandId
            ? _value.brandId
            : brandId // ignore: cast_nullable_to_non_nullable
                  as int?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        brewery: freezed == brewery
            ? _value.brewery
            : brewery // ignore: cast_nullable_to_non_nullable
                  as String?,
        types: freezed == types
            ? _value._types
            : types // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        taste: freezed == taste
            ? _value.taste
            : taste // ignore: cast_nullable_to_non_nullable
                  as String?,
        sakeMeterValue: freezed == sakeMeterValue
            ? _value.sakeMeterValue
            : sakeMeterValue // ignore: cast_nullable_to_non_nullable
                  as int?,
        type: freezed == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as String?,
        price: freezed == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as String?,
        description: freezed == description
            ? _value.description
            : description // ignore: cast_nullable_to_non_nullable
                  as String?,
        recommendationScore: freezed == recommendationScore
            ? _value.recommendationScore
            : recommendationScore // ignore: cast_nullable_to_non_nullable
                  as int?,
        impression: freezed == impression
            ? _value.impression
            : impression // ignore: cast_nullable_to_non_nullable
                  as String?,
        place: freezed == place
            ? _value.place
            : place // ignore: cast_nullable_to_non_nullable
                  as String?,
        drinkingPlace: freezed == drinkingPlace
            ? _value.drinkingPlace
            : drinkingPlace // ignore: cast_nullable_to_non_nullable
                  as DrinkingPlace?,
        userTags: freezed == userTags
            ? _value._userTags
            : userTags // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        savedId: freezed == savedId
            ? _value.savedId
            : savedId // ignore: cast_nullable_to_non_nullable
                  as String?,
        imagePaths: freezed == imagePaths
            ? _value._imagePaths
            : imagePaths // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
        username: freezed == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String?,
        displayName: freezed == displayName
            ? _value.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String?,
        iconUrl: freezed == iconUrl
            ? _value.iconUrl
            : iconUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        prefectureCode: freezed == prefectureCode
            ? _value.prefectureCode
            : prefectureCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        primaryImageUrl: freezed == primaryImageUrl
            ? _value.primaryImageUrl
            : primaryImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        community: freezed == community
            ? _value._community
            : community // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>?,
        sameBrandSakes: freezed == sameBrandSakes
            ? _value._sameBrandSakes
            : sameBrandSakes // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>?,
        envyCount: null == envyCount
            ? _value.envyCount
            : envyCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isPublic: null == isPublic
            ? _value.isPublic
            : isPublic // ignore: cast_nullable_to_non_nullable
                  as bool,
        syncStatus: null == syncStatus
            ? _value.syncStatus
            : syncStatus // ignore: cast_nullable_to_non_nullable
                  as SavedSakeSyncStatus,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SakeImpl implements _Sake {
  const _$SakeImpl({
    this.sakeId,
    this.brandId,
    this.name,
    this.brewery,
    final List<String>? types,
    this.taste,
    this.sakeMeterValue,
    this.type,
    this.price,
    this.description,
    this.recommendationScore,
    this.impression,
    this.place,
    this.drinkingPlace,
    final List<String>? userTags,
    this.savedId,
    final List<String>? imagePaths,
    this.username,
    this.displayName,
    this.iconUrl,
    this.prefectureCode,
    this.primaryImageUrl,
    final Map<String, dynamic>? community,
    final List<Map<String, dynamic>>? sameBrandSakes,
    this.envyCount = 0,
    @JsonKey(name: 'is_public') this.isPublic = false,
    @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
    this.syncStatus = SavedSakeSyncStatus.localOnly,
  }) : _types = types,
       _userTags = userTags,
       _imagePaths = imagePaths,
       _community = community,
       _sameBrandSakes = sameBrandSakes;

  factory _$SakeImpl.fromJson(Map<String, dynamic> json) =>
      _$$SakeImplFromJson(json);

  @override
  final int? sakeId;
  @override
  final int? brandId;
  @override
  final String? name;
  @override
  final String? brewery;
  final List<String>? _types;
  @override
  List<String>? get types {
    final value = _types;
    if (value == null) return null;
    if (_types is EqualUnmodifiableListView) return _types;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? taste;
  @override
  final int? sakeMeterValue;
  @override
  final String? type;
  @override
  final String? price;
  @override
  final String? description;
  @override
  final int? recommendationScore;
  @override
  final String? impression;
  @override
  final String? place;
  @override
  final DrinkingPlace? drinkingPlace;
  final List<String>? _userTags;
  @override
  List<String>? get userTags {
    final value = _userTags;
    if (value == null) return null;
    if (_userTags is EqualUnmodifiableListView) return _userTags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? savedId;
  final List<String>? _imagePaths;
  @override
  List<String>? get imagePaths {
    final value = _imagePaths;
    if (value == null) return null;
    if (_imagePaths is EqualUnmodifiableListView) return _imagePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? username;
  @override
  final String? displayName;
  @override
  final String? iconUrl;
  @override
  final String? prefectureCode;
  @override
  final String? primaryImageUrl;
  final Map<String, dynamic>? _community;
  @override
  Map<String, dynamic>? get community {
    final value = _community;
    if (value == null) return null;
    if (_community is EqualUnmodifiableMapView) return _community;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  final List<Map<String, dynamic>>? _sameBrandSakes;
  @override
  List<Map<String, dynamic>>? get sameBrandSakes {
    final value = _sameBrandSakes;
    if (value == null) return null;
    if (_sameBrandSakes is EqualUnmodifiableListView) return _sameBrandSakes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  @JsonKey()
  final int envyCount;
  @override
  @JsonKey(name: 'is_public')
  final bool isPublic;
  @override
  @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
  final SavedSakeSyncStatus syncStatus;

  @override
  String toString() {
    return 'Sake(sakeId: $sakeId, brandId: $brandId, name: $name, brewery: $brewery, types: $types, taste: $taste, sakeMeterValue: $sakeMeterValue, type: $type, price: $price, description: $description, recommendationScore: $recommendationScore, impression: $impression, place: $place, drinkingPlace: $drinkingPlace, userTags: $userTags, savedId: $savedId, imagePaths: $imagePaths, username: $username, displayName: $displayName, iconUrl: $iconUrl, prefectureCode: $prefectureCode, primaryImageUrl: $primaryImageUrl, community: $community, sameBrandSakes: $sameBrandSakes, envyCount: $envyCount, isPublic: $isPublic, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SakeImpl &&
            (identical(other.sakeId, sakeId) || other.sakeId == sakeId) &&
            (identical(other.brandId, brandId) || other.brandId == brandId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.brewery, brewery) || other.brewery == brewery) &&
            const DeepCollectionEquality().equals(other._types, _types) &&
            (identical(other.taste, taste) || other.taste == taste) &&
            (identical(other.sakeMeterValue, sakeMeterValue) ||
                other.sakeMeterValue == sakeMeterValue) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.recommendationScore, recommendationScore) ||
                other.recommendationScore == recommendationScore) &&
            (identical(other.impression, impression) ||
                other.impression == impression) &&
            (identical(other.place, place) || other.place == place) &&
            (identical(other.drinkingPlace, drinkingPlace) ||
                other.drinkingPlace == drinkingPlace) &&
            const DeepCollectionEquality().equals(other._userTags, _userTags) &&
            (identical(other.savedId, savedId) || other.savedId == savedId) &&
            const DeepCollectionEquality().equals(
              other._imagePaths,
              _imagePaths,
            ) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.iconUrl, iconUrl) || other.iconUrl == iconUrl) &&
            (identical(other.prefectureCode, prefectureCode) ||
                other.prefectureCode == prefectureCode) &&
            (identical(other.primaryImageUrl, primaryImageUrl) ||
                other.primaryImageUrl == primaryImageUrl) &&
            const DeepCollectionEquality().equals(
              other._community,
              _community,
            ) &&
            const DeepCollectionEquality().equals(
              other._sameBrandSakes,
              _sameBrandSakes,
            ) &&
            (identical(other.envyCount, envyCount) ||
                other.envyCount == envyCount) &&
            (identical(other.isPublic, isPublic) ||
                other.isPublic == isPublic) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
    runtimeType,
    sakeId,
    brandId,
    name,
    brewery,
    const DeepCollectionEquality().hash(_types),
    taste,
    sakeMeterValue,
    type,
    price,
    description,
    recommendationScore,
    impression,
    place,
    drinkingPlace,
    const DeepCollectionEquality().hash(_userTags),
    savedId,
    const DeepCollectionEquality().hash(_imagePaths),
    username,
    displayName,
    iconUrl,
    prefectureCode,
    primaryImageUrl,
    const DeepCollectionEquality().hash(_community),
    const DeepCollectionEquality().hash(_sameBrandSakes),
    envyCount,
    isPublic,
    syncStatus,
  ]);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SakeImplCopyWith<_$SakeImpl> get copyWith =>
      __$$SakeImplCopyWithImpl<_$SakeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SakeImplToJson(this);
  }
}

abstract class _Sake implements Sake {
  const factory _Sake({
    final int? sakeId,
    final int? brandId,
    final String? name,
    final String? brewery,
    final List<String>? types,
    final String? taste,
    final int? sakeMeterValue,
    final String? type,
    final String? price,
    final String? description,
    final int? recommendationScore,
    final String? impression,
    final String? place,
    final DrinkingPlace? drinkingPlace,
    final List<String>? userTags,
    final String? savedId,
    final List<String>? imagePaths,
    final String? username,
    final String? displayName,
    final String? iconUrl,
    final String? prefectureCode,
    final String? primaryImageUrl,
    final Map<String, dynamic>? community,
    final List<Map<String, dynamic>>? sameBrandSakes,
    final int envyCount,
    @JsonKey(name: 'is_public') final bool isPublic,
    @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
    final SavedSakeSyncStatus syncStatus,
  }) = _$SakeImpl;

  factory _Sake.fromJson(Map<String, dynamic> json) = _$SakeImpl.fromJson;

  @override
  int? get sakeId;
  @override
  int? get brandId;
  @override
  String? get name;
  @override
  String? get brewery;
  @override
  List<String>? get types;
  @override
  String? get taste;
  @override
  int? get sakeMeterValue;
  @override
  String? get type;
  @override
  String? get price;
  @override
  String? get description;
  @override
  int? get recommendationScore;
  @override
  String? get impression;
  @override
  String? get place;
  @override
  DrinkingPlace? get drinkingPlace;
  @override
  List<String>? get userTags;
  @override
  String? get savedId;
  @override
  List<String>? get imagePaths;
  @override
  String? get username;
  @override
  String? get displayName;
  @override
  String? get iconUrl;
  @override
  String? get prefectureCode;
  @override
  String? get primaryImageUrl;
  @override
  Map<String, dynamic>? get community;
  @override
  List<Map<String, dynamic>>? get sameBrandSakes;
  @override
  int get envyCount;
  @override
  @JsonKey(name: 'is_public')
  bool get isPublic;
  @override
  @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
  SavedSakeSyncStatus get syncStatus;
  @override
  @JsonKey(ignore: true)
  _$$SakeImplCopyWith<_$SakeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
