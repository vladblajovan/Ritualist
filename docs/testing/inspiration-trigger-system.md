# Inspiration Trigger System - Test Specification

## Overview

The inspiration trigger system shows motivational messages in a carousel on the Overview screen. It uses **category-based selection** to ensure relevant, non-redundant messages.

**Max cards: 3** (one from each category, or 1 for edge cases)

---

## Trigger Categories

### Category 1: Progress-Based (Mutually Exclusive)

Based on completion percentage. Only ONE can fire.

| Trigger | Condition | Priority |
|---------|-----------|----------|
| `perfectDay` | completionRate >= 100% | Highest |
| `strongFinish` | completionRate >= 75% | High |
| `halfwayPoint` | completionRate >= 50% | Medium |
| `firstHabitComplete` | completionRate > 0% AND completedCount == 1 | Low |

**Logic:** Check in priority order, return first match.

### Category 2: Time-of-Day (Mutually Exclusive)

Based on current time period and progress. Only ONE can fire.

| Trigger | Time | Condition |
|---------|------|-----------|
| `morningMotivation` | Morning | completionRate == 0% |
| `strugglingMidDay` | Noon | completionRate < 40% |
| `afternoonPush` | Noon (3-4:59 PM) | completionRate < 60% |
| `eveningReflection` | Evening | completionRate >= 60% |

**Logic:** Switch on `timeOfDay`, check conditions within each case.

**Note:** `afternoonPush` fires during "noon" period when hour is 15-16.

### Category 3: Special Context (Mutually Exclusive)

Based on situational context. Only ONE can fire.

| Trigger | Condition | Priority |
|---------|-----------|----------|
| `comebackStory` | Improved from yesterday | Higher |
| `weekendMotivation` | Is weekend (Sat/Sun) | Lower |

**Logic:** Check `comebackStory` first (more specific), then `weekendMotivation`.

### Edge Cases (Shown Alone)

These triggers are exclusive - when they fire, no other triggers are evaluated.

| Trigger | Condition | Use Case |
|---------|-----------|----------|
| `sessionStart` | totalHabitsCount == 0 | New user, no habits created yet |
| `emptyDay` | totalHabits == 0 (today) AND totalHabitsCount > 0 | Has habits but none scheduled today |

---

## Evaluation Flow

```
evaluateInspirationTriggers(summary, totalHabitsCount)
│
├─ totalHabitsCount == 0?
│  └─ YES → return [sessionStart]
│
├─ summary.totalHabits == 0?
│  └─ YES → return [emptyDay]
│
└─ NO (has habits scheduled today)
   │
   ├─ evaluateProgressTrigger() → 0 or 1 trigger
   ├─ evaluateTimeTrigger()     → 0 or 1 trigger
   └─ evaluateSpecialTrigger()  → 0 or 1 trigger
   │
   └─ return combined triggers (1-3 cards)
```

---

## Test Scenarios

### Edge Cases

| # | Scenario | Input | Expected Output |
|---|----------|-------|-----------------|
| 1 | No habits at all | `totalHabitsCount: 0` | `[.sessionStart]` |
| 2 | Has habits, none scheduled today | `totalHabits: 0, totalHabitsCount: 5` | `[.emptyDay]` |

### Progress Triggers (Category 1)

| # | Scenario | Input | Expected Output |
|---|----------|-------|-----------------|
| 3 | Perfect day | `completionRate: 1.0` | includes `.perfectDay` |
| 4 | Strong finish | `completionRate: 0.75` | includes `.strongFinish` |
| 5 | Strong finish (80%) | `completionRate: 0.80` | includes `.strongFinish` |
| 6 | Halfway point | `completionRate: 0.50` | includes `.halfwayPoint` |
| 7 | First habit complete | `completionRate: 0.2, completedCount: 1` | includes `.firstHabitComplete` |
| 8 | Multiple habits complete | `completionRate: 0.3, completedCount: 2` | NO progress trigger |
| 9 | No progress | `completionRate: 0.0` | NO progress trigger |

### Time-of-Day Triggers (Category 2)

| # | Scenario | Input | Expected Output |
|---|----------|-------|-----------------|
| 10 | Morning, no progress | `timeOfDay: .morning, completionRate: 0.0` | includes `.morningMotivation` |
| 11 | Morning, some progress | `timeOfDay: .morning, completionRate: 0.3` | NO time trigger |
| 12 | Noon, struggling | `timeOfDay: .noon, completionRate: 0.3, hour: 12` | includes `.strugglingMidDay` |
| 13 | Noon, not struggling | `timeOfDay: .noon, completionRate: 0.5, hour: 12` | NO time trigger |
| 14 | Afternoon push (3PM) | `timeOfDay: .noon, completionRate: 0.4, hour: 15` | includes `.afternoonPush` |
| 15 | Afternoon push (4PM) | `timeOfDay: .noon, completionRate: 0.5, hour: 16` | includes `.afternoonPush` |
| 16 | Afternoon, good progress | `timeOfDay: .noon, completionRate: 0.7, hour: 15` | NO time trigger |
| 17 | Evening, good progress | `timeOfDay: .evening, completionRate: 0.6` | includes `.eveningReflection` |
| 18 | Evening, poor progress | `timeOfDay: .evening, completionRate: 0.4` | NO time trigger |

### Special Context Triggers (Category 3)

| # | Scenario | Input | Expected Output |
|---|----------|-------|-----------------|
| 19 | Weekend | `isWeekend: true, comebackStory: false` | includes `.weekendMotivation` |
| 20 | Weekday | `isWeekend: false, comebackStory: false` | NO special trigger |
| 21 | Comeback story | `comebackStory: true, isWeekend: false` | includes `.comebackStory` |
| 22 | Comeback on weekend | `comebackStory: true, isWeekend: true` | includes `.comebackStory` (NOT weekend) |

### Combined Scenarios (Integration)

| # | Scenario | Input | Expected Output |
|---|----------|-------|-----------------|
| 23 | Morning, 0%, weekday | `morning, 0%, weekday` | `[.morningMotivation]` |
| 24 | Morning, 0%, weekend | `morning, 0%, weekend` | `[.morningMotivation, .weekendMotivation]` |
| 25 | Morning, 50%, weekend | `morning, 50%, weekend` | `[.halfwayPoint, .weekendMotivation]` |
| 26 | Noon, 30%, weekday | `noon, 30%, weekday, hour: 12` | `[.strugglingMidDay]` |
| 27 | 3PM, 40%, weekday | `noon, 40%, weekday, hour: 15` | `[.afternoonPush]` |
| 28 | Evening, 100%, weekday | `evening, 100%, weekday` | `[.perfectDay, .eveningReflection]` |
| 29 | Evening, 100%, comeback | `evening, 100%, comeback` | `[.perfectDay, .eveningReflection, .comebackStory]` |
| 30 | Evening, 75%, weekend, comeback | `evening, 75%, weekend, comeback` | `[.strongFinish, .eveningReflection, .comebackStory]` |

---

## Invalid Combinations (Should Never Occur)

These combinations should NEVER appear in the output:

| Invalid Combination | Reason |
|---------------------|--------|
| `perfectDay` + `strongFinish` | Both are progress triggers (mutually exclusive) |
| `halfwayPoint` + `firstHabitComplete` | Both are progress triggers |
| `morningMotivation` + `afternoonPush` | Both are time triggers (mutually exclusive) |
| `strugglingMidDay` + `eveningReflection` | Both are time triggers |
| `weekendMotivation` + `comebackStory` | Both are special triggers (mutually exclusive) |
| `sessionStart` + anything | Edge case, shown alone |
| `emptyDay` + anything | Edge case, shown alone |

---

## Implementation Reference

**File:** `Ritualist/Features/Overview/Presentation/OverviewViewModel.swift`

**Functions:**
- `evaluateInspirationTriggers(summary:totalHabitsCount:)` - Main entry point
- `evaluateProgressTrigger(completionRate:completedCount:)` - Category 1
- `evaluateTimeTrigger(completionRate:hour:)` - Category 2
- `evaluateSpecialTrigger(completionRate:isWeekend:)` - Category 3

**Dependencies:**
- `TodaysSummary` - Contains `totalHabits`, `completedHabitsCount`, `completionPercentage`
- `TimeOfDay` - Enum: `.morning`, `.noon`, `.evening`
- `CalendarUtils` - For hour/weekday extraction
- `checkForComebackStory()` - Async function to check improvement from yesterday

---

## Message Templates

Each trigger has personality-based message variants. See:
- `RitualistCore/Sources/RitualistCore/Services/PersonalizedMessageGenerator.swift`

Personalities: `openness`, `conscientiousness`, `extraversion`, `agreeableness`, `neuroticism`
