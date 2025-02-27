import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mola_gemini_flutter_template/presentation/common/loading/ai_loading.dart';
import 'package:provider/provider.dart';

import '../../common/assets.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import 'main_search_page_notifier.dart';

class MainSearchPage extends StatelessWidget {
  const MainSearchPage._({Key? key}) : super(key: key);

  static Widget wrapped() {
    return MultiProvider(
      providers: [
        StateNotifierProvider<MainSearchPageNotifier, MainSearchPageState>(
          create: (context) => MainSearchPageNotifier(
            context: context,
          ),
        ),
      ],
      child: const MainSearchPage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MainSearchPageNotifier>();
    final favNotifier = context.watch<FavoriteNotifier>();
    final myFavoriteList =
        context.select((FavoriteState state) => state.myFavoriteList);
    final isLoading =
        context.select((MainSearchPageState state) => state.isLoading);
    final sakeInfo =
        context.select((MainSearchPageState state) => state.sakeInfo);
    final errorMessage =
        context.select((MainSearchPageState state) => state.errorMessage);
    final geminiResponse =
        context.select((MainSearchPageState state) => state.geminiResponse);
    final searchMode =
        context.select((MainSearchPageState state) => state.searchMode);
    final sakeImage =
        context.select((MainSearchPageState state) => state.sakeImage);

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Color(0xFF1D3567),
        ),
        child: SingleChildScrollView(
          child: isLoading
              ? const AILoading(loadingText: '日本酒情報を取得しています...')
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 50),
                      Container(
                        height: 180,
                        width: 180,
                        padding: const EdgeInsets.all(20),
                        child: Image(
                          image: Assets.sakeLogo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          '日本酒検索',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 5,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // タブと検索UIの間隔を調整
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            // タブ部分
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // 名前で検索タブ
                                    Expanded(
                                      child: _buildTabButton(
                                        context,
                                        '名前で検索',
                                        Icons.search,
                                        SearchMode.name,
                                        searchMode,
                                        notifier,
                                      ),
                                    ),
                                    // 酒瓶検索タブ
                                    Expanded(
                                      child: _buildTabButton(
                                        context,
                                        '酒瓶検索',
                                        Icons.camera_alt,
                                        SearchMode.bottle,
                                        searchMode,
                                        notifier,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // 検索UI部分（角丸を下部のみに適用）
                            Container(
                              margin: EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                              ),
                              padding: const EdgeInsets.all(0),
                              child: searchMode == SearchMode.name
                                  ? _buildNameSearchUI(
                                      context, notifier, sakeInfo, errorMessage)
                                  : _buildBottleSearchUI(
                                      context, notifier, sakeImage),
                            ),
                          ],
                        ),
                      ),

                      // 検索結果表示
                      if (sakeInfo != null)
                        _buildSakeInfoCard(context, notifier, favNotifier,
                            sakeInfo, myFavoriteList),

                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            errorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      if (geminiResponse != null &&
                          searchMode == SearchMode.bottle)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'AIの解析結果',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF1D3567),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  geminiResponse,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // タブボタンを構築するメソッド
  Widget _buildTabButton(
    BuildContext context,
    String text,
    IconData icon,
    SearchMode mode,
    SearchMode currentMode,
    MainSearchPageNotifier notifier,
  ) {
    final isSelected = mode == currentMode;

    return InkWell(
      onTap: () {
        notifier.setSearchMode(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isSelected ? const Color(0xFF1D3567) : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? const Color(0xFF1D3567) : Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                color: isSelected ? const Color(0xFF1D3567) : Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 名前検索UI
  Widget _buildNameSearchUI(
    BuildContext context,
    MainSearchPageNotifier notifier,
    Sake? sakeInfo,
    String? errorMessage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          TextField(
            onChanged: (value) {
              notifier.setSakeName(value);
            },
            decoration: InputDecoration(
              hintText: '日本酒名を入力',
              labelText: '日本酒名',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: const Icon(Icons.wine_bar),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) {
              notifier.setSakeType(value);
            },
            decoration: InputDecoration(
              hintText: '種類を入力（任意）',
              labelText: '種類',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: const Icon(Icons.category),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              notifier.searchSake();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D3567),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search),
                SizedBox(width: 8),
                Text(
                  '検索',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 酒瓶検索UI
  Widget _buildBottleSearchUI(
    BuildContext context,
    MainSearchPageNotifier notifier,
    File? sakeImage,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Text(
            '日本酒のラベルや瓶の画像を選択してください',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // 画像表示エリア
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: sakeImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      sakeImage,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Center(
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // 画像選択ボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // カメラボタン
              ElevatedButton.icon(
                onPressed: () {
                  notifier.pickImage(ImageSource.camera);
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('カメラ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D3567),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // ギャラリーボタン
              ElevatedButton.icon(
                onPressed: () {
                  notifier.pickImage(ImageSource.gallery);
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('ギャラリー'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D3567),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          // 画像がある場合はクリアボタンを表示
          if (sakeImage != null)
            TextButton.icon(
              onPressed: () {
                notifier.clearImage();
              },
              icon: const Icon(Icons.clear, size: 16),
              label: const Text('画像をクリア'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
              ),
            ),

          const SizedBox(height: 16),

          // 解析ボタン
          ElevatedButton(
            onPressed: sakeImage != null
                ? () async {
                    await notifier.analyzeSakeBottle();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D3567),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search),
                SizedBox(width: 8),
                Text(
                  'AIに解析してもらう',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 日本酒情報カード
  Widget _buildSakeInfoCard(
    BuildContext context,
    MainSearchPageNotifier notifier,
    FavoriteNotifier favNotifier,
    Sake sakeInfo,
    List<String> myFavoriteList,
  ) {
    final isFavorite = myFavoriteList.contains(sakeInfo.name);

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1D3567),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.wine_bar,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sakeInfo.name ?? '不明',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () async {
                    if (sakeInfo.name != null) {
                      await favNotifier.addOrRemoveString(sakeInfo.name!);
                    }
                  },
                ),
              ],
            ),
          ),

          // 詳細情報
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sakeInfo.brewery != null)
                  _buildInfoRowEnhanced('蔵元', sakeInfo.brewery!, Icons.home),
                if (sakeInfo.types != null && sakeInfo.types!.isNotEmpty)
                  _buildTypesRowEnhanced(context, notifier, sakeInfo),
                if (sakeInfo.description != null)
                  _buildInfoRowEnhanced(
                      '説明', sakeInfo.description!, Icons.description),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowEnhanced(String key, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1D3567), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  key,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1D3567),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypesRowEnhanced(
      BuildContext context, MainSearchPageNotifier notifier, Sake sakeInfo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_bar, color: const Color(0xFF1D3567), size: 20),
              const SizedBox(width: 12),
              const Text(
                'タイプ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1D3567),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: sakeInfo.types!.map((type) {
              return InkWell(
                onTap: () {
                  notifier.searchByNameAndType(
                    sakeName: sakeInfo.name ?? '',
                    sakeType: type,
                  );
                },
                child: Chip(
                  label: Text(type),
                  backgroundColor: const Color(0xFF1D3567).withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: Color(0xFF1D3567),
                    fontWeight: FontWeight.bold,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  avatar: const Icon(
                    Icons.search,
                    size: 16,
                    color: Color(0xFF1D3567),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);
