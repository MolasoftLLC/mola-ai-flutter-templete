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

  static final ScrollController _scrollController = ScrollController();

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
    final isAdLoading =
        context.select((MainSearchPageState state) => state.isAdLoading);
    final isAnalyzingInBackground = context
        .select((MainSearchPageState state) => state.isAnalyzingInBackground);
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

    if (sakeInfo != null && !isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToResults();
      });
    }

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          color: Color(0xFF1D3567),
        ),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: isLoading || isAdLoading
              ? isAdLoading
                  ? const AILoading(loadingText: '解析中...広告の表示にご協力ください...')
                  : isAnalyzingInBackground
                      ? const AILoading(loadingText: 'バックグラウンドで処理中...')
                      : const AILoading(loadingText: '日本酒情報を取得しています...')
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
                                      context,
                                      notifier,
                                      sakeImage,
                                      isAnalyzingInBackground,
                                    ),
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
    bool isAnalyzingInBackground,
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

          SizedBox(
            height: 220,
            width: double.infinity,
            child: sakeImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          sakeImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: InkWell(
                          onTap: notifier.clearImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.85),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Color(0xFF1D3567),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : InkWell(
                    onTap: () {
                      notifier.pickImage(ImageSource.gallery);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_search,
                            size: 48,
                            color: Color(0xFF1D3567),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'タップして画像を選択',
                            style: TextStyle(
                              color: Color(0xFF1D3567),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          ElevatedButton.icon(
            onPressed: () {
              notifier.pickImage(ImageSource.camera);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('カメラで撮影'),
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

          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sakeImage != null && !isAnalyzingInBackground
                      ? () async {
                          await notifier.saveAndAnalyzeBottle();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD54F),
                    foregroundColor: const Color(0xFF1D3567),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: const Text(
                    '解析して保存',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: sakeImage != null && !isAnalyzingInBackground
                      ? () async {
                          await notifier.analyzeSakeBottle();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D3567),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: const Text(
                    '解析だけ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // 日本酒情報カードを修正
  Widget _buildSakeInfoCard(
    BuildContext context,
    MainSearchPageNotifier notifier,
    FavoriteNotifier favNotifier,
    Sake sakeInfo,
    List<FavoriteSake> myFavoriteList,
  ) {
    // 日本酒名とタイプが一致するかどうかでお気に入り判定
    final bool isFavorite = myFavoriteList.any(
        (item) => item.name == sakeInfo.name && item.type == sakeInfo.type);

    // おすすめ度の表示を決定
    String recommendationText = '';
    Color recommendationColor = Colors.orange;
    IconData recommendationIcon = Icons.star;

    if (sakeInfo.recommendationScore != null) {
      if (sakeInfo.recommendationScore! >= 9) {
        recommendationText = '超おすすめ！';
        recommendationColor = Colors.red;
        recommendationIcon = Icons.star;
      } else if (sakeInfo.recommendationScore! >= 7) {
        recommendationText = 'おすすめ！';
        recommendationColor = Colors.orange;
        recommendationIcon = Icons.star;
      } else if (sakeInfo.recommendationScore! >= 5) {
        recommendationText = '良い日本酒';
        recommendationColor = Colors.amber;
        recommendationIcon = Icons.star_half;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー部分（日本酒名）
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1D3567),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
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
                // お気に入りボタン
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: () {
                    final favoriteSake = FavoriteSake(
                      name: sakeInfo.name ?? '不明',
                      type: sakeInfo.type,
                    );

                    favNotifier.addOrRemoveFavorite(favoriteSake);
                  },
                ),
              ],
            ),
          ),

          // おすすめ度表示（スコアがある場合のみ）
          if (recommendationText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: recommendationColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    recommendationIcon,
                    color: recommendationColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    recommendationText,
                    style: TextStyle(
                      color: recommendationColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (sakeInfo.recommendationScore != null)
                    Text(
                      '${sakeInfo.recommendationScore}/10',
                      style: TextStyle(
                        color: recommendationColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),

          // 日本酒の詳細情報
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 特徴
                if (sakeInfo.taste != null)
                  _buildInfoRow(
                    context,
                    '特徴',
                    sakeInfo.taste!,
                    Icons.description,
                  ),

                // 蔵元情報（特徴の下に移動）
                if (sakeInfo.brewery != null)
                  _buildInfoRow(
                    context,
                    '蔵元',
                    sakeInfo.brewery!,
                    Icons.business,
                  ),

                // 日本酒度
                if (sakeInfo.sakeMeterValue != null)
                  _buildInfoRow(
                    context,
                    '日本酒度',
                    '${sakeInfo.sakeMeterValue! > 0 ? '+' : ''}${sakeInfo.sakeMeterValue}',
                    Icons.scale,
                  ),

                // 甘口/辛口の表示
                if (sakeInfo.sakeMeterValue != null)
                  _buildSakeMeterScale(
                      context, sakeInfo.sakeMeterValue!.toDouble()),

                // タイプ別検索（甘口・辛口ゲージの下に移動）
                if (sakeInfo.types != null && sakeInfo.types!.isNotEmpty)
                  _buildTypesRowEnhanced(context, notifier, sakeInfo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
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
              Icon(icon, color: const Color(0xFF1D3567), size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1D3567),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // タイプ別検索の表示を修正
  Widget _buildTypesRowEnhanced(
      BuildContext context, MainSearchPageNotifier notifier, Sake sakeInfo) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 12),
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
              Icon(Icons.search, color: const Color(0xFF1D3567), size: 20),
              const SizedBox(width: 12),
              const Text(
                'タイプ別検索',
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

  // 日本酒度のスケール表示
  Widget _buildSakeMeterScale(BuildContext context, double sakeMeterValue) {
    // 日本酒度の範囲は一般的に-15〜+15程度
    // UIでは-10〜+10の範囲で表示
    final double normalizedValue = sakeMeterValue.clamp(-10.0, 10.0);
    final double percentage = (normalizedValue + 10) / 20; // 0〜1の範囲に正規化

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '甘口',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.pink,
                ),
              ),
              const Text(
                '辛口',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.pink, Colors.white, Colors.blue],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Stack(
              children: [
                // インジケーター
                Positioned(
                  left: percentage *
                      MediaQuery.of(context).size.width *
                      0.7, // 親の幅の70%を使用
                  child: Container(
                    width: 12,
                    height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D3567),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _scrollToResults() {
    if (_scrollController.hasClients) {
      final double targetPosition =
          _scrollController.position.maxScrollExtent * 0.6;
      _scrollController.animateTo(
        targetPosition,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
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
