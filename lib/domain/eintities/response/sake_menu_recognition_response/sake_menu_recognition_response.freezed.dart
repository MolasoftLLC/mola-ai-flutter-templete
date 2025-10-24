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
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SakeMenuRecognitionResponse _$SakeMenuRecognitionResponseFromJson(
    Map<String, dynamic> json) {
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
          $Res Function(SakeMenuRecognitionResponse) then) =
      _$SakeMenuRecognitionResponseCopyWithImpl<$Res,
          SakeMenuRecognitionResponse>;
  @useResult
  $Res call({List<Sake>? sakes});
}

/// @nodoc
class _$SakeMenuRecognitionResponseCopyWithImpl<$Res,
        $Val extends SakeMenuRecognitionResponse>
    implements $SakeMenuRecognitionResponseCopyWith<$Res> {
  _$SakeMenuRecognitionResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sakes = freezed,
  }) {
    return _then(_value.copyWith(
      sakes: freezed == sakes
          ? _value.sakes
          : sakes // ignore: cast_nullable_to_non_nullable
              as List<Sake>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SakeMenuRecognitionResponseImplCopyWith<$Res>
    implements $SakeMenuRecognitionResponseCopyWith<$Res> {
  factory _$$SakeMenuRecognitionResponseImplCopyWith(
          _$SakeMenuRecognitionResponseImpl value,
          $Res Function(_$SakeMenuRecognitionResponseImpl) then) =
      __$$SakeMenuRecognitionResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Sake>? sakes});
}

/// @nodoc
class __$$SakeMenuRecognitionResponseImplCopyWithImpl<$Res>
    extends _$SakeMenuRecognitionResponseCopyWithImpl<$Res,
        _$SakeMenuRecognitionResponseImpl>
    implements _$$SakeMenuRecognitionResponseImplCopyWith<$Res> {
  __$$SakeMenuRecognitionResponseImplCopyWithImpl(
      _$SakeMenuRecognitionResponseImpl _value,
      $Res Function(_$SakeMenuRecognitionResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sakes = freezed,
  }) {
    return _then(_$SakeMenuRecognitionResponseImpl(
      sakes: freezed == sakes
          ? _value._sakes
          : sakes // ignore: cast_nullable_to_non_nullable
              as List<Sake>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SakeMenuRecognitionResponseImpl
    implements _SakeMenuRecognitionResponse {
  const _$SakeMenuRecognitionResponseImpl({final List<Sake>? sakes})
      : _sakes = sakes;

  factory _$SakeMenuRecognitionResponseImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$SakeMenuRecognitionResponseImplFromJson(json);

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
      get copyWith => __$$SakeMenuRecognitionResponseImplCopyWithImpl<
          _$SakeMenuRecognitionResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SakeMenuRecognitionResponseImplToJson(
      this,
    );
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

Sake _$SakeFromJson(Map<String, dynamic> json) {
  return _Sake.fromJson(json);
}

/// @nodoc
mixin _$Sake {
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
  List<String>? get userTags => throw _privateConstructorUsedError;
  String? get savedId => throw _privateConstructorUsedError;
  List<String>? get imagePaths => throw _privateConstructorUsedError;
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
  $Res call(
      {String? name,
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
      SavedSakeSyncStatus syncStatus});
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
    Object? userTags = freezed,
    Object? savedId = freezed,
    Object? imagePaths = freezed,
    Object? syncStatus = null,
  }) {
    return _then(_value.copyWith(
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
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SavedSakeSyncStatus,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SakeImplCopyWith<$Res> implements $SakeCopyWith<$Res> {
  factory _$$SakeImplCopyWith(
          _$SakeImpl value, $Res Function(_$SakeImpl) then) =
      __$$SakeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? name,
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
      SavedSakeSyncStatus syncStatus});
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
    Object? userTags = freezed,
    Object? savedId = freezed,
    Object? imagePaths = freezed,
    Object? syncStatus = null,
  }) {
    return _then(_$SakeImpl(
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
      syncStatus: null == syncStatus
          ? _value.syncStatus
          : syncStatus // ignore: cast_nullable_to_non_nullable
              as SavedSakeSyncStatus,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SakeImpl implements _Sake {
  const _$SakeImpl(
      {this.name,
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
      final List<String>? userTags,
      this.savedId,
      final List<String>? imagePaths,
      @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
      this.syncStatus = SavedSakeSyncStatus.localOnly})
      : _types = types,
        _userTags = userTags,
        _imagePaths = imagePaths;

  factory _$SakeImpl.fromJson(Map<String, dynamic> json) =>
      _$$SakeImplFromJson(json);

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
  @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
  final SavedSakeSyncStatus syncStatus;

  @override
  String toString() {
    return 'Sake(name: $name, brewery: $brewery, types: $types, taste: $taste, sakeMeterValue: $sakeMeterValue, type: $type, price: $price, description: $description, recommendationScore: $recommendationScore, impression: $impression, place: $place, userTags: $userTags, savedId: $savedId, imagePaths: $imagePaths, syncStatus: $syncStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SakeImpl &&
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
            const DeepCollectionEquality().equals(other._userTags, _userTags) &&
            (identical(other.savedId, savedId) || other.savedId == savedId) &&
            const DeepCollectionEquality()
                .equals(other._imagePaths, _imagePaths) &&
            (identical(other.syncStatus, syncStatus) ||
                other.syncStatus == syncStatus));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
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
      const DeepCollectionEquality().hash(_userTags),
      savedId,
      const DeepCollectionEquality().hash(_imagePaths),
      syncStatus);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SakeImplCopyWith<_$SakeImpl> get copyWith =>
      __$$SakeImplCopyWithImpl<_$SakeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SakeImplToJson(
      this,
    );
  }
}

abstract class _Sake implements Sake {
  const factory _Sake(
      {final String? name,
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
      final List<String>? userTags,
      final String? savedId,
      final List<String>? imagePaths,
      @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
      final SavedSakeSyncStatus syncStatus}) = _$SakeImpl;

  factory _Sake.fromJson(Map<String, dynamic> json) = _$SakeImpl.fromJson;

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
  List<String>? get userTags;
  @override
  String? get savedId;
  @override
  List<String>? get imagePaths;
  @override
  @JsonKey(unknownEnumValue: SavedSakeSyncStatus.localOnly)
  SavedSakeSyncStatus get syncStatus;
  @override
  @JsonKey(ignore: true)
  _$$SakeImplCopyWith<_$SakeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
