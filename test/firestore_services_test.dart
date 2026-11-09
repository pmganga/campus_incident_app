import 'dart:typed_data';

import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/services/incident_service.dart';
import 'package:campus_incident_app/services/user_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_incident_service.dart';

/// Runs the real services against an in-memory Firestore and checks exactly
/// what they write: the document shape firestore.rules expects.
void main() {
  late FakeFirebaseFirestore db;
  late IncidentService incidents;
  late UserService users;

  setUp(() {
    db = FakeFirebaseFirestore();
    incidents = IncidentService(firestore: db);
    users = UserService(firestore: db);
  });

  Future<String> create({Uint8List? photo, bool isAnonymous = false}) => incidents.createIncident(
        reporter: testStudent,
        title: '  Leaking tap  ',
        description: 'The tap in the washroom keeps running.',
        category: IncidentCategory.water,
        location: 'Block B',
        locationDetail: '   ',
        photo: photo,
        isAnonymous: isAnonymous,
      );

  Future<Map<String, dynamic>> incidentDoc(String id) async =>
      (await db.collection('incidents').doc(id).get()).data()!;

  group('IncidentService', () {
    test('creates a report with exactly the fields the rules allow', () async {
      final id = await create();
      final data = await incidentDoc(id);

      expect(data.keys.toSet(), {
        'title', 'description', 'category', 'location', 'locationDetail', 'status',
        'hasPhoto', 'isAnonymous', 'reporterId', 'reporterName',
        'createdAt', 'updatedAt', 'statusHistory',
      });
      expect(data['title'], 'Leaking tap'); // trimmed
      expect(data['locationDetail'], isNull); // blank becomes null
      expect(data['status'], 'submitted');
      expect(data['reporterId'], 'u1');
      expect(data['reporterName'], 'Amina Hassan');
      expect(data['hasPhoto'], isFalse);
      expect((data['statusHistory'] as List), hasLength(1));
      expect((await db.collection('incident_photos').doc(id).get()).exists, isFalse);
    });

    test('saves the photo in its own document with the same id', () async {
      final photo = Uint8List.fromList([0xFF, 0xD8, 1, 2, 3]);
      final id = await create(photo: photo);

      expect((await incidentDoc(id))['hasPhoto'], isTrue);
      final photoDoc = (await db.collection('incident_photos').doc(id).get()).data()!;
      expect(photoDoc['reporterId'], 'u1');
      expect(await incidents.fetchPhoto(id), photo);
    });

    test('an anonymous report does not contain the student\'s name anywhere', () async {
      final id = await create(isAnonymous: true);
      final data = await incidentDoc(id);

      expect(data['isAnonymous'], isTrue);
      expect(data['reporterName'], 'Anonymous student');
      expect(data.toString(), isNot(contains('Amina')));
    });

    test('a status update appends to the history and keeps earlier entries', () async {
      final id = await create();
      await incidents.updateStatus(
        incidentId: id,
        status: IncidentStatus.inProgress,
        changedBy: testStaff,
        note: '  Plumber assigned ',
      );

      final incident = Incident.fromMap(id, await incidentDoc(id));
      expect(incident.status, IncidentStatus.inProgress);
      expect(incident.statusHistory.map((c) => c.status),
          [IncidentStatus.submitted, IncidentStatus.inProgress]);
      expect(incident.statusHistory.last.changedByName, 'Grace Staff');
      expect(incident.statusHistory.last.note, 'Plumber assigned');
    });

    test('withdrawing a report also deletes its photo', () async {
      final id = await create(photo: Uint8List.fromList([1, 2, 3]));
      final incident = Incident.fromMap(id, await incidentDoc(id));

      await incidents.deleteIncident(incident);

      expect((await db.collection('incidents').doc(id).get()).exists, isFalse);
      expect((await db.collection('incident_photos').doc(id).get()).exists, isFalse);
    });

    test('a student only receives their own reports, newest first', () async {
      CollectionReference<Map<String, dynamic>> col = db.collection('incidents');
      await col.add({'title': 'Mine, old', 'reporterId': 'u1', 'createdAt': Timestamp.fromDate(DateTime(2026, 10, 1))});
      await col.add({'title': 'Mine, new', 'reporterId': 'u1', 'createdAt': Timestamp.fromDate(DateTime(2026, 10, 9))});
      await col.add({'title': 'Someone else', 'reporterId': 'u2', 'createdAt': Timestamp.fromDate(DateTime(2026, 10, 5))});

      final mine = await incidents.watchIncidentsByReporter('u1').first;
      expect(mine.map((i) => i.title), ['Mine, new', 'Mine, old']);

      final all = await incidents.watchAllIncidents().first;
      expect(all, hasLength(3));
    });
  });

  group('UserService', () {
    test('a new profile is always a student, with a lower-case email', () async {
      await users.createStudentProfile(uid: 'u9', name: 'Brian', email: 'Brian.O@ALUSTUDENT.com');
      final data = (await db.collection('users').doc('u9').get()).data()!;

      expect(data['role'], 'student');
      expect(data['email'], 'brian.o@alustudent.com');
      expect(data.keys.toSet(), {'name', 'email', 'role', 'createdAt'});
    });

    test('watchUser emits null until the profile exists, then the profile', () async {
      expect(await users.watchUser('u9').first, isNull);

      await db.collection('users').doc('u9').set({'name': 'Brian', 'email': 'b@alustudent.com', 'role': 'staff'});
      final profile = await users.watchUser('u9').first;
      expect(profile?.role, UserRole.staff);
    });
  });
}
