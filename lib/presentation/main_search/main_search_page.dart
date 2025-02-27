import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
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
                            SizedBox(
                              height: 24,
                            ),
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
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
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
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 16),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (errorMessage != null)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(
                                    color: Colors.red.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (sakeInfo != null)
                        Container(
                          margin: const EdgeInsets.all(16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ヘッダー部分
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sakeInfo.name ?? '不明',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        myFavoriteList.contains(sakeInfo.name)
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: myFavoriteList
                                                .contains(sakeInfo.name)
                                            ? Colors.red
                                            : Colors.white,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        if (sakeInfo.name != null) {
                                          favNotifier.addOrRemoveString(
                                              sakeInfo.name!);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              // 詳細情報部分
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (sakeInfo.brewery != null)
                                      _buildInfoRowEnhanced(
                                          '蔵元', sakeInfo.brewery!, Icons.home),
                                    if (sakeInfo.type != null)
                                      _buildInfoRowEnhanced(
                                          '種類', sakeInfo.type!, Icons.category),
                                    if (sakeInfo.taste != null)
                                      _buildInfoRowEnhanced('味わい',
                                          sakeInfo.taste!, Icons.restaurant),
                                    if (sakeInfo.sakeMeterValue != null)
                                      _buildInfoRowEnhanced(
                                          '日本酒度',
                                          sakeInfo.sakeMeterValue.toString(),
                                          Icons.scale),
                                    if (sakeInfo.price != null)
                                      _buildInfoRowEnhanced('価格',
                                          sakeInfo.price!, Icons.attach_money),
                                    if (sakeInfo.description != null)
                                      _buildInfoRowEnhanced(
                                          '説明',
                                          sakeInfo.description!,
                                          Icons.description),
                                    if (sakeInfo.types != null &&
                                        sakeInfo.types!.isNotEmpty)
                                      _buildTypesRowEnhanced(
                                          context, notifier, sakeInfo),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$key: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
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

  Widget _buildTypesRow(
      BuildContext context, MainSearchPageNotifier notifier, Sake sakeInfo) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'タイプ: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
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
                    backgroundColor: Colors.blue.shade100,
                  ),
                );
              }).toList(),
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
