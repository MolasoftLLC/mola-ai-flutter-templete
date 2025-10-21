import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const _cachedEmailKey = 'auth.lastEmail';

  final FirebaseAuth _firebaseAuth;

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _cacheEmail(email);
    return credential;
  }

  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _cacheEmail(email);
    return credential;
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
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
}
