import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'common/access_url.dart';
import 'domain/repository/gemini_mola_api_repository.dart';
import 'infrastructure/api_client/api_client.dart';
import 'infrastructure/api_client/client_creator.dart';

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
    // Provider<SharedPreference>(
    //   create: (_) => SharedPreferenceImpl(),
    // ),
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
    // StateNotifierProvider<AuthNotifier, AuthState>(
    //   create: (_) => AuthNotifier(),
    // ),
  ];
}
