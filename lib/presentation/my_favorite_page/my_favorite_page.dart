import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/assets.dart';
import 'my_favorite_page_notifier.dart';

class MyFavoritePage extends StatelessWidget {
  const MyFavoritePage._({Key? key}) : super(key: key);

  static Widget wrapped() {
    return MultiProvider(
      providers: [
        StateNotifierProvider<MyFavoritePageNotifier, MyFavoritePageState>(
          create: (context) => MyFavoritePageNotifier(
            context: context,
          ),
        ),
      ],
      child: const MyFavoritePage._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<MyFavoritePageNotifier>();
    final isLoading =
        context.select((MyFavoritePageState state) => state.isLoading);
    final geminiResponse =
        context.select((MyFavoritePageState state) => state.geminiResponse);
    return Scaffold(
        body: Container(
      height: MediaQuery.of(context).size.height,
      color: const Color(0xFF1D3567),
      child: SingleChildScrollView(
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(
              height: 80,
            ),
            SizedBox(
              height: 100,
              width: 100,
              child: Image(
                image: Assets.sakeLogo,
                fit: BoxFit.contain,
              ),
            ),
            Text(
              textAlign: TextAlign.center,
              'ベータ版 ver0.0.1',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
