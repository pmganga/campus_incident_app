import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/screens/shared/incident_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_incident_service.dart';

/// The actions on the Details screen depend on who is looking.
void main() {
  late FakeIncidentService service;
  late IncidentProvider provider;

  Future<void> pumpDetails(WidgetTester tester, AppUser user, Incident incident) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    service = FakeIncidentService();
    provider = IncidentProvider(service)..updateUser(user);
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: provider,
      child: MaterialApp(home: IncidentDetailsScreen(incidentId: incident.id)),
    ));
    await tester.runAsync(() async {
      service.controller.add([incident]);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
  }

  final submitted =
      makeIncident('1', 'Water shortage', IncidentCategory.water, IncidentStatus.submitted);
  final inProgress =
      makeIncident('2', 'Broken projector', IncidentCategory.facilities, IncidentStatus.inProgress);

  testWidgets('a student can withdraw a report that is still submitted', (tester) async {
    await pumpDetails(tester, testStudent, submitted);
    expect(find.text('Water shortage'), findsWidgets);
    expect(find.text('Withdraw Report'), findsOneWidget);
    expect(find.text('Update Status'), findsNothing);
  });

  testWidgets('a student cannot withdraw once staff have started', (tester) async {
    await pumpDetails(tester, testStudent, inProgress);
    expect(find.text('Withdraw Report'), findsNothing);
    expect(find.text('Update Status'), findsNothing);
  });

  testWidgets('withdrawing asks for confirmation first', (tester) async {
    await pumpDetails(tester, testStudent, submitted);
    await tester.tap(find.text('Withdraw Report'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw this report?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.deletedIds, isEmpty);
  });

  testWidgets('staff get Update Status, which opens the status sheet', (tester) async {
    await pumpDetails(tester, testStaff, inProgress);
    expect(find.text('Withdraw Report'), findsNothing);

    await tester.tap(find.text('Update Status'));
    await tester.pumpAndSettle();
    expect(find.text('Save Update'), findsOneWidget);
  });

  testWidgets('an anonymous report hides the name from staff', (tester) async {
    final anonymous = makeIncident('3', 'Unsafe stairs', IncidentCategory.safety,
        IncidentStatus.submitted, reporterName: 'Anonymous student', isAnonymous: true);
    await pumpDetails(tester, testStaff, anonymous);
    expect(find.text('Reported anonymously'), findsOneWidget);
    expect(find.textContaining('Amina'), findsNothing);
  });

  testWidgets('a report that disappears shows "Report not found"', (tester) async {
    await pumpDetails(tester, testStudent, submitted);
    await tester.runAsync(() async {
      service.controller.add(const []);
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(find.text('Report not found'), findsOneWidget);
  });
}
