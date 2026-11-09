import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';
import '../utils/constants.dart';

/// Reads and writes user profiles in Firestore (users/{uid}).
class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(AppConstants.usersCollection);

  /// Live profile updates, so a role changed in the Console applies immediately.
  /// Emits null while the profile document does not exist yet.
  Stream<AppUser?> watchUser(String uid) {
    return _users
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  /// Every new account starts as a student. Staff are promoted manually.
  Future<void> createStudentProfile({
    required String uid,
    required String name,
    required String email,
  }) {
    return _users.doc(uid).set({
      'name': name,
      'email': email.toLowerCase(),
      'role': UserRole.student.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
