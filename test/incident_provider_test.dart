import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_incident_service.dart';

void main() {
  late FakeIncidentService service;
  late IncidentProvider provider;

  setUp(() {
    service = FakeIncidentService();
    provider = IncidentProvider(service)..updateUser(testStudent);
  });

  final sample = [
    makeIncident('1', 'Water shortage', IncidentCategory.water, IncidentStatus.submitted,
        location: 'Student Residence'),
    makeIncident('2', 'Broken projector', IncidentCategory.facilities, IncidentStatus.inProgress),
    makeIncident('3', 'Overflowing bin', IncidentCategory.sanitation, IncidentStatus.resolved,
        location: 'Cafeteria'),
    makeIncident('4', 'Leaking tap', IncidentCategory.water, IncidentStatus.inProgress),
  ];

  Future<void> emit(List<Incident> incidents) async {
    service.controller.add(incidents);
    await Future<void>.delayed(Duration.zero);
  }

  group('student', () {
    test('only watches their own reports', () {
      expect(service.watchedQuery, 'reporter:u1');
      expect(provider.isStaffView, isFalse);
    });

    test('is loading until the first snapshot arrives', () async {
      expect(provider.isLoading, isTrue);
      await emit(sample);
      expect(provider.isLoading, isFalse);
      expect(provider.reports, hasLength(4));
    });

    test('counts reports by status', () async {
      await emit(sample);
      expect(provider.countByStatus(IncidentStatus.inProgress), 2);
      expect(provider.countByStatus(IncidentStatus.resolved), 1);
      expect(provider.countByStatus(IncidentStatus.rejected), 0);
    });

    test('a live status change updates counts without any refresh', () async {
      await emit(sample);
      final updated = [...sample]
        ..[0] = makeIncident('1', 'Water shortage', IncidentCategory.water, IncidentStatus.resolved);
      await emit(updated);
      expect(provider.countByStatus(IncidentStatus.resolved), 2);
      expect(provider.incidentById('1')!.status, IncidentStatus.resolved);
    });

    test('status, category and search filters combine', () async {
      await emit(sample);

      provider.setStatusFilter(IncidentStatus.inProgress);
      expect(provider.filteredIncidents.map((i) => i.id), ['2', '4']);

      provider.setCategoryFilter(IncidentCategory.water);
      expect(provider.filteredIncidents.map((i) => i.id), ['4']);

      provider.clearFilters();
      provider.setSearchQuery('  cafeteria ');
      expect(provider.filteredIncidents.map((i) => i.id), ['3']);
      expect(provider.hasActiveFilters, isTrue);

      provider.clearFilters();
      expect(provider.filteredIncidents, hasLength(4));
      expect(provider.hasActiveFilters, isFalse);
    });

    test('can withdraw their own report only while it is still submitted', () async {
      await emit(sample);
      expect(provider.canWithdraw(sample[0]), isTrue); // submitted
      expect(provider.canWithdraw(sample[1]), isFalse); // in progress

      expect((await provider.withdrawIncident(sample[0])).outcome, WriteOutcome.done);
      expect((await provider.withdrawIncident(sample[1])).isFailure, isTrue);
      expect(service.deletedIds, ['1']);
    });

    test('cannot change a status', () async {
      await emit(sample);
      final result = await provider.updateStatus(sample[0], IncidentStatus.resolved);
      expect(result.isFailure, isTrue);
      expect(service.statusUpdates, isEmpty);
    });

    test('signing out clears the reports', () async {
      await emit(sample);
      provider.updateUser(null);
      expect(provider.reports, isEmpty);
      expect(provider.incidentById('1'), isNull);
    });
  });

  group('staff', () {
    setUp(() => provider.updateUser(testStaff));

    test('watches every report', () {
      expect(service.watchedQuery, 'all');
      expect(provider.isStaffView, isTrue);
    });

    test('awaiting review lists submitted reports, oldest first', () async {
      final newer = makeIncident('5', 'Dark corridor', IncidentCategory.electricity,
          IncidentStatus.submitted,
          reporterId: 'u2', reporterName: 'Brian Otieno', createdAt: DateTime(2026, 10, 20));
      final older = makeIncident('6', 'Broken door', IncidentCategory.facilities,
          IncidentStatus.submitted, createdAt: DateTime(2026, 10, 1));
      await emit([newer, ...sample, older]);
      expect(provider.awaitingReview.map((i) => i.id), ['6', '1', '5']);
    });

    test('search also matches the reporter name', () async {
      final other = makeIncident('5', 'Dark corridor', IncidentCategory.electricity,
          IncidentStatus.submitted, reporterId: 'u2', reporterName: 'Brian Otieno');
      await emit([...sample, other]);
      provider.setSearchQuery('brian');
      expect(provider.filteredIncidents.map((i) => i.id), ['5']);
    });

    test('updates a status with a note', () async {
      await emit(sample);
      final result = await provider.updateStatus(sample[0], IncidentStatus.inProgress,
          note: 'Plumber assigned');
      expect(result.outcome, WriteOutcome.done);
      expect(service.statusUpdates.single, ('1', IncidentStatus.inProgress, 'Plumber assigned'));
    });

    test('rejecting needs a reason, and the status must change', () async {
      await emit(sample);
      final noReason = await provider.updateStatus(sample[0], IncidentStatus.rejected, note: '  ');
      final sameStatus = await provider.updateStatus(sample[0], IncidentStatus.submitted);
      expect(noReason.isFailure, isTrue);
      expect(sameStatus.isFailure, isTrue);
      expect(service.statusUpdates, isEmpty);
    });

    test("cannot withdraw a student's report", () async {
      await emit(sample);
      expect(provider.canWithdraw(sample[0]), isFalse);
    });
  });

  group('Formatters', () {
    final now = DateTime(2026, 10, 15, 12);

    test('timeAgo', () {
      expect(Formatters.timeAgo(now.subtract(const Duration(seconds: 20)), now: now), 'Just now');
      expect(Formatters.timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5 min ago');
      expect(Formatters.timeAgo(now.subtract(const Duration(hours: 2)), now: now), '2 hours ago');
      expect(Formatters.timeAgo(now.subtract(const Duration(days: 1)), now: now), '1 day ago');
      expect(Formatters.timeAgo(DateTime(2026, 9, 1), now: now), '1 Sep 2026');
    });

    test('initials and first name', () {
      expect(Formatters.initials('Amina Hassan'), 'AH');
      expect(Formatters.initials('amina'), 'A');
      expect(Formatters.initials('  '), '?');
      expect(Formatters.firstName('Amina Hassan'), 'Amina');
    });
  });
}
