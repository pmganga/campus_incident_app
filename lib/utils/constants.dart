class AppConstants {
  AppConstants._();

  // Only these email domains may register or sign in.
  static const List<String> allowedEmailDomains = [
    'alustudent.com',
    'alueducation.com',
  ];

  // Firestore collection names
  static const String usersCollection = 'users';
  static const String incidentsCollection = 'incidents';
  static const String photosCollection = 'incident_photos';

  // Campus areas offered in the "Location" dropdown. Edit to match your campus.
  static const List<String> campusLocations = [
    'Enterprise Commons',
    'Social Commons',
    'Learning Commons',
    'Library',
    'Cafeteria',
    'Student Residence',
    'Sports Ground',
    'Parking Area',
    'Main Gate',
    'Other',
  ];

  // Must match the limit in firestore.rules.
  static const int nameMaxLength = 60;

  // Limits for report text fields (also enforced in firestore.rules)
  static const int titleMinLength = 5;
  static const int titleMaxLength = 80;
  static const int descriptionMinLength = 15;
  static const int descriptionMaxLength = 1000;
  static const int locationDetailMaxLength = 60;
  static const int statusNoteMaxLength = 300;

  // Photos are stored in Firestore (free Spark plan), so they must fit in a
  // 1 MiB document. Keep in sync with firestore.rules.
  static const int photoMaxDimension = 1280;
  static const int photoMaxBytes = 700 * 1024;

  // Misuse protection
  static const int dailyReportLimit = 5;

  // Shown instead of the student's name when they report anonymously.
  // Must match firestore.rules.
  static const String anonymousReporterName = 'Anonymous student';
}
