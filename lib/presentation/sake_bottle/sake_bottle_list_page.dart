import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/common/utils/file_utils.dart';

import '../../common/localization/localization_extensions.dart';
import '../../domain/eintities/sake_bottle_image.dart';
import '../common/widgets/primary_app_bar.dart';
import 'sake_bottle_list_page_notifier.dart';

class SakeBottleListPage extends StatelessWidget {
  const SakeBottleListPage._({Key? key}) : super(key: key);

  static Widget wrapped() {
    return StateNotifierProvider<SakeBottleListPageNotifier,
        SakeBottleListPageState>(
      create: (context) => SakeBottleListPageNotifier(
        context: context,
      ),
      child: const SakeBottleListPage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.read<SakeBottleListPageNotifier>();
    final isLoading =
        context.select((SakeBottleListPageState state) => state.isLoading);
    final sakeBottleImages = context
        .select((SakeBottleListPageState state) => state.sakeBottleImages);
    final errorMessage =
        context.select((SakeBottleListPageState state) => state.errorMessage);

    return Scaffold(
      appBar: PrimaryAppBar(
        title: context.l10n.bottleList,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D3567), Color(0xFF0A1428)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () => notifier.refreshSakeBottleImages(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  context.l10n.bottleListClosingNotice,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : errorMessage != null
                        ? _buildErrorState(context, errorMessage)
                        : sakeBottleImages.isEmpty
                            ? _buildEmptyState(context)
                            : _buildGridView(context, sakeBottleImages),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.wine_bar,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.noBottleImages,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.captureBottleHint,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            context.l10n.errorOccurred,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizeLegacyMessage(context.l10n, message),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(
    BuildContext context,
    List<SakeBottleImage> images,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.75,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          final image = images[index];
          return _buildImageCard(context, image);
        },
      ),
    );
  }

  Widget _buildImageCard(
    BuildContext context,
    SakeBottleImage image,
  ) {
    return GestureDetector(
      onTap: () {
        _showSakeBottleDialog(context, image);
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image(
                  image: FileUtils.safeLoadImage(
                    image.path,
                    base64Image: image.base64Image,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.sakeName == null
                        ? context.l10n.unknownSake
                        : localizeLegacyMessage(
                            context.l10n,
                            image.sakeName!,
                          ),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(image.capturedAt),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  void _showSakeBottleDialog(BuildContext context, SakeBottleImage image) {
    // 先にnotifierを取得しておく
    final notifier = context.read<SakeBottleListPageNotifier>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image(
                    image: FileUtils.safeLoadImage(
                      image.path,
                      base64Image: image.base64Image,
                    ),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  image.sakeName == null
                      ? context.l10n.unknownSake
                      : localizeLegacyMessage(
                          context.l10n,
                          image.sakeName!,
                        ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (image.type != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    image.type!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  context.l10n.capturedDate(_formatDate(image.capturedAt)),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(context.l10n.close),
                    ),
                    TextButton(
                      onPressed: () {
                        _confirmDeleteImage(dialogContext, image, notifier);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: Text(context.l10n.delete),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteImage(BuildContext context, SakeBottleImage image,
      SakeBottleListPageNotifier notifier) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(context.l10n.deleteBottleImageTitle),
          content: Text(context.l10n.deleteBottleImageDescription),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // ダイアログを閉じる
              },
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                // 外部で取得したnotifierを使用
                notifier.deleteSakeBottleImage(image.id);
                Navigator.of(dialogContext).pop(); // 削除確認ダイアログを閉じる
                Navigator.of(context).pop(); // 詳細ダイアログを閉じる
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
  }
}
