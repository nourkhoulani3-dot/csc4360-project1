# Plot device checks — fill in actual results

Device 1 / Android version / date: ____________________
Device 2 / Android version / date: ____________________
Tester(s): ____________________

Run all rows on both devices. Record Pass, Fail, or Not tested; do not prefill Pass.

| Check | Expected behavior | Device 1 | Device 2 |
| --- | --- | --- | --- |
| Existing data after update | Old activities/categories/reflections remain | | |
| Category CRUD | Add, read, rename, recolor, delete; activity remains Uncategorized | | |
| Activity CRUD | Add, read, edit title/notes/category/times, confirm deletion | | |
| Validation | Empty name, end before start, future finish and overlapping times show errors | | |
| Helper five types | AI_FEATURE.md expected values and explanation | | |
| Helper user control | Apply, dismiss, override to 10, open timer, per-category disable persists | | |
| Default duration | Set 40, open new timed activity: 40 is selected | | |
| Timer | Start, progress, pause excludes waiting time, resume, finish persists | | |
| One running timer | A second start is rejected until first pauses/finishes | | |
| Reset | Confirmation clears unfinished elapsed time without deleting completed history | | |
| Restart while running | Close app, reopen: elapsed time includes closed interval | | |
| Restart while paused | Close/reopen: elapsed time does not grow | | |
| Manual past entry | A valid unlogged gap can be filled and appears in timeline | | |
| Overnight sleep | Past manual Sleep 23:30–01:00 shows 30min then 60min; one record | | |
| Filter and aggregate | Compare two known 10min/20min records: selected-category total 30min | | |
| Reflection | Long text saves, optional emoji, edit, delete, discard confirmation | | |
| History mood | Past date shows selected emoji and opens correct day | | |
| Offline / restart | Airplane mode: CRUD/settings/reflections remain available after restart | | |
| Accessibility | Larger system text, dark/light themes, clear labels, usable touch targets | | |
| Navigation | Today / History / Settings and Android Back work; no layout overflow | | |
| Empty state | No entries/categories/matching filter gives clear feedback | | |

Save screenshots of the important outcomes and record failures/fixes honestly. Database-error feedback is implemented but a real write-failure scenario has not been induced here. Device restart and plugin behavior need the actual Android checks; pure logic tests do not replace them.
