import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/screens/student/report_incident_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_incident_service.dart';

void main() {
  late FakeIncidentService service;

  Future<void> pumpForm(WidgetTester tester) async {
    // A tall test screen, so the whole form is built and visible without
    // scrolling.
    tester.view.physicalSize = const Size(1080, 4200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    service = FakeIncidentService();
    final provider = IncidentProvider(service)..updateUser(testStudent);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const MaterialApp(home: ReportIncidentScreen()),
      ),
    );
  }

  testWidgets('empty form shows validation errors and does not submit', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.text('Submit Report'));
    await tester.pumpAndSettle();

    expect(find.text('Please choose a category'), findsOneWidget);
    expect(find.text('Please give the issue a short title'), findsOneWidget);
    expect(find.text('Please choose a location'), findsOneWidget);
    expect(service.createCalls, 0);
  });

  testWidgets('after a failed submit, an error clears as soon as it is fixed', (tester) async {
    await pumpForm(tester);
    await tester.tap(find.text('Submit Report'));
    await tester.pumpAndSettle();
    expect(find.text('Please give the issue a short title'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Title'), 'Broken window');
    await tester.pump();

    expect(find.text('Please give the issue a short title'), findsNothing);
    expect(find.text('Please describe the issue'), findsOneWidget);
  });

  testWidgets('offers camera and gallery for the optional photo', (tester) async {
    await pumpForm(tester);
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
  });

  testWidgets('the anonymous switch explains that staff will not see the name', (tester) async {
    await pumpForm(tester);
    expect(find.textContaining('Your name is shared with campus staff'), findsOneWidget);

    await tester.tap(find.text('Report anonymously'));
    await tester.pump();

    expect(find.textContaining('Your name will be hidden from staff'), findsOneWidget);
  });
}
