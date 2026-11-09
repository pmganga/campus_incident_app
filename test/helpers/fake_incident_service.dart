import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';

import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident.dart';
import 'package:campus_incident_app/services/incident_service.dart';

/// Stands in for Firestore in tests. Tests push "snapshots" through
/// [controller], and the fake records which query and writes the app made.
class FakeIncidentService implements IncidentService {
  final controller = StreamController<List<Incident>>.broadcast();
  String? watchedQuery;
  int createCalls = 0;
  Uint8List? lastPhoto;
  bool? lastIsAnonymous;
  int photoFetches = 0;
  final photos = <String, Uint8List>{};

  /// How many photo downloads fail before they start working.
  int photoFailuresLeft = 0;
  final statusUpdates = <(String id, IncidentStatus status, String? note)>[];
  final deletedIds = <String>[];

  @override
  Stream<List<Incident>> watchIncidentsByReporter(String uid) {
    watchedQuery = 'reporter:$uid';
    return controller.stream;
  }

  @override
  Stream<List<Incident>> watchAllIncidents() {
    watchedQuery = 'all';
    return controller.stream;
  }

  @override
  Future<String> createIncident({
    required AppUser reporter,
    required String title,
    required String description,
    required IncidentCategory category,
    required String location,
    String? locationDetail,
    Uint8List? photo,
    bool isAnonymous = false,
  }) async {
    createCalls++;
    lastPhoto = photo;
    lastIsAnonymous = isAnonymous;
    return 'fake-id';
  }

  @override
  Future<void> updateStatus({
    required String incidentId,
    required IncidentStatus status,
    required AppUser changedBy,
    String? note,
  }) async =>
      statusUpdates.add((incidentId, status, note));

  @override
  Future<Uint8List?> fetchPhoto(String incidentId) async {
    photoFetches++;
    if (photoFailuresLeft > 0) {
      photoFailuresLeft--;
      throw FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
    }
    return photos[incidentId];
  }

  @override
  Future<void> deleteIncident(Incident incident) async => deletedIds.add(incident.id);
}

Incident makeIncident(
  String id,
  String title,
  IncidentCategory category,
  IncidentStatus status, {
  String location = 'Block B',
  String reporterId = 'u1',
  String reporterName = 'Amina Hassan',
  DateTime? createdAt,
  DateTime? updatedAt,
  bool hasPhoto = false,
  bool isAnonymous = false,
}) {
  final at = createdAt ?? DateTime(2026, 10, 15);
  return Incident(
    id: id,
    title: title,
    description: 'Details about $title',
    category: category,
    location: location,
    status: status,
    reporterId: reporterId,
    reporterName: reporterName,
    createdAt: at,
    updatedAt: updatedAt ?? at,
    hasPhoto: hasPhoto,
    isAnonymous: isAnonymous,
  );
}

const testStudent = AppUser(
  uid: 'u1',
  name: 'Amina Hassan',
  email: 'a@alustudent.com',
  role: UserRole.student,
);

const testStaff = AppUser(
  uid: 's1',
  name: 'Grace Staff',
  email: 'g@alueducation.com',
  role: UserRole.staff,
);
