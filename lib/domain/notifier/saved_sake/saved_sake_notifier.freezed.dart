// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'saved_sake_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SavedSakeState {
  List<Sake> get savedSakeList => throw _privateConstructorUsedError;
  bool get isGridView => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SavedSakeStateCopyWith<SavedSakeState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SavedSakeStateCopyWith<$Res> {
  factory $SavedSakeStateCopyWith(
          SavedSakeState value, $Res Function(SavedSakeState) then) =
      _$SavedSakeStateCopyWithImpl<$Res, SavedSakeState>;
  @useResult
  $Res call({List<Sake> savedSakeList, bool isGridView});
}

/// @nodoc
class _$SavedSakeStateCopyWithImpl<$Res, $Val extends SavedSakeState>
    implements $SavedSakeStateCopyWith<$Res> {
  _$SavedSakeStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? savedSakeList = null,
    Object? isGridView = null,
  }) {
    return _then(_value.copyWith(
      savedSakeList: null == savedSakeList
          ? _value.savedSakeList
          : savedSakeList // ignore: cast_nullable_to_non_nullable
              as List<Sake>,
      isGridView: null == isGridView
          ? _value.isGridView
          : isGridView // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SavedSakeStateImplCopyWith<$Res>
    implements $SavedSakeStateCopyWith<$Res> {
  factory _$$SavedSakeStateImplCopyWith(_$SavedSakeStateImpl value,
          $Res Function(_$SavedSakeStateImpl) then) =
      __$$SavedSakeStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<Sake> savedSakeList, bool isGridView});
}

/// @nodoc
class __$$SavedSakeStateImplCopyWithImpl<$Res>
    extends _$SavedSakeStateCopyWithImpl<$Res, _$SavedSakeStateImpl>
    implements _$$SavedSakeStateImplCopyWith<$Res> {
  __$$SavedSakeStateImplCopyWithImpl(
      _$SavedSakeStateImpl _value, $Res Function(_$SavedSakeStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? savedSakeList = null,
    Object? isGridView = null,
  }) {
    return _then(_$SavedSakeStateImpl(
      savedSakeList: null == savedSakeList
          ? _value._savedSakeList
          : savedSakeList // ignore: cast_nullable_to_non_nullable
              as List<Sake>,
      isGridView: null == isGridView
          ? _value.isGridView
          : isGridView // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$SavedSakeStateImpl implements _SavedSakeState {
  const _$SavedSakeStateImpl(
      {final List<Sake> savedSakeList = const [], this.isGridView = false})
      : _savedSakeList = savedSakeList;

  final List<Sake> _savedSakeList;
  @override
  @JsonKey()
  List<Sake> get savedSakeList {
    if (_savedSakeList is EqualUnmodifiableListView) return _savedSakeList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_savedSakeList);
  }

  @override
  @JsonKey()
  final bool isGridView;

  @override
  String toString() {
    return 'SavedSakeState(savedSakeList: $savedSakeList, isGridView: $isGridView)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SavedSakeStateImpl &&
            const DeepCollectionEquality()
                .equals(other._savedSakeList, _savedSakeList) &&
            (identical(other.isGridView, isGridView) ||
                other.isGridView == isGridView));
  }

  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_savedSakeList), isGridView);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SavedSakeStateImplCopyWith<_$SavedSakeStateImpl> get copyWith =>
      __$$SavedSakeStateImplCopyWithImpl<_$SavedSakeStateImpl>(
          this, _$identity);
}

abstract class _SavedSakeState implements SavedSakeState {
  const factory _SavedSakeState(
      {final List<Sake> savedSakeList,
      final bool isGridView}) = _$SavedSakeStateImpl;

  @override
  List<Sake> get savedSakeList;
  @override
  bool get isGridView;
  @override
  @JsonKey(ignore: true)
  _$$SavedSakeStateImplCopyWith<_$SavedSakeStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
