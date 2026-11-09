import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_auth.dart';
import 'helpers/fake_incident_service.dart';

void main() {
  late FakeAuthService auth;
  late FakeUserService users;
  late AuthProvider provider;

  setUp(() {
    auth = FakeAuthService();
    users = FakeUserService();
    provider = AuthProvider(auth, users);
  });

  tearDown(() => provider.dispose());

  test('starts as unknown while Firebase restores the session', () {
    expect(provider.status, AuthStatus.unknown);
  });

  test('no user means the login screen', () async {
    await auth.emit(null);
    expect(provider.status, AuthStatus.unauthenticated);
  });

  test('a non-ALU account is signed out immediately', () async {
    await auth.emit(FakeUser(email: 'someone@gmail.com'));
    expect(auth.signOutCalls, 1);
    expect(provider.status, AuthStatus.unauthenticated);
    expect(users.created, isEmpty);
  });

  test('an unverified ALU account must verify its email first', () async {
    await auth.emit(FakeUser(emailVerified: false));
    expect(provider.status, AuthStatus.unverified);
    expect(provider.appUser, isNull);
  });

  test('first verified sign-in creates a student profile with the registered name', () async {
    await provider.register('  Amina Hassan ', 'a@alustudent.com', 'password1');
    await auth.emit(FakeUser());
    expect(provider.status, AuthStatus.loadingProfile);

    await users.emit(null); // the profile document does not exist yet
    expect(users.created.single, (uid: 'u1', name: 'Amina Hassan', email: 'a@alustudent.com'));

    await users.emit(testStudent); // Firestore reports the new document
    expect(provider.status, AuthStatus.authenticated);
    expect(provider.isStaff, isFalse);
  });

  test('without a registered name, the email prefix is used', () async {
    await auth.emit(FakeUser(email: 'p.mganga@alustudent.com'));
    await users.emit(null);
    expect(users.created.single.name, 'p.mganga');
  });

  test('a role changed to staff in the Console applies immediately', () async {
    await auth.emit(FakeUser());
    await users.emit(testStudent);
    expect(provider.isStaff, isFalse);

    await users.emit(const AppUser(
      uid: 'u1',
      name: 'Amina Hassan',
      email: 'a@alustudent.com',
      role: UserRole.staff,
    ));
    expect(provider.isStaff, isTrue);
  });

  test('verifying the email moves on to loading the profile', () async {
    await auth.emit(FakeUser(emailVerified: false));
    auth.verifiedOnReload = true;

    expect(await provider.checkEmailVerified(), isTrue);
    expect(provider.status, AuthStatus.loadingProfile);
  });

  test('failed actions return a friendly message instead of throwing', () async {
    auth.nextError = const AuthException('Incorrect email or password.');
    expect(await provider.signIn('a@alustudent.com', 'wrong'), 'Incorrect email or password.');
    expect(provider.isBusy, isFalse);

    expect(await provider.signIn('a@alustudent.com', 'right1234'), isNull);
  });

  test('signing out returns to the login screen', () async {
    await auth.emit(FakeUser());
    await users.emit(testStudent);
    await provider.signOut();
    expect(provider.status, AuthStatus.unauthenticated);
    expect(provider.appUser, isNull);
  });
}
