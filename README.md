# Campus Reports: Campus Incident Reporting App

A Flutter mobile app for African Leadership University (ALU) students to report campus problems, such as broken facilities, water shortages, power outages, damaged furniture, sanitation and safety issues, and follow them until they are fixed. Authorised staff review the reports and update their status, and students see each change live.

Built for Mobile Application Development, Individual Assignment 2.

## Features

**Students**
- Register and sign in with an **ALU email only** (`@alustudent.com` / `@alueducation.com`), with **email verification**.
- Report an incident with a category, title, description, campus location, optional room, and an **optional photo** from the camera or gallery.
- Home dashboard with live report counts and recent reports.
- **My Reports** with search, status filter chips, a category filter and sorting.
- Report details with a **status timeline** and staff updates, which change **live** without refreshing.
- Withdraw a report while it is still *Submitted*.

**Staff**
- Dashboard with counts for every status and an *Awaiting Review* queue (oldest first).
- All reports, searchable by title, place, category or student.
- **Update status** with a note for the student. A reason is required to reject, with one-tap reasons including *Spam or misuse*.

**Privacy and misuse protection**
- **Anonymous reporting**: staff see "Anonymous student", and the name is not stored in the report.
- Photos are shrunk, and their **GPS location and camera metadata are removed** before upload.
- At most 5 reports per student in 24 hours, and a warning before submitting a likely duplicate.
- Role-based access enforced by **Firestore Security Rules**, not only by the app.
- Works offline: reports are saved on the phone and sent when the connection returns.

## Technology

| | |
|---|---|
| UI | Flutter (Material 3) |
| State management | Provider (`ChangeNotifier`, `ChangeNotifierProxyProvider`) |
| Authentication | Firebase Authentication (email and password, email verification) |
| Database | Cloud Firestore (live `snapshots()` streams, offline cache) |
| Photos | `image_picker` and the `image` package; stored as compressed JPEG bytes in Firestore |
| Tests | `flutter_test` and `fake_cloud_firestore`: 103 tests, 77% line coverage |

## Project structure

```
lib/
├── main.dart                 Firebase setup and providers
├── models/                   AppUser, Incident, StatusChange (+ Firestore mapping)
├── services/                 All Firebase access: AuthService, UserService, IncidentService
├── providers/                AuthProvider (session, role), IncidentProvider (live reports, filters, actions)
├── screens/
│   ├── auth/                 AuthGate (routing by sign-in state and role), login, register, verify email
│   ├── student/              Student shell, Home, My Reports, Report form
│   ├── staff/                Staff shell, Dashboard, All Reports
│   └── shared/               Report details, reports list, profile
├── widgets/                  Reusable UI: ReportCard, StatusChip, StatusTimeline, PhotoPickerField, …
├── theme/                    App theme and status colours
└── utils/                    Constants, validators, formatters, photo processing
firestore.rules               Security rules (role-based access control)
docs/TESTING.md               Test strategy, coverage, manual and security test plans
```

Screens never call Firebase directly. They read providers, providers call services, and services are the only code that talks to Firebase.

## Firestore data model

| Collection | Document | Contents |
|---|---|---|
| `users` | `{uid}` | `name`, `email`, `role` (`student` / `staff`), `createdAt` |
| `incidents` | `{incidentId}` | `title`, `description`, `category`, `location`, `locationDetail`, `status`, `hasPhoto`, `isAnonymous`, `reporterId`, `reporterName`, `createdAt`, `updatedAt`, `statusHistory[]` |
| `incident_photos` | `{incidentId}` | `data` (JPEG bytes, ≤ 700 KB), `reporterId`, `createdAt` |

`statusHistory` is a list of `{status, changedById, changedByName, note, at}`, so every change records who made it, when, and why.

## Setup

1. Install Flutter and the Firebase CLI, then run `dart pub global activate flutterfire_cli`.
2. Create a Firebase project. Enable **Authentication → Email/Password** and create a **Firestore** database.
3. Connect the app and publish the rules:
   ```bash
   flutterfire configure --project=<your-project-id> --platforms=android,ios,web
   firebase deploy --only firestore:rules
   ```
4. Run it on a device: `flutter run`.
5. **Make a staff account:** register in the app, then in the Firebase Console change that user's `role` in `users/{uid}` from `student` to `staff`. The app never lets users change their own role.

## Tests

```bash
flutter analyze
flutter test
```

See [docs/TESTING.md](docs/TESTING.md) for the test list, coverage, the manual test plan on a physical phone, and the security rule checks.
