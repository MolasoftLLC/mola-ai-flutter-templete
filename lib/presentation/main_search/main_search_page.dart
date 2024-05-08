import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:mola_gemini_flutter_template/presentation/common/loading/ai_loading.dart';
import 'package:provider/provider.dart';

import '../../common/assets.dart';
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: geminiResponse != null ? 120 : 240,
                      ),
                      SizedBox(
                        height: 200,
                        width: 200,
                        child: Image(
                          image: Assets.sakeLogo,
                          fit: BoxFit.contain,
                        ),
                      ),
                      if (geminiResponse != null)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            style: TextStyle(color: Colors.white),
                            geminiResponse,
                          ),
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
}

final ButtonStyle flatButtonStyle = TextButton.styleFrom(
  foregroundColor: Colors.black,
  minimumSize: Size(88, 36),
  padding: EdgeInsets.symmetric(horizontal: 16),
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(2)),
  ),
);
