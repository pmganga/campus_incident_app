import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  staff;

  // Anything other than 'staff' is treated as a student, so a missing or
  // mistyped role never grants extra permissions.
  static UserRole fromString(String? value) =>
      value == 'staff' ? UserRole.staff : UserRole.student;

  String get label => this == UserRole.staff ? 'Staff' : 'Student';
}

/// The profile stored in Firestore at users/{uid}.
class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
