import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const _cachedEmailKey = 'auth.emailForLink';

  final FirebaseAuth _firebaseAuth;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> sendEmailLink({
    required String email,
    required ActionCodeSettings settings,
  }) async {
    await _firebaseAuth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: settings,
    );
    await _cacheEmail(email);
  }

  bool isSignInWithEmailLink(String emailLink) {
    return _firebaseAuth.isSignInWithEmailLink(emailLink);
  }

  Future<UserCredential> signInWithEmailLink({
    required String email,
    required String emailLink,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );
    await _clearCachedEmail();
    return credential;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _clearCachedEmail();
  }

  Future<void> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  Future<String?> getCachedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedEmail = prefs.getString(_cachedEmailKey);
    if (cachedEmail == null || cachedEmail.isEmpty) {
      return null;
    }
    return cachedEmail;
  }

  Future<void> _cacheEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedEmailKey, email);
  }

  Future<void> _clearCachedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedEmailKey);
  }
}
