# Retroactive Logging - Implementation Plan

## Problem
Users cannot log habits for dates before the habit's `startDate`. If they try to log retroactively (e.g., forgot to log yesterday), the streak calculation ignores those logs because they fall before the habit's creation date.

## Solution
1. **Make `startDate` editable** in the Edit Habit sheet via a date picker
2. **Add validation** to prevent logging for dates before `startDate`

This way:
- Users who want to log retroactively must first edit the habit's start date to an earlier date
- Data integrity is maintained (no logs exist before the habit "existed")
- Streak calculation remains unchanged (bounded by `startDate`)

---

## Implementation Steps

### Step 1: Add Start Date Picker to Edit Habit Sheet
- [x] Add `startDate` state to `HabitDetailViewModel`
- [x] Add `DatePicker` for start date in `HabitFormView`
- [x] Create `StartDateSection.swift` component for the date picker UI
- [x] Ensure start date is saved when habit is updated
- [x] Add validation: start date cannot be in the future
- [x] Add validation: start date cannot be after existing logs (if any)

### Step 2: Add Validation to Prevent Logging Before Start Date
- [x] Find where habit logs are created (toggle, numeric input)
- [x] Add check: if `logDate < habit.startDate`, show error/prevent action
- [x] Show user-friendly message explaining why they can't log for that date
- [x] Suggest editing the habit's start date if they need to log retroactively
- [x] Create `LogValidationTests.swift` for comprehensive validation testing

### Step 3: Testing
- [x] Test editing start date to earlier date, then logging retroactively
- [x] Test that logging before start date is blocked
- [x] Test streak calculation respects the (possibly edited) start date
- [x] Test edge cases: start date = today, start date in past, etc.

---

## Files Modified

### Step 1 (Start Date Picker)
- `Ritualist/Features/Habits/Presentation/HabitDetailViewModel.swift`
- `Ritualist/Features/Habits/Presentation/HabitDetail/HabitFormView.swift`
- `Ritualist/Features/Habits/Presentation/HabitDetail/StartDateSection.swift` (NEW)

### Step 2 (Validation)
- `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/LogUseCases.swift`
- `RitualistCore/Sources/RitualistCore/Enums/Errors/HabitScheduleValidationError.swift`
- `RitualistTests/Core/UseCases/LogValidationTests.swift` (NEW)

---

## Additional Changes Made

### Streak UI Enhancement
- Added streak indicator (e.g., "🔥3") with pulse animation on Overview screen
- Modified `TodaysSummaryCard.swift` and `OverviewView.swift`

### Timezone Audit (38 fixes total)
All `CalendarUtils` methods updated to use timezone-aware Local variants for DST safety:

#### New CalendarUtils Methods
- Added `addWeeksLocal(_ weeks: Int, to date: Date, timezone: TimeZone) -> Date`
- Added `addMonthsLocal(_ months: Int, to date: Date, timezone: TimeZone) -> Date`

#### Overview & Dashboard (13 fixes)
- `OverviewViewModel.swift` - 7 locations
- `MonthlyCalendarCard.swift` - 1 location
- `TodaysSummaryCard.swift` - 1 location
- `DashboardViewModel+UnifiedLoading.swift` - 2 locations
- `DashboardData.swift` - 2 locations

#### Widget Files (13 fixes)
- `WidgetDateNavigationService.swift` - 1 fix
- `RitualistWidget.swift` - 2 fixes
- `AppIntent.swift` - 1 fix
- `WidgetHabitsViewModel.swift` - 1 fix
- Preview files: `MediumWidgetView.swift`, `LargeWidgetView.swift`, `SmallWidgetView.swift`, `WidgetHabitChip.swift`, `WidgetDateNavigationHeader.swift` - 8 fixes

#### Personality Analysis Files (12 fixes)
- `PersonalityAnalysisUseCases.swift` - 2 fixes
- `PersonalityProfile.swift` - 2 fixes
- `PersonalityAnalysisScheduler.swift` - 3 fixes (using new `addWeeksLocal`/`addMonthsLocal`)
- `PersonalityTailoredNotificationContentGenerator.swift` - 1 fix
- `ScheduleAwareCompletionCalculator.swift` - 3 fixes
- `PersonalityAnalysisService.swift` - 1 fix

### Weekly Insights Calculation Fix
Fixed bugs in `OverviewData.generateSmartInsights()`:
1. **Bug**: `totalPossibleCompletions = habits.count * 7` assumed all habits are daily and ignored start dates
   - **Fix**: Now uses `HabitScheduleAnalyzer.calculateExpectedDays()` for schedule-aware counting
2. **Bug**: Iterating per log could count same day multiple times for numeric habits
   - **Fix**: Now iterates per day with `countedDates` Set to prevent double-counting

### Habit Start Date Handling
Verified correct `max(habit.startDate, startDate)` pattern in:
- `HabitCompletionService.swift`
- `ScheduleAwareCompletionCalculator.swift`
- `HabitScheduleAnalyzer.isHabitExpectedOnDate()`
- `TodaysSummaryCard.swift`
- `WidgetLogHabit` (AppIntent)

### Streak Calculation Service
- Updated `StreakCalculationService.swift` and tests
- Verified streak calculation respects habit start date boundaries

### Documentation
- Created `docs/PersonalityAnalysisArchitecture.md` - Comprehensive documentation of the Big Five (OCEAN) personality analysis system

---

## Notes
- The streak calculation in `StreakCalculationService.swift` remains unchanged in logic
- `habitStartDate` continues to be the boundary for streak counting
- This approach enforces data integrity at the input level rather than calculation level
- All timezone operations now use `*Local` variants with `.current` timezone for DST safety
- Future: Wire `TimezoneService.getDisplayTimezone()` to all calculations for full timezone settings support

---

*Last updated: November 2025*
