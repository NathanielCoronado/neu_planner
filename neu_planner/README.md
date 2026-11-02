# NEU Class Planner
Class Schedule and Assignment Planner — APP DEV Final Project
Nathaniel S. Coronado and Zirk Eins B. Layupan, 3 BSIT-1, New Era University

Students miss deadlines because their tasks are scattered across group chats.
NEU Class Planner keeps every subject, class schedule, and assignment in one
offline app with due dates, priorities, overdue alerts, and a weekly view.

## Run it
1. Install Flutter (3.38 or newer) and Android Studio with an emulator or a phone in USB-debugging mode.
2. In this folder: `flutter pub get`
3. Run: `flutter run`
4. Tests: `flutter test` (18 automated test cases, all passing)
5. APK: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`

## Screens (5 + 2 forms)
| Screen | File | Purpose |
|---|---|---|
| Today | `screens/today_screen.dart` | Date header, overdue alert, today's class timeline, due today, next 7 days |
| Tasks | `screens/task_list_screen.dart` | Search, filter by status and subject, sort, swipe to delete with undo |
| Add / edit task | `screens/task_form_screen.dart` | Data entry with validation |
| Subjects | `screens/subjects_screen.dart` | All classes with schedule and pending count |
| Subject details | `screens/subject_detail_screen.dart` | Schedule, progress bar, to-do / done tasks |
| Add / edit subject | `screens/subject_form_screen.dart` | Name, code, room, days, time, color, conflict check |
| Week | `screens/week_screen.dart` | Weekly calendar with summary stats (due, done, overdue, % complete) |

## Features
1. Add, edit, delete subjects with class days and times
2. Add, edit, delete assignments with due date and time
3. Priority levels (low, medium, high) and sort by priority
4. Mark tasks done / not done
5. Filter by subject and status (to do, overdue, done, all) plus search
6. Overdue alerts (Today banner + red badge on the Tasks tab + red task rows)
7. Weekly view with completion summary
8. Schedule conflict detection between subjects

## Architecture
```
lib/
  main.dart              starts Hive, then the app
  models/                Subject and Task + hand-written Hive adapters
  data/store.dart        every database read/write, filters and queries
  utils/validators.dart  all input rules (unit-tested)
  utils/format.dart      date/time wording
  theme/app_theme.dart   NEU blue and gold theme
  screens/               UI screens
  widgets/task_tile.dart reusable task row
test/                    unit, database, and widget tests
```
Data flow: Screen → `Store` → Hive box (saved on the phone). Every screen listens
to `Store.changes`, so the UI refreshes by itself after any save.

Storage: Hive (local NoSQL). Two boxes: `subjects` and `tasks`. Each task stores
the key of its subject. Deleting a subject also deletes its tasks.

## Validation rules
| Field | Rule | Message |
|---|---|---|
| Task title | Required, 3–80 characters | "Enter a task title." |
| Subject (on task) | Required | "Choose a subject." |
| Due date | Required, not in the past, within 1 year | "Due date and time can't be in the past." |
| Notes | Max 300 characters | "Notes must be 300 characters or fewer." |
| Subject name | Required, unique, max 60 | "You already have a subject named …" |
| Code | Max 12, letters/numbers/spaces/hyphens | "Use letters, numbers, spaces, or hyphens only." |
| Class days | At least one | "Pick at least one class day." |
| Class time | End after start, at least 30 min | "End time must be after start time." |
| Schedule | No overlap with another subject | "Overlaps with Networking (Mon, Wed, 10:00 AM – 11:30 AM)." |

Note: when editing an old task, an unchanged past due date is allowed so overdue
tasks can still be edited or marked done.

## Automated tests (`flutter test`)
| ID | Test | Expected | Result |
|---|---|---|---|
| TC-01 | Empty / spaces-only title | Rejected | Pass |
| TC-02 | Title under 3 or over 80 chars | Rejected | Pass |
| TC-03 | Valid title | Accepted | Pass |
| TC-04 | No due date | Rejected | Pass |
| TC-05 | Past due date | Rejected | Pass |
| TC-06 | Future due date | Accepted | Pass |
| TC-07 | Due date over a year ahead | Rejected | Pass |
| TC-08 | Editing with unchanged past date | Accepted | Pass |
| TC-09 | Empty or duplicate subject name | Rejected | Pass |
| TC-10 | Invalid subject code characters | Rejected | Pass |
| TC-11 | No class days | Rejected | Pass |
| TC-12 | End before start / under 30 min | Rejected | Pass |
| TC-13 | Overlapping schedules (back-to-back allowed) | Detected | Pass |
| TC-14 | Task saved and reloaded from Hive | Same data | Pass |
| TC-15 | Mark done + status filters | Correct lists | Pass |
| TC-16 | Search and priority sort | Correct order | Pass |
| TC-17 | Delete subject deletes its tasks | Both empty | Pass |
| TC-18 | All screens open, overdue alert opens Overdue filter, empty form shows 3 errors | Works | Pass |

Add manual test cases on a real phone too (rotate screen, close and reopen app to confirm data persists, etc.).

## Packages used (disclose these)
- `hive`, `hive_flutter` — local database
- `intl` — date and time formatting
- `cupertino_icons` — default Flutter icons

## Disclosure
Per the project rules (Section E), this code was generated with the help of an AI
assistant (Claude by Anthropic) and reviewed, tested, and modified by the group.
Update this section to describe what you changed yourselves.
