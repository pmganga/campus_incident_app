# Test Results: Campus Reports

**Date:** 7 November 2026
**Where:** Google Chrome with device emulation (the DevTools phone view): a 393 × 873 screen, touch input and an Android 15 phone user agent, against the real Firebase project.
**Accounts:**
- Student: `qa.student.test@alustudent.com`
- Staff: `qa.staff.test@alueducation.com`

Both test accounts and their reports were deleted after testing.
**Evidence:** every row links to a screenshot in [`screenshots/`](screenshots/).

Key: ✅ pass · 🔧 failed at first, fixed and re-tested · ⏳ not tested yet

---

## 1. Summary

| | Count |
|---|---|
| Checks passed | 29 |
| Bugs found and fixed (re-tested after the fix) | 5 |
| Improvements made after testing | 2 |
| Not tested yet: the staff role (section 4) | 9 |
| Automated tests after the fixes | **103, all passing**; `flutter analyze`: no issues |

---

## 2. Accounts and sign-in

| ✓ | ID | Test | Result | Evidence |
|---|---|---|---|---|
| ✅ | A0 | Login screen layout at phone size | Clear and centred, with nothing cut off | [01](screenshots/01_login.png) |
| ✅ | A0b | Sign in with empty fields | "Please enter your email / password" | [02](screenshots/02_login_empty.png) |
| ✅ | A1 | Sign in with a Gmail address | "Use your ALU email (e.g. name@alustudent.com)" | [03](screenshots/03_login_gmail.png) |
| ✅ | A1b | Register with Gmail, password `abc`, passwords that don't match | All three errors shown; no account created | [49](screenshots/49_a1_a2_register_errors.png) |
| ✅ | A6 | Wrong password | "Incorrect email or password." | [04](screenshots/04_wrong_password.png) |
| ✅ | – | Correct student sign-in | Opens the student Home screen | [06](screenshots/06_after_login.png) |
| 🔧 | – | An error clears once the field is fixed | **Was:** the red error stayed until Submit was pressed again. **Now:** it clears as soon as the field is valid | [37](screenshots/37_login_error_clears.png) |
| ✅ | D8 | Sign out | A confirmation dialog, then back to login. The Sign out button is now red | [52](screenshots/52_red_signout.png) |
| ⏳ | A3–A5, A7 | Verification and password-reset emails | Needs a real inbox; test on the phone | – |
| ⏳ | A8 | Set `role` to `staff` while the app is open | Waiting for the role change in the Firebase Console | – |

## 3. Student: reporting and tracking

| ✓ | ID | Test | Result | Evidence |
|---|---|---|---|---|
| ✅ | B1 | Submit an empty form | Errors for category, title, description and location, plus a "Please fix the highlighted fields" message | [10](screenshots/10_form_errors_top.png) |
| ✅ | B4 | Pick a photo from the gallery (4000×3000, **2.5 MB**) | "Photo ready · **287 KB** · location data removed" | [12](screenshots/12_photo_ready.png) |
| ✅ | B5 | Submit a complete report | "Report submitted…"; it appears on Home straight away and the counts update | [20](screenshots/20_home_reloaded.png) |
| 🔧 | B5b | The new report's photo thumbnail | **Was:** the category icon showed until the screen was rebuilt, because the photo wasn't on the server yet and the first read was refused. **Now:** the app retries, and the photo shows within about a second | [16 before](screenshots/16_home_thumb_later.png) · [43 after](screenshots/43_thumb_1s.png) |
| ✅ | B7 | A second report with the same category and place | "Already reported?" with View existing / Submit anyway | [18](screenshots/18_duplicate_dialog.png) |
| ✅ | B8 | Report anonymously | The footnote changes to "Your name will be hidden from staff"; Details says "Reported anonymously"; the history shows "Anonymous student" | [17](screenshots/17_anon_on.png) · [31](screenshots/31_anon_details_student.png) |
| ✅ | B11 | A 6th report within 24 hours | A red banner explains the limit, and Submit is disabled | [45](screenshots/45_b11_limit_top.png) · [46](screenshots/46_b11_limit_bottom.png) |
| 🔧 | C1 | Home: tap the **Submitted** tile | Works with a finger. **Was:** it couldn't be opened with a screen reader (TalkBack). **Now:** it opens My Reports filtered to Submitted | [38](screenshots/38_c1_tile_opens_filter.png) |
| ✅ | C2 | Search "leaking" | The list narrows to the matching report; ✕ clears the search | [23](screenshots/23_c2_search.png) |
| ✅ | C3 | Category filter → Electricity | A removable "Electricity" chip; a red dot on the filter icon | [26](screenshots/26_c3_electricity.png) |
| ✅ | C4 | Search for nonsense | "No matching reports" with **Clear filters** | [24](screenshots/24_c4_nomatch.png) |
| 🔧 | C5 | Sort → Oldest first | The order reverses. **Was:** the sort icon looked the same as the filter icon. **Now:** sort is ↕, with a dot when a non-default sort is on | [27](screenshots/27_c5_oldest.png) |
| ✅ | – | Report details | Summary, status timeline, description, photo, updates history, Withdraw button | [28](screenshots/28_details_top.png) · [29](screenshots/29_details_bottom.png) |
| ✅ | C6 | Tap the photo | Opens full screen on black, with a back button | [30](screenshots/30_c6_photo_full.png) |
| ✅ | C7 | Withdraw a Submitted report | A confirmation dialog, then "Report withdrawn"; the counts drop from 5 to 4 everywhere | [47](screenshots/47_c7_withdraw_confirm.png) · [48](screenshots/48_c7_after_withdraw.png) |
| ✅ | – | Profile | Name, email, role and counts are correct | [32](screenshots/32_profile_student.png) |
| ✅ | – | **Privacy:** another account can't see the student's reports | The second account sees 0 reports | [35](screenshots/35_staff_first_login.png) |
| 🔧 | – | Empty Home screen: the "Report an issue" button | **Was:** hidden behind the round **+** button. **Now:** the page scrolls far enough to show it | [36](screenshots/36_staffacct_home_scrolled.png) |
| ⏳ | B3 | **Take photo** with the camera | The browser has no camera; test on the phone | – |
| ⏳ | B9–B10 | Offline submit, then reconnect | Test on the phone with airplane mode | – |

## 4. Staff workflow ⏳

These tests were not run in the browser: the staff account's role had not been changed in the Console before the test accounts were deleted. Run them on the phone with a real staff account (rows D1–D8 in [TESTING.md](TESTING.md)).

| ✓ | ID | Test | Expected |
|---|---|---|---|
| ⏳ | A8 | Role changed while the app is open | Switches to the Staff Dashboard without restarting |
| ⏳ | D1 | Dashboard | Counts for all 4 statuses; Awaiting Review, oldest first |
| ⏳ | D2 | All Reports → search "Qa Student" | The student's named reports are shown; the anonymous one isn't |
| ⏳ | D3 | Update Status → In Progress, with a note | "Status changed to In Progress" |
| ⏳ | D4 | The student sees the change | Chip, timeline and note update without refreshing |
| ⏳ | D5 | Rejected with no reason | "Please give a reason for rejecting" |
| ⏳ | D6 | Rejected using "Spam or misuse…" | Saved; the student sees the reason |
| ⏳ | D7 | Open the anonymous report | "Anonymous student"; no name anywhere |
| ⏳ | – | Resolved | Moves to Resolved; the student's timeline completes |

---

## 5. What works well

- **Validation is thorough** on every form, with clear, specific messages.
- **The photo feature does what it promises.** A 2.5 MB photo was cut to 287 KB, location data was removed, and the screen says so.
- **Misuse protection is visible:** duplicate warning, daily limit, anonymous option.
- **Live updates.** Submitting or withdrawing updates Home, My Reports and Profile at once, with no refresh.
- **Privacy.** Students can't see each other's reports.
- **The layout fits a phone screen.** No overflow or cut-off text was seen. Long titles end with "…" and the filter chips scroll sideways.

## 6. Bugs fixed during testing

| # | Problem | Fix | Automated test added |
|---|---|---|---|
| 1 | A new report's photo thumbnail didn't appear | The photo download retries up to 4 times (waiting 1 s, 2 s, then 4 s) | ✅ 2 tests |
| 2 | Summary tiles couldn't be opened with a screen reader | The tile now exposes its tap action to accessibility | ✅ 1 test |
| 3 | Fixed fields stayed red | Forms re-check each field as you type, after the first failed submit | ✅ 1 test |
| 4 | A button was hidden behind the **+** button | Extra bottom padding on Home and the report lists | – (visual) |
| 5 | The sort and filter icons looked alike | The sort icon is now ↕, with a dot when active | – (visual) |

## 7. Improvements made after testing

| Improvement | Status |
|---|---|
| The daily-limit banner says *when* the student can report again ("…submit again from Nov 8, 4:02 PM") | ✅ Done (2 tests) |
| The **Withdraw** and **Sign out** confirmation buttons are red, because they can't be undone | ✅ Done |

## 8. Still to improve (not blocking)

| Idea | Why |
|---|---|
| Custom app icon | The default Flutter icon still shows on the phone |
| Lock the form when the daily limit is reached | A student can still fill in the form before finding Submit disabled |
| Show more of long report titles on cards (2 lines) | Titles such as "Leaking tap in washr…" get cut off by the status chip |
| Light/dark theme | Only the light theme exists |

## 9. Limits of browser testing

The camera, the offline queue, verification and reset emails, and phone performance can't be checked in Chrome. Test them on the phone; they are rows A3–A5, A7, B3 and B9–B10 in [TESTING.md](TESTING.md).
