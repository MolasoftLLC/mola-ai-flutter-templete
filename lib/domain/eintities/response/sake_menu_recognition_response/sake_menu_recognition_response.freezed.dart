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
  List<Sake> get sakes => throw _privateConstructorUsedError;

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
  $Res call({List<Sake> sakes});
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
    Object? sakes = null,
  }) {
    return _then(_value.copyWith(
      sakes: null == sakes
          ? _value.sakes
          : sakes // ignore: cast_nullable_to_non_nullable
              as List<Sake>,
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
  $Res call({List<Sake> sakes});
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
    Object? sakes = null,
  }) {
    return _then(_$SakeMenuRecognitionResponseImpl(
      sakes: null == sakes
          ? _value._sakes
          : sakes // ignore: cast_nullable_to_non_nullable
              as List<Sake>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SakeMenuRecognitionResponseImpl
    implements _SakeMenuRecognitionResponse {
  const _$SakeMenuRecognitionResponseImpl({required final List<Sake> sakes})
      : _sakes = sakes;

  factory _$SakeMenuRecognitionResponseImpl.fromJson(
          Map<String, dynamic> json) =>
      _$$SakeMenuRecognitionResponseImplFromJson(json);

  final List<Sake> _sakes;
  @override
  List<Sake> get sakes {
    if (_sakes is EqualUnmodifiableListView) return _sakes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sakes);
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
  const factory _SakeMenuRecognitionResponse(
      {required final List<Sake> sakes}) = _$SakeMenuRecognitionResponseImpl;

  factory _SakeMenuRecognitionResponse.fromJson(Map<String, dynamic> json) =
      _$SakeMenuRecognitionResponseImpl.fromJson;

  @override
  List<Sake> get sakes;
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
  String get name => throw _privateConstructorUsedError;
  String get type => throw _privateConstructorUsedError;
  String get brewery => throw _privateConstructorUsedError;
  List<String> get types => throw _privateConstructorUsedError;
  String get taste => throw _privateConstructorUsedError;
  int get sakeMeterValue => throw _privateConstructorUsedError;

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
      {String name,
      String type,
      String brewery,
      List<String> types,
      String taste,
      int sakeMeterValue});
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
    Object? name = null,
    Object? type = null,
    Object? brewery = null,
    Object? types = null,
    Object? taste = null,
    Object? sakeMeterValue = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      brewery: null == brewery
          ? _value.brewery
          : brewery // ignore: cast_nullable_to_non_nullable
              as String,
      types: null == types
          ? _value.types
          : types // ignore: cast_nullable_to_non_nullable
              as List<String>,
      taste: null == taste
          ? _value.taste
          : taste // ignore: cast_nullable_to_non_nullable
              as String,
      sakeMeterValue: null == sakeMeterValue
          ? _value.sakeMeterValue
          : sakeMeterValue // ignore: cast_nullable_to_non_nullable
              as int,
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
      {String name,
      String type,
      String brewery,
      List<String> types,
      String taste,
      int sakeMeterValue});
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
    Object? name = null,
    Object? type = null,
    Object? brewery = null,
    Object? types = null,
    Object? taste = null,
    Object? sakeMeterValue = null,
  }) {
    return _then(_$SakeImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      brewery: null == brewery
          ? _value.brewery
          : brewery // ignore: cast_nullable_to_non_nullable
              as String,
      types: null == types
          ? _value._types
          : types // ignore: cast_nullable_to_non_nullable
              as List<String>,
      taste: null == taste
          ? _value.taste
          : taste // ignore: cast_nullable_to_non_nullable
              as String,
      sakeMeterValue: null == sakeMeterValue
          ? _value.sakeMeterValue
          : sakeMeterValue // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SakeImpl implements _Sake {
  const _$SakeImpl(
      {required this.name,
      required this.type,
      required this.brewery,
      required final List<String> types,
      required this.taste,
      required this.sakeMeterValue})
      : _types = types;

  factory _$SakeImpl.fromJson(Map<String, dynamic> json) =>
      _$$SakeImplFromJson(json);

  @override
  final String name;
  @override
  final String type;
  @override
  final String brewery;
  final List<String> _types;
  @override
  List<String> get types {
    if (_types is EqualUnmodifiableListView) return _types;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_types);
  }

  @override
  final String taste;
  @override
  final int sakeMeterValue;

  @override
  String toString() {
    return 'Sake(name: $name, type: $type, brewery: $brewery, types: $types, taste: $taste, sakeMeterValue: $sakeMeterValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SakeImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.brewery, brewery) || other.brewery == brewery) &&
            const DeepCollectionEquality().equals(other._types, _types) &&
            (identical(other.taste, taste) || other.taste == taste) &&
            (identical(other.sakeMeterValue, sakeMeterValue) ||
                other.sakeMeterValue == sakeMeterValue));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, name, type, brewery,
      const DeepCollectionEquality().hash(_types), taste, sakeMeterValue);

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
      {required final String name,
      required final String type,
      required final String brewery,
      required final List<String> types,
      required final String taste,
      required final int sakeMeterValue}) = _$SakeImpl;

  factory _Sake.fromJson(Map<String, dynamic> json) = _$SakeImpl.fromJson;

  @override
  String get name;
  @override
  String get type;
  @override
  String get brewery;
  @override
  List<String> get types;
  @override
  String get taste;
  @override
  int get sakeMeterValue;
  @override
  @JsonKey(ignore: true)
  _$$SakeImplCopyWith<_$SakeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
