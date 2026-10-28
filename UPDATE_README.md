# Plot update — October 28, 2026

## Install in the Git project
Close the running Flutter app with `q` in its terminal. Back up `C:\dev\plot\lib`, `test`, and `pubspec.yaml` before replacing files. Extract this ZIP directly into `C:\dev\plot`, allowing its lib/test folders to merge. Do not extract into the older Downloads copy. Do not delete or uninstall the existing app if you want to test the database migration.

The package contains source files, tests and these notes. It does not replace your Android project, repository history, or Git configuration. pubspec.yaml adds sqflite_common_ffi as a development-only dependency for database tests.

Run in PowerShell:

```powershell
cd C:\dev\plot
$env:Path = "C:\dev\flutter\bin;" + $env:Path
$env:PUB_CACHE = "C:\dev\pub-cache"
flutter pub get
flutter analyze
flutter test
flutter devices
```

Then run `flutter run -d emulator-5554` if that device ID still appears. Use the current Android device ID if it has changed. Stop at any error and share its full output.

## Included changes
- Today: date selection, category-colored chronological timeline, recorded-time total, unlogged gaps, and links to add manual records.
- Categories: create, list, edit name/color and delete. Deletion preserves activities under Uncategorized. The form uses the actual saved categories.
- Activities: add/edit/delete, timed/open sessions, manual past entries, invalid-time and overlap feedback. Editing completed start/end times intentionally replaces pauses with one continuous interval; metadata-only edits keep pauses.
- Timer: start/resume, pause, finish and reset before completion; timestamp recovery; only one running timer at a time. Paused activities may coexist. Pauses are saved as gaps. Reset clears that unfinished session's recorded time.
- History: category filter, totals, count of completed activities, dates and saved mood emoji. Open a day to review or edit it.
- Reflection: one editable/deletable note per date, optional mood emoji, expandable journal, optional gratitude prompts, and confirmation before leaving unsaved writing.
- Settings: saved light/dark mode, default duration, optional completion animation, and category management. Helper suggestions can be disabled per category from the activity form.
- Rule helper: same median/fallback rules, explanations, explicit apply/dismiss/override, baseline, tests and AI_FEATURE.md.

## Data and engineering notes
Database version 4 migrates the provided version-3 schema without intentionally deleting records. It adds serialized active intervals to Activities and makes the reflection mood nullable. Categories and Activities remain the two required related entities with full CRUD; reflections are an additional local table. The small metadata table prevents deleted default categories from being recreated on restart.

Intervals are stored only when pausing or finishing; a running segment is recovered from its saved resume timestamp. The app need not run in the background to calculate elapsed time when reopened. Crossing midnight splits the display into daily portions without duplicating the activity record. No automatic stop occurs at midnight or at the goal, including sleep.

Old records did not store exact pause positions. Their timeline uses an approximate continuous interval and cannot reconstruct old gaps. New sessions preserve exact intervals. Timers assume the device clock is reasonable; changing the clock or time zone during a session is not fully handled. No device-wide screen-time monitoring, lock-screen widget, reminders, recurring schedule or cloud service is included.

The timeline is a chronological list, not a proportional calendar grid. Filtered history opens the complete day when tapped. Historical entries from existing data may overlap; new manual intervals are checked against existing recorded intervals.

## Validation completed here
- All Dart files parsed successfully through Dart format.
- Twelve direct pure Dart assertions passed for helper results, midnight splitting, running-period recovery and overlap endpoints.
- SQLite checks passed for the fresh schema, category foreign-key deletion behavior, optional mood and version-3 migration statements preserving sample records.

Full Flutter analyze/test, Android compilation, visual accessibility checks, and actual two-device testing are still pending for this update. Automatic approval review blocked the Flutter setup after it attempted a cloud metadata endpoint; it was not bypassed. The included tests are runnable checks, not claimed passing results.

## Before submission
Run the checklist in DEVICE_TEST_CHECKLIST.md on both devices/emulators. Record actual results and screenshots. Review the diff and understand the code before committing. Use meaningful commits describing real work; do not invent commits or test evidence. Coordinate with Bryce before integrating these overlapping changes.

This ZIP is not the final class submission. The presentation, ClickUp evidence, authentic commit contributions, signatures, approval evidence, required final artifacts and individual upload still need to be checked against the instructor's submission instructions. Disclose AI help and update ownership to match actual work.
