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
    final geminiResponse =
        context.select((MenuSearchPageState state) => state.geminiResponse);
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
                        height: 240,
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
                          'Comming Soon!',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'メニューの中からオススメの日本酒を教えてくれるありがた機能！',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.all(12),
                      //   child: TextFormField(
                      //     maxLength: 30,
                      //     decoration: const InputDecoration(
                      //       fillColor: Colors.white,
                      //       filled: true,
                      //       hintText: '日本酒の銘柄(例 田酒、仙禽...)',
                      //       border: OutlineInputBorder(),
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
                      //       await notifier.promptWithText();
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
                        height: 40,
                      ),
                      if (geminiResponse != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            style: TextStyle(color: Colors.white),
                            geminiResponse,
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

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);
