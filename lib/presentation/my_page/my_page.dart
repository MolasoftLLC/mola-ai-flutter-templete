import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/notifier/favorite/favorite_notifier.dart';
import 'how_to_use/how_to_use_page.dart';
import 'my_page_notifier.dart';

class MyPage extends StatelessWidget {
  const MyPage._({Key? key}) : super(key: key);

  static Widget wrapped() {
    return MultiProvider(
      providers: [
        StateNotifierProvider<MyPageNotifier, MyPageState>(
          create: (context) => MyPageNotifier(
            context: context,
          ),
        ),
      ],
      child: const MyPage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MyPageNotifier>();
    final isLoading = context.select((MyPageState state) => state.isLoading);
    final geminiResponse =
        context.select((MyPageState state) => state.geminiResponse);
    final myFavoriteSakeList =
        context.select((FavoriteState state) => state.myFavoriteList);
    final favNotifier = context.watch<FavoriteNotifier>();
    return Scaffold(
        body: Container(
      height: MediaQuery.of(context).size.height,
      color: const Color(0xFF1D3567),
      child: SingleChildScrollView(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
            SizedBox(
              height: 80,
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              color: Colors.black,
              padding: EdgeInsets.only(top: 34),
              child: Center(
                child: Text(
                  '〜お気に入りのお酒〜',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (myFavoriteSakeList.isEmpty)
              Container(
                width: MediaQuery.of(context).size.width,
                color: Colors.black,
                padding: EdgeInsets.only(top: 12, bottom: 43),
                child: const Center(
                  child: Text(
                    'まだお気に入りはありません。',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            if (myFavoriteSakeList.isNotEmpty)
              Container(
                  height: 400,
                  color: Colors.black,
                  child: ListView.builder(
                      itemCount: myFavoriteSakeList.length,
                      itemBuilder: (context, index) {
                        return Container(
                          height: 80,
                          width: 300,
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            child: ListTile(
                              title: SizedBox(
                                  width: 200,
                                  child: Text(myFavoriteSakeList[index])),
                              trailing: SizedBox(
                                width: 80,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // InkWell(
                                    //   onTap: () {
                                    //     // 再検索処理をここに記述
                                    //     ScaffoldMessenger.of(context)
                                    //         .showSnackBar(
                                    //       SnackBar(
                                    //         content: Text(
                                    //             '再検索: ${myFavoriteSakeList[index]}'),
                                    //       ),
                                    //     );
                                    //   },
                                    //   child: Icon(Icons.search),
                                    // ),
                                    SizedBox(width: 16),
                                    InkWell(
                                        onTap: () {
                                          favNotifier.addOrRemoveString(
                                              myFavoriteSakeList[index]);
                                        },
                                        child: Icon(
                                          true
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: true ? Colors.red : null,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      })),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: () async => {
                        await Navigator.of(context, rootNavigator: true)
                            .push<void>(
                          CupertinoPageRoute(builder: (_) => const HowToUse()),
                        )
                      },
                      child: Text(
                        '利用規約',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: GestureDetector(
                      onTap: () async => {
                        await launchUrl(Uri.parse('https://molasoft.jp')),
                      },
                      child: Text(
                        '開発会社',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ]),
        ),
      ),
    ));
  }
}
