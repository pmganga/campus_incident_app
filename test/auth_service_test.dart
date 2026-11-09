import 'package:campus_incident_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase Auth that fails every sign-in with a chosen error code and
/// records whether it was called at all.
class FailingFirebaseAuth implements FirebaseAuth {
  FailingFirebaseAuth(this.code);

  final String code;
  int calls = 0;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    calls++;
    throw FirebaseAuthException(code: code);
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
    ActionCodeSettings? actionCodeSettings,
  }) async {
    calls++;
    throw FirebaseAuthException(code: code);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Future<String> signInError(String code, {String email = 'a@alustudent.com'}) async {
    try {
      await AuthService(auth: FailingFirebaseAuth(code)).signIn(email: email, password: 'x');
      return 'no error';
    } on AuthException catch (e) {
      return e.message;
    }
  }

  test('Firebase error codes become friendly messages', () async {
    expect(await signInError('wrong-password'), 'Incorrect email or password.');
    expect(await signInError('invalid-credential'), 'Incorrect email or password.');
    expect(await signInError('too-many-requests'), contains('Too many attempts'));
    expect(await signInError('network-request-failed'), contains('No internet connection'));
    expect(await signInError('something-new'), contains('something-new'));
  });

  test('a non-ALU email is refused before Firebase is contacted', () async {
    final firebase = FailingFirebaseAuth('wrong-password');
    final service = AuthService(auth: firebase);

    await expectLater(
      service.signIn(email: 'someone@gmail.com', password: 'x'),
      throwsA(isA<AuthException>()
          .having((e) => e.message, 'message', 'Only ALU email addresses can use this app.')),
    );
    await expectLater(service.sendPasswordReset('someone@gmail.com'), throwsA(isA<AuthException>()));
    expect(firebase.calls, 0);
  });

  test('the user-enumeration-safe message is the same for unknown users', () async {
    // "user-not-found" and "wrong-password" give the same message, so the
    // app does not reveal which ALU emails have accounts.
    expect(await signInError('user-not-found'), await signInError('wrong-password'));
  });
}
