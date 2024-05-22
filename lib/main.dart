import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mola_gemini_flutter_template/presentation/app_page.dart';
import 'package:provider/provider.dart';

import 'app_config.dart';
import 'common/access_url.dart';
import 'di_container.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        final isValidHost = [
          productionUrl,
        ].contains(host);
        return isValidHost;
      };
  }
}

Future<void> main() async {
  ///各種アプリの設定を読み取り
  HttpOverrides.global = MyHttpOverrides();
  await dotenv.load(fileName: ".env");
  await configure();
  runApp(
    MultiProvider(
      providers: await providers,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MolaAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: AppPage.wrapped(),
    );
  }
}
