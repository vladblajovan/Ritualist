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
- [ ] Add `startDate` state to `HabitDetailViewModel`
- [ ] Add `DatePicker` for start date in `HabitFormView`
- [ ] Ensure start date is saved when habit is updated
- [ ] Add validation: start date cannot be in the future
- [ ] Add validation: start date cannot be after existing logs (if any)

### Step 2: Add Validation to Prevent Logging Before Start Date
- [ ] Find where habit logs are created (toggle, numeric input)
- [ ] Add check: if `logDate < habit.startDate`, show error/prevent action
- [ ] Show user-friendly message explaining why they can't log for that date
- [ ] Suggest editing the habit's start date if they need to log retroactively

### Step 3: Testing
- [ ] Test editing start date to earlier date, then logging retroactively
- [ ] Test that logging before start date is blocked
- [ ] Test streak calculation respects the (possibly edited) start date
- [ ] Test edge cases: start date = today, start date in past, etc.

---

## Files to Modify

### Step 1 (Start Date Picker)
- `Ritualist/Features/Habits/Presentation/HabitDetailViewModel.swift`
- `Ritualist/Features/Habits/Presentation/HabitDetail/HabitFormView.swift`

### Step 2 (Validation)
- `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/HabitLoggingUseCases.swift` (or wherever logs are created)
- Potentially ViewModel that handles habit toggling

---

## Notes
- The streak calculation in `StreakCalculationService.swift` remains unchanged
- `habitStartDate` continues to be the boundary for streak counting
- This approach enforces data integrity at the input level rather than calculation level
