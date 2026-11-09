import 'constants.dart';

/// Form validators. Each returns an error message, or null when the value is valid.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static bool isAluEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return AppConstants.allowedEmailDomains
        .any((domain) => normalized.endsWith('@$domain'));
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your name';
    if (value.trim().length < 2) return 'Name is too short';
    if (value.trim().length > AppConstants.nameMaxLength) {
      return 'Name must be at most ${AppConstants.nameMaxLength} characters';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter your email';
    if (!_emailPattern.hasMatch(value.trim())) return 'Enter a valid email address';
    if (!isAluEmail(value)) return 'Use your ALU email (e.g. name@alustudent.com)';
    return null;
  }

  /// Used on login: we only check that something was typed.
  static String? requiredPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your password';
    return null;
  }

  /// Used on registration: enforces a stronger password.
  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!value.contains(RegExp(r'[0-9]'))) return 'Password must contain a number';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? incidentTitle(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please give the issue a short title';
    if (text.length < AppConstants.titleMinLength) {
      return 'Title must be at least ${AppConstants.titleMinLength} characters';
    }
    if (text.length > AppConstants.titleMaxLength) {
      return 'Title must be at most ${AppConstants.titleMaxLength} characters';
    }
    return null;
  }

  static String? incidentDescription(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please describe the issue';
    if (text.length < AppConstants.descriptionMinLength) {
      return 'Add a bit more detail (at least ${AppConstants.descriptionMinLength} characters)';
    }
    if (text.length > AppConstants.descriptionMaxLength) {
      return 'Description must be at most ${AppConstants.descriptionMaxLength} characters';
    }
    return null;
  }

  /// Staff note on a status change. Required when rejecting, so the student
  /// is told why.
  static String? statusNote(String? value, {required bool required}) {
    final text = value?.trim() ?? '';
    if (required && text.isEmpty) return 'Please give a reason for rejecting';
    if (text.length > AppConstants.statusNoteMaxLength) {
      return 'Note must be at most ${AppConstants.statusNoteMaxLength} characters';
    }
    return null;
  }

  static String? requiredSelection(Object? value, String message) =>
      value == null ? message : null;
}
