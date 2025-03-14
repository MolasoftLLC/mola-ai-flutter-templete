import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';
import '../../domain/eintities/sake_bottle_image.dart';
import '../../domain/repository/sake_bottle_image_repository.dart';
import 'sake_bottle_list_page_notifier.dart';

class SakeBottleListPage extends StatelessWidget {
  const SakeBottleListPage._({Key? key}) : super(key: key);

  static Widget wrapped() {
    return StateNotifierProvider<SakeBottleListPageNotifier, SakeBottleListPageState>(
      create: (context) => SakeBottleListPageNotifier(
        context: context,
      ),
      child: const SakeBottleListPage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<SakeBottleListPageNotifier>(context, listen: false);
    final isLoading = context.select((SakeBottleListPageState state) => state.isLoading);
    final sakeBottleImages = context.select((SakeBottleListPageState state) => state.sakeBottleImages);
    final errorMessage = context.select((SakeBottleListPageState state) => state.errorMessage);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D3567),
        elevation: 0,
        title: const Text(
          '酒瓶リスト',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              notifier.refreshSakeBottleImages();
            },
          ),
        ],
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
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : errorMessage != null
                  ? _buildErrorState(errorMessage)
                  : sakeBottleImages.isEmpty
                      ? _buildEmptyState()
                      : _buildGridView(context, sakeBottleImages, notifier),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
          const Text(
            '保存された酒瓶画像はありません',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '酒瓶検索で画像を撮影してみましょう',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
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
            'エラーが発生しました',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
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
    SakeBottleListPageNotifier notifier,
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
          return _buildImageCard(context, image, notifier);
        },
      ),
    );
  }

  Widget _buildImageCard(
    BuildContext context,
    SakeBottleImage image,
    SakeBottleListPageNotifier notifier,
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.file(
                  File(image.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    image.sakeName ?? '不明な酒',
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
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                  child: Image.file(
                    File(image.path),
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  image.sakeName ?? '不明な酒',
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
                  '撮影日: ${_formatDate(image.capturedAt)}',
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
                        Navigator.of(context).pop();
                      },
                      child: const Text('閉じる'),
                    ),
                    TextButton(
                      onPressed: () {
                        _confirmDeleteImage(context, image);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('削除'),
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

  void _confirmDeleteImage(BuildContext context, SakeBottleImage image) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('画像を削除'),
          content: const Text('この酒瓶画像を削除してもよろしいですか？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                final notifier = Provider.of<SakeBottleListPageNotifier>(
                  context,
                  listen: false,
                );
                notifier.deleteSakeBottleImage(image.id);
                Navigator.of(context).pop(); // 削除確認ダイアログを閉じる
                Navigator.of(context).pop(); // 詳細ダイアログを閉じる
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }
}
