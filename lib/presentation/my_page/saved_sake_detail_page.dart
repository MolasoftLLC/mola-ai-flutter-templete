import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:provider/provider.dart';

import '../../common/sake/master.dart' as sake_master;
import '../../common/utils/custom_image_picker.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../domain/notifier/auth/auth_notifier.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../../domain/notifier/my_page/my_page_notifier.dart';
import '../../domain/repository/sake_menu_recognition_repository.dart';
import '../../common/logger.dart';
import '../common/widgets/guest_limit_dialog.dart';

const double _blockSpacing = 16;
const double _blockVerticalPadding = 20;

class SavedSakeDetailPage extends StatefulWidget {
  const SavedSakeDetailPage({super.key, required this.sake});

  final Sake sake;

  @override
  State<SavedSakeDetailPage> createState() => _SavedSakeDetailPageState();
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
  String? _progressMessage;
  bool _hasNameChanged = false;
  final GlobalKey _memoryHeadingKey = GlobalKey();

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
    _impressionController =
        TextEditingController(text: widget.sake.impression ?? '');
    _placeController = TextEditingController(text: widget.sake.place ?? '');
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
    final isFavorited = context.select((FavoriteState state) =>
        state.myFavoriteList.any((fav) =>
            fav.name == (_currentSake.name ?? '名称不明') &&
            fav.type == _currentSake.type));

    final infoRows = <Widget>[];
    if (_isValid(_currentSake.brewery)) {
      infoRows.add(
        _buildInfoRow('蔵元', _currentSake.brewery!, Icons.home_work),
      );
    }
    if (_isValid(_currentSake.price)) {
      infoRows.add(
        _buildInfoRow('価格', _currentSake.price!, Icons.price_check),
      );
    }
    if (_currentSake.sakeMeterValue != null) {
      infoRows.add(
        _buildInfoRow(
          '日本酒度',
          _currentSake.sakeMeterValue!.toString(),
          Icons.science,
        ),
      );
    }
    if (_currentSake.recommendationScore != null) {
      infoRows.add(
        _buildInfoRow(
          'おすすめ度',
          '${_currentSake.recommendationScore}',
          Icons.star,
        ),
      );
    }

    final featureWidgets = <Widget>[];
    if (_isValid(_currentSake.taste)) {
      featureWidgets.add(_buildBodyText('味わい', _currentSake.taste!));
    }
    if (_isValid(_currentSake.description)) {
      featureWidgets.add(_buildBodyText('説明', _currentSake.description!));
    }
    if (_currentSake.types != null && _currentSake.types!.isNotEmpty) {
      featureWidgets.add(_buildTypesSection(_currentSake.types!));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: themeColor,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _currentSake.name ?? '日本酒詳細',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
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
                      title: '基本情報',
                      children: infoRows,
                    ),
                  if (featureWidgets.isNotEmpty)
                    _buildSection(
                      title: 'テイスト・特徴',
                      children: featureWidgets,
                    ),
                  if (infoRows.isEmpty && featureWidgets.isEmpty)
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
                      child: const Text(
                        '詳細情報が登録されていません。',
                        style: TextStyle(color: Colors.white70),
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
                        _progressMessage ?? (_isSyncing ? '処理中…' : '処理中…'),
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
    final isRecommended = (_currentSake.recommendationScore ?? 0) >= 7;
    final canReanalyze =
        isLoggedIn && (_currentSake.savedId?.isNotEmpty ?? false);
    final savedDateText = _formatSavedDate(_currentSake.savedId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (savedDateText != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              '保存日 $savedDateText',
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                  ),
                ),
              if (_isValid(_currentSake.type))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _currentSake.type!,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ),
              if (_isValid(_currentSake.place))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.place, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _currentSake.place!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (isRecommended)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.redAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.recommend, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        (_currentSake.recommendationScore ?? 0) >= 8
                            ? '超おすすめ！'
                            : 'おすすめ！',
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
                        _currentSake.syncStatus == SavedSakeSyncStatus.serverSynced
                            ? Colors.lightBlueAccent
                            : Colors.orangeAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentSake.syncStatus ==
                              SavedSakeSyncStatus.serverSynced
                          ? 'サーバーに保存済み'
                          : '未同期（この端末にのみ保存されています）',
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
                      label: const Text('サーバーへ同期'),
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
            ],
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
    final String buttonLabel =
        hasChanged ? (allowReanalyze ? '再解析' : '保存') : '変更';
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
                    labelText: '日本酒の名前',
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
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
                          _showSnack('ログインすると再解析できます');
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
              'ログインすると名前変更後に再解析できます',
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
              '保存IDが未設定のため再解析は利用できません',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ),
      ],
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
              const Text(
                'メモ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _saveMemo,
                child: const Text(
                  '保存',
                  style: TextStyle(
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
            '設定しておくと一覧でフィルタリングができる！',
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
              labelText: '感想 (200文字まで)',
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              hintText: '味わいや香りの印象を記録しましょう',
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
            maxLines: 1,
            maxLength: 30,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              labelText: '飲んだ場所',
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              hintText: 'お店やイベント名などを記録できます',
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
            '思い出も残そう',
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
            _removeImagePath(
              path,
              showToast: false,
              showLoading: false,
            ),
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
                Image.file(
                  file,
                  fit: BoxFit.cover,
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
                      children: const [
                        Text(
                          'このお酒の記録を残しませんか？',
                          style: TextStyle(
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

  Widget _buildRemoteImageTile(String url,
      {required BorderRadius borderRadius}) {
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
                  child: const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                  ),
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

    return InkWell(
      onTap: canAdd ? _showImageSourceSheet : null,
      borderRadius: borderRadius,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            border: Border.all(
              color: isPrimary ? const Color(0xFFFFD54F) : Colors.white24,
              width: 1.5,
            ),
            color: Colors.white.withOpacity(0.05),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_a_photo,
                  color: isPrimary ? const Color(0xFFFFD54F) : Colors.white60,
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  '追加',
                  style: TextStyle(
                    color: isPrimary ? const Color(0xFFFFD54F) : Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
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

  Widget _buildTypesSection(List<String> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'タイプ',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
          ),
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

  Future<void> _saveMemo() async {
    FocusScope.of(context).unfocus();
    final authNotifier = context.read<AuthNotifier>();
    final isLoggedIn = authNotifier.state.user != null;

    final updatedSake = _currentSake.copyWith(
      impression: _impressionController.text.trim().isEmpty
          ? null
          : _impressionController.text.trim(),
      place: _placeController.text.trim().isEmpty
          ? null
          : _placeController.text.trim(),
      userTags: _selectedTags.isEmpty ? null : _selectedTags.toList(),
      imagePaths: _imagePaths.isEmpty ? null : _imagePaths,
      syncStatus: isLoggedIn
          ? SavedSakeSyncStatus.localOnly
          : _currentSake.syncStatus,
    );

    _applySakeUpdate(
      updatedSake,
      toastMessage: isLoggedIn ? null : 'メモを保存しました',
    );

    if (!isLoggedIn) {
      return;
    }

    final savedId = updatedSake.savedId;
    if (savedId == null || savedId.isEmpty) {
      _showSnack('保存IDが未設定のためサーバー保存はできません');
      return;
    }

    setState(() {
      _isSyncing = true;
      _progressMessage = 'サーバーに保存中…';
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
      _showSnack('サーバーへの保存に失敗しました。通信環境をご確認ください。');
      return;
    }

    _applySakeUpdate(
      synced,
      toastMessage: 'サーバーに保存しました',
    );
  }

  String? _formatSavedDate(String? savedId) {
    final date = _savedDateFromId(savedId);
    if (date == null) {
      return null;
    }
    return DateFormat('yyyy/MM/dd').format(date);
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
      _showSnack('日本酒の名前を入力してください');
      return;
    }

    final originalName = _currentSake.name ?? '';
    final nameChanged = trimmed != originalName;

    if (!nameChanged && !reanalyze) {
      _showSnack('変更された内容がありません');
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
      toastMessage: !reanalyze ? '名前を保存しました' : null,
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
      _showSnack('ログインするとサーバー再解析を利用できます');
      if (mounted && _hasNameChanged) {
        setState(() {
          _hasNameChanged = false;
        });
      }
      return;
    }

    final savedId = updated.savedId;
    if (savedId == null || savedId.isEmpty) {
      _showSnack('保存IDが見つかりませんでした');
      return;
    }

    setState(() {
      _isSyncing = true;
      _progressMessage = '再解析中…';
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
      _showSnack('再解析に失敗しました。通信環境をご確認のうえ再度お試しください。');
      return;
    }

    Sake? fetched;
    try {
      final repository = context.read<SakeMenuRecognitionRepository>();
      final preferences =
          context.read<MyPageNotifier>().state.preferences?.trim();
      fetched = await repository.getSakeInfo(
        trimmed,
        type: synced.type,
        preferences:
            preferences == null || preferences.isEmpty ? null : preferences,
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
      toastMessage: fetched != null ? '再解析が完了しました' : 'サーバーに保存しました',
      updateNotifier: false,
    );

    if (fetched == null) {
      _showSnack('詳細情報の取得に失敗しました');
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
      _showSnack('同期できる保存IDが見つかりませんでした。');
      return;
    }

    setState(() {
      _isSyncing = true;
      _progressMessage = 'サーバーと同期中…';
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
      _showSnack('同期に失敗しました。通信環境をご確認のうえ再度お試しください。');
      return;
    }

    _applySakeUpdate(
      synced,
      toastMessage: 'サーバーと同期しました！',
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
      _showSnack('画像は最大3枚までです');
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
                leading:
                    const Icon(Icons.photo_camera, color: Color(0xFF1D3567)),
                title: const Text('カメラで撮影'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndAddImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: Color(0xFF1D3567)),
                title: const Text('フォトライブラリから選択'),
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
      _showSnack('画像は最大3枚までです');
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
      _showSnack('画像の保存に失敗しました');
      return;
    }

    final savedId = _currentSake.savedId;
    if (savedId == null) {
      _showSnack('保存情報が見つかりません');
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
      _showSnack('画像の追加に失敗しました');
      return;
    }

    _applySakeUpdate(
      updated,
      toastMessage: '画像を追加しました',
      refreshTags: false,
      updateNotifier: false,
    );
  }

  Future<void> _confirmRemoveImage(String path) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('画像を削除しますか？'),
          content: const Text('この画像をリストから削除します。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('削除'),
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
      _showSnack('保存情報が見つかりません');
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
      _showSnack('画像の削除に失敗しました');
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
      toastMessage: showToast ? '画像を削除しました' : null,
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                        : Image.file(
                            File(path),
                            fit: BoxFit.contain,
                          ),
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
                    child: const Text(
                      '画像を削除',
                      style: TextStyle(
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
      FavoriteNotifier notifier, bool isFavorited) async {
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
      isFavorited ? 'お気に入りから削除しました' : 'お気に入りに追加しました',
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
