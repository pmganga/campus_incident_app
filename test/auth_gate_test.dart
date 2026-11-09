import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/screens/auth/auth_gate.dart';
import 'package:campus_incident_app/screens/auth/login_screen.dart';
import 'package:campus_incident_app/screens/auth/verify_email_screen.dart';
import 'package:campus_incident_app/screens/staff/staff_shell.dart';
import 'package:campus_incident_app/screens/student/student_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_auth.dart';
import 'helpers/fake_incident_service.dart';

/// Routing from sign-in state and role, using the same provider wiring as
/// main.dart but with fake Firebase services.
void main() {
  late FakeAuthService auth;
  late FakeUserService users;
  late FakeIncidentService incidents;

  Future<void> pumpApp(WidgetTester tester) async {
    auth = FakeAuthService();
    users = FakeUserService();
    incidents = FakeIncidentService();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(auth, users)),
          ChangeNotifierProxyProvider<AuthProvider, IncidentProvider>(
            create: (_) => IncidentProvider(incidents),
            update: (_, authProvider, provider) => provider!..updateUser(authProvider.appUser),
          ),
        ],
        child: const MaterialApp(home: AuthGate()),
      ),
    );
  }

  Future<void> settle(WidgetTester tester, Future<void> Function() change) async {
    await tester.runAsync(change);
    await tester.pump();
  }

  testWidgets('signed out shows the login screen', (tester) async {
    await pumpApp(tester);
    await settle(tester, () => auth.emit(null));
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('unverified email shows the verify screen', (tester) async {
    await pumpApp(tester);
    await settle(tester, () => auth.emit(FakeUser(emailVerified: false)));
    expect(find.byType(VerifyEmailScreen), findsOneWidget);
  });

  testWidgets('a student goes to the student screens and watches only their reports',
      (tester) async {
    await pumpApp(tester);
    await settle(tester, () => auth.emit(FakeUser()));
    await settle(tester, () => users.emit(testStudent));

    expect(find.byType(StudentShell), findsOneWidget);
    expect(find.byType(StaffShell), findsNothing);
    expect(incidents.watchedQuery, 'reporter:u1');
  });

  testWidgets('staff go to the staff screens and watch every report', (tester) async {
    await pumpApp(tester);
    await settle(tester, () => auth.emit(FakeUser(uid: 's1', email: 'g@alueducation.com')));
    await settle(tester, () => users.emit(testStaff));

    expect(find.byType(StaffShell), findsOneWidget);
    expect(find.byType(StudentShell), findsNothing);
    expect(incidents.watchedQuery, 'all');
  });

  testWidgets('promoting a student to staff switches screens live', (tester) async {
    await pumpApp(tester);
    await settle(tester, () => auth.emit(FakeUser()));
    await settle(tester, () => users.emit(testStudent));
    expect(find.byType(StudentShell), findsOneWidget);

    await settle(
        tester,
        () => users.emit(const AppUser(
              uid: 'u1',
              name: 'Amina Hassan',
              email: 'a@alustudent.com',
              role: UserRole.staff,
            )));
    expect(find.byType(StaffShell), findsOneWidget);
  });
}
