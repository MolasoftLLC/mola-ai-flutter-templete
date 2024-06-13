import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/common/loading/ai_loading.dart';
import 'package:provider/provider.dart';

import '../../domain/notifier/favorite/favorite_notifier.dart';
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
    final favNotifier = context.watch<FavoriteNotifier>();
    final myFavoriteList =
        context.select((FavoriteState state) => state.myFavoriteList);

    final openAIResponseList = context
        .select((ImageSearchPageState state) => state.openAiResponseList);

    final isLoading =
        context.select((ImageSearchPageState state) => state.isLoading);
    final hint = context.select((ImageSearchPageState state) => state.hint);
    final searchCategory =
        context.select((ImageSearchPageState state) => state.searchCategory);

    final sakeImage =
        context.select((ImageSearchPageState state) => state.sakeImage);
    final canUse = context.select((ImageSearchPageState state) => state.canUse);
    final geminiResponse =
        context.select((ImageSearchPageState state) => state.geminiResponse);
    final deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        color: const Color(0xFF1D3567),
        child: SingleChildScrollView(
          child: isLoading
              ? const AILoading(loadingText: 'AIに問い合わせています')
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 50,
                      ),

                      if (openAIResponseList != null)
                        SizedBox(
                          height: openAIResponseList.length *
                              (searchCategory == '酒瓶'
                                  ? deviceHeight * 0.62
                                  : deviceHeight * 0.82),
                          child: ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: openAIResponseList.length,
                            itemBuilder: (context, index) {
                              final response = openAIResponseList[index];
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: IntrinsicHeight(
                                  child: Column(
                                    children: [
                                      if (index == 0 && searchCategory == '酒瓶')
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 12, bottom: 12),
                                          child: Text(
                                            '〜画像の日本酒情報〜',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      if (index == 1 && searchCategory == '酒瓶')
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 12, bottom: 12),
                                          child: Text(
                                            '〜こういうのも好きかも？〜',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      if (index == 0 &&
                                          searchCategory == 'メニュー')
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 12, bottom: 12),
                                          child: Text(
                                            '〜メニューの中であなたにオススメ〜',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      Stack(
                                        children: [
                                          SingleChildScrollView(
                                            child: Card(
                                              child: ListTile(
                                                title: Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    top: 16,
                                                    bottom: 16,
                                                  ),
                                                  child: Text(
                                                    response.title!,
                                                    style: const TextStyle(
                                                        color: Colors.black,
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                subtitle: response.title != '不明'
                                                    ? Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          descriptionBody(
                                                              response
                                                                  .description!,
                                                              '特徴'),
                                                          if (response.description![
                                                                  'おすすめ理由'] !=
                                                              null)
                                                            descriptionBody(
                                                                response
                                                                    .description!,
                                                                'おすすめ理由'),
                                                          descriptionBody(
                                                              response
                                                                  .description!,
                                                              '辛口か甘口か'),
                                                          descriptionBody(
                                                              response
                                                                  .description!,
                                                              '酒造情報'),
                                                          descriptionBody(
                                                              response
                                                                  .description!,
                                                              '日本酒度合い'),
                                                          descriptionBody(
                                                              response
                                                                  .description!,
                                                              '使用米'),
                                                          descriptionBody(
                                                              response
                                                                  .description!,
                                                              'バリエーション'),
                                                          descriptionBody(
                                                              response
                                                                  .description!,
                                                              'アルコール度'),
                                                        ],
                                                      )
                                                    : Text(
                                                        'ごめんなさい。ご指定の日本酒はまだ私の情報にはありません、、、。'),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: InkWell(
                                              onTap: () {
                                                favNotifier.addOrRemoveString(
                                                    response.title!);
                                              },
                                              child: Icon(
                                                Icons.favorite,
                                                size: 32,
                                                color: myFavoriteList.contains(
                                                        response.title)
                                                    ? Colors.redAccent
                                                    : Colors.grey,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                      SizedBox(
                                        height: 28,
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      SizedBox(
                        height: 30,
                      ),
                      Center(
                        child: Text(
                          'メニューか酒瓶で画像検索！',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(
                        height: 40,
                      ),
                      SizedBox(
                        height: 100,
                        width: 300,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            InkWell(
                              onTap: () {
                                notifier.setText('メニュー');
                              },
                              child: Container(
                                height: 50,
                                width: 120,
                                decoration: BoxDecoration(
                                  color: hint == 'メニュー'
                                      ? Colors.cyan
                                      : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Center(
                                  child: Text(
                                    'メニュー',
                                    style: TextStyle(
                                      color: hint == 'メニュー'
                                          ? Colors.white
                                          : Colors.white60,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 40,
                              child: Center(
                                child: Text(
                                  'or',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                notifier.setText('酒瓶');
                              },
                              child: Container(
                                height: 50,
                                width: 120,
                                decoration: BoxDecoration(
                                  color:
                                      hint == '酒瓶' ? Colors.cyan : Colors.grey,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Center(
                                  child: Text(
                                    ' 酒　瓶 ',
                                    style: TextStyle(
                                      color: hint == '酒瓶'
                                          ? Colors.white
                                          : Colors.white60,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                            width: 300,
                            height: 120,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF014772), // 影の色
                                  offset: Offset(1, 3), // 影のオフセット (X, Y)
                                  spreadRadius: 2, // 影の広がり具合
                                ),
                              ],
                              borderRadius: BorderRadius.circular(20),
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
                      SizedBox(
                        height: 40,
                      ),

                      // Padding(
                      //   padding: const EdgeInsets.all(12),
                      //   child: TextFormField(
                      //     maxLength: 30,
                      //     decoration: const InputDecoration(
                      //       fillColor: Colors.white,
                      //       filled: true,
                      //       hintStyle: TextStyle(fontSize: 12),
                      //       hintText: '(任意)画像に対しての補足 「右下に書いてる」とか',
                      //       border: OutlineInputBorder(),
                      //       counterStyle: TextStyle(color: Colors.white),
                      //     ),
                      //     maxLines: 1,
                      //     onChanged: (String text) {
                      //       notifier.setText(text);
                      //     },
                      //   ),
                      // ),
                      // SizedBox(
                      //   width: 220,
                      //   child: FilledButton(
                      //     onPressed: () async {
                      //       await notifier.promptWithImage(false);
                      //     },
                      //     style: OutlinedButton.styleFrom(
                      //       shape: RoundedRectangleBorder(
                      //         borderRadius: BorderRadius.circular(16),
                      //       ),
                      //     ),
                      //     child: Text('AIに質問'),
                      //   ),
                      // ),
                      const SizedBox(
                        height: 30,
                      ),
                      SizedBox(
                        width: 220,
                        child: FilledButton(
                          onPressed: () async {
                            if (canUse) {
                              await notifier.promptWithImage(true);
                            }
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
                              ), // キラキラマークのアイコン
                              SizedBox(width: 2), // アイコンとテキストの間のスペース
                              Text(
                                'AIに質問',
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
                      SizedBox(
                        height: 4,
                      ),
                      Center(
                          child: Text(
                        '※利用状況に応じて優秀な方が使えない場合(灰色)があります。',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      )),
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

  Widget descriptionBody(Map<String, String> description, String key) {
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                '$key: '),
            Expanded(
              child: Text(
                description[key]!,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
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
