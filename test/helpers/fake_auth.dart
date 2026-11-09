import 'dart:async';

import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/services/auth_service.dart';
import 'package:campus_incident_app/services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A signed-in Firebase user with just the fields the app reads.
/// Anything else throws, so a test notices if the app starts using it.
class FakeUser implements User {
  FakeUser({
    this.uid = 'u1',
    this.email = 'a@alustudent.com',
    this.emailVerified = true,
    this.displayName,
  });

  @override
  final String uid;
  @override
  final String? email;
  @override
  bool emailVerified;
  @override
  final String? displayName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Stands in for Firebase Authentication. Tests push sign-in changes through
/// [authChanges] and can make the next action fail with [nextError].
class FakeAuthService implements AuthService {
  final authChanges = StreamController<User?>.broadcast();
  User? signedInUser;
  int signOutCalls = 0;
  bool verifiedOnReload = false;
  AuthException? nextError;
  final registered = <String>[];

  @override
  User? get currentUser => signedInUser;

  @override
  Stream<User?> get authStateChanges => authChanges.stream;

  /// Simulates Firebase reporting a sign-in (or sign-out with null).
  Future<void> emit(User? user) async {
    signedInUser = user;
    authChanges.add(user);
    await Future<void>.delayed(Duration.zero);
  }

  Future<void> _maybeFail() async {
    final error = nextError;
    nextError = null;
    if (error != null) throw error;
  }

  @override
  Future<void> signIn({required String email, required String password}) => _maybeFail();

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _maybeFail();
    registered.add(email);
  }

  @override
  Future<void> sendEmailVerification() => _maybeFail();

  @override
  Future<bool> reloadAndCheckVerified() async {
    if (verifiedOnReload && signedInUser is FakeUser) {
      (signedInUser! as FakeUser).emailVerified = true;
    }
    return verifiedOnReload;
  }

  @override
  Future<void> sendPasswordReset(String email) => _maybeFail();

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await emit(null);
  }
}

/// Stands in for the users/{uid} collection.
class FakeUserService implements UserService {
  final profiles = StreamController<AppUser?>.broadcast();
  final created = <({String uid, String name, String email})>[];

  /// Simulates the profile document changing in Firestore.
  Future<void> emit(AppUser? profile) async {
    profiles.add(profile);
    await Future<void>.delayed(Duration.zero);
  }

  @override
  Stream<AppUser?> watchUser(String uid) => profiles.stream;

  @override
  Future<void> createStudentProfile({
    required String uid,
    required String name,
    required String email,
  }) async =>
      created.add((uid: uid, name: name, email: email));
}
