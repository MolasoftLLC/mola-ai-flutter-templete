import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../common/access_url.dart';
import '../domain/notifier/favorite/favorite_notifier.dart';
import '../domain/notifier/my_page/my_page_notifier.dart';
import '../domain/notifier/saved_sake/saved_sake_notifier.dart';
import '../domain/repository/gemini_mola_api_repository.dart';
import '../domain/repository/mola_api_repository.dart';
import '../domain/repository/sake_bottle_image_repository.dart';
import '../domain/repository/sake_menu_recognition_repository.dart';
import '../infrastructure/api_client/api_client.dart';
import '../infrastructure/api_client/client_creator.dart';
import '../infrastructure/api_client/sake_menu_recognition_api_client.dart';
import '../infrastructure/api_client/sake_menu_recognition_client_creator.dart';
import '../infrastructure/local_database/shared_preference.dart';

Future<List<SingleChildWidget>> get providers async {
  return <SingleChildWidget>[
    Provider(create: (context) => GlobalKey<NavigatorState>()),
    ..._repositoryProviders,
    ..._applicationProviders,
    ...await _notifierProviders,
  ];
}

String apiURL() {
  if (const String.fromEnvironment('FLAVOR') == 'production') {
    return productionUrl;
  } else {
    return developUrl;
  }
}

/// DI repository
List<SingleChildWidget> get _repositoryProviders {
  return <SingleChildWidget>[
    Provider<GeminiMolaApiRepository>(
      create: (_) => GeminiMolaApiRepository(
        ApiClient.create(chopperClient(url: apiURL())),
      ),
    ),
    Provider<MolaApiRepository>(
      create: (_) => MolaApiRepository(
        ApiClient.create(chopperClient(url: apiURL())),
      ),
    ),
    Provider<SharedPreference>(
      create: (_) => SharedPreference(),
    ),
    Provider<SakeMenuRecognitionApiClient>(
      create: (_) => SakeMenuRecognitionApiClient.create(
        sakeMenuRecognitionChopperClient(),
      ),
    ),
    Provider<SakeMenuRecognitionRepository>(
      create: (context) => SakeMenuRecognitionRepository(
        context.read<SakeMenuRecognitionApiClient>(),
      ),
    ),
    Provider<SakeBottleImageRepository>(
      create: (_) => SakeBottleImageRepository(),
    ),
  ];
}

/// DI application
List<SingleChildWidget> get _applicationProviders {
  return <SingleChildWidget>[
    // Provider<AnalyticsLogger>(
    //   create: (_) => AnalyticsLoggerImpl(FirebaseAnalytics.instance),
    // ),
  ];
}

/// DI state notifier
/// Singletonのように扱いたい場合はここに追加する
Future<List<SingleChildWidget>> get _notifierProviders async {
  return <SingleChildWidget>[
    StateNotifierProvider<FavoriteNotifier, FavoriteState>(
      create: (_) => FavoriteNotifier(),
    ),
    StateNotifierProvider<SavedSakeNotifier, SavedSakeState>(
      create: (_) => SavedSakeNotifier(),
    ),
    StateNotifierProvider<MyPageNotifier, MyPageState>(
      create: (_) => MyPageNotifier(),
    ),
  ];
}
