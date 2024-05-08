// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'image_search_page_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ImageSearchPageState {
  bool get isLoading => throw _privateConstructorUsedError;
  String? get hint => throw _privateConstructorUsedError;
  File? get sakeImage => throw _privateConstructorUsedError;
  String? get geminiResponse => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $ImageSearchPageStateCopyWith<ImageSearchPageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImageSearchPageStateCopyWith<$Res> {
  factory $ImageSearchPageStateCopyWith(ImageSearchPageState value,
          $Res Function(ImageSearchPageState) then) =
      _$ImageSearchPageStateCopyWithImpl<$Res, ImageSearchPageState>;
  @useResult
  $Res call(
      {bool isLoading, String? hint, File? sakeImage, String? geminiResponse});
}

/// @nodoc
class _$ImageSearchPageStateCopyWithImpl<$Res,
        $Val extends ImageSearchPageState>
    implements $ImageSearchPageStateCopyWith<$Res> {
  _$ImageSearchPageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? hint = freezed,
    Object? sakeImage = freezed,
    Object? geminiResponse = freezed,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hint: freezed == hint
          ? _value.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as String?,
      sakeImage: freezed == sakeImage
          ? _value.sakeImage
          : sakeImage // ignore: cast_nullable_to_non_nullable
              as File?,
      geminiResponse: freezed == geminiResponse
          ? _value.geminiResponse
          : geminiResponse // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImageSearchPageStateImplCopyWith<$Res>
    implements $ImageSearchPageStateCopyWith<$Res> {
  factory _$$ImageSearchPageStateImplCopyWith(_$ImageSearchPageStateImpl value,
          $Res Function(_$ImageSearchPageStateImpl) then) =
      __$$ImageSearchPageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading, String? hint, File? sakeImage, String? geminiResponse});
}

/// @nodoc
class __$$ImageSearchPageStateImplCopyWithImpl<$Res>
    extends _$ImageSearchPageStateCopyWithImpl<$Res, _$ImageSearchPageStateImpl>
    implements _$$ImageSearchPageStateImplCopyWith<$Res> {
  __$$ImageSearchPageStateImplCopyWithImpl(_$ImageSearchPageStateImpl _value,
      $Res Function(_$ImageSearchPageStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? hint = freezed,
    Object? sakeImage = freezed,
    Object? geminiResponse = freezed,
  }) {
    return _then(_$ImageSearchPageStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      hint: freezed == hint
          ? _value.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as String?,
      sakeImage: freezed == sakeImage
          ? _value.sakeImage
          : sakeImage // ignore: cast_nullable_to_non_nullable
              as File?,
      geminiResponse: freezed == geminiResponse
          ? _value.geminiResponse
          : geminiResponse // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ImageSearchPageStateImpl implements _ImageSearchPageState {
  const _$ImageSearchPageStateImpl(
      {this.isLoading = false, this.hint, this.sakeImage, this.geminiResponse});

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? hint;
  @override
  final File? sakeImage;
  @override
  final String? geminiResponse;

  @override
  String toString() {
    return 'ImageSearchPageState(isLoading: $isLoading, hint: $hint, sakeImage: $sakeImage, geminiResponse: $geminiResponse)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImageSearchPageStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.hint, hint) || other.hint == hint) &&
            (identical(other.sakeImage, sakeImage) ||
                other.sakeImage == sakeImage) &&
            (identical(other.geminiResponse, geminiResponse) ||
                other.geminiResponse == geminiResponse));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, isLoading, hint, sakeImage, geminiResponse);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ImageSearchPageStateImplCopyWith<_$ImageSearchPageStateImpl>
      get copyWith =>
          __$$ImageSearchPageStateImplCopyWithImpl<_$ImageSearchPageStateImpl>(
              this, _$identity);
}

abstract class _ImageSearchPageState implements ImageSearchPageState {
  const factory _ImageSearchPageState(
      {final bool isLoading,
      final String? hint,
      final File? sakeImage,
      final String? geminiResponse}) = _$ImageSearchPageStateImpl;

  @override
  bool get isLoading;
  @override
  String? get hint;
  @override
  File? get sakeImage;
  @override
  String? get geminiResponse;
  @override
  @JsonKey(ignore: true)
  _$$ImageSearchPageStateImplCopyWith<_$ImageSearchPageStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
