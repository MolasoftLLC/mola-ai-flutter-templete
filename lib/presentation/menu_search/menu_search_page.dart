import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/common/loading/ai_loading.dart';
import 'package:provider/provider.dart';

import '../../common/assets.dart';
import 'menu_search_page_notifier.dart';

class MenuSearchPage extends StatelessWidget {
  const MenuSearchPage._({Key? key}) : super(key: key);

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
    final sakeMenuRecognitionResponse =
        context.select((MenuSearchPageState state) => state.sakeMenuRecognitionResponse);
    
    String loadingText = 'AIに問い合わせています';
    if (isExtractingInfo) {
      loadingText = '画像から日本酒を認識しています...';
    } else if (isGettingDetails) {
      loadingText = '日本酒の詳細情報を取得しています...';
    }
    
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFF1D3567),
        child: SingleChildScrollView(
          child: isLoading
              ? AILoading(loadingText: loadingText)
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 50,
                      ),
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: Image(
                          image: Assets.sakeLogo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'メニューの中からオススメの日本酒を教えてくれる機能',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      
                      // 抽出された日本酒情報（詳細取得中の表示）
                      if (extractedSakes != null && sakeMenuRecognitionResponse == null)
                        Column(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16),
                              margin: EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '画像から以下の日本酒を認識しました',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  ...extractedSakes.map((sake) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Icon(Icons.local_bar, color: Colors.blue),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${sake['name']} (${sake['type']})',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )).toList(),
                                  SizedBox(height: 12),
                                  Text(
                                    '詳細情報を取得しています...',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      
                      // 詳細情報の表示
                      if (sakeMenuRecognitionResponse != null)
                        SizedBox(
                          height: sakeMenuRecognitionResponse.sakes.length * 300,
                          child: ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: sakeMenuRecognitionResponse.sakes.length,
                            itemBuilder: (context, index) {
                              final sake = sakeMenuRecognitionResponse.sakes[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sake.name,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text('種類: ${sake.type}'),
                                        Text('酒蔵: ${sake.brewery}'),
                                        Text('味わい: ${sake.taste}'),
                                        Text('日本酒度: ${sake.sakeMeterValue}'),
                                        Text('タイプ: ${sake.types.join(', ')}'),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      
                      SizedBox(
                        height: 40,
                      ),
                      
                      if (sakeImage != null)
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                child: Image.file(sakeImage),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 1,
                              child: InkWell(
                                onTap: () {
                                  notifier.clearImage();
                                },
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                      if (sakeImage == null)
                        InkWell(
                          onTap: () async {
                            await showImagePickerBottomSheet(context, notifier);
                          },
                          child: Container(
                            width: 300,
                            height: 120,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF014772),
                                  offset: Offset(1, 3),
                                  spreadRadius: 2,
                                ),
                              ],
                              borderRadius: BorderRadius.circular(20),
                              color: Color(0xFF0360A4),
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 4),
                                Icon(
                                  size: 40,
                                  Icons.photo_camera,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'メニュー画像を選ぶ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  size: 20,
                                  Icons.add,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      SizedBox(
                        height: 30,
                      ),
                      
                      if (sakeImage != null && !isLoading)
                        SizedBox(
                          width: 220,
                          child: FilledButton(
                            onPressed: () async {
                              await notifier.recognizeMenu();
                            },
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star_border_purple500,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'メニューを解析',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      
                      const SizedBox(
                        height: 40,
                      ),
                    ],
                  ),
                ),
        ),
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

Future<void> showImagePickerBottomSheet(
    BuildContext context, MenuSearchPageNotifier notifier) async {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext context) {
      return Container(
        height: 200,
        color: Colors.white,
        child: Column(
          children: [
            ListTile(
              onTap: () async {
                await notifier.pickImageFromGallery();
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              leading: const Icon(Icons.photo),
              title: const Text('ライブラリから選択'),
            ),
            ListTile(
              onTap: () async {
                await notifier.pickImageFromCamera();
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              leading: const Icon(Icons.camera),
              title: const Text('撮影する'),
            ),
          ],
        ),
      );
    },
  );
}
