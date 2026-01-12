// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_page_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AppPageState {
  int get currentIndex => throw _privateConstructorUsedError;
  bool get needUpDate => throw _privateConstructorUsedError;
  bool get hasShownPreferencesDialog => throw _privateConstructorUsedError;
  bool get hasReadTimelineIntro => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $AppPageStateCopyWith<AppPageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppPageStateCopyWith<$Res> {
  factory $AppPageStateCopyWith(
          AppPageState value, $Res Function(AppPageState) then) =
      _$AppPageStateCopyWithImpl<$Res, AppPageState>;
  @useResult
  $Res call(
      {int currentIndex,
      bool needUpDate,
      bool hasShownPreferencesDialog,
      bool hasReadTimelineIntro});
}

/// @nodoc
class _$AppPageStateCopyWithImpl<$Res, $Val extends AppPageState>
    implements $AppPageStateCopyWith<$Res> {
  _$AppPageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentIndex = null,
    Object? needUpDate = null,
    Object? hasShownPreferencesDialog = null,
    Object? hasReadTimelineIntro = null,
  }) {
    return _then(_value.copyWith(
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      needUpDate: null == needUpDate
          ? _value.needUpDate
          : needUpDate // ignore: cast_nullable_to_non_nullable
              as bool,
      hasShownPreferencesDialog: null == hasShownPreferencesDialog
          ? _value.hasShownPreferencesDialog
          : hasShownPreferencesDialog // ignore: cast_nullable_to_non_nullable
              as bool,
      hasReadTimelineIntro: null == hasReadTimelineIntro
          ? _value.hasReadTimelineIntro
          : hasReadTimelineIntro // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppPageStateImplCopyWith<$Res>
    implements $AppPageStateCopyWith<$Res> {
  factory _$$AppPageStateImplCopyWith(
          _$AppPageStateImpl value, $Res Function(_$AppPageStateImpl) then) =
      __$$AppPageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int currentIndex,
      bool needUpDate,
      bool hasShownPreferencesDialog,
      bool hasReadTimelineIntro});
}

/// @nodoc
class __$$AppPageStateImplCopyWithImpl<$Res>
    extends _$AppPageStateCopyWithImpl<$Res, _$AppPageStateImpl>
    implements _$$AppPageStateImplCopyWith<$Res> {
  __$$AppPageStateImplCopyWithImpl(
      _$AppPageStateImpl _value, $Res Function(_$AppPageStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentIndex = null,
    Object? needUpDate = null,
    Object? hasShownPreferencesDialog = null,
    Object? hasReadTimelineIntro = null,
  }) {
    return _then(_$AppPageStateImpl(
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      needUpDate: null == needUpDate
          ? _value.needUpDate
          : needUpDate // ignore: cast_nullable_to_non_nullable
              as bool,
      hasShownPreferencesDialog: null == hasShownPreferencesDialog
          ? _value.hasShownPreferencesDialog
          : hasShownPreferencesDialog // ignore: cast_nullable_to_non_nullable
              as bool,
      hasReadTimelineIntro: null == hasReadTimelineIntro
          ? _value.hasReadTimelineIntro
          : hasReadTimelineIntro // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$AppPageStateImpl implements _AppPageState {
  const _$AppPageStateImpl(
      {this.currentIndex = 0,
      this.needUpDate = false,
      this.hasShownPreferencesDialog = false,
      this.hasReadTimelineIntro = false});

  @override
  @JsonKey()
  final int currentIndex;
  @override
  @JsonKey()
  final bool needUpDate;
  @override
  @JsonKey()
  final bool hasShownPreferencesDialog;
  @override
  @JsonKey()
  final bool hasReadTimelineIntro;

  @override
  String toString() {
    return 'AppPageState(currentIndex: $currentIndex, needUpDate: $needUpDate, hasShownPreferencesDialog: $hasShownPreferencesDialog, hasReadTimelineIntro: $hasReadTimelineIntro)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppPageStateImpl &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.needUpDate, needUpDate) ||
                other.needUpDate == needUpDate) &&
            (identical(other.hasShownPreferencesDialog,
                    hasShownPreferencesDialog) ||
                other.hasShownPreferencesDialog == hasShownPreferencesDialog) &&
            (identical(other.hasReadTimelineIntro, hasReadTimelineIntro) ||
                other.hasReadTimelineIntro == hasReadTimelineIntro));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentIndex, needUpDate,
      hasShownPreferencesDialog, hasReadTimelineIntro);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppPageStateImplCopyWith<_$AppPageStateImpl> get copyWith =>
      __$$AppPageStateImplCopyWithImpl<_$AppPageStateImpl>(this, _$identity);
}

abstract class _AppPageState implements AppPageState {
  const factory _AppPageState(
      {final int currentIndex,
      final bool needUpDate,
      final bool hasShownPreferencesDialog,
      final bool hasReadTimelineIntro}) = _$AppPageStateImpl;

  @override
  int get currentIndex;
  @override
  bool get needUpDate;
  @override
  bool get hasShownPreferencesDialog;
  @override
  bool get hasReadTimelineIntro;
  @override
  @JsonKey(ignore: true)
  _$$AppPageStateImplCopyWith<_$AppPageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
