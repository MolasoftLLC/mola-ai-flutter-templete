import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseAuthConfig {
  FirebaseAuthConfig._();

  static const String _continueUrlKey = 'EMAIL_LINK_CONTINUE_URL';
  static const String _iosBundleId = 'okinawa.molasoft.sakepedia';
  static const String _androidPackageName = 'okinawa.molasoft_ai.sake';

  static ActionCodeSettings emailLinkActionCodeSettings() {
    final continueUrl = dotenv.env[_continueUrlKey];

    if (continueUrl == null || continueUrl.isEmpty) {
      throw StateError('EMAIL_LINK_CONTINUE_URL が設定されていません。');
    }

    return ActionCodeSettings(
      url: continueUrl,
      handleCodeInApp: true,
      androidPackageName: _androidPackageName,
      androidInstallApp: true,
      androidMinimumVersion: '1',
      iOSBundleId: _iosBundleId,
    );
  }
}
