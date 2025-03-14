// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sake_bottle_list_page_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SakeBottleListPageState {
  List<SakeBottleImage> get sakeBottleImages =>
      throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  File? get selectedImage => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SakeBottleListPageStateCopyWith<SakeBottleListPageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SakeBottleListPageStateCopyWith<$Res> {
  factory $SakeBottleListPageStateCopyWith(SakeBottleListPageState value,
          $Res Function(SakeBottleListPageState) then) =
      _$SakeBottleListPageStateCopyWithImpl<$Res, SakeBottleListPageState>;
  @useResult
  $Res call(
      {List<SakeBottleImage> sakeBottleImages,
      bool isLoading,
      String? errorMessage,
      File? selectedImage});
}

/// @nodoc
class _$SakeBottleListPageStateCopyWithImpl<$Res,
        $Val extends SakeBottleListPageState>
    implements $SakeBottleListPageStateCopyWith<$Res> {
  _$SakeBottleListPageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sakeBottleImages = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
    Object? selectedImage = freezed,
  }) {
    return _then(_value.copyWith(
      sakeBottleImages: null == sakeBottleImages
          ? _value.sakeBottleImages
          : sakeBottleImages // ignore: cast_nullable_to_non_nullable
              as List<SakeBottleImage>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedImage: freezed == selectedImage
          ? _value.selectedImage
          : selectedImage // ignore: cast_nullable_to_non_nullable
              as File?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SakeBottleListPageStateImplCopyWith<$Res>
    implements $SakeBottleListPageStateCopyWith<$Res> {
  factory _$$SakeBottleListPageStateImplCopyWith(
          _$SakeBottleListPageStateImpl value,
          $Res Function(_$SakeBottleListPageStateImpl) then) =
      __$$SakeBottleListPageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<SakeBottleImage> sakeBottleImages,
      bool isLoading,
      String? errorMessage,
      File? selectedImage});
}

/// @nodoc
class __$$SakeBottleListPageStateImplCopyWithImpl<$Res>
    extends _$SakeBottleListPageStateCopyWithImpl<$Res,
        _$SakeBottleListPageStateImpl>
    implements _$$SakeBottleListPageStateImplCopyWith<$Res> {
  __$$SakeBottleListPageStateImplCopyWithImpl(
      _$SakeBottleListPageStateImpl _value,
      $Res Function(_$SakeBottleListPageStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sakeBottleImages = null,
    Object? isLoading = null,
    Object? errorMessage = freezed,
    Object? selectedImage = freezed,
  }) {
    return _then(_$SakeBottleListPageStateImpl(
      sakeBottleImages: null == sakeBottleImages
          ? _value._sakeBottleImages
          : sakeBottleImages // ignore: cast_nullable_to_non_nullable
              as List<SakeBottleImage>,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      selectedImage: freezed == selectedImage
          ? _value.selectedImage
          : selectedImage // ignore: cast_nullable_to_non_nullable
              as File?,
    ));
  }
}

/// @nodoc

class _$SakeBottleListPageStateImpl implements _SakeBottleListPageState {
  const _$SakeBottleListPageStateImpl(
      {final List<SakeBottleImage> sakeBottleImages = const [],
      this.isLoading = true,
      this.errorMessage,
      this.selectedImage})
      : _sakeBottleImages = sakeBottleImages;

  final List<SakeBottleImage> _sakeBottleImages;
  @override
  @JsonKey()
  List<SakeBottleImage> get sakeBottleImages {
    if (_sakeBottleImages is EqualUnmodifiableListView)
      return _sakeBottleImages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sakeBottleImages);
  }

  @override
  @JsonKey()
  final bool isLoading;
  @override
  final String? errorMessage;
  @override
  final File? selectedImage;

  @override
  String toString() {
    return 'SakeBottleListPageState(sakeBottleImages: $sakeBottleImages, isLoading: $isLoading, errorMessage: $errorMessage, selectedImage: $selectedImage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SakeBottleListPageStateImpl &&
            const DeepCollectionEquality()
                .equals(other._sakeBottleImages, _sakeBottleImages) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.selectedImage, selectedImage) ||
                other.selectedImage == selectedImage));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_sakeBottleImages),
      isLoading,
      errorMessage,
      selectedImage);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SakeBottleListPageStateImplCopyWith<_$SakeBottleListPageStateImpl>
      get copyWith => __$$SakeBottleListPageStateImplCopyWithImpl<
          _$SakeBottleListPageStateImpl>(this, _$identity);
}

abstract class _SakeBottleListPageState implements SakeBottleListPageState {
  const factory _SakeBottleListPageState(
      {final List<SakeBottleImage> sakeBottleImages,
      final bool isLoading,
      final String? errorMessage,
      final File? selectedImage}) = _$SakeBottleListPageStateImpl;

  @override
  List<SakeBottleImage> get sakeBottleImages;
  @override
  bool get isLoading;
  @override
  String? get errorMessage;
  @override
  File? get selectedImage;
  @override
  @JsonKey(ignore: true)
  _$$SakeBottleListPageStateImplCopyWith<_$SakeBottleListPageStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}
