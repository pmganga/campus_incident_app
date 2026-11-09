import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/theme/status_style.dart';
import 'package:campus_incident_app/widgets/empty_state.dart';
import 'package:campus_incident_app/widgets/report_card.dart';
import 'package:campus_incident_app/widgets/status_chip.dart';
import 'package:campus_incident_app/widgets/status_timeline.dart';
import 'package:campus_incident_app/widgets/summary_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'helpers/fake_incident_service.dart';

/// Wraps a widget in the app's providers and a Material page.
Widget host(Widget child) => ChangeNotifierProvider(
      create: (_) => IncidentProvider(FakeIncidentService())..updateUser(testStudent),
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
    );

void main() {
  group('StatusChip', () {
    for (final status in IncidentStatus.values) {
      testWidgets('shows "${status.label}" in its own colour', (tester) async {
        await tester.pumpWidget(host(StatusChip(status: status)));
        final text = tester.widget<Text>(find.text(status.label));
        expect(text.style?.color, status.color);
      });
    }

    test('every status has a different colour', () {
      final colours = IncidentStatus.values.map((s) => s.color).toSet();
      expect(colours, hasLength(IncidentStatus.values.length));
    });
  });

  group('ReportCard', () {
    final incident = makeIncident(
        '1', 'Broken projector', IncidentCategory.facilities, IncidentStatus.inProgress);

    testWidgets('shows title, place and status, and responds to taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(host(ReportCard(incident: incident, onTap: () => taps++)));

      expect(find.text('Broken projector'), findsOneWidget);
      expect(find.text('Block B'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.textContaining('Amina Hassan'), findsNothing); // students see no names

      await tester.tap(find.byType(ReportCard));
      expect(taps, 1);
    });

    testWidgets('staff lists show the reporter', (tester) async {
      await tester.pumpWidget(
          host(ReportCard(incident: incident, onTap: () {}, showReporter: true)));
      expect(find.textContaining('Amina Hassan'), findsOneWidget);
    });

    testWidgets('without a photo, the category icon is shown', (tester) async {
      await tester.pumpWidget(host(ReportCard(incident: incident, onTap: () {})));
      expect(find.byIcon(IncidentCategory.facilities.icon), findsOneWidget);
    });
  });

  group('StatusTimeline', () {
    testWidgets('ends at Resolved for a normal report', (tester) async {
      final incident = makeIncident(
          '1', 'Leaking tap', IncidentCategory.water, IncidentStatus.inProgress);
      await tester.pumpWidget(host(StatusTimeline(incident: incident)));
      expect(find.text('Submitted'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Resolved'), findsOneWidget);
      expect(find.text('Rejected'), findsNothing);
    });

    testWidgets('ends at Rejected for a rejected report', (tester) async {
      final incident = makeIncident(
          '1', 'Spam report', IncidentCategory.other, IncidentStatus.rejected);
      await tester.pumpWidget(host(StatusTimeline(incident: incident)));
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Resolved'), findsNothing);
    });

    testWidgets('the history shows who changed the status and their note', (tester) async {
      final history = [
        StatusChange(
          status: IncidentStatus.submitted,
          changedById: 'u1',
          changedByName: 'Amina Hassan',
          note: 'Report submitted',
          at: DateTime(2026, 10, 15, 9),
        ),
        StatusChange(
          status: IncidentStatus.inProgress,
          changedById: 's1',
          changedByName: 'Grace Staff',
          note: 'Plumber assigned',
          at: DateTime(2026, 10, 15, 11),
        ),
      ];
      await tester.pumpWidget(host(StatusHistoryList(history: history)));
      expect(find.text('In Progress · Grace Staff'), findsOneWidget);
      expect(find.text('Plumber assigned'), findsOneWidget);

      // Newest first.
      final newest = tester.getTopLeft(find.text('In Progress · Grace Staff')).dy;
      final oldest = tester.getTopLeft(find.text('Submitted · Amina Hassan')).dy;
      expect(newest, lessThan(oldest));
    });
  });

  testWidgets('EmptyState shows its action button only when given one', (tester) async {
    var pressed = false;
    await tester.pumpWidget(host(EmptyState(
      icon: Icons.inbox_outlined,
      title: 'No reports yet',
      message: 'Nothing here',
      actionLabel: 'Report an issue',
      onAction: () => pressed = true,
    )));
    await tester.tap(find.text('Report an issue'));
    expect(pressed, isTrue);

    await tester.pumpWidget(host(const EmptyState(
      icon: Icons.inbox_outlined,
      title: 'No reports yet',
      message: 'Nothing here',
    )));
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('SummaryTile can be opened with a screen reader', (tester) async {
    final semantics = tester.ensureSemantics();
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SummaryTile(
            icon: Icons.inbox, count: 3, label: 'Submitted', color: Colors.orange, onTap: () => taps++),
      ),
    ));

    expect(tester.getSemantics(find.byType(SummaryTile)),
        matchesSemantics(label: '3 Submitted', isButton: true, hasTapAction: true));
    tester.semantics.tap(find.semantics.byLabel('3 Submitted'));
    expect(taps, 1);
    semantics.dispose();
  });
}
