import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';

import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/providers/incident_provider.dart';
import 'package:campus_incident_app/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_incident_service.dart';

void main() {
  late FakeIncidentService service;
  late IncidentProvider provider;

  setUp(() {
    service = FakeIncidentService();
    provider = IncidentProvider(service, photoRetryDelay: Duration.zero)..updateUser(testStudent);
  });

  Future<void> emit(List<Incident> incidents) async {
    service.controller.add(incidents);
    await Future<void>.delayed(Duration.zero);
  }

  Future<WriteResult> submit({Uint8List? photo, bool isAnonymous = false}) =>
      provider.submitIncident(
        title: 'Leaking tap',
        description: 'The tap in the 2nd floor washroom keeps running.',
        category: IncidentCategory.water,
        location: 'Block B',
        photo: photo,
        isAnonymous: isAnonymous,
      );

  group('photos', () {
    test('the photo and anonymity choice are passed to the service', () async {
      final photo = Uint8List.fromList([1, 2, 3]);
      await submit(photo: photo, isAnonymous: true);
      expect(service.lastPhoto, photo);
      expect(service.lastIsAnonymous, isTrue);
    });

    test('a photo is downloaded once, then served from the cache', () async {
      service.photos['1'] = Uint8List.fromList([9, 9]);
      final incident = makeIncident('1', 'Broken window', IncidentCategory.facilities,
          IncidentStatus.submitted, hasPhoto: true);

      expect(await provider.photoFor(incident), [9, 9]);
      expect(await provider.photoFor(incident), [9, 9]);
      expect(service.photoFetches, 1);
    });

    test('a photo that is not on the server yet is retried until it loads', () async {
      service.photos['1'] = Uint8List.fromList([7]);
      service.photoFailuresLeft = 2;
      final incident = makeIncident('1', 'Broken window', IncidentCategory.facilities,
          IncidentStatus.submitted, hasPhoto: true);

      expect(await provider.photoFor(incident), [7]);
      expect(service.photoFetches, 3);
    });

    test('after repeated failures the photo is given up on, then retried later', () async {
      service.photos['1'] = Uint8List.fromList([7]);
      service.photoFailuresLeft = IncidentProvider.photoAttempts;
      final incident = makeIncident('1', 'Broken window', IncidentCategory.facilities,
          IncidentStatus.submitted, hasPhoto: true);

      await expectLater(provider.photoFor(incident), throwsA(isA<FirebaseException>()));
      expect(await provider.photoFor(incident), [7]);
    });

    test('reports without a photo never hit Firestore', () async {
      final incident =
          makeIncident('2', 'Broken chair', IncidentCategory.furniture, IncidentStatus.submitted);
      expect(await provider.photoFor(incident), isNull);
      expect(service.photoFetches, 0);
    });
  });

  group('misuse protection', () {
    List<Incident> recentReports(int count) => [
          for (var i = 0; i < count; i++)
            makeIncident('r$i', 'Report $i', IncidentCategory.other, IncidentStatus.submitted,
                location: 'Library',
                createdAt: DateTime.now().subtract(Duration(hours: i + 1))),
        ];

    test('says when the student can report again', () async {
      await emit(recentReports(AppConstants.dailyReportLimit));
      // The oldest counted report is 5 hours old, so the limit lifts in 19 hours.
      final expected = DateTime.now().add(const Duration(hours: 19));
      expect(provider.nextReportAllowedAt!.difference(expected).inMinutes.abs(), lessThan(1));
    });

    test('no "report again" time while under the limit', () async {
      await emit(recentReports(AppConstants.dailyReportLimit - 1));
      expect(provider.nextReportAllowedAt, isNull);
    });

    test('blocks a student after ${AppConstants.dailyReportLimit} reports in 24 hours', () async {
      await emit(recentReports(AppConstants.dailyReportLimit));
      expect(provider.hasReachedDailyLimit, isTrue);

      final result = await submit();
      expect(result.isFailure, isTrue);
      expect(service.createCalls, 0);
    });

    test('older reports do not count towards the limit', () async {
      final old = makeIncident('old', 'Old report', IncidentCategory.other,
          IncidentStatus.resolved, createdAt: DateTime.now().subtract(const Duration(days: 2)));
      await emit([...recentReports(AppConstants.dailyReportLimit - 1), old]);
      expect(provider.hasReachedDailyLimit, isFalse);
      expect((await submit()).outcome, WriteOutcome.done);
    });

    test('finds an open report for the same problem and place', () async {
      final open = makeIncident('1', 'No water', IncidentCategory.water, IncidentStatus.inProgress);
      final closed = makeIncident('2', 'Dripping tap', IncidentCategory.water,
          IncidentStatus.resolved, location: 'Library');
      await emit([open, closed]);

      expect(provider.findSimilarOpenReport(IncidentCategory.water, 'Block B')?.id, '1');
      expect(provider.findSimilarOpenReport(IncidentCategory.water, 'Library'), isNull); // resolved
      expect(provider.findSimilarOpenReport(IncidentCategory.safety, 'Block B'), isNull);
    });

    test('staff have no daily limit', () async {
      provider.updateUser(testStaff);
      await emit(recentReports(AppConstants.dailyReportLimit + 2));
      expect(provider.hasReachedDailyLimit, isFalse);
    });
  });

  group('anonymous reports', () {
    test("staff can't find an anonymous report by searching for a name", () async {
      provider.updateUser(testStaff);
      await emit([
        makeIncident('1', 'Unsafe stairs', IncidentCategory.safety, IncidentStatus.submitted,
            reporterName: AppConstants.anonymousReporterName, isAnonymous: true),
      ]);
      provider.setSearchQuery('anonymous');
      expect(provider.filteredIncidents, isEmpty);
    });
  });

  group('sorting', () {
    test('newest, oldest and recently updated', () async {
      final a = makeIncident('a', 'First', IncidentCategory.other, IncidentStatus.submitted,
          createdAt: DateTime(2026, 10, 1), updatedAt: DateTime(2026, 10, 20));
      final b = makeIncident('b', 'Second', IncidentCategory.other, IncidentStatus.submitted,
          createdAt: DateTime(2026, 10, 5));
      final c = makeIncident('c', 'Third', IncidentCategory.other, IncidentStatus.submitted,
          createdAt: DateTime(2026, 10, 10));
      await emit([c, b, a]); // the service delivers newest first

      expect(provider.filteredIncidents.map((i) => i.id), ['c', 'b', 'a']);
      provider.setSort(ReportSort.oldest);
      expect(provider.filteredIncidents.map((i) => i.id), ['a', 'b', 'c']);
      provider.setSort(ReportSort.recentlyUpdated);
      expect(provider.filteredIncidents.map((i) => i.id), ['a', 'c', 'b']);
    });
  });
}
