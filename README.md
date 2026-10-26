
# Plot

Plot is an offline time-tracking app built with Flutter for CSC 4360 Mobile App Development at Georgia State University.

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

## Smart Helper
The Smart Helper looks at the last three completed activities in the selected category.

It uses the median duration to suggest how long the next activity should be, keeping suggestions between 10 and 60 minutes.

If there aren't enough completed activities, it suggests 10 minutes.

Users can choose whether to apply the suggestion or enter their own duration.

## Running the App
1. Install Flutter and Android Studio.
2. Clone the GitHub repository.
3. Open the project folder in VS Code.
4. Start an Android emulator.
5. Run these commands:

```bash
flutter pub get
flutter run
```

## Testing
Run the widget tests using:

```bash
flutter test
```

## Project Status
The app is still in development. Additional features, testing, and documentation are being completed.

