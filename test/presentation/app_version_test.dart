import 'package:flutter_test/flutter_test.dart';
import 'package:mola_gemini_flutter_template/presentation/app_page_notifier.dart';

void main() {
  test('minimum version is compared as semantic version', () {
    expect(
      isVersionBelowMinimum(currentVersion: '4.7.1', minimumVersion: '4.8.0'),
      isTrue,
    );
    expect(
      isVersionBelowMinimum(currentVersion: '5.0.0', minimumVersion: '4.8.0'),
      isFalse,
    );
    expect(
      isVersionBelowMinimum(currentVersion: '4.10.0', minimumVersion: '4.9.9'),
      isFalse,
    );
  });
}
