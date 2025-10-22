import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

import 'app_config.dart';
import 'common/access_url.dart';
import 'common/utils/ad_utils.dart';
import 'config/di_container.dart';
import 'firebase_options.dart';
import 'presentation/startup/first_launch_gate.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 画面の向きを縦に固定
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await _requestTrackingAuthorization();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // AdMobのテストデバイス設定
  MobileAds.instance.updateRequestConfiguration(
    RequestConfiguration(
      testDeviceIds: [
        '04654E8A84F896A7A68E5B1748584242', // Android test device
        '00000000-0000-0000-0000-000000000000', // Replace with actual iOS test device ID
      ],
    ),
  );

  // AdMobの初期化
  try {
    await AdUtils.initialize();
    print('AdMob initialized successfully');
  } catch (e) {
    print('Failed to initialize AdMob: $e');
    // Continue with app initialization even if AdMob fails
  }

  ///各種アプリの設定を読み取り
  HttpOverrides.global = MyHttpOverrides();
  await dotenv.load(fileName: ".env");
  await configure();

  // DIコンテナからプロバイダーを取得
  final providerList = await providers;

  runApp(
    MultiProvider(
      providers: providerList,
      child: const MyApp(),
    ),
  );
}

Future<void> _requestTrackingAuthorization() async {
  if (!Platform.isIOS) {
    return;
  }

  final status = await AppTrackingTransparency.trackingAuthorizationStatus;
  if (status == TrackingStatus.notDetermined) {
    await Future.delayed(const Duration(milliseconds: 500));
    await AppTrackingTransparency.requestTrackingAuthorization();
  }
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
      home: const FirstLaunchGate(),
    );
  }
}
