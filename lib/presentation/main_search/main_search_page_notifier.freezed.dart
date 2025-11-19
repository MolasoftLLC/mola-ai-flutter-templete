// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'main_search_page_notifier.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$MainSearchPageState {
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isAdLoading => throw _privateConstructorUsedError;
  bool get isAnalyzingInBackground => throw _privateConstructorUsedError;
  int get searchButtonClickCount => throw _privateConstructorUsedError;
  int get analyzeButtonClickCount => throw _privateConstructorUsedError;
  String? get sakeName => throw _privateConstructorUsedError;
  String? get hint => throw _privateConstructorUsedError;
  File? get sakeImage => throw _privateConstructorUsedError;
  String? get sakeType => throw _privateConstructorUsedError;
  Sake? get sakeInfo => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  String? get geminiResponse => throw _privateConstructorUsedError;
  SearchMode get searchMode => throw _privateConstructorUsedError;
  List<String> get pendingSavedSakeIds => throw _privateConstructorUsedError;
  String? get analyzingImagePath => throw _privateConstructorUsedError;
  bool get shareToTimeline => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $MainSearchPageStateCopyWith<MainSearchPageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MainSearchPageStateCopyWith<$Res> {
  factory $MainSearchPageStateCopyWith(
          MainSearchPageState value, $Res Function(MainSearchPageState) then) =
      _$MainSearchPageStateCopyWithImpl<$Res, MainSearchPageState>;
  @useResult
  $Res call(
      {bool isLoading,
      bool isAdLoading,
      bool isAnalyzingInBackground,
      int searchButtonClickCount,
      int analyzeButtonClickCount,
      String? sakeName,
      String? hint,
      File? sakeImage,
      String? sakeType,
      Sake? sakeInfo,
      String? errorMessage,
      String? geminiResponse,
      SearchMode searchMode,
      List<String> pendingSavedSakeIds,
      String? analyzingImagePath,
      bool shareToTimeline});

  $SakeCopyWith<$Res>? get sakeInfo;
}

/// @nodoc
class _$MainSearchPageStateCopyWithImpl<$Res, $Val extends MainSearchPageState>
    implements $MainSearchPageStateCopyWith<$Res> {
  _$MainSearchPageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isAdLoading = null,
    Object? isAnalyzingInBackground = null,
    Object? searchButtonClickCount = null,
    Object? analyzeButtonClickCount = null,
    Object? sakeName = freezed,
    Object? hint = freezed,
    Object? sakeImage = freezed,
    Object? sakeType = freezed,
    Object? sakeInfo = freezed,
    Object? errorMessage = freezed,
    Object? geminiResponse = freezed,
    Object? searchMode = null,
    Object? pendingSavedSakeIds = null,
    Object? analyzingImagePath = freezed,
    Object? shareToTimeline = null,
  }) {
    return _then(_value.copyWith(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAdLoading: null == isAdLoading
          ? _value.isAdLoading
          : isAdLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAnalyzingInBackground: null == isAnalyzingInBackground
          ? _value.isAnalyzingInBackground
          : isAnalyzingInBackground // ignore: cast_nullable_to_non_nullable
              as bool,
      searchButtonClickCount: null == searchButtonClickCount
          ? _value.searchButtonClickCount
          : searchButtonClickCount // ignore: cast_nullable_to_non_nullable
              as int,
      analyzeButtonClickCount: null == analyzeButtonClickCount
          ? _value.analyzeButtonClickCount
          : analyzeButtonClickCount // ignore: cast_nullable_to_non_nullable
              as int,
      sakeName: freezed == sakeName
          ? _value.sakeName
          : sakeName // ignore: cast_nullable_to_non_nullable
              as String?,
      hint: freezed == hint
          ? _value.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as String?,
      sakeImage: freezed == sakeImage
          ? _value.sakeImage
          : sakeImage // ignore: cast_nullable_to_non_nullable
              as File?,
      sakeType: freezed == sakeType
          ? _value.sakeType
          : sakeType // ignore: cast_nullable_to_non_nullable
              as String?,
      sakeInfo: freezed == sakeInfo
          ? _value.sakeInfo
          : sakeInfo // ignore: cast_nullable_to_non_nullable
              as Sake?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      geminiResponse: freezed == geminiResponse
          ? _value.geminiResponse
          : geminiResponse // ignore: cast_nullable_to_non_nullable
              as String?,
      searchMode: null == searchMode
          ? _value.searchMode
          : searchMode // ignore: cast_nullable_to_non_nullable
              as SearchMode,
      pendingSavedSakeIds: null == pendingSavedSakeIds
          ? _value.pendingSavedSakeIds
          : pendingSavedSakeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      analyzingImagePath: freezed == analyzingImagePath
          ? _value.analyzingImagePath
          : analyzingImagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      shareToTimeline: null == shareToTimeline
          ? _value.shareToTimeline
          : shareToTimeline // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $SakeCopyWith<$Res>? get sakeInfo {
    if (_value.sakeInfo == null) {
      return null;
    }

    return $SakeCopyWith<$Res>(_value.sakeInfo!, (value) {
      return _then(_value.copyWith(sakeInfo: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$MainSearchPageStateImplCopyWith<$Res>
    implements $MainSearchPageStateCopyWith<$Res> {
  factory _$$MainSearchPageStateImplCopyWith(_$MainSearchPageStateImpl value,
          $Res Function(_$MainSearchPageStateImpl) then) =
      __$$MainSearchPageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isLoading,
      bool isAdLoading,
      bool isAnalyzingInBackground,
      int searchButtonClickCount,
      int analyzeButtonClickCount,
      String? sakeName,
      String? hint,
      File? sakeImage,
      String? sakeType,
      Sake? sakeInfo,
      String? errorMessage,
      String? geminiResponse,
      SearchMode searchMode,
      List<String> pendingSavedSakeIds,
      String? analyzingImagePath,
      bool shareToTimeline});

  @override
  $SakeCopyWith<$Res>? get sakeInfo;
}

/// @nodoc
class __$$MainSearchPageStateImplCopyWithImpl<$Res>
    extends _$MainSearchPageStateCopyWithImpl<$Res, _$MainSearchPageStateImpl>
    implements _$$MainSearchPageStateImplCopyWith<$Res> {
  __$$MainSearchPageStateImplCopyWithImpl(_$MainSearchPageStateImpl _value,
      $Res Function(_$MainSearchPageStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isLoading = null,
    Object? isAdLoading = null,
    Object? isAnalyzingInBackground = null,
    Object? searchButtonClickCount = null,
    Object? analyzeButtonClickCount = null,
    Object? sakeName = freezed,
    Object? hint = freezed,
    Object? sakeImage = freezed,
    Object? sakeType = freezed,
    Object? sakeInfo = freezed,
    Object? errorMessage = freezed,
    Object? geminiResponse = freezed,
    Object? searchMode = null,
    Object? pendingSavedSakeIds = null,
    Object? analyzingImagePath = freezed,
    Object? shareToTimeline = null,
  }) {
    return _then(_$MainSearchPageStateImpl(
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAdLoading: null == isAdLoading
          ? _value.isAdLoading
          : isAdLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isAnalyzingInBackground: null == isAnalyzingInBackground
          ? _value.isAnalyzingInBackground
          : isAnalyzingInBackground // ignore: cast_nullable_to_non_nullable
              as bool,
      searchButtonClickCount: null == searchButtonClickCount
          ? _value.searchButtonClickCount
          : searchButtonClickCount // ignore: cast_nullable_to_non_nullable
              as int,
      analyzeButtonClickCount: null == analyzeButtonClickCount
          ? _value.analyzeButtonClickCount
          : analyzeButtonClickCount // ignore: cast_nullable_to_non_nullable
              as int,
      sakeName: freezed == sakeName
          ? _value.sakeName
          : sakeName // ignore: cast_nullable_to_non_nullable
              as String?,
      hint: freezed == hint
          ? _value.hint
          : hint // ignore: cast_nullable_to_non_nullable
              as String?,
      sakeImage: freezed == sakeImage
          ? _value.sakeImage
          : sakeImage // ignore: cast_nullable_to_non_nullable
              as File?,
      sakeType: freezed == sakeType
          ? _value.sakeType
          : sakeType // ignore: cast_nullable_to_non_nullable
              as String?,
      sakeInfo: freezed == sakeInfo
          ? _value.sakeInfo
          : sakeInfo // ignore: cast_nullable_to_non_nullable
              as Sake?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      geminiResponse: freezed == geminiResponse
          ? _value.geminiResponse
          : geminiResponse // ignore: cast_nullable_to_non_nullable
              as String?,
      searchMode: null == searchMode
          ? _value.searchMode
          : searchMode // ignore: cast_nullable_to_non_nullable
              as SearchMode,
      pendingSavedSakeIds: null == pendingSavedSakeIds
          ? _value._pendingSavedSakeIds
          : pendingSavedSakeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      analyzingImagePath: freezed == analyzingImagePath
          ? _value.analyzingImagePath
          : analyzingImagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      shareToTimeline: null == shareToTimeline
          ? _value.shareToTimeline
          : shareToTimeline // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$MainSearchPageStateImpl implements _MainSearchPageState {
  const _$MainSearchPageStateImpl(
      {this.isLoading = false,
      this.isAdLoading = false,
      this.isAnalyzingInBackground = false,
      this.searchButtonClickCount = 0,
      this.analyzeButtonClickCount = 0,
      this.sakeName,
      this.hint,
      this.sakeImage,
      this.sakeType,
      this.sakeInfo,
      this.errorMessage,
      this.geminiResponse,
      this.searchMode = SearchMode.bottle,
      final List<String> pendingSavedSakeIds = const [],
      this.analyzingImagePath,
      this.shareToTimeline = true})
      : _pendingSavedSakeIds = pendingSavedSakeIds;

  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isAdLoading;
  @override
  @JsonKey()
  final bool isAnalyzingInBackground;
  @override
  @JsonKey()
  final int searchButtonClickCount;
  @override
  @JsonKey()
  final int analyzeButtonClickCount;
  @override
  final String? sakeName;
  @override
  final String? hint;
  @override
  final File? sakeImage;
  @override
  final String? sakeType;
  @override
  final Sake? sakeInfo;
  @override
  final String? errorMessage;
  @override
  final String? geminiResponse;
  @override
  @JsonKey()
  final SearchMode searchMode;
  final List<String> _pendingSavedSakeIds;
  @override
  @JsonKey()
  List<String> get pendingSavedSakeIds {
    if (_pendingSavedSakeIds is EqualUnmodifiableListView)
      return _pendingSavedSakeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pendingSavedSakeIds);
  }

  @override
  final String? analyzingImagePath;
  @override
  @JsonKey()
  final bool shareToTimeline;

  @override
  String toString() {
    return 'MainSearchPageState(isLoading: $isLoading, isAdLoading: $isAdLoading, isAnalyzingInBackground: $isAnalyzingInBackground, searchButtonClickCount: $searchButtonClickCount, analyzeButtonClickCount: $analyzeButtonClickCount, sakeName: $sakeName, hint: $hint, sakeImage: $sakeImage, sakeType: $sakeType, sakeInfo: $sakeInfo, errorMessage: $errorMessage, geminiResponse: $geminiResponse, searchMode: $searchMode, pendingSavedSakeIds: $pendingSavedSakeIds, analyzingImagePath: $analyzingImagePath, shareToTimeline: $shareToTimeline)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MainSearchPageStateImpl &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isAdLoading, isAdLoading) ||
                other.isAdLoading == isAdLoading) &&
            (identical(
                    other.isAnalyzingInBackground, isAnalyzingInBackground) ||
                other.isAnalyzingInBackground == isAnalyzingInBackground) &&
            (identical(other.searchButtonClickCount, searchButtonClickCount) ||
                other.searchButtonClickCount == searchButtonClickCount) &&
            (identical(
                    other.analyzeButtonClickCount, analyzeButtonClickCount) ||
                other.analyzeButtonClickCount == analyzeButtonClickCount) &&
            (identical(other.sakeName, sakeName) ||
                other.sakeName == sakeName) &&
            (identical(other.hint, hint) || other.hint == hint) &&
            (identical(other.sakeImage, sakeImage) ||
                other.sakeImage == sakeImage) &&
            (identical(other.sakeType, sakeType) ||
                other.sakeType == sakeType) &&
            (identical(other.sakeInfo, sakeInfo) ||
                other.sakeInfo == sakeInfo) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.geminiResponse, geminiResponse) ||
                other.geminiResponse == geminiResponse) &&
            (identical(other.searchMode, searchMode) ||
                other.searchMode == searchMode) &&
            const DeepCollectionEquality()
                .equals(other._pendingSavedSakeIds, _pendingSavedSakeIds) &&
            (identical(other.analyzingImagePath, analyzingImagePath) ||
                other.analyzingImagePath == analyzingImagePath) &&
            (identical(other.shareToTimeline, shareToTimeline) ||
                other.shareToTimeline == shareToTimeline));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      isLoading,
      isAdLoading,
      isAnalyzingInBackground,
      searchButtonClickCount,
      analyzeButtonClickCount,
      sakeName,
      hint,
      sakeImage,
      sakeType,
      sakeInfo,
      errorMessage,
      geminiResponse,
      searchMode,
      const DeepCollectionEquality().hash(_pendingSavedSakeIds),
      analyzingImagePath,
      shareToTimeline);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MainSearchPageStateImplCopyWith<_$MainSearchPageStateImpl> get copyWith =>
      __$$MainSearchPageStateImplCopyWithImpl<_$MainSearchPageStateImpl>(
          this, _$identity);
}

abstract class _MainSearchPageState implements MainSearchPageState {
  const factory _MainSearchPageState(
      {final bool isLoading,
      final bool isAdLoading,
      final bool isAnalyzingInBackground,
      final int searchButtonClickCount,
      final int analyzeButtonClickCount,
      final String? sakeName,
      final String? hint,
      final File? sakeImage,
      final String? sakeType,
      final Sake? sakeInfo,
      final String? errorMessage,
      final String? geminiResponse,
      final SearchMode searchMode,
      final List<String> pendingSavedSakeIds,
      final String? analyzingImagePath,
      final bool shareToTimeline}) = _$MainSearchPageStateImpl;

  @override
  bool get isLoading;
  @override
  bool get isAdLoading;
  @override
  bool get isAnalyzingInBackground;
  @override
  int get searchButtonClickCount;
  @override
  int get analyzeButtonClickCount;
  @override
  String? get sakeName;
  @override
  String? get hint;
  @override
  File? get sakeImage;
  @override
  String? get sakeType;
  @override
  Sake? get sakeInfo;
  @override
  String? get errorMessage;
  @override
  String? get geminiResponse;
  @override
  SearchMode get searchMode;
  @override
  List<String> get pendingSavedSakeIds;
  @override
  String? get analyzingImagePath;
  @override
  bool get shareToTimeline;
  @override
  @JsonKey(ignore: true)
  _$$MainSearchPageStateImplCopyWith<_$MainSearchPageStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
