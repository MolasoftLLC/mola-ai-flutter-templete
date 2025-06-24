import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/common/utils/file_utils.dart';
import 'package:mola_gemini_flutter_template/presentation/common/loading/ai_loading.dart';
import 'package:mola_gemini_flutter_template/presentation/menu_search/widgets/menu_history_section.dart';
import 'package:provider/provider.dart';

import '../../common/assets.dart';
import '../../domain/eintities/response/sake_menu_recognition_response/sake_menu_recognition_response.dart';
import '../../domain/notifier/favorite/favorite_notifier.dart';
import 'menu_search_page_notifier.dart';

class MenuSearchPage extends StatelessWidget {
  const MenuSearchPage._({Key? key}) : super(key: key);

  static final ScrollController _scrollController = ScrollController();

  static Widget wrapped() {
    return MultiProvider(
      providers: [
        StateNotifierProvider<MenuSearchPageNotifier, MenuSearchPageState>(
          create: (context) => MenuSearchPageNotifier(
            context: context,
          ),
        ),
      ],
      child: const MenuSearchPage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MenuSearchPageNotifier>();
    final favNotifier = context.watch<FavoriteNotifier>();
    final isLoading =
        context.select((MenuSearchPageState state) => state.isLoading);
    final isExtractingInfo =
        context.select((MenuSearchPageState state) => state.isExtractingInfo);
    final isGettingDetails =
        context.select((MenuSearchPageState state) => state.isGettingDetails);
    final sakeImage =
        context.select((MenuSearchPageState state) => state.sakeImage);
    final extractedSakes =
        context.select((MenuSearchPageState state) => state.extractedSakes);
    final sakes = context.select((MenuSearchPageState state) => state.sakes);
    final myFavoriteList =
        context.select((FavoriteState state) => state.myFavoriteList);
    final errorMessage =
        context.select((MenuSearchPageState state) => state.errorMessage);
    // 詳細情報が取得された日本酒の名前リスト
    final detailedSakeNames = sakes?.map((sake) => sake.name).toList() ?? [];

    // 各日本酒の読み込み状態
    final sakeLoadingStatus =
        context.select((MenuSearchPageState state) => state.sakeLoadingStatus);

    // 名前のマッピング（元の名前 -> 取得した詳細情報の名前）
    final nameMapping =
        context.select((MenuSearchPageState state) => state.nameMapping);

    String loadingText = 'AIに問い合わせています';
    if (isExtractingInfo) {
      loadingText = '解析中...時々ある広告表示にご協力ください...';
    } else if (isGettingDetails) {
      loadingText = '日本酒の詳細情報を取得しています...';
    }

    final hasScrolledToResults =
        context.select((MenuSearchPageState state) => state.hasScrolledToResults);
    
    if (extractedSakes.isNotEmpty && !isLoading && !isExtractingInfo && !hasScrolledToResults) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToResults();
        notifier.setHasScrolledToResults(true);
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
          child: isLoading
              ? AILoading(loadingText: loadingText)
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
                          'メニュー検索',
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
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
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
                            const Text(
                              'メニューの写真をアップロードして日本酒を検索',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D3567),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            if (sakeImage != null)
                              Stack(
                                children: [
                                  Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 2,
                                      ),
                                      image: DecorationImage(
                                        image: FileUtils.safeLoadImage(
                                          sakeImage.path,
                                          base64Image: null, // Current image doesn't have base64 yet
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: InkWell(
                                      onTap: () {
                                        notifier.clearImage();
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.8),
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
                            else
                              Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      notifier.pickImageFromGallery();
                                    },
                                    child: Container(
                                      height: 150,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      notifier.pickImageFromCamera();
                                    },
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('カメラで撮影'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1D3567),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),
                            if (sakeImage != null)
                              ElevatedButton.icon(
                                onPressed: () {
                                  notifier.extractAndFetchSakeInfo(sakeImage);
                                },
                                icon: const Icon(Icons.search),
                                label: const Text('日本酒を検索'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1D3567),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            if (errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade300,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          errorMessage,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (extractedSakes.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.only(
                              top: 42, left: 12, right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: const Text(
                                  '検出された日本酒',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: extractedSakes.length,
                                itemBuilder: (context, index) {
                                  final sake = extractedSakes[index];

                                  // 元の名前から取得した詳細情報の名前を取得
                                  final mappedName =
                                      nameMapping[sake.name] ?? sake.name;

                                  // 詳細情報が取得された日本酒を探す
                                  final detailedSake = sakes?.firstWhere(
                                    (s) => s.name == mappedName,
                                    orElse: () =>
                                        Sake(name: sake.name, type: sake.type),
                                  );

                                  // この日本酒が現在読み込み中かどうか
                                  final isItemLoading =
                                      sakeLoadingStatus[sake.name] ?? false;

                                  // 詳細情報があるかどうか
                                  final hasDetails = sakes != null &&
                                      sakes.any((s) => s.name == mappedName);

                                  // 詳細情報の取得に失敗したかどうか
                                  final hasFailed = !isItemLoading &&
                                      !hasDetails &&
                                      sakeLoadingStatus.containsKey(sake.name);

                                  // 推薦スコア
                                  final recommendationScore =
                                      detailedSake?.recommendationScore;

                                  // 超おすすめかどうか（スコアが8以上）
                                  final isHighlyRecommended =
                                      recommendationScore != null &&
                                          recommendationScore >= 8;
                                  final isFavorited = myFavoriteList.any(
                                      (favorite) =>
                                          favorite.name ==
                                              (hasDetails
                                                  ? detailedSake!.name
                                                  : sake.name) &&
                                          favorite.type ==
                                              (hasDetails
                                                  ? detailedSake!.type
                                                  : sake.type));

                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8.0, top: 0),
                                    child: Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ExpansionTile(
                                        title: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    hasDetails
                                                        ? detailedSake!.name ??
                                                            'Unknown'
                                                        : sake.name ??
                                                            'Unknown',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 12),
                                                  child: IconButton(
                                                    icon: Icon(
                                                      isFavorited
                                                          ? Icons.favorite
                                                          : Icons
                                                              .favorite_border,
                                                      color: isFavorited
                                                          ? Colors.red
                                                          : Colors.grey,
                                                      size: 24,
                                                    ),
                                                    onPressed: () {
                                                      final favoriteSake =
                                                          FavoriteSake(
                                                        name: detailedSake!
                                                                .name ??
                                                            'Unknown',
                                                        type: detailedSake.type,
                                                      );
                                                      favNotifier
                                                          .addOrRemoveFavorite(
                                                              favoriteSake);
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (isHighlyRecommended)
                                              Container(
                                                margin: const EdgeInsets.only(
                                                    top: 4),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: Colors.red.shade300,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.star,
                                                      color:
                                                          Colors.red.shade700,
                                                      size: 16,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      recommendationScore >= 9
                                                          ? '超おすすめ！'
                                                          : 'おすすめ！',
                                                      style: TextStyle(
                                                        color:
                                                            Colors.red.shade700,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        subtitle: Text(
                                          sake.type ?? '種類不明',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        trailing: hasDetails
                                            ? const Icon(
                                                size: 30,
                                                Icons.expand_circle_down,
                                                color: Color(0xFF1D3567))
                                            : !hasFailed
                                                ? const SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Color(0xFF1D3567),
                                                    ),
                                                  )
                                                : isLoading
                                                    ? const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color:
                                                              Color(0xFF1D3567),
                                                        ),
                                                      )
                                                    : Icon(Icons.error_outline,
                                                        color: Colors
                                                            .red.shade700),
                                        children: [
                                          if (hasDetails)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (detailedSake!.brewery !=
                                                      null)
                                                    _buildInfoRow(
                                                      '蔵元',
                                                      detailedSake.brewery!,
                                                      Icons.home_work,
                                                    ),
                                                  if (detailedSake.taste !=
                                                      null)
                                                    _buildInfoRow(
                                                      '味わい',
                                                      detailedSake.taste!,
                                                      Icons.restaurant,
                                                    ),
                                                  if (detailedSake
                                                          .sakeMeterValue !=
                                                      null)
                                                    _buildInfoRow(
                                                      '日本酒度',
                                                      '${detailedSake.sakeMeterValue}',
                                                      Icons.science,
                                                    ),
                                                  if (detailedSake.types !=
                                                          null &&
                                                      detailedSake
                                                          .types!.isNotEmpty)
                                                    _buildTypesRow(
                                                        detailedSake.types!),
                                                ],
                                              ),
                                            )
                                          else
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    isItemLoading
                                                        ? Icons.hourglass_top
                                                        : Icons.error_outline,
                                                    color: isItemLoading
                                                        ? const Color(
                                                            0xFF1D3567)
                                                        : Colors.red.shade700,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      isItemLoading
                                                          ? '詳細情報を取得中...'
                                                          : '詳細情報を取得できませんでした',
                                                      style: TextStyle(
                                                        color: isItemLoading
                                                            ? const Color(
                                                                0xFF1D3567)
                                                            : Colors
                                                                .red.shade700,
                                                        fontStyle: isItemLoading
                                                            ? FontStyle.italic
                                                            : FontStyle.normal,
                                                        fontWeight:
                                                            isItemLoading
                                                                ? FontWeight
                                                                    .normal
                                                                : FontWeight
                                                                    .bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      
                      // メニュー解析履歴セクション
                      const MenuHistorySection(),
                    ],
                  ),
                ),
        ),
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

  Widget _buildInfoRow(String key, String value, IconData icon) {
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

  Widget _buildTypesRow(List<String> types) {
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
            children: types.map((type) {
              return Chip(
                label: Text(type),
                backgroundColor: const Color(0xFF1D3567).withOpacity(0.1),
                labelStyle: const TextStyle(
                  color: Color(0xFF1D3567),
                  fontWeight: FontWeight.bold,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
