# Plot local duration helper

## Purpose and method
This is a local rule-based helper, not a trained model. It offers a starting session length for a category. It does not measure attention, diagnose phone addiction, or predict a user's mood. It uses no remote service.

## Inputs and units
The selected category ID and the three most recent completed activities in that category with a positive whole-minute duration, ordered by finish time. Recorded seconds are stored separately; completed whole minutes are rounded down. Zero-minute sessions are excluded. Manual completed activities count too. Running, paused and planned activities do not qualify.

## Rules and explanation
If fewer than three qualifying activities exist, suggest 10 minutes and explain that history is limited. Otherwise sort the three durations, select the middle value (median), and limit the result to 10–60 minutes. Show the durations and the explanation before the user applies anything.

Example: 15, 20, 45 minutes gives 20 minutes.

## Baseline and alternative
The baseline always suggests 25 minutes. A possible alternative is the arithmetic average. Median was selected because a single unusually long session changes the average more strongly. These choices do not demonstrate better focus or better wellbeing.

## User control
The user explicitly requests the suggestion and can apply it, dismiss it, choose another duration, or select an open timer. Suggestions can be disabled for a category; the preference is saved locally. Suggested minutes are a goal, not a forced stopping point. Tracking continues until Finish.

## Five evaluation case types
| Type | Input minutes | Expected helper | Baseline | What to check |
| --- | --- | --- | --- | --- |
| No history | none | 10 | 25 | Limited-history explanation |
| Limited history | 45; or 15,45 | 10 | 25 | Fewer than three does not use median |
| Normal history | 15,20,45 | 20 | 25 | Median and explanation |
| Extreme history | 1,2,3; or 90,120,180 | 10; or 60 | 25 | Both limits |
| Counterexample / override | 40,45,50, but only 10 minutes available today | 45, then user chooses 10 | 25 | History cannot know today's available time; override stays saved |

## Validation status
The pure Dart rule checks for the listed inputs passed on October 28, 2026. The baseline is the constant 25. These checks establish rule behavior, not recommendation quality. The counterexample produces an unsuitable 45-minute recommendation as expected.

Flutter test files are included, but the full Flutter suite and device override interaction have NOT been run in this environment. Run `flutter test` and record the actual device results below. Do not label pending checks as passed.

| Device / date | Explanation visible | Apply / dismiss | Override to 10 saves | Disable persists | Result / fixes |
| --- | --- | --- | --- | --- | --- |
| Pending | | | | | |
| Pending | | | | | |

## Ownership and assistance
Planned helper owner: Bryce Leidgertwood. This update includes AI-assisted implementation and test changes. Both members must review and understand their actual contributions and disclose assistance under the course rules; authorship and test evidence should reflect what each person actually did.

## Limits
Three past sessions can be unrepresentative. A completed manual entry may describe sleep or work rather than focused study. Category choice remains the user's responsibility. There is no trained model, learning process, confidence score, or evidence that these suggestions improve productivity. The evaluation described here is the undergraduate plan; any graduate held-out comparison cases still need to be added if applicable.
