import 'package:campus_incident_app/providers/auth_provider.dart';
import 'package:campus_incident_app/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_auth.dart';

void main() {
  late FakeAuthService auth;

  Future<void> pumpRegister(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    auth = FakeAuthService();
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => AuthProvider(auth, FakeUserService()),
      child: MaterialApp(home: RegisterScreen(onShowLogin: () {})),
    ));
  }

  Future<void> fill(WidgetTester tester, String label, String text) =>
      tester.enterText(find.widgetWithText(TextFormField, label), text);

  testWidgets('a non-ALU email and a weak password are refused', (tester) async {
    await pumpRegister(tester);
    await fill(tester, 'Full name', 'Amina Hassan');
    await fill(tester, 'ALU email', 'amina@gmail.com');
    await fill(tester, 'Password', 'short');
    await fill(tester, 'Confirm password', 'different');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(find.text('Use your ALU email (e.g. name@alustudent.com)'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(auth.registered, isEmpty);
  });

  testWidgets('a valid form registers the account', (tester) async {
    await pumpRegister(tester);
    await fill(tester, 'Full name', 'Amina Hassan');
    await fill(tester, 'ALU email', 'a.hassan@alustudent.com');
    await fill(tester, 'Password', 'campus2026');
    await fill(tester, 'Confirm password', 'campus2026');
    await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
    await tester.pump();

    expect(auth.registered, ['a.hassan@alustudent.com']);
  });
}
