import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../models/incident.dart';
import '../utils/constants.dart';

/// All Firestore access for incident reports (incidents/{id}) and their
/// photos (incident_photos/{id}).
///
/// Who may do what is enforced by firestore.rules, not just by the app.
class IncidentService {
  IncidentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _incidents =>
      _firestore.collection(AppConstants.incidentsCollection);

  /// Photos live in their own collection, so loading a list of reports does
  /// not download every photo.
  CollectionReference<Map<String, dynamic>> get _photos =>
      _firestore.collection(AppConstants.photosCollection);

  /// Sorted on the phone rather than with orderBy(), because combining
  /// where() and orderBy() on different fields needs a composite index.
  static List<Incident> _newestFirst(QuerySnapshot<Map<String, dynamic>> snapshot) =>
      snapshot.docs.map(Incident.fromFirestore).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Live list of one student's reports, newest first.
  Stream<List<Incident>> watchIncidentsByReporter(String uid) =>
      _incidents.where('reporterId', isEqualTo: uid).snapshots().map(_newestFirst);

  /// Live list of every report, newest first. Staff only (see firestore.rules).
  Stream<List<Incident>> watchAllIncidents() => _incidents.snapshots().map(_newestFirst);

  /// Creates a new report with status "submitted" and returns its id.
  ///
  /// The report and its photo are written in one batch: either both are
  /// saved or neither is, so a failed upload never leaves a broken report.
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
    final doc = _incidents.doc();
    final reporterName = isAnonymous ? AppConstants.anonymousReporterName : reporter.name;
    final firstEntry = StatusChange(
      status: IncidentStatus.submitted,
      changedById: reporter.uid,
      changedByName: reporterName,
      note: 'Report submitted',
      at: DateTime.now(),
    );
    final detail = locationDetail?.trim();

    final batch = _firestore.batch()
      ..set(doc, {
        'title': title.trim(),
        'description': description.trim(),
        'category': category.name,
        'location': location,
        'locationDetail': (detail == null || detail.isEmpty) ? null : detail,
        'status': IncidentStatus.submitted.name,
        'hasPhoto': photo != null,
        'isAnonymous': isAnonymous,
        'reporterId': reporter.uid,
        'reporterName': reporterName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'statusHistory': [firstEntry.toMap()],
      });
    if (photo != null) {
      batch.set(_photos.doc(doc.id), {
        'reporterId': reporter.uid,
        'data': Blob(photo),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    return doc.id;
  }

  /// The JPEG bytes of a report's photo, or null if it has none.
  Future<Uint8List?> fetchPhoto(String incidentId) async {
    final snapshot = await _photos.doc(incidentId).get();
    final blob = snapshot.data()?['data'];
    return blob is Blob ? blob.bytes : null;
  }

  /// Staff: changes the status and appends an entry to the status history,
  /// so the student can see who changed it, when, and why.
  Future<void> updateStatus({
    required String incidentId,
    required IncidentStatus status,
    required AppUser changedBy,
    String? note,
  }) {
    final trimmed = note?.trim();
    final entry = StatusChange(
      status: status,
      changedById: changedBy.uid,
      changedByName: changedBy.name,
      note: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
      at: DateTime.now(),
    );
    return _incidents.doc(incidentId).update({
      'status': status.name,
      'updatedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([entry.toMap()]),
    });
  }

  /// Student: withdraws (deletes) their own report, and its photo, while it
  /// is still "submitted".
  Future<void> deleteIncident(Incident incident) {
    final batch = _firestore.batch()..delete(_incidents.doc(incident.id));
    if (incident.hasPhoto) batch.delete(_photos.doc(incident.id));
    return batch.commit();
  }
}
