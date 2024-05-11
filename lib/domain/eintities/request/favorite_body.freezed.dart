// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorite_body.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FavoriteBody _$FavoriteBodyFromJson(Map<String, dynamic> json) {
  return _FavoriteBody.fromJson(json);
}

/// @nodoc
mixin _$FavoriteBody {
  List<String>? get flavors => throw _privateConstructorUsedError;
  List<String>? get designs => throw _privateConstructorUsedError;
  List<String>? get tastes => throw _privateConstructorUsedError;
  String? get prefecture => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FavoriteBodyCopyWith<FavoriteBody> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FavoriteBodyCopyWith<$Res> {
  factory $FavoriteBodyCopyWith(
          FavoriteBody value, $Res Function(FavoriteBody) then) =
      _$FavoriteBodyCopyWithImpl<$Res, FavoriteBody>;
  @useResult
  $Res call(
      {List<String>? flavors,
      List<String>? designs,
      List<String>? tastes,
      String? prefecture});
}

/// @nodoc
class _$FavoriteBodyCopyWithImpl<$Res, $Val extends FavoriteBody>
    implements $FavoriteBodyCopyWith<$Res> {
  _$FavoriteBodyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flavors = freezed,
    Object? designs = freezed,
    Object? tastes = freezed,
    Object? prefecture = freezed,
  }) {
    return _then(_value.copyWith(
      flavors: freezed == flavors
          ? _value.flavors
          : flavors // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      designs: freezed == designs
          ? _value.designs
          : designs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      tastes: freezed == tastes
          ? _value.tastes
          : tastes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      prefecture: freezed == prefecture
          ? _value.prefecture
          : prefecture // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FavoriteBodyImplCopyWith<$Res>
    implements $FavoriteBodyCopyWith<$Res> {
  factory _$$FavoriteBodyImplCopyWith(
          _$FavoriteBodyImpl value, $Res Function(_$FavoriteBodyImpl) then) =
      __$$FavoriteBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<String>? flavors,
      List<String>? designs,
      List<String>? tastes,
      String? prefecture});
}

/// @nodoc
class __$$FavoriteBodyImplCopyWithImpl<$Res>
    extends _$FavoriteBodyCopyWithImpl<$Res, _$FavoriteBodyImpl>
    implements _$$FavoriteBodyImplCopyWith<$Res> {
  __$$FavoriteBodyImplCopyWithImpl(
      _$FavoriteBodyImpl _value, $Res Function(_$FavoriteBodyImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? flavors = freezed,
    Object? designs = freezed,
    Object? tastes = freezed,
    Object? prefecture = freezed,
  }) {
    return _then(_$FavoriteBodyImpl(
      flavors: freezed == flavors
          ? _value._flavors
          : flavors // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      designs: freezed == designs
          ? _value._designs
          : designs // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      tastes: freezed == tastes
          ? _value._tastes
          : tastes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      prefecture: freezed == prefecture
          ? _value.prefecture
          : prefecture // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FavoriteBodyImpl extends _FavoriteBody {
  _$FavoriteBodyImpl(
      {final List<String>? flavors,
      final List<String>? designs,
      final List<String>? tastes,
      this.prefecture})
      : _flavors = flavors,
        _designs = designs,
        _tastes = tastes,
        super._();

  factory _$FavoriteBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$FavoriteBodyImplFromJson(json);

  final List<String>? _flavors;
  @override
  List<String>? get flavors {
    final value = _flavors;
    if (value == null) return null;
    if (_flavors is EqualUnmodifiableListView) return _flavors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _designs;
  @override
  List<String>? get designs {
    final value = _designs;
    if (value == null) return null;
    if (_designs is EqualUnmodifiableListView) return _designs;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final List<String>? _tastes;
  @override
  List<String>? get tastes {
    final value = _tastes;
    if (value == null) return null;
    if (_tastes is EqualUnmodifiableListView) return _tastes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final String? prefecture;

  @override
  String toString() {
    return 'FavoriteBody(flavors: $flavors, designs: $designs, tastes: $tastes, prefecture: $prefecture)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FavoriteBodyImpl &&
            const DeepCollectionEquality().equals(other._flavors, _flavors) &&
            const DeepCollectionEquality().equals(other._designs, _designs) &&
            const DeepCollectionEquality().equals(other._tastes, _tastes) &&
            (identical(other.prefecture, prefecture) ||
                other.prefecture == prefecture));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_flavors),
      const DeepCollectionEquality().hash(_designs),
      const DeepCollectionEquality().hash(_tastes),
      prefecture);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FavoriteBodyImplCopyWith<_$FavoriteBodyImpl> get copyWith =>
      __$$FavoriteBodyImplCopyWithImpl<_$FavoriteBodyImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FavoriteBodyImplToJson(
      this,
    );
  }
}

abstract class _FavoriteBody extends FavoriteBody {
  factory _FavoriteBody(
      {final List<String>? flavors,
      final List<String>? designs,
      final List<String>? tastes,
      final String? prefecture}) = _$FavoriteBodyImpl;
  _FavoriteBody._() : super._();

  factory _FavoriteBody.fromJson(Map<String, dynamic> json) =
      _$FavoriteBodyImpl.fromJson;

  @override
  List<String>? get flavors;
  @override
  List<String>? get designs;
  @override
  List<String>? get tastes;
  @override
  String? get prefecture;
  @override
  @JsonKey(ignore: true)
  _$$FavoriteBodyImplCopyWith<_$FavoriteBodyImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
