import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum IncidentCategory {
  facilities('Facilities', Icons.apartment_outlined),
  water('Water', Icons.water_drop_outlined),
  electricity('Electricity', Icons.bolt_outlined),
  furniture('Furniture', Icons.chair_outlined),
  sanitation('Sanitation', Icons.delete_outline),
  safety('Safety', Icons.shield_outlined),
  other('Other', Icons.more_horiz);

  const IncidentCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  static IncidentCategory fromString(String? value) => IncidentCategory.values
      .firstWhere((c) => c.name == value, orElse: () => IncidentCategory.other);
}

enum IncidentStatus {
  submitted('Submitted'),
  inProgress('In Progress'),
  resolved('Resolved'),
  rejected('Rejected');

  const IncidentStatus(this.label);

  final String label;

  bool get isOpen => this == submitted || this == inProgress;

  static IncidentStatus fromString(String? value) => IncidentStatus.values
      .firstWhere((s) => s.name == value, orElse: () => IncidentStatus.submitted);
}

/// One entry in an incident's status timeline.
class StatusChange {
  final IncidentStatus status;
  final String changedById;
  final String changedByName;
  final String? note;
  final DateTime at;

  const StatusChange({
    required this.status,
    required this.changedById,
    required this.changedByName,
    required this.at,
    this.note,
  });

  factory StatusChange.fromMap(Map<String, dynamic> map) {
    return StatusChange(
      status: IncidentStatus.fromString(map['status'] as String?),
      changedById: map['changedById'] as String? ?? '',
      changedByName: map['changedByName'] as String? ?? '',
      note: map['note'] as String?,
      at: (map['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Uses a client Timestamp: Firestore does not allow serverTimestamp() inside arrays.
  Map<String, dynamic> toMap() => {
        'status': status.name,
        'changedById': changedById,
        'changedByName': changedByName,
        'note': note,
        'at': Timestamp.fromDate(at),
      };
}

/// An incident report stored at incidents/{id}.
class Incident {
  final String id;
  final String title;
  final String description;
  final IncidentCategory category;
  final String location;
  final String? locationDetail;
  final IncidentStatus status;
  /// The photo itself is stored separately in incident_photos/{id}, so lists
  /// of reports stay small and fast to load.
  final bool hasPhoto;
  final String reporterId;

  /// When true, [reporterName] is "Anonymous student" and staff never see who
  /// reported it.
  final bool isAnonymous;
  final String reporterName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<StatusChange> statusHistory;

  const Incident({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.status,
    required this.reporterId,
    required this.reporterName,
    required this.createdAt,
    required this.updatedAt,
    this.locationDetail,
    this.hasPhoto = false,
    this.isAnonymous = false,
    this.statusHistory = const [],
  });

  /// "Learning Commons — Room 204", or just "Learning Commons" when no detail was given.
  String get fullLocation =>
      (locationDetail == null || locationDetail!.isEmpty) ? location : '$location — $locationDetail';

  factory Incident.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) =>
      Incident.fromMap(doc.id, doc.data() ?? {});

  factory Incident.fromMap(String id, Map<String, dynamic> data) {
    // createdAt/updatedAt are null for a moment after a local write, until the
    // server timestamp arrives.
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    return Incident(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      category: IncidentCategory.fromString(data['category'] as String?),
      location: data['location'] as String? ?? '',
      locationDetail: data['locationDetail'] as String?,
      status: IncidentStatus.fromString(data['status'] as String?),
      hasPhoto: data['hasPhoto'] as bool? ?? false,
      isAnonymous: data['isAnonymous'] as bool? ?? false,
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String? ?? '',
      createdAt: createdAt,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? createdAt,
      statusHistory: (data['statusHistory'] as List<dynamic>? ?? [])
          .map((e) => StatusChange.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
