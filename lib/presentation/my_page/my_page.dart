import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../common/assets.dart';
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
