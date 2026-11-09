import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/utils/validators.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Enum parsing', () {
    test('unknown values fall back safely', () {
      expect(IncidentCategory.fromString('water'), IncidentCategory.water);
      expect(IncidentCategory.fromString('nonsense'), IncidentCategory.other);
      expect(IncidentStatus.fromString('inProgress'), IncidentStatus.inProgress);
      expect(IncidentStatus.fromString(null), IncidentStatus.submitted);
    });

    test('only submitted and in-progress count as open', () {
      expect(IncidentStatus.submitted.isOpen, isTrue);
      expect(IncidentStatus.inProgress.isOpen, isTrue);
      expect(IncidentStatus.resolved.isOpen, isFalse);
      expect(IncidentStatus.rejected.isOpen, isFalse);
    });
  });

  group('Incident.fromMap', () {
    final submittedAt = DateTime(2026, 10, 15, 10, 24);

    Map<String, dynamic> sampleData() => {
          'title': 'Water shortage',
          'description': 'No water on the 2nd floor since this morning.',
          'category': 'water',
          'location': 'Student Residence',
          'locationDetail': '2nd floor',
          'status': 'inProgress',
          'hasPhoto': true,
          'isAnonymous': false,
          'reporterId': 'uid123',
          'reporterName': 'Amina Hassan',
          'createdAt': Timestamp.fromDate(submittedAt),
          'updatedAt': Timestamp.fromDate(submittedAt),
          'statusHistory': [
            StatusChange(
              status: IncidentStatus.submitted,
              changedById: 'uid123',
              changedByName: 'Amina Hassan',
              note: 'Report submitted',
              at: submittedAt,
            ).toMap(),
          ],
        };

    test('reads every field', () {
      final incident = Incident.fromMap('abc', sampleData());
      expect(incident.id, 'abc');
      expect(incident.category, IncidentCategory.water);
      expect(incident.status, IncidentStatus.inProgress);
      expect(incident.createdAt, submittedAt);
      expect(incident.fullLocation, 'Student Residence — 2nd floor');
      expect(incident.statusHistory.single.note, 'Report submitted');
      expect(incident.statusHistory.single.at, submittedAt);
      expect(incident.hasPhoto, isTrue);
      expect(incident.isAnonymous, isFalse);
    });

    test('reports created before photos/anonymity existed default to false', () {
      final data = sampleData()
        ..remove('hasPhoto')
        ..remove('isAnonymous');
      final incident = Incident.fromMap('abc', data);
      expect(incident.hasPhoto, isFalse);
      expect(incident.isAnonymous, isFalse);
    });

    test('handles a pending server timestamp and missing detail', () {
      final data = sampleData()
        ..['createdAt'] = null
        ..['updatedAt'] = null
        ..['locationDetail'] = null;
      final incident = Incident.fromMap('abc', data);
      expect(incident.createdAt, isNotNull);
      expect(incident.fullLocation, 'Student Residence');
    });
  });

  group('StatusChange', () {
    test('survives a save and load round trip', () {
      final original = StatusChange(
        status: IncidentStatus.rejected,
        changedById: 's1',
        changedByName: 'Grace Staff',
        note: 'Duplicate of an existing report',
        at: DateTime(2026, 10, 16, 14, 5),
      );
      final copy = StatusChange.fromMap(original.toMap());
      expect(copy.status, original.status);
      expect(copy.changedById, original.changedById);
      expect(copy.changedByName, original.changedByName);
      expect(copy.note, original.note);
      expect(copy.at, original.at);
    });

    test('is stored with a Firestore Timestamp, not a DateTime', () {
      final map = StatusChange(
        status: IncidentStatus.submitted,
        changedById: 'u1',
        changedByName: 'Amina',
        at: DateTime(2026, 10, 16),
      ).toMap();
      expect(map['at'], isA<Timestamp>());
      expect(map['status'], 'submitted'); // enum saved by name
    });
  });

  group('Report validators', () {
    test('title length limits', () {
      expect(Validators.incidentTitle(''), isNotNull);
      expect(Validators.incidentTitle('Leak'), isNotNull);
      expect(Validators.incidentTitle('Leaking tap'), isNull);
      expect(Validators.incidentTitle('x' * 81), isNotNull);
    });

    test('description needs real detail', () {
      expect(Validators.incidentDescription('Broken'), isNotNull);
      expect(Validators.incidentDescription('The projector in room 204 does not turn on.'), isNull);
    });
  });
}
