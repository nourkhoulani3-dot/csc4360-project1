
# Plot Smart Helper

## Feature Overview
Plot includes a local Smart Helper that recommends a duration when creating an activity.

The goal is to help users plan their time based on their previous completed activities.

## Method
The Smart Helper uses a rule-based recommendation system. It does not use a trained AI model or an external API.

It looks at the three most recent completed activities in the selected category and uses the median duration.

The recommended duration is limited to a minimum of 10 minutes and a maximum of 60 minutes.

If fewer than three completed activities are available, the helper recommends 10 minutes.

## Inputs
- Selected activity category
- Durations of the last three completed activities in that category, measured in minutes
- Completed activity records stored in SQLite

Canceled activities and activities with zero recorded minutes are excluded.

## Why We Chose This Method
The median is less affected by unusually long or short sessions than the mean.

For example, with durations of 15, 20, and 60 minutes, the median is 20 minutes.

This provides a simple recommendation that can work completely offline.

## Baseline
Our baseline is a fixed 25-minute recommendation, regardless of category or activity history.

The Smart Helper is different because it adjusts its recommendation using the user's previous activity durations.

## User Control
The suggestion is optional.

Users can:
- Request a suggested duration
- Read an explanation of the suggestion
- Apply the suggested duration
- Ignore the suggestion and enter their own duration

The helper does not automatically save an activity.

## Evaluation Plan

| Case | Input durations (minutes) | Expected suggestion | Baseline | Status |
|---|---|---|---|---|
| Normal | 15, 20, 30 | 20 min | 25 min | Not yet verified |
| Insufficient history | 15, 20 | 10 min | 25 min | Not yet verified |
| Lower boundary | 2, 5, 8 | 10 min | 25 min | Not yet verified |
| Upper boundary | 65, 75, 90 | 60 min | 25 min | Not yet verified |
| Outlier | 15, 20, 60 | 20 min | 25 min | Not yet verified |

These are expected results based on the rule, not claims that all five tests have passed.

## Counterexample
A user might have a history of 45-minute sessions but only have 10 minutes available today.

The Smart Helper could suggest 45 minutes even though that is not appropriate for the user's current schedule.

The user can override the suggestion manually.

## Limitations
- The helper only uses the last three completed activities.
- It does not know the user's current availability or energy level.
- Categories with limited history receive the same 10-minute fallback.
- The recommendations are based on past behavior, not a trained prediction model.

## Offline Operation
The Smart Helper uses local SQLite activity records. It does not require internet access.

## Future Improvements
A future version could consider the user's available time, time of day, and a larger number of completed sessions.

## Testing Status
The helper's recommendation interface and median-based behavior have been tested during development.

The full five-case evaluation is still pending. Expected values above must be compared against actual results before marking evaluation complete.
