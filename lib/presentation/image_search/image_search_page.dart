import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/common/loading/ai_loading.dart';
import 'package:provider/provider.dart';

import '../../common/assets.dart';
import 'image_search_page_notifier.dart';

class ImageSearchPage extends StatelessWidget {
  const ImageSearchPage._({Key? key}) : super(key: key);

  static Widget wrapped() {
    return MultiProvider(
      providers: [
        StateNotifierProvider<ImageSearchPageNotifier, ImageSearchPageState>(
          create: (context) => ImageSearchPageNotifier(
            context: context,
          ),
        ),
      ],
      child: const ImageSearchPage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ImageSearchPageNotifier>();
    final isLoading =
        context.select((ImageSearchPageState state) => state.isLoading);
    final sakeImage =
        context.select((ImageSearchPageState state) => state.sakeImage);
    final geminiResponse =
        context.select((ImageSearchPageState state) => state.geminiResponse);
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFF1D3567),
        child: SingleChildScrollView(
          child: isLoading
              ? const AILoading(loadingText: 'AIに問い合わせています')
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: sakeImage != null ? 120 : 240,
                      ),
                      if (geminiResponse != null)
                        SizedBox(
                          height: 200,
                          width: 200,
                          child: Image(
                            image: Assets.sakeLogo,
                            fit: BoxFit.contain,
                          ),
                        ),
                      const SizedBox(
                        height: 20,
                      ),
                      if (geminiResponse != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            style: TextStyle(color: Colors.white),
                            geminiResponse,
                          ),
                        ),
                      if (sakeImage != null)
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width,
                                // 変更後の画像パスを取得して、空であればデフォルト画像、値があれば画像の表示
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
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF014772), // 影の色
                                  offset: Offset(1, 3), // 影のオフセット (X, Y)
                                  spreadRadius: 2, // 影の広がり具合
                                ),
                              ],
                              borderRadius: BorderRadius.circular(80),
                              color:
                                  Color(0xFF0360A4), // Set the background color
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
                                  '画像を選ぶ',
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
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          textAlign: TextAlign.center,
                          '酒瓶などから問い合わせ！\nはっきり映ってないと難しい、、、。\n特に手書きなどは解析が難しいかも?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextFormField(
                          maxLength: 30,
                          decoration: const InputDecoration(
                            fillColor: Colors.white,
                            filled: true,
                            hintStyle: TextStyle(fontSize: 12),
                            hintText: '(任意)画像に対しての補足 「右下に書いてる」とか',
                            border: OutlineInputBorder(),
                            counterStyle: TextStyle(color: Colors.white),
                          ),
                          maxLines: 1,
                          onChanged: (String text) {
                            notifier.setText(text);
                          },
                        ),
                      ),
                      SizedBox(
                        width: 220,
                        child: FilledButton(
                          onPressed: () async {
                            await notifier.promptWithImage();
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text('AIに質問'),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

Future<void> showImagePickerBottomSheet(
    BuildContext context, ImageSearchPageNotifier notifier) async {
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
                Navigator.pop(context);
              },
              leading: const Icon(Icons.photo),
              title: const Text('ライブラリから選択'),
            ),
            ListTile(
              onTap: () async {
                final pickedFile = await notifier.pickImageFromCamera();
                Navigator.pop(context);
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
