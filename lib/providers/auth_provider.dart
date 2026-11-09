import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/validators.dart';

enum AuthStatus {
  /// App just started; waiting for Firebase to restore the session.
  unknown,
  unauthenticated,

  /// Signed in, but the email address has not been verified yet.
  unverified,

  /// Verified; loading (or creating) the Firestore profile to learn the role.
  loadingProfile,
  authenticated,
}

/// App-wide authentication state. Screens read this instead of calling Firebase.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._userService) {
    _authSubscription = _authService.authStateChanges.listen(_onAuthChanged);
  }

  final AuthService _authService;
  final UserService _userService;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<AppUser?>? _profileSubscription;

  AuthStatus _status = AuthStatus.unknown;
  User? _firebaseUser;
  AppUser? _appUser;
  bool _isBusy = false;
  String? _profileError;

  // Name typed on the register form, used when the profile is first created.
  String? _pendingName;

  AuthStatus get status => _status;
  User? get firebaseUser => _firebaseUser;
  AppUser? get appUser => _appUser;
  bool get isBusy => _isBusy;
  bool get isStaff => _appUser?.isStaff ?? false;
  String? get profileError => _profileError;

  Future<void> _onAuthChanged(User? user) async {
    await _profileSubscription?.cancel();
    _profileSubscription = null;
    _appUser = null;
    _profileError = null;
    _firebaseUser = user;

    if (user == null) {
      _setStatus(AuthStatus.unauthenticated);
      return;
    }
    // Second line of defence: never let a non-ALU account into the app.
    if (!Validators.isAluEmail(user.email ?? '')) {
      await _authService.signOut();
      return;
    }
    if (!user.emailVerified) {
      _setStatus(AuthStatus.unverified);
      return;
    }
    _listenToProfile(user);
  }

  void _listenToProfile(User user) {
    _setStatus(AuthStatus.loadingProfile);
    _profileSubscription = _userService.watchUser(user.uid).listen(
      (profile) async {
        if (profile == null) {
          // First verified sign-in: create the profile. The snapshot listener
          // fires again once the document exists.
          try {
            await _userService.createStudentProfile(
              uid: user.uid,
              name: _pendingName ?? user.displayName ?? user.email!.split('@').first,
              email: user.email!,
            );
          } catch (e) {
            _profileError = 'Could not create your profile: $e';
            notifyListeners();
          }
          return;
        }
        _pendingName = null;
        _appUser = profile;
        _setStatus(AuthStatus.authenticated);
      },
      onError: (Object e) {
        _profileError = 'Could not load your profile: $e';
        notifyListeners();
      },
    );
  }

  /// Each action below returns null on success, or an error message for the UI.

  Future<String?> signIn(String email, String password) =>
      _run(() => _authService.signIn(email: email, password: password));

  Future<String?> register(String name, String email, String password) {
    _pendingName = name.trim();
    return _run(() =>
        _authService.register(name: name, email: email, password: password));
  }

  Future<String?> resendVerificationEmail() =>
      _run(_authService.sendEmailVerification);

  Future<String?> sendPasswordReset(String email) =>
      _run(() => _authService.sendPasswordReset(email));

  /// Returns true once the user has clicked the link in the verification email.
  Future<bool> checkEmailVerified() async {
    try {
      final verified = await _authService.reloadAndCheckVerified();
      // authStateChanges does not fire after a reload, so re-run the checks.
      if (verified) await _onAuthChanged(_authService.currentUser);
      return verified;
    } on AuthException {
      return false;
    }
  }

  Future<void> signOut() async {
    _pendingName = null;
    await _authService.signOut();
  }

  Future<String?> _run(Future<void> Function() action) async {
    _isBusy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Something went wrong. Please try again.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
