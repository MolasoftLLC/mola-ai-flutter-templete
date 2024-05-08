import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

//半透明のローディング
class AILoading extends StatelessWidget {
  const AILoading({
    required this.loadingText,
    super.key,
  });

  final String loadingText;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1D3567),
      child: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/ai_loading.json',
                width: 300,
                height: 300,
                fit: BoxFit.fitWidth,
                repeat: true,
                onLoaded: (composition) {},
              ),
              Text(
                loadingText,
                style: const TextStyle(
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
