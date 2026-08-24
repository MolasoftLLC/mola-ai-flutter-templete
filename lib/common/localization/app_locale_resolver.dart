import 'dart:ui';

import '../../infrastructure/local_database/shared_key.dart';
import '../../infrastructure/local_database/shared_preference.dart';
import 'app_locale_controller.dart';

Future<String> resolveAppLocaleLanguageCode() async {
  final savedLanguage = await SharedPreference.staticGetString(
    key: appLanguageKey,
    defaultValue: AppLanguage.system.name,
  );

  if (savedLanguage == AppLanguage.japanese.name) {
    return 'ja';
  }
  if (savedLanguage == AppLanguage.english.name) {
    return 'en';
  }

  return PlatformDispatcher.instance.locale.languageCode == 'ja' ? 'ja' : 'en';
}
