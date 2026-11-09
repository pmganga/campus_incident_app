import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/widgets/update_status_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_incident_service.dart';

void main() {
  late FakeIncidentService service;
  final incident =
      makeIncident('1', 'Water shortage', IncidentCategory.water, IncidentStatus.submitted);

  Future<void> pumpSheet(WidgetTester tester) async {
    service = FakeIncidentService();
    final provider = IncidentProvider(service)
      ..updateUser(testStaff);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(body: UpdateStatusSheet(incident: incident)),
        ),
      ),
    );
  }

  testWidgets('offers every status except the current one', (tester) async {
    await pumpSheet(tester);
    expect(find.widgetWithText(ChoiceChip, 'Submitted'), findsNothing);
    expect(find.widgetWithText(ChoiceChip, 'In Progress'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'Rejected'), findsOneWidget);
  });

  testWidgets('rejecting without a reason is blocked', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Rejected'));
    await tester.pump();
    await tester.tap(find.text('Save Update'));
    await tester.pump();

    expect(find.text('Please give a reason for rejecting'), findsOneWidget);
    expect(service.statusUpdates, isEmpty);
  });

  testWidgets('saves the chosen status and note', (tester) async {
    await pumpSheet(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'In Progress'));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'Plumber assigned');
    await tester.tap(find.text('Save Update'));
    await tester.pumpAndSettle();

    expect(service.statusUpdates.single, ('1', IncidentStatus.inProgress, 'Plumber assigned'));
  });
}
