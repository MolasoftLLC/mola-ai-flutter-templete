import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mola_gemini_flutter_template/common/localization/app_locale_controller.dart';
import 'package:mola_gemini_flutter_template/common/localization/app_locale_resolver.dart';
import 'package:mola_gemini_flutter_template/common/localization/localization_extensions.dart';
import 'package:mola_gemini_flutter_template/infrastructure/local_database/shared_key.dart';
import 'package:mola_gemini_flutter_template/l10n/generated/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('保存した言語を復元し、変更内容を永続化する', () async {
    SharedPreferences.setMockInitialValues({
      appLanguageKey: AppLanguage.english.name,
    });
    final controller = AppLocaleController();

    await controller.load();
    expect(controller.language, AppLanguage.english);
    expect(controller.locale, const Locale('en'));

    await controller.setLanguage(AppLanguage.japanese);
    expect(controller.locale, const Locale('ja'));
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString(appLanguageKey), AppLanguage.japanese.name);
  });

  test('端末設定に従う場合はlocaleを指定しない', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppLocaleController();

    await controller.load();

    expect(controller.language, AppLanguage.system);
    expect(controller.locale, isNull);
  });

  test('APIへ送る言語はアプリ内設定を優先する', () async {
    SharedPreferences.setMockInitialValues({
      appLanguageKey: AppLanguage.english.name,
    });
    expect(await resolveAppLocaleLanguageCode(), 'en');

    SharedPreferences.setMockInitialValues({
      appLanguageKey: AppLanguage.japanese.name,
    });
    expect(await resolveAppLocaleLanguageCode(), 'ja');
  });

  testWidgets('英語ロケールの文言を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(builder: (context) => Text(context.l10n.searchPageTitle)),
      ),
    );

    expect(find.text('Sake Search'), findsOneWidget);
  });

  testWidgets('言語変更を再起動なしで画面へ反映する', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppLocaleController();
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: Consumer<AppLocaleController>(
          builder: (context, localeController, _) => MaterialApp(
            locale: localeController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(builder: (context) => Text(context.l10n.language)),
          ),
        ),
      ),
    );

    await controller.setLanguage(AppLanguage.english);
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);

    await controller.setLanguage(AppLanguage.japanese);
    await tester.pumpAndSettle();
    expect(find.text('言語'), findsOneWidget);
  });
}
