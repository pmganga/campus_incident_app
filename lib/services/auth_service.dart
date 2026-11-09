import 'package:firebase_auth/firebase_auth.dart';

import '../utils/validators.dart';

/// Thrown by [AuthService] with a message that is safe to show to the user.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Wraps Firebase Authentication. The UI never talks to FirebaseAuth directly.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn({required String email, required String password}) async {
    _requireAluEmail(email);
    await _guard(() => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
  }

  /// Creates the account, saves the display name and sends the verification email.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _requireAluEmail(email);
    final credential = await _guard(() => _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
    final user = credential.user!;
    await _guard(() => user.updateDisplayName(name.trim()));
    await _guard(() => user.sendEmailVerification());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthException('You are not signed in.');
    await _guard(() => user.sendEmailVerification());
  }

  /// Reloads the user from Firebase and reports whether the email is now verified.
  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await _guard(() => user.reload());
    final refreshed = _auth.currentUser;
    if (refreshed == null || !refreshed.emailVerified) return false;
    // Refresh the ID token so Firestore security rules see email_verified = true.
    await _guard(() => refreshed.getIdToken(true));
    return true;
  }

  Future<void> sendPasswordReset(String email) async {
    _requireAluEmail(email);
    await _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  Future<void> signOut() => _auth.signOut();

  void _requireAluEmail(String email) {
    if (!Validators.isAluEmail(email)) {
      throw const AuthException('Only ALU email addresses can use this app.');
    }
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_messageFor(e.code));
    }
  }

  static String _messageFor(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Contact campus support.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for this email. Try signing in.';
      case 'weak-password':
        return 'Please choose a stronger password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Check your network and try again.';
      case 'operation-not-allowed':
        return 'Email sign-in is not enabled for this app yet.';
      default:
        return 'Something went wrong ($code). Please try again.';
    }
  }
}
