import 'package:flutter/material.dart';

import '../../infrastructure/local_database/shared_preference.dart';
import '../../infrastructure/local_database/shared_key.dart';

enum AppLanguage {
  system,
  japanese,
  english,
}

class AppLocaleController extends ChangeNotifier {
  AppLanguage _language = AppLanguage.system;

  AppLanguage get language => _language;

  Locale? get locale => switch (_language) {
        AppLanguage.system => null,
        AppLanguage.japanese => const Locale('ja'),
        AppLanguage.english => const Locale('en'),
      };

  Future<void> load() async {
    final savedValue = await SharedPreference.staticGetString(
      key: appLanguageKey,
      defaultValue: AppLanguage.system.name,
    );
    _language = AppLanguage.values.firstWhere(
      (language) => language.name == savedValue,
      orElse: () => AppLanguage.system,
    );
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) {
      return;
    }
    _language = language;
    notifyListeners();
    await SharedPreference.staticSetString(
      key: appLanguageKey,
      value: language.name,
    );
  }
}
