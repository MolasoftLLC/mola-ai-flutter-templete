import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:provider/provider.dart';

import '../../common/localization/localization_extensions.dart';
import '../../common/sake/master.dart' as sake_master;
import '../../common/utils/custom_image_picker.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../domain/notifier/auth/auth_notifier.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../../domain/repository/place_map_repository.dart';
import '../../common/logger.dart';
import '../common/widgets/guest_limit_dialog.dart';
import '../common/widgets/primary_app_bar.dart';
import '../sake_map/sake_master_detail_page.dart';
import 'widgets/place_picker_sheet.dart';

const double _blockSpacing = 16;
const double _blockVerticalPadding = 20;

class SavedSakeDetailPage extends StatefulWidget {
  const SavedSakeDetailPage({super.key, required this.sake});

  final Sake sake;

  /// 保存済みの日本酒は、すべて客観情報と個人記録を一つにした詳細へ開く。
  /// マスターIDがない過去の記録は、銘柄名からマスターを補完して表示する。
  static Widget forSake(Sake sake) {
    return _SavedSakeMasterDetailResolver(sake: sake);
  }

  @override
  State<SavedSakeDetailPage> createState() => _SavedSakeDetailPageState();
}

class _SavedSakeMasterDetailResolver extends StatefulWidget {
  const _SavedSakeMasterDetailResolver({required this.sake});

  final Sake sake;

  @override
  State<_SavedSakeMasterDetailResolver> createState() =>
      _SavedSakeMasterDetailResolverState();
}

class _SavedSakeMasterDetailResolverState
    extends State<_SavedSakeMasterDetailResolver> {
  Future<VenueSake>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _resolveMaster();
  }

  Future<VenueSake> _resolveMaster() async {
    final sake = widget.sake;
    if (sake.sakeId != null && sake.sakeId! > 0) {
      return _asVenueSake(sake);
    }

    final name = sake.name?.trim() ?? '';
    if (name.isEmpty) return _asVenueSake(sake);
    try {
      final results = await context
          .read<PlaceMapRepository>()
          .searchSakeMasters(name);
      final normalizedName = name.replaceAll(RegExp(r'\s+'), '');
      final matching = results.where(
        (result) =>
            result.sakeId != null &&
            result.sakeId! > 0 &&
            result.name.replaceAll(RegExp(r'\s+'), '') == normalizedName,
      );
      final exactBrewery = matching.where(
        (result) =>
            sake.brewery?.trim().isNotEmpty == true &&
            result.brewery?.trim() == sake.brewery?.trim(),
      );
      final resolved = exactBrewery.isNotEmpty
          ? exactBrewery.first
          : matching.isNotEmpty
          ? matching.first
          : null;
      if (resolved == null) return _asVenueSake(sake);
      return VenueSake(
        sakeId: resolved.sakeId,
        searchToken: resolved.searchToken,
        name: resolved.name,
        brewery: resolved.brewery ?? sake.brewery,
        type: resolved.type ?? sake.type,
        primaryImageUrl: resolved.primaryImageUrl ?? sake.primaryImageUrl,
        recordCount: 0,
      );
    } catch (_) {
      return _asVenueSake(sake);
    }
  }

  VenueSake _asVenueSake(Sake sake) => VenueSake(
    sakeId: sake.sakeId,
    name: sake.name ?? '名称不明',
    brewery: sake.brewery,
    type: sake.type,
    primaryImageUrl: sake.primaryImageUrl,
    recordCount: 0,
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<VenueSake>(
    future: _future,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      final sake = snapshot.requireData;
      return SakeMasterDetailPage(
        key: ValueKey('saved-sake-master-${sake.sakeId ?? sake.name}'),
        venueSake: sake,
      );
    },
  );
}

class _SavedSakeDetailPageState extends State<SavedSakeDetailPage> {
  late final TextEditingController _nameController;
  late final TextEditingController _impressionController;
  late final TextEditingController _placeController;
  late final FocusNode _nameFocusNode;
  late final ScrollController _scrollController;
  late Sake _currentSake;
  late Set<String> _selectedTags;
  late List<String> _imagePaths;
  bool _isImageProcessing = false;
  bool _isSyncing = false;
  bool _isVisibilityUpdating = false;
  bool _placeDirty = false;
  String? _progressMessage;
  bool _hasNameChanged = false;
  final GlobalKey _memoryHeadingKey = GlobalKey();

  bool get _isNameAnalyzing {
    final name = _currentSake.name?.trim() ?? '';
    return name == '解析中' || name == context.l10n.processing;
  }

  bool get _isNameAnalysisFailed =>
      (_currentSake.name?.trim() ?? '') ==
      SavedSakeNotifier.analysisFailedLabel;
  bool get _canUploadMemoryImage =>
      (_currentSake.savedId?.isNotEmpty ?? false) &&
      _currentSake.syncStatus == SavedSakeSyncStatus.serverSynced;

  bool _isRemotePath(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  @override
  void initState() {
    super.initState();
    _currentSake = widget.sake;
    _nameFocusNode = FocusNode();
    _scrollController = ScrollController();
    _nameController = TextEditingController(text: widget.sake.name ?? '');
    _nameController.addListener(_handleNameFieldChanged);
    _impressionController = TextEditingController(
      text: widget.sake.impression ?? '',
    );
    _placeController = TextEditingController(
      text: widget.sake.drinkingPlace?.displayName ?? widget.sake.place ?? '',
    );
    _selectedTags = {...(widget.sake.userTags ?? <String>[])};
    _imagePaths = [...(widget.sake.imagePaths ?? <String>[])];
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameFieldChanged);
    _nameFocusNode.dispose();
    _nameController.dispose();
    _impressionController.dispose();
    _placeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF1D3567);
    final gradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1D3567), Color(0xFF0A1428)],
    );
    final favoriteNotifier = context.read<FavoriteNotifier>();
    final isLoggedIn = context.select((AuthState state) => state.user != null);
    final isLocalOnly =
        _currentSake.syncStatus == SavedSakeSyncStatus.localOnly;
    final isFavorited = context.select(
      (FavoriteState state) => state.myFavoriteList.any(
        (fav) =>
            fav.name == (_currentSake.name ?? '名称不明') &&
            fav.type == _currentSake.type,
      ),
    );

    final infoRows = <Widget>[];
    if (_isValid(_currentSake.brewery)) {
      infoRows.add(
        _buildInfoRow(
          context.l10n.brewery,
          _currentSake.brewery!,
          Icons.home_work,
        ),
      );
    }
    if (_isValid(_currentSake.price)) {
      infoRows.add(
        _buildInfoRow(
          context.l10n.price,
          _currentSake.price!,
          Icons.price_check,
        ),
      );
    }
    if (_currentSake.sakeMeterValue != null) {
      infoRows.add(
        _buildInfoRow(
          context.l10n.sakeMeterValue,
          _currentSake.sakeMeterValue!.toString(),
          Icons.science,
        ),
      );
    }
    if (_currentSake.recommendationScore != null) {
      infoRows.add(
        _buildInfoRow(
          context.l10n.recommendationScore,
          '${_currentSake.recommendationScore}',
          Icons.star,
        ),
      );
    }

    final featureWidgets = <Widget>[];
    if (_isValid(_currentSake.taste)) {
      featureWidgets.add(
        _buildBodyText(context.l10n.taste, _currentSake.taste!),
      );
    }
    if (_isValid(_currentSake.description)) {
      featureWidgets.add(
        _buildBodyText(context.l10n.description, _currentSake.description!),
      );
    }
    if (_currentSake.types != null && _currentSake.types!.isNotEmpty) {
      featureWidgets.add(_buildTypesSection(_currentSake.types!));
    }

    return Scaffold(
      appBar: PrimaryAppBar(
        title: _currentSake.name ?? context.l10n.sakeDetails,
        titleFontSize: 21,
        actions: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.redAccent : Colors.white,
            ),
            onPressed: () async =>
                await _toggleFavorite(favoriteNotifier, isFavorited),
          ),
        ],
      ),
      bottomNavigationBar: _buildMemoCtaFooter(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: gradient),
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeaderCard(
                    themeColor,
                    showSyncButton: isLoggedIn && isLocalOnly,
                    isLoggedIn: isLoggedIn,
                  ),
                  if (infoRows.isNotEmpty)
                    _buildSection(
                      title: context.l10n.basicInformation,
                      children: infoRows,
                    ),
                  if (featureWidgets.isNotEmpty)
                    _buildSection(
                      title: context.l10n.tasteAndFeatures,
                      children: featureWidgets,
                    ),
                  if (_currentSake.community?.isNotEmpty ?? false)
                    _buildCommunitySection(_currentSake.community!),
                  if (_currentSake.sameBrandSakes?.isNotEmpty ?? false)
                    _buildSameBrandSection(_currentSake.sameBrandSakes!),
                  if (infoRows.isEmpty &&
                      featureWidgets.isEmpty &&
                      !(_currentSake.community?.isNotEmpty ?? false) &&
                      !(_currentSake.sameBrandSakes?.isNotEmpty ?? false))
                    Container(
                      margin: const EdgeInsets.only(top: _blockSpacing),
                      padding: const EdgeInsets.symmetric(
                        vertical: _blockVerticalPadding,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        context.l10n.noDetailedInformation,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  _buildImageGallerySection(),
                  _buildMemoSection(),
                ],
              ),
            ),
          ),
          if (_isImageProcessing || _isSyncing)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.45),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        _progressMessage ?? context.l10n.processing,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(
    Color themeColor, {
    required bool showSyncButton,
    required bool isLoggedIn,
  }) {
    final double recommendationScore = (_currentSake.recommendationScore ?? 0)
        .toDouble();
    final isRecommended = recommendationScore >= 6;
    final canReanalyze =
        isLoggedIn && (_currentSake.savedId?.isNotEmpty ?? false);
    final savedDateText = _formatSavedDate(_currentSake.savedId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_isNameAnalyzing)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildNameAnalyzingNotice(),
          )
        else if (_isNameAnalysisFailed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildAnalysisFailedNotice(),
          ),
        if (savedDateText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              context.l10n.savedDate(savedDateText),
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(
            vertical: _blockVerticalPadding,
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildNameEditor(
                isLoggedIn: isLoggedIn,
                canReanalyze: canReanalyze,
              ),
              const SizedBox(height: 12),
              if (_isValid(_currentSake.brewery))
                Text(
                  _currentSake.brewery!,
                  style: const TextStyle(color: Colors.white70, fontSize: 15),
                ),
              if (_isValid(_currentSake.type))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _currentSake.type!,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                ),
              if (_isValid(
                _currentSake.drinkingPlace?.displayName ?? _currentSake.place,
              ))
                InkWell(
                  onTap: _openPlacePicker,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.place, color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _currentSake.drinkingPlace?.displayName ??
                                _currentSake.place!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.edit_outlined,
                          color: Colors.white54,
                          size: 17,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _openPlacePicker,
                    icon: const Icon(Icons.add_location_alt_outlined),
                    label: Text(context.l10n.addConsumedPlace),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                  ),
                ),
              if (isRecommended)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.redAccent.withOpacity(0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.recommend,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        recommendationScore >= 8
                            ? context.l10n.highlyRecommended
                            : context.l10n.recommended,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              if ((_currentSake.userTags ?? []).isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _currentSake.userTags!
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(
                                color: Color(0xFF1D3567),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: Colors.white.withOpacity(0.18),
                          ),
                        )
                        .toList(),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    _currentSake.syncStatus == SavedSakeSyncStatus.serverSynced
                        ? Icons.cloud_done
                        : Icons.cloud_upload,
                    color:
                        _currentSake.syncStatus ==
                            SavedSakeSyncStatus.serverSynced
                        ? Colors.lightBlueAccent
                        : Colors.orangeAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentSake.syncStatus ==
                              SavedSakeSyncStatus.serverSynced
                          ? context.l10n.syncedToServer
                          : context.l10n.localOnly,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (showSyncButton)
                    TextButton.icon(
                      onPressed: _isSyncing ? null : _handleManualSync,
                      icon: const Icon(Icons.cloud_upload, size: 16),
                      label: Text(context.l10n.syncToServer),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        backgroundColor: Colors.white.withOpacity(0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
              if ((isLoggedIn || (_currentSake.savedId?.isNotEmpty ?? false)))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _buildVisibilityToggle(
                    isLoggedIn: isLoggedIn,
                    hasSavedId: _currentSake.savedId?.isNotEmpty ?? false,
                    isServerSynced:
                        _currentSake.syncStatus ==
                        SavedSakeSyncStatus.serverSynced,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNameAnalyzingNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1D3567), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.manualNameSearchHint,
              style: const TextStyle(
                color: Color(0xFF1D3567),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisFailedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.redAccent.withOpacity(0.6)),
      ),
      child: Row(
        children: const [
          Icon(Icons.error_outline, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              SavedSakeNotifier.analysisFailedLabel,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisibilityToggle({
    required bool isLoggedIn,
    required bool hasSavedId,
    required bool isServerSynced,
  }) {
    final bool canToggle =
        isLoggedIn &&
        hasSavedId &&
        isServerSynced &&
        !_isVisibilityUpdating &&
        !_isSyncing;
    final bool needsSync = !hasSavedId || !isServerSynced;
    final String helperText;
    if (needsSync) {
      helperText = context.l10n.syncToChangeVisibility;
    } else if (!isLoggedIn) {
      helperText = context.l10n.loginToChangeVisibility;
    } else {
      helperText = context.l10n.visibilityChangeHint;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.public, color: Color(0xFFFFD54F), size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.showOnTimeline,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_isVisibilityUpdating)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            Switch.adaptive(
              value: _currentSake.isPublic,
              onChanged: needsSync
                  ? null
                  : (canToggle ? _handleVisibilityToggle : null),
              activeColor: const Color(0xFFFFD54F),
              inactiveTrackColor: Colors.white30,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildNameEditor({
    required bool isLoggedIn,
    required bool canReanalyze,
  }) {
    final bool hasChanged = _hasNameChanged;
    final bool allowReanalyze = hasChanged && canReanalyze;
    final ButtonStyle changeStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      backgroundColor: Colors.white.withOpacity(0.12),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    final ButtonStyle reanalyzeStyle = FilledButton.styleFrom(
      minimumSize: const Size(0, 48),
      backgroundColor: const Color(0xFFFFD54F),
      foregroundColor: const Color(0xFF1D3567),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
    final String buttonLabel = hasChanged
        ? (allowReanalyze ? context.l10n.reanalyze : context.l10n.save)
        : context.l10n.change;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  focusNode: _nameFocusNode,
                  controller: _nameController,
                  maxLength: 50,
                  textAlignVertical: TextAlignVertical.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: context.l10n.sakeName,
                    labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _isSyncing
                    ? null
                    : () async {
                        if (!hasChanged) {
                          FocusScope.of(context).requestFocus(_nameFocusNode);
                          return;
                        }
                        if (!canReanalyze) {
                          await _handleSaveName(reanalyze: false);
                          _showSnack(context.l10n.loginToReanalyze);
                          return;
                        }
                        await _handleSaveName(reanalyze: true);
                      },
                style: hasChanged ? reanalyzeStyle : changeStyle,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
        if (!isLoggedIn)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.l10n.loginToReanalyzeAfterRename,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ),
        if (isLoggedIn && !canReanalyze)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              context.l10n.missingSavedIdReanalyze,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleVisibilityToggle(bool isPublic) async {
    final savedId = _currentSake.savedId;
    if (savedId == null || savedId.isEmpty) {
      _showSnack(context.l10n.syncBeforeVisibility);
      return;
    }
    if (_currentSake.syncStatus != SavedSakeSyncStatus.serverSynced) {
      _showSnack(context.l10n.syncBeforeVisibility);
      return;
    }

    setState(() {
      _isVisibilityUpdating = true;
    });

    final notifier = context.read<SavedSakeNotifier>();
    final success = await notifier.updateTimelineVisibility(
      savedId: savedId,
      isPublic: isPublic,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isVisibilityUpdating = false;
    });

    if (!success) {
      _showSnack(context.l10n.errorVisibilityUpdate);
      return;
    }

    setState(() {
      _currentSake = _currentSake.copyWith(isPublic: isPublic);
    });

    _showSnack(
      isPublic
          ? context.l10n.publishedToTimeline
          : context.l10n.hiddenFromTimeline,
    );
  }

  Widget _buildMemoSection() {
    return Container(
      margin: const EdgeInsets.only(top: _blockSpacing),
      padding: const EdgeInsets.symmetric(
        vertical: _blockVerticalPadding,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.memo,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _saveMemo,
                child: Text(
                  context.l10n.save,
                  style: const TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.memoFilterHint,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tagChoices
                .map(
                  (tag) => _TagCheckbox(
                    label: tag,
                    selected: _selectedTags.contains(tag),
                    onChanged: () => _toggleTag(tag),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _impressionController,
            maxLength: 200,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              labelText: context.l10n.impressionLabel,
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              hintText: context.l10n.impressionHint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterStyle: const TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _placeController,
            readOnly: true,
            onTap: _openPlacePicker,
            maxLines: 1,
            maxLength: 60,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              labelText: context.l10n.placeConsumed,
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              hintText: context.l10n.placeConsumedHint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.08),
              suffixIcon: IconButton(
                tooltip: context.l10n.addConsumedPlace,
                onPressed: _openPlacePicker,
                icon: const Icon(
                  Icons.location_searching,
                  color: Colors.white70,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              counterStyle: const TextStyle(color: Colors.white70),
            ),
          ),
          if (_currentSake.drinkingPlace != null) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.amber,
              title: const Text(
                '写真をマップに表示',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                _currentSake.drinkingPlace!.mapPhotoPublic
                    ? '店舗のマップにこの写真を表示します'
                    : '店舗と日本酒の情報だけがマップに登録されます',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              value: _currentSake.drinkingPlace!.mapPhotoPublic,
              onChanged:
                  !_isSyncing &&
                      (_imagePaths.isNotEmpty ||
                          _currentSake.drinkingPlace!.mapPhotoPublic)
                  ? _updateMapPhotoVisibility
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _isSyncing ? null : _deleteDrinkingPlace,
                icon: const Icon(Icons.delete_outline),
                label: const Text('店舗登録を削除'),
                style: TextButton.styleFrom(foregroundColor: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGallerySection() {
    return Container(
      margin: const EdgeInsets.only(top: _blockSpacing),
      padding: const EdgeInsets.symmetric(vertical: _blockVerticalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.saveMemories,
            key: _memoryHeadingKey,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < 3; i++) ...[
                Expanded(child: _buildImageTile(i)),
                if (i < 2) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(int index) {
    final borderRadius = BorderRadius.circular(12);
    final hasImage = index < _imagePaths.length;

    if (hasImage) {
      final path = _imagePaths[index];
      if (_isRemotePath(path)) {
        return _buildRemoteImageTile(path, borderRadius: borderRadius);
      }

      final file = File(path);
      if (!file.existsSync()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaited(
            _removeImagePath(path, showToast: false, showLoading: false),
          );
        });
        return _buildAddTile(isPrimary: index == 0);
      }

      return GestureDetector(
        onTap: () => _showImagePreview(path),
        onLongPress: () => _confirmRemoveImage(path),
        child: AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: borderRadius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(file, fit: BoxFit.cover),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isPrimarySlot = index == _imagePaths.length;
    return _buildAddTile(isPrimary: isPrimarySlot);
  }

  Future<void> _scrollToMemoryHeading() async {
    final context = _memoryHeadingKey.currentContext;
    if (context == null) {
      return;
    }
    await Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildMemoCtaFooter() {
    return Container(
      color: const Color(0xFF0A1428),
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (_isImageProcessing || _isSyncing)
                ? null
                : () async {
                    await _scrollToMemoryHeading();
                  },
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_note,
                    color: Color(0xFF1D3567),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.l10n.recordPrompt,
                          style: const TextStyle(
                            color: Color(0xFF1D3567),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF1D3567),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRemoteImageTile(
    String url, {
    required BorderRadius borderRadius,
  }) {
    return GestureDetector(
      onTap: () => _showImagePreview(url),
      onLongPress: () => _confirmRemoveImage(url),
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: borderRadius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
                errorBuilder: (context, _, __) => Container(
                  color: Colors.black26,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image, color: Colors.white54),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddTile({required bool isPrimary}) {
    final borderRadius = BorderRadius.circular(12);
    final canAdd = _imagePaths.length < 3;
    final isLocked = !_canUploadMemoryImage;
    final borderColor = isLocked
        ? Colors.white24
        : (isPrimary ? const Color(0xFFFFD54F) : Colors.white24);
    final accentColor = isLocked
        ? Colors.white38
        : (isPrimary ? const Color(0xFFFFD54F) : Colors.white60);
    final backgroundColor = isLocked
        ? Colors.white.withOpacity(0.02)
        : Colors.white.withOpacity(0.05);

    return InkWell(
      onTap: () {
        if (!canAdd) {
          _showSnack(context.l10n.maxThreeImages);
          return;
        }
        _handleAddImageTap();
      },
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1.5),
            color: backgroundColor,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_a_photo, color: accentColor, size: 28),
                const SizedBox(height: 6),
                Text(
                  context.l10n.add,
                  style: TextStyle(color: accentColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAddImageTap() {
    if (_imagePaths.length >= 3) {
      _showSnack(context.l10n.maxThreeImages);
      return;
    }
    if (!_canUploadMemoryImage) {
      _showSnack(context.l10n.syncToAddImages);
      return;
    }
    if (_isImageProcessing || _isSyncing) {
      return;
    }
    _showImageSourceSheet();
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: _blockSpacing),
      padding: const EdgeInsets.symmetric(
        vertical: _blockVerticalPadding,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySection(Map<String, dynamic> community) {
    final count = (community['impressionCount'] as num?)?.toInt() ?? 0;
    final recent = community['recentImpressions'];
    final children = <Widget>[
      Text(
        context.l10n.communityImpressionCount(count),
        style: const TextStyle(color: Colors.white70),
      ),
    ];
    if (recent is List && recent.isNotEmpty) {
      children.addAll([
        const SizedBox(height: 12),
        Text(
          context.l10n.recentPublicPosts,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        ...recent.whereType<Map>().take(3).map((post) {
          final map = Map<String, dynamic>.from(post);
          final author = map['displayName'] ?? map['username'];
          final text = map['impression'] ?? map['comment'] ?? '';
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.chat_bubble_outline, color: Colors.amber),
            title: Text(
              text.toString(),
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: author == null
                ? null
                : Text(
                    author.toString(),
                    style: const TextStyle(color: Colors.white60),
                  ),
          );
        }),
      ]);
    }
    return _buildSection(
      title: context.l10n.communityImpressions,
      children: children,
    );
  }

  Widget _buildSameBrandSection(List<Map<String, dynamic>> sameBrandSakes) {
    return _buildSection(
      title: context.l10n.sameBrandSakes,
      children: sameBrandSakes
          .take(5)
          .map((item) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wine_bar_outlined, color: Colors.amber),
              title: Text(
                item['name']?.toString() ?? '-',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: item['type'] == null
                  ? null
                  : Text(
                      item['type'].toString(),
                      style: const TextStyle(color: Colors.white60),
                    ),
            );
          })
          .toList(growable: false),
    );
  }

  Widget _buildTypesSection(List<String> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.type,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types
              .map(
                (type) => Chip(
                  label: Text(
                    type,
                    style: const TextStyle(
                      color: Color(0xFF1D3567),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.15),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  bool _isValid(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  List<String> get _tagChoices {
    final sorted = <String>[];
    for (final tag in sake_master.Sake.userMemoTags) {
      if (!sorted.contains(tag)) {
        sorted.add(tag);
      }
    }
    for (final tag in _selectedTags) {
      if (!sorted.contains(tag)) {
        sorted.add(tag);
      }
    }
    return sorted;
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _openPlacePicker() async {
    FocusScope.of(context).unfocus();
    if (_currentSake.sakeId == null) {
      _showSnack('日本酒マスターと紐付いたお酒だけ店舗へ登録できます。');
      return;
    }
    var place = await PlacePickerSheet.show(
      context,
      initialPlace: _placeController.text.trim(),
    );
    if (!mounted ||
        place == null ||
        place.providerPlaceId == null ||
        place.displayName.trim().isEmpty) {
      return;
    }

    var mapPhotoPublic = false;
    if (_imagePaths.isNotEmpty) {
      final publishPhoto = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('この写真をマップに表示しますか？'),
          content: const Text(
            '表示しない場合も、この店舗と日本酒の情報はマップに登録され、5ptを獲得します。写真を表示すると、さらに10ptを獲得できます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('写真は表示しない'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('写真を表示する（+10pt）'),
            ),
          ],
        ),
      );
      if (!mounted || publishPhoto == null) return;
      mapPhotoPublic = publishPhoto;
    }
    place = place.copyWith(
      visibility: PlaceVisibility.public,
      mapPhotoPublic: mapPhotoPublic,
    );
    _placeController.text = place.displayName.trim();
    _placeDirty = true;
    _applySakeUpdate(
      _currentSake.copyWith(
        place: place.displayName.trim(),
        drinkingPlace: place,
      ),
    );
    await _saveMemo();
  }

  Future<void> _updateMapPhotoVisibility(bool makePublic) async {
    final savedId = _currentSake.savedId;
    final currentPlace = _currentSake.drinkingPlace;
    if (savedId == null || savedId.isEmpty || currentPlace == null) return;
    setState(() => _isSyncing = true);
    MapContributionSaveResult? result;
    try {
      result = await context
          .read<PlaceMapRepository>()
          .updateMapPhotoVisibility(
            savedId: savedId,
            mapPhotoPublic: makePublic,
          );
    } catch (error) {
      logger.warning('マップ写真の公開設定変更に失敗しました: $error');
    }
    if (!mounted) return;
    setState(() => _isSyncing = false);
    if (result == null) {
      _showSnack(context.l10n.errorVisibilityUpdate);
      return;
    }
    _applySakeUpdate(
      _currentSake.copyWith(drinkingPlace: result.drinkingPlace),
      toastMessage: result.pointsAwarded > 0
          ? '写真をマップに公開しました（+${result.pointsAwarded}pt）'
          : makePublic
          ? '写真をマップに表示します'
          : '写真をマップから非表示にしました',
    );
    if (result.pointsAwarded > 0) {
      unawaited(context.read<MyPageNotifier>().loadAchievementStats());
    }
  }

  Future<void> _deleteDrinkingPlace() async {
    final savedId = _currentSake.savedId;
    if (savedId == null || savedId.isEmpty) return;
    final isLocalOnly =
        context.read<AuthState>().user == null ||
        _currentSake.syncStatus == SavedSakeSyncStatus.localOnly;
    if (isLocalOnly) {
      _clearLocalDrinkingPlace();
      return;
    }
    setState(() => _isSyncing = true);
    var deleted = false;
    try {
      deleted = await context.read<PlaceMapRepository>().deletePlace(savedId);
    } catch (error) {
      logger.warning('店舗情報の削除に失敗しました: $error');
    }
    if (!mounted) return;
    setState(() => _isSyncing = false);
    if (!deleted) {
      _showSnack(context.l10n.errorSaveToServer);
      return;
    }
    _clearLocalDrinkingPlace();
  }

  void _clearLocalDrinkingPlace() {
    _placeDirty = false;
    _placeController.clear();
    _applySakeUpdate(
      _currentSake.copyWith(place: null, drinkingPlace: null),
      toastMessage: context.l10n.memoSaved,
    );
  }

  Future<void> _saveMemo() async {
    FocusScope.of(context).unfocus();
    final isLoggedIn = context.read<AuthState>().user != null;
    final enteredPlace = _placeController.text.trim();
    final currentPlace = _currentSake.drinkingPlace;
    final editedPlace = !_placeDirty
        ? currentPlace
        : enteredPlace.isEmpty
        ? null
        : currentPlace?.displayName == enteredPlace
        ? currentPlace
        : DrinkingPlace(displayName: enteredPlace);

    final updatedSake = _currentSake.copyWith(
      impression: _impressionController.text.trim().isEmpty
          ? null
          : _impressionController.text.trim(),
      place: _placeController.text.trim().isEmpty
          ? null
          : _placeController.text.trim(),
      drinkingPlace: editedPlace,
      userTags: _selectedTags.isEmpty ? null : _selectedTags.toList(),
      imagePaths: _imagePaths.isEmpty ? null : _imagePaths,
      syncStatus: isLoggedIn
          ? SavedSakeSyncStatus.localOnly
          : _currentSake.syncStatus,
    );

    _applySakeUpdate(
      updatedSake,
      toastMessage: isLoggedIn ? null : context.l10n.memoSaved,
    );

    if (!isLoggedIn) {
      return;
    }

    final savedId = updatedSake.savedId;
    if (savedId == null || savedId.isEmpty) {
      _showSnack(context.l10n.missingSavedIdServerSave);
      return;
    }

    setState(() {
      _isSyncing = true;
      _progressMessage = context.l10n.savingToServer;
    });

    final notifier = context.read<SavedSakeNotifier>();
    Sake? synced;
    try {
      synced = await notifier.syncSavedSakeToServer(savedId);
    } catch (error, stackTrace) {
      logger.warning('メモ同期で例外が発生しました: $error');
      logger.info(stackTrace.toString());
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSyncing = false;
      _progressMessage = null;
    });

    if (synced == null) {
      _showSnack(context.l10n.errorSaveToServer);
      return;
    }

    _applySakeUpdate(
      synced,
      toastMessage: _placeDirty ? null : context.l10n.savedToServer,
    );
    if (_placeDirty) {
      await _syncDirtyPlace(savedId);
    }
  }

  Future<void> _syncDirtyPlace(String savedId) async {
    final place = _currentSake.drinkingPlace;
    setState(() {
      _isSyncing = true;
      _progressMessage = context.l10n.savingToServer;
    });
    MapContributionSaveResult? result;
    var deleted = false;
    try {
      final repository = context.read<PlaceMapRepository>();
      if (place == null || place.displayName.trim().isEmpty) {
        deleted = await repository.deletePlace(savedId);
      } else {
        result = await repository.savePlace(savedId: savedId, place: place);
      }
    } catch (error, stackTrace) {
      logger.warning('店舗情報の同期に失敗しました: $error');
      logger.info(stackTrace.toString());
    }
    if (!mounted) return;
    setState(() {
      _isSyncing = false;
      _progressMessage = null;
    });
    if (result == null && !deleted) {
      _showSnack(context.l10n.errorSaveToServer);
      return;
    }
    _placeDirty = false;
    if (result != null) {
      final verifiedPlace = result.drinkingPlace;
      _placeController.text = verifiedPlace.displayName;
      _applySakeUpdate(
        _currentSake.copyWith(
          place: verifiedPlace.displayName,
          drinkingPlace: verifiedPlace,
          syncStatus: SavedSakeSyncStatus.serverSynced,
        ),
        toastMessage: result.pointsAwarded > 0
            ? 'マップへ登録しました（+${result.pointsAwarded}pt）'
            : context.l10n.savedToServer,
      );
      if (result.pointsAwarded > 0) {
        unawaited(context.read<MyPageNotifier>().loadAchievementStats());
      }
    } else {
      _clearLocalDrinkingPlace();
    }
  }

  String? _formatSavedDate(String? savedId) {
    final date = _savedDateFromId(savedId);
    if (date == null) {
      return null;
    }
    return DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(date);
  }

  DateTime? _savedDateFromId(String? savedId) {
    if (savedId == null) {
      return null;
    }
    final parts = savedId.split('_');
    if (parts.length < 3) {
      return null;
    }
    final millis = int.tryParse(parts[1]);
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> _handleSaveName({required bool reanalyze}) async {
    FocusScope.of(context).unfocus();
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      _showSnack(context.l10n.errorEnterSakeNameDetail);
      return;
    }

    final originalName = _currentSake.name ?? '';
    final nameChanged = trimmed != originalName;

    if (!nameChanged && !reanalyze) {
      _showSnack(context.l10n.noChanges);
      return;
    }

    final authNotifier = context.read<AuthNotifier>();
    final isLoggedIn = authNotifier.state.user != null;
    final shouldMarkUnsynced = isLoggedIn && (nameChanged || reanalyze);

    final updated = _currentSake.copyWith(
      name: trimmed,
      syncStatus: shouldMarkUnsynced
          ? SavedSakeSyncStatus.localOnly
          : _currentSake.syncStatus,
    );

    _applySakeUpdate(
      updated,
      toastMessage: !reanalyze ? context.l10n.nameSaved : null,
      refreshTags: false,
    );

    if (!reanalyze) {
      if (mounted && _hasNameChanged) {
        setState(() {
          _hasNameChanged = false;
        });
      }
      return;
    }

    if (!isLoggedIn) {
      _showSnack(context.l10n.loginForServerReanalyze);
      if (mounted && _hasNameChanged) {
        setState(() {
          _hasNameChanged = false;
        });
      }
      return;
    }

    final savedId = updated.savedId;
    if (savedId == null || savedId.isEmpty) {
      _showSnack(context.l10n.savedIdNotFound);
      return;
    }

    setState(() {
      _isSyncing = true;
      _progressMessage = context.l10n.reanalyzing;
    });

    final notifier = context.read<SavedSakeNotifier>();
    Sake? synced;
    try {
      synced = await notifier.syncSavedSakeToServer(savedId);
    } catch (error, stackTrace) {
      logger.warning('再解析の同期処理で例外が発生しました: $error');
      logger.info(stackTrace.toString());
    }

    if (!mounted) {
      return;
    }

    if (synced == null) {
      setState(() {
        _isSyncing = false;
        _progressMessage = null;
      });
      _showSnack(context.l10n.errorReanalyze);
      return;
    }

    Sake? fetched;
    try {
      final repository = context.read<SakeMenuRecognitionRepository>();
      final preferences = context
          .read<MyPageNotifier>()
          .state
          .preferences
          ?.trim();
      fetched = await repository.getSakeInfo(
        trimmed,
        type: synced.type,
        preferences: preferences == null || preferences.isEmpty
            ? null
            : preferences,
      );
    } catch (error, stackTrace) {
      logger.warning('getSakeInfo の取得に失敗しました: $error');
      logger.info(stackTrace.toString());
    }

    if (fetched != null) {
      await notifier.updateSavedSakeWithInfo(
        savedId,
        fetched.copyWith(savedId: savedId),
      );
    }

    final Sake resolvedSynced = synced.copyWith(name: trimmed);

    final Sake latest = notifier.state.savedSakeList.firstWhere(
      (item) => item.savedId == savedId,
      orElse: () => resolvedSynced,
    );

    _applySakeUpdate(
      latest.copyWith(
        name: trimmed,
        syncStatus: SavedSakeSyncStatus.serverSynced,
      ),
      toastMessage: fetched != null
          ? context.l10n.reanalyzeCompleted
          : context.l10n.savedToServer,
      updateNotifier: false,
    );

    if (fetched == null) {
      _showSnack(context.l10n.errorSakeDetailFetch);
    }

    if (mounted) {
      setState(() {
        _isSyncing = false;
        _progressMessage = null;
        _hasNameChanged = false;
      });
    }
  }

  Future<void> _handleManualSync() async {
    final savedId = _currentSake.savedId;
    if (savedId == null || savedId.isEmpty) {
      _showSnack(context.l10n.syncableSavedIdNotFound);
      return;
    }

    setState(() {
      _isSyncing = true;
      _progressMessage = context.l10n.syncingWithServer;
    });

    final notifier = context.read<SavedSakeNotifier>();
    final synced = await notifier.syncSavedSakeToServer(savedId);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSyncing = false;
      _progressMessage = null;
    });

    if (synced == null) {
      _showSnack(context.l10n.errorSync);
      return;
    }

    _applySakeUpdate(
      synced,
      toastMessage: context.l10n.syncedWithServer,
      updateNotifier: false,
    );
  }

  void _applySakeUpdate(
    Sake updated, {
    String? toastMessage,
    bool refreshTags = true,
    bool updateNotifier = true,
  }) {
    if (updateNotifier) {
      context.read<SavedSakeNotifier>().updateSavedSake(updated);
    }
    setState(() {
      _currentSake = updated;
      _imagePaths = [...(updated.imagePaths ?? <String>[])];
      if (refreshTags) {
        _selectedTags = {...(updated.userTags ?? <String>[])};
      }
    });
    final newName = updated.name ?? '';
    if (_nameController.text != newName) {
      _nameController
        ..text = newName
        ..selection = TextSelection.collapsed(offset: newName.length);
    }
    if (toastMessage != null) {
      _showSnack(toastMessage);
    }
  }

  void _handleNameFieldChanged() {
    final trimmed = _nameController.text.trim();
    final currentName = (_currentSake.name ?? '').trim();
    final changed = trimmed != currentName;
    if (changed != _hasNameChanged && mounted) {
      setState(() {
        _hasNameChanged = changed;
      });
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1D3567).withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showImageSourceSheet() {
    if (_imagePaths.length >= 3) {
      _showSnack(context.l10n.maxThreeImages);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_camera,
                  color: Color(0xFF1D3567),
                ),
                title: Text(context.l10n.takePhoto),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndAddImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF1D3567),
                ),
                title: Text(context.l10n.selectFromPhotoLibrary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndAddImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndAddImage(ImageSource source) async {
    if (_imagePaths.length >= 3) {
      _showSnack(context.l10n.maxThreeImages);
      return;
    }

    final file = await CustomImagePicker.pickImage(source: source);
    if (!mounted || file == null) {
      return;
    }

    File workingFile = file;
    final cropped = await ImageCropperService.cropAndRotateImage(file.path);
    if (cropped != null) {
      workingFile = cropped;
    }

    final savedPath = await ImageCropperService.saveImagePermanently(
      workingFile,
      'saved_sake',
    );

    if (!mounted || savedPath == null) {
      _showSnack(context.l10n.imageSaveFailed);
      return;
    }

    final savedId = _currentSake.savedId;
    if (savedId == null) {
      _showSnack(context.l10n.savedInformationNotFound);
      return;
    }

    final notifier = context.read<SavedSakeNotifier>();
    if (mounted) {
      setState(() {
        _isImageProcessing = true;
      });
    }

    Sake? updated;
    try {
      updated = await notifier.addImageToSavedSake(
        savedId: savedId,
        localPath: savedPath,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImageProcessing = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    if (updated == null) {
      try {
        final file = File(savedPath);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // ignore delete errors
      }
      _showSnack(context.l10n.errorImageAdd);
      return;
    }

    _applySakeUpdate(
      updated,
      toastMessage: context.l10n.imageAdded,
      refreshTags: false,
      updateNotifier: false,
    );
  }

  Future<void> _confirmRemoveImage(String path) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.deleteImageConfirmation),
          content: Text(context.l10n.deleteImageDescription),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );

    if (result != true || !mounted) {
      return;
    }

    await _removeImagePath(path, showToast: true);
  }

  Future<void> _removeImagePath(
    String path, {
    bool showToast = true,
    bool showLoading = true,
  }) async {
    final savedId = _currentSake.savedId;
    if (savedId == null) {
      _showSnack(context.l10n.savedInformationNotFound);
      return;
    }

    final notifier = context.read<SavedSakeNotifier>();
    if (showLoading && mounted) {
      setState(() {
        _isImageProcessing = true;
      });
    }

    Sake? updated;
    try {
      updated = await notifier.removeImageFromSavedSake(
        savedId: savedId,
        imagePath: path,
      );
    } finally {
      if (showLoading && mounted) {
        setState(() {
          _isImageProcessing = false;
        });
      }
    }

    if (!mounted) {
      return;
    }

    if (updated == null) {
      _showSnack(context.l10n.errorImageDelete);
      return;
    }

    if (!_isRemotePath(path)) {
      try {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (_) {
        // ignore delete errors
      }
    }

    _applySakeUpdate(
      updated,
      toastMessage: showToast ? context.l10n.imageDeleted : null,
      refreshTags: false,
      updateNotifier: false,
    );
  }

  void _showImagePreview(String path) {
    showDialog<void>(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: InteractiveViewer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _isRemotePath(path)
                        ? Image.network(
                            path,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            },
                            errorBuilder: (context, _, __) => const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white54,
                                size: 48,
                              ),
                            ),
                          )
                        : Image.file(File(path), fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () async {
                    Navigator.of(context).pop();
                    await _removeImagePath(path, showToast: true);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      context.l10n.deleteImage,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleFavorite(
    FavoriteNotifier notifier,
    bool isFavorited,
  ) async {
    final favorite = FavoriteSake(
      name: _currentSake.name ?? '名称不明',
      type: _currentSake.type,
    );
    if (!isFavorited && notifier.hasReachedGuestLimit) {
      await GuestLimitDialog.showFavoriteLimit(
        context,
        maxCount: FavoriteNotifier.guestFavoriteLimit,
      );
      return;
    }
    try {
      await notifier.addOrRemoveFavorite(favorite);
    } on FavoriteGuestLimitReachedException {
      await GuestLimitDialog.showFavoriteLimit(
        context,
        maxCount: FavoriteNotifier.guestFavoriteLimit,
      );
      return;
    }
    _showSnack(
      isFavorited
          ? context.l10n.removedFromFavoritesToast
          : context.l10n.addedToFavorites,
    );
  }
}

class _TagCheckbox extends StatelessWidget {
  const _TagCheckbox({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFFFD54F).withOpacity(0.25)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFFFD54F) : Colors.white24,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: selected,
              onChanged: (_) => onChanged(),
              checkColor: const Color(0xFF1D3567),
              activeColor: const Color(0xFFFFD54F),
              side: const BorderSide(color: Colors.white60, width: 1.2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
