# Testing: Campus Incident Reporting App

The app is tested in three ways:

1. **Automated tests** (103 tests) that run on the computer with `flutter test`. They use fake Firebase services, so they are fast and need no internet.
2. **Manual tests** on a physical Android phone (model 23106RN0DA, Android 15) against the real Firebase project.
3. **Security rule checks** in the Firebase Rules Playground. These show that Firebase itself refuses forbidden actions, not just the app.

---

## 1. Automated tests

### How to run them
```powershell
cd campus_incident_app
flutter analyze             # static analysis: expect "No issues found!"
flutter test                # all tests: expect "All tests passed!"
flutter test --coverage     # also writes coverage/lcov.info
```

### What is tested

| Test file | Type | Tests | What it checks |
|---|---|---|---|
| `validators_test.dart` | Unit | 7 | ALU-only emails (including look-alikes such as `alustudent.com.evil.com`), password rules, roles |
| `incident_model_test.dart` | Unit | 9 | Reading reports from Firestore data, safe defaults for unknown values, status history round trip |
| `photo_processor_test.dart` | Unit | 4 | Photos shrunk under 700 KB, **GPS location removed**, rotation fixed, non-images refused |
| `auth_service_test.dart` | Unit | 3 | Firebase errors become friendly messages; non-ALU emails refused before Firebase is contacted |
| `auth_provider_test.dart` | Unit | 10 | Sign-in flow: non-ALU sign-out, email verification, first-time profile creation, live role change |
| `incident_provider_test.dart` | Unit | 16 | Live updates, counts, filters and search; what students and staff may and may not do |
| `photos_and_misuse_test.dart` | Unit | 13 | Photo caching and retry, 5-per-day limit, duplicate detection, anonymous reports, sorting |
| `firestore_services_test.dart` | Integration (in-memory Firestore) | 8 | The exact documents written: field list, photo document, no name in anonymous reports, history kept, photo deleted on withdraw |
| `widgets_test.dart` | Widget | 13 | `SummaryTile` screen-reader tap, `StatusChip` colours, `ReportCard`, `StatusTimeline`, `StatusHistoryList`, `EmptyState` |
| `report_incident_screen_test.dart` | Widget | 4 | Form validation (errors clear once fixed), photo buttons, anonymous switch |
| `register_screen_test.dart` | Widget | 2 | Registration validation and a successful registration |
| `update_status_sheet_test.dart` | Widget | 3 | Status choices, reason required to reject, saving a note |
| `incident_details_screen_test.dart` | Widget | 6 | Withdraw only while Submitted, Update Status only for staff, anonymity, deleted report |
| `auth_gate_test.dart` | Widget | 5 | Routing: login, verify email, student screens, staff screens, live promotion to staff |

### Line coverage (`flutter test --coverage`)

| Layer | Coverage |
|---|---|
| Models | 100% |
| Theme | 100% |
| Providers (state management) | 89% |
| Utils (validators, photo processor) | 88% |
| Widgets | 83% |
| Services (Firestore) | 80% |
| Screens | 66–70% |
| **Total** | **77%** |

Screens are lower because some paths only happen on a real device, such as the camera, snack bars after network writes and navigation animations. The manual tests below cover them.

---

## 2. Manual tests on the phone

**Setup:** two accounts. `S` is a student account. `T` is a staff account, an ALU account whose `role` was changed to `staff` in the Firebase Console. Run the app with `flutter run -d <device-id>`.

Fill in **Result** (Pass or Fail) and **Notes** while testing. A screenshot of key rows is useful evidence for the report.

### A. Accounts and sign-in

| ID | Who | Steps | Expected | Result | Notes |
|---|---|---|---|---|---|
| A1 | – | Register with a Gmail address | "Use your ALU email…" and no account created | | |
| A2 | – | Register with an ALU email, password `abc` | "Password must be at least 8 characters" | | |
| A3 | – | Register with a valid ALU email and password | Verify Email screen; email arrives (check Spam) | | |
| A4 | S | Try to continue without clicking the link | Stays on Verify Email | | |
| A5 | S | Click the link in the email, return to the app | Opens Home within about 5 seconds, no restart needed | | |
| A6 | S | Sign out, sign in with the wrong password | "Incorrect email or password." | | |
| A7 | S | Forgot password | Reset email arrives | | |
| A8 | T | In the Console, set `role` to `staff` while the app is open | App switches to the Staff Dashboard straight away | | |

### B. Reporting an incident (student)

| ID | Who | Steps | Expected | Result | Notes |
|---|---|---|---|---|---|
| B1 | S | Tap **+**, then Submit with an empty form | Errors for category, title, description and location | | |
| B2 | S | Fill the form, press back | "Discard this report?" dialog | | |
| B3 | S | **Take photo** | Permission prompt; preview shows "Photo ready · ___ KB · location data removed" | | |
| B4 | S | Remove the photo (✕), then choose from **Gallery** | Preview replaced | | |
| B5 | S | Submit a complete report with a photo | "Report submitted"; it appears on Home **immediately** with the thumbnail | | |
| B6 | S | In the Console, open `incident_photos` | A document with the same ID as the report | | |
| B7 | S | Submit another report, same category and place | "Already reported?" dialog with View existing / Submit anyway | | |
| B8 | S | Turn on **Report anonymously** and submit | Footnote changes; Details says "Reported anonymously" | | |
| B9 | S | Turn on airplane mode, submit a report | "saved on this phone and will be sent automatically" | | |
| B10 | S | Turn airplane mode off | The report reaches Firestore (check the Console) | | |
| B11 | S | Submit a 6th report within 24 hours | Banner explains the limit; Submit is disabled | | |

### C. Tracking reports (student)

| ID | Who | Steps | Expected | Result | Notes |
|---|---|---|---|---|---|
| C1 | S | Home → tap the **Submitted** tile | My Reports opens filtered to Submitted | | |
| C2 | S | Search for a word from a title | List narrows; ✕ clears it | | |
| C3 | S | Filter icon → choose a category | Removable chip shown; list filtered | | |
| C4 | S | Search for nonsense | "No matching reports" with **Clear filters** | | |
| C5 | S | Sort → Oldest first | Order reverses | | |
| C6 | S | Open a report, tap the photo | Full screen; pinch to zoom works | | |
| C7 | S | Withdraw a **Submitted** report | Confirmation, then it disappears everywhere | | |
| C8 | S | Open an **In Progress** report | No Withdraw button | | |

### D. Staff workflow and live updates

| ID | Who | Steps | Expected | Result | Notes |
|---|---|---|---|---|---|
| D1 | T | Open the Dashboard | Counts for all statuses; new reports under Awaiting Review, oldest first | | |
| D2 | T | All Reports → search for the student's name | Their reports shown (anonymous ones are not) | | |
| D3 | T | Open a report → Update Status → In Progress, add a note | "Status changed to In Progress" | | |
| D4 | S | With the same report open **on the student's phone** during D3 | Chip, timeline and Updates note change **without refreshing** | | |
| D5 | T | Choose Rejected with no reason | "Please give a reason for rejecting" | | |
| D6 | T | Choose Rejected, tap "Spam or misuse…" and save | Saved; the student sees the reason | | |
| D7 | T | Open an anonymous report | "Anonymous student" / "Reported anonymously"; no name anywhere | | |
| D8 | T | Profile → Sign out | Confirmation; back to login | | |

---

## 3. Security rule checks (Firebase Rules Playground)

These prove that the rules in `firestore.rules` are enforced **by Firebase**, even if someone bypasses the app.

**How:**
1. Go to Firebase Console → Firestore Database → **Rules** → **Rules Playground**.
2. Choose the simulation type, enter the document path and switch **Authenticated** on.
3. Set the **Firebase UID**, and set `email` and `email_verified: true` in the token.
4. Click **Run**.
5. Take a screenshot of each result for the report.

Use real IDs from the Data tab: `<S-uid>` is the student's user ID, `<T-uid>` is the staff user ID, and `<report-id>` is one of S's reports.

| ID | As | Simulate | Path | Data / change | Expected | Result |
|---|---|---|---|---|---|---|
| R1 | Not signed in | get | `/incidents/<report-id>` | – | **Denied** | |
| R2 | S | get | `/incidents/<report-id>` | – | Allowed | |
| R3 | Another student | get | `/incidents/<report-id>` | – | **Denied** | |
| R4 | S | update | `/incidents/<report-id>` | `status: "resolved"` | **Denied** (only staff change status) | |
| R5 | S | update | `/users/<S-uid>` | `role: "staff"` | **Denied** (cannot make yourself staff) | |
| R6 | T | update | `/incidents/<report-id>` | `title: "changed"` | **Denied** (content can't be edited) | |
| R7 | T | delete | `/incidents/<report-id>` | – | **Denied** (staff reject, never delete) | |
| R8 | S, `email_verified: false` | get | `/incidents/<report-id>` | – | **Denied** | |
| R9 | T | get | `/incident_photos/<report-id>` | – | Allowed | |
| R10 | Another student | get | `/incident_photos/<report-id>` | – | **Denied** | |

The staff status update (allowed) is shown by test D3 in the app. The Playground cannot easily simulate it, because the rule also checks the appended history entry.

---

## 4. Known limitations

- **The security rules are not covered by automated tests.** That needs the Firebase Emulator, which needs Java; it isn't installed on the development PC. They are checked manually (section 3) instead.
- **The 5-per-day limit is enforced by the app, not the rules.** A server-side limit needs Cloud Functions, which require the paid Blaze plan.
- **Anonymity applies inside the app.** Staff cannot read user profiles, so they cannot match the hidden reporter ID to a name. A Firebase project owner using the Console still can.
- **The camera, gallery and offline queue need a real device**, so they are tested manually (B3–B10).
