import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/common/loading/ai_loading.dart';
import 'package:provider/provider.dart';

import '../../common/assets.dart';
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

    final openAIResponseList =
        context.select((MainSearchPageState state) => state.openAiResponseList);

    final isLoading =
        context.select((MainSearchPageState state) => state.isLoading);
    final geminiResponse =
        context.select((MainSearchPageState state) => state.geminiResponse);

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
                        height: openAIResponseList != null
                            ? 50
                            : MediaQuery.of(context).size.height * 0.2,
                      ),
                      SizedBox(
                        height: openAIResponseList != null ? 50 : 200,
                        width: openAIResponseList != null ? 50 : 200,
                        child: Image(
                          image: Assets.sakeLogo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (openAIResponseList != null)
                        SizedBox(
                          height: openAIResponseList.length *
                              MediaQuery.of(context).size.height *
                              0.68,
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
                                      if (index == 1)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 12, bottom: 12),
                                          child: Text(
                                            '〜あなたにオススメ〜',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      Stack(
                                        children: [
                                          Card(
                                            child: ListTile(
                                              title: Padding(
                                                padding: const EdgeInsets.only(
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
                                        height: 20,
                                      ),
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
                          '日本酒の名前から検索',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
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
                            hintText: '日本酒の銘柄(例 田酒、仙禽...)',
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
                            await notifier.promptWithText();
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text('AIに質問'),
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
                description[key] ?? '不明です',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
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
