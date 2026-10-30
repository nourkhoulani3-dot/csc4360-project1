
# Plot Device Testing Checklist

## Device Information

**Device 1:** Google Pixel 7 Pro  
**Device 2:** Google Pixel 8  
**Android versions:** To be confirmed  
**Testers:** Bryce and Nour  
**Date:** October 30, 2026

## Checklist Preparation

- [x] Device names entered
- [x] All test cases documented
- [x] Expected behaviors documented
- [x] Smart Helper evaluation cases included
- [x] Offline and restart scenarios included
- [x] Accessibility and navigation checks included
- [x] Flutter static analysis completed successfully

## Device Test Results

| Check | Expected Behavior | Pixel 7 Pro | Pixel 8 |
| --- | --- | --- | --- |
| Existing data after update | Old activities, categories, and reflections remain | Not verified | Not verified |
| Category CRUD | Add, read, rename, recolor, delete; activities remain Uncategorized | Not verified | Not verified |
| Activity CRUD | Add, read, edit title, notes, category, times; confirm deletion | Not verified | Not verified |
| Validation | Invalid names, times, and overlapping entries display errors | Not verified | Not verified |
| Helper five types | Results match the five cases in AI_FEATURE.md | Not verified | Not verified |
| Helper user control | Apply, dismiss, override, open timer, disable preference persists | Not verified | Not verified |
| Default duration | Setting 40 minutes makes it the default | Not verified | Not verified |
| Timer | Start, pause, resume, finish, and persistence work | Not verified | Not verified |
| One running timer | A second running timer is prevented | Not verified | Not verified |
| Reset | Confirmation clears unfinished time without deleting history | Not verified | Not verified |
| Restart while running | Elapsed time includes the closed interval | Not verified | Not verified |
| Restart while paused | Paused time does not increase | Not verified | Not verified |
| Manual past entry | Valid past activity appears in timeline | Not verified | Not verified |
| Overnight sleep | 23:30–01:00 displays correctly across both dates | Not verified | Not verified |
| Filter and aggregate | Two activities of 10 and 20 minutes total 30 minutes | Not verified | Not verified |
| Reflection | Long text, emoji, editing, deleting, and discard confirmation work | Not verified | Not verified |
| History mood | Saved emoji appears on the correct date | Not verified | Not verified |
| Offline / restart | Data and settings remain available offline after restarting | Not verified | Not verified |
| Accessibility | Large text, themes, labels, and touch targets are usable | Not verified | Not verified |
| Navigation | Today, History, Settings, and Android Back work | Not verified | Not verified |
| Empty state | Empty activities, categories, and filters show feedback | Not verified | Not verified |

## Current Verification

- [x] Flutter project opened successfully
- [x] Latest main branch pulled from GitHub
- [x] Flutter dependencies installed
- [x] `flutter analyze` completed with no issues
- [x] Plot launched successfully on the Android emulator

## Final Notes

The device testing checklist is fully prepared for the Google Pixel 7 Pro and Google Pixel 8.

The full device tests still require verification on both devices. Results should be updated to Pass or Fail after execution, with screenshots and bug notes where appropriate.

Database write-failure simulation and complete restart testing remain unverified.
