import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import 'package:provider/provider.dart';

import '../../common/sake/master.dart' as sake_master;
import '../../common/utils/custom_image_picker.dart';
import '../../common/utils/image_cropper_service.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import '../../domain/notifier/saved_sake/saved_sake_notifier.dart';

class SavedSakeDetailPage extends StatefulWidget {
  const SavedSakeDetailPage({super.key, required this.sake});

  final Sake sake;

  @override
  State<SavedSakeDetailPage> createState() => _SavedSakeDetailPageState();
}

class _SavedSakeDetailPageState extends State<SavedSakeDetailPage> {
  late final TextEditingController _impressionController;
  late final TextEditingController _placeController;
  late Sake _currentSake;
  late Set<String> _selectedTags;
  late List<String> _imagePaths;

  @override
  void initState() {
    super.initState();
    _currentSake = widget.sake;
    _impressionController =
        TextEditingController(text: widget.sake.impression ?? '');
    _placeController = TextEditingController(text: widget.sake.place ?? '');
    _selectedTags = {...(widget.sake.userTags ?? <String>[])};
    _imagePaths = [...(widget.sake.imagePaths ?? <String>[])];
  }

  @override
  void dispose() {
    _impressionController.dispose();
    _placeController.dispose();
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.redAccent : Colors.white,
            ),
            onPressed: () => _toggleFavorite(favoriteNotifier, isFavorited),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeaderCard(themeColor),
              _buildImageGallerySection(),
              _buildMemoSection(),
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
                  margin: const EdgeInsets.only(top: 24),
                  padding: const EdgeInsets.all(16),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(Color themeColor) {
    final isRecommended = (_currentSake.recommendationScore ?? 0) >= 7;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentSake.name ?? '名称不明',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (_isValid(_currentSake.brewery))
            Text(
              _currentSake.brewery!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          if (_isValid(_currentSake.type))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _currentSake.type!,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
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
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (isRecommended)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
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
        ],
      ),
    );
  }

  Widget _buildMemoSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: _saveMemo,
                child: const Text(
                  '保存',
                  style: TextStyle(
                    color: Color(0xFFFFD54F),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: '感想 (200文字まで)',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: '味わいや香りの印象を記録しましょう',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: '飲んだ場所',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              hintText: 'お店やイベント名などを記録できます',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
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
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            Expanded(child: _buildImageTile(i)),
            if (i < 2) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildImageTile(int index) {
    final borderRadius = BorderRadius.circular(12);
    final hasImage = index < _imagePaths.length;

    if (hasImage) {
      final path = _imagePaths[index];
      final file = File(path);
      if (!file.existsSync()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _removeImagePath(path, showToast: false);
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
                    fontSize: 12,
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
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
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
              fontSize: 16,
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
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
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
            fontSize: 12,
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

  void _saveMemo() {
    FocusScope.of(context).unfocus();
    final updatedSake = _currentSake.copyWith(
      impression: _impressionController.text.trim().isEmpty
          ? null
          : _impressionController.text.trim(),
      place: _placeController.text.trim().isEmpty
          ? null
          : _placeController.text.trim(),
      userTags: _selectedTags.isEmpty ? null : _selectedTags.toList(),
      imagePaths: _imagePaths.isEmpty ? null : _imagePaths,
    );

    _applySakeUpdate(updatedSake, toastMessage: 'メモを保存しました');
  }

  void _applySakeUpdate(Sake updated,
      {String? toastMessage, bool refreshTags = true}) {
    context.read<SavedSakeNotifier>().updateSavedSake(updated);
    setState(() {
      _currentSake = updated;
      _imagePaths = [...(updated.imagePaths ?? <String>[])];
      if (refreshTags) {
        _selectedTags = {...(updated.userTags ?? <String>[])};
      }
    });
    if (toastMessage != null) {
      _showSnack(toastMessage);
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

    final newPaths = [..._imagePaths, savedPath];
    _applySakeUpdate(
      _currentSake.copyWith(imagePaths: newPaths),
      toastMessage: '画像を追加しました',
      refreshTags: false,
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

    _removeImagePath(path, showToast: true);
  }

  void _removeImagePath(String path, {bool showToast = true}) {
    final newPaths = [..._imagePaths]..remove(path);
    _applySakeUpdate(
      _currentSake.copyWith(imagePaths: newPaths.isEmpty ? null : newPaths),
      toastMessage: showToast ? '画像を削除しました' : null,
      refreshTags: false,
    );

    try {
      final file = File(path);
      if (file.existsSync()) {
        file.deleteSync();
      }
    } catch (_) {
      // ignore delete errors
    }
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
                    child: Image.file(
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
                  onTap: () {
                    Navigator.of(context).pop();
                    _removeImagePath(path, showToast: true);
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

  void _toggleFavorite(FavoriteNotifier notifier, bool isFavorited) {
    final favorite = FavoriteSake(
      name: _currentSake.name ?? '名称不明',
      type: _currentSake.type,
    );
    notifier.addOrRemoveFavorite(favorite);
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
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
