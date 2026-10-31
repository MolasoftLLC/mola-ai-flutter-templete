import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mola_gemini_flutter_template/common/logger.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/my_page/my_page_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/notifier/favorite/favorite_notifier.dart';
import 'package:mola_gemini_flutter_template/domain/repository/auth_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/sake_menu_recognition_repository.dart';
import 'package:mola_gemini_flutter_template/domain/repository/user_preference_repository.dart';

class _Guest implements AuthRepository {
  @override
  get currentUser => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Analysis implements SakeMenuRecognitionRepository {
  _Analysis(this.error);
  final Object error;
  @override
  Future<String?> analyzeSakePreference(List<FavoriteSake> sakes) async =>
      throw error;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Notifier extends MyPageNotifier {
  _Notifier(this.error);
  final Object error;
  @override
  SakeMenuRecognitionRepository get sakeMenuRecognitionRepository =>
      _Analysis(error);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loggerConfigure);
  for (final error in [
    const MonthlyTasteAnalysisLimitException(),
    StateError('offline'),
  ]) {
    test('解析エラーは保存対象にせず既存の好みを保持: ${error.runtimeType}', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = _Notifier(error)..read = (<T>() => _Guest() as T);
      await Future<void>.delayed(Duration.zero);
      notifier.setPreferences('すっきりした味が好き');
      await notifier.analyzeSakePreference([
        FavoriteSake(name: 'テスト', type: '純米'),
      ]);
      expect(notifier.state.sakePreferenceAnalysis, isNull);
      expect(notifier.state.sakePreferenceAnalysisError, isNotEmpty);
      expect(await notifier.saveSakePreferenceAsPreferences(), false);
      expect(notifier.currentPreferences, 'すっきりした味が好き');
      notifier.dispose();
    });
  }
}
