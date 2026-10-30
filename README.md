
# Plot

Plot is an offline time-tracking application built with Flutter for CSC 4360 Mobile Application Development at Georgia State University.

The app helps users organize daily activities, track how they spend their time, and review their activity history.

## Team

- Bryce
- Nour

## Features

- Create activities with names, categories, notes, and planned durations
- Start, pause, resume, and finish activity timers
- Save activities locally using SQLite
- Edit saved activities
- View activity history and category totals
- Filter activity history by category
- Get suggested activity durations using the Smart Helper
- Use the app without an internet connection

## App Navigation

### Today
The Today screen provides an overview of the user's daily activities and recorded time.

Users can add activities, browse existing activities, and access their activity timers.

### History
The History screen allows users to review previously recorded activities and see time totals by category.

### Settings
The Settings tab provides access to the app's settings.

## Smart Helper

The Smart Helper examines the last three completed activities in the selected category.

It calculates the median duration and uses that value to suggest a duration for the next activity.

Suggestions are limited to a range of 10 to 60 minutes.

If fewer than three completed activities are available, the Smart Helper suggests 10 minutes.

Users can accept the suggested duration or manually enter their own.

The Smart Helper runs locally and does not require an internet connection.

## Technology

- Flutter
- Dart
- SQLite
- Android emulator for development and testing

## Running the App

1. Install Flutter and Android Studio.
2. Clone the GitHub repository.
3. Open the project folder in VS Code.
4. Start an Android emulator.
5. Run the following commands:

```bash
flutter pub get
flutter run
```

## Testing

Check the project for Dart and Flutter issues:

```bash
flutter analyze
```

Run automated widget tests:

```bash
flutter test
```

Additional testing instructions and checklists are available in:

- `TESTING.md`
- `DEVICE_TEST_CHECKLIST.md`

## Additional Documentation

- `AI_FEATURE.md` — Smart Helper implementation
- `TESTING.md` — Testing checklist
- `DEVICE_TEST_CHECKLIST.md` — Device testing
- `VISUAL_UPDATE.md` — UI design changes

## Project Status

The main application features and updated user interface have been implemented.

Final testing, bug fixes, and submission preparation are still in progress.
