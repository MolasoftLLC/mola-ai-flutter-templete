// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'open_ai_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OpenAIResponse _$OpenAIResponseFromJson(Map<String, dynamic> json) {
  return _OpenAIResponse.fromJson(json);
}

/// @nodoc
mixin _$OpenAIResponse {
  String? get title => throw _privateConstructorUsedError;
  Map<String, String>? get description => throw _privateConstructorUsedError;
  String? get etc => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $OpenAIResponseCopyWith<OpenAIResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OpenAIResponseCopyWith<$Res> {
  factory $OpenAIResponseCopyWith(
          OpenAIResponse value, $Res Function(OpenAIResponse) then) =
      _$OpenAIResponseCopyWithImpl<$Res, OpenAIResponse>;
  @useResult
  $Res call({String? title, Map<String, String>? description, String? etc});
}

/// @nodoc
class _$OpenAIResponseCopyWithImpl<$Res, $Val extends OpenAIResponse>
    implements $OpenAIResponseCopyWith<$Res> {
  _$OpenAIResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? etc = freezed,
  }) {
    return _then(_value.copyWith(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      etc: freezed == etc
          ? _value.etc
          : etc // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OpenAIResponseImplCopyWith<$Res>
    implements $OpenAIResponseCopyWith<$Res> {
  factory _$$OpenAIResponseImplCopyWith(_$OpenAIResponseImpl value,
          $Res Function(_$OpenAIResponseImpl) then) =
      __$$OpenAIResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String? title, Map<String, String>? description, String? etc});
}

/// @nodoc
class __$$OpenAIResponseImplCopyWithImpl<$Res>
    extends _$OpenAIResponseCopyWithImpl<$Res, _$OpenAIResponseImpl>
    implements _$$OpenAIResponseImplCopyWith<$Res> {
  __$$OpenAIResponseImplCopyWithImpl(
      _$OpenAIResponseImpl _value, $Res Function(_$OpenAIResponseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = freezed,
    Object? description = freezed,
    Object? etc = freezed,
  }) {
    return _then(_$OpenAIResponseImpl(
      title: freezed == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value._description
          : description // ignore: cast_nullable_to_non_nullable
              as Map<String, String>?,
      etc: freezed == etc
          ? _value.etc
          : etc // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OpenAIResponseImpl extends _OpenAIResponse {
  _$OpenAIResponseImpl(
      {this.title, final Map<String, String>? description, this.etc})
      : _description = description,
        super._();

  factory _$OpenAIResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$OpenAIResponseImplFromJson(json);

  @override
  final String? title;
  final Map<String, String>? _description;
  @override
  Map<String, String>? get description {
    final value = _description;
    if (value == null) return null;
    if (_description is EqualUnmodifiableMapView) return _description;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final String? etc;

  @override
  String toString() {
    return 'OpenAIResponse(title: $title, description: $description, etc: $etc)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OpenAIResponseImpl &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality()
                .equals(other._description, _description) &&
            (identical(other.etc, etc) || other.etc == etc));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, title,
      const DeepCollectionEquality().hash(_description), etc);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$OpenAIResponseImplCopyWith<_$OpenAIResponseImpl> get copyWith =>
      __$$OpenAIResponseImplCopyWithImpl<_$OpenAIResponseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OpenAIResponseImplToJson(
      this,
    );
  }
}

abstract class _OpenAIResponse extends OpenAIResponse {
  factory _OpenAIResponse(
      {final String? title,
      final Map<String, String>? description,
      final String? etc}) = _$OpenAIResponseImpl;
  _OpenAIResponse._() : super._();

  factory _OpenAIResponse.fromJson(Map<String, dynamic> json) =
      _$OpenAIResponseImpl.fromJson;

  @override
  String? get title;
  @override
  Map<String, String>? get description;
  @override
  String? get etc;
  @override
  @JsonKey(ignore: true)
  _$$OpenAIResponseImplCopyWith<_$OpenAIResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
