# Remaining Timezone Fixes - Quick Checklist

**Status**: 69/77 Fixed (90% Complete) | 8 Remaining

---

## 🚨 Fix #1: Dashboard Time Periods (2 changes)

**File**: `RitualistCore/Sources/RitualistCore/Enums/TimePeriod.swift`

### Line 43:
```swift
// BEFORE (WRONG):
let startOfWeek = CalendarUtils.weekIntervalUTC(for: now)?.start ?? now

// AFTER (CORRECT):
let startOfWeek = CalendarUtils.weekIntervalLocal(for: now)?.start ?? now
```

### Line 47:
```swift
// BEFORE (WRONG):
let startOfMonth = CalendarUtils.monthIntervalUTC(for: now)?.start ?? now

// AFTER (CORRECT):
let startOfMonth = CalendarUtils.monthIntervalLocal(for: now)?.start ?? now
```

**Impact**: Dashboard "This Week" and "This Month" analytics will show correct week/month boundaries

---

## 🚨 Fix #2: Widget ViewModel (2 changes)

**File**: `RitualistWidget/ViewModels/WidgetHabitsViewModel.swift`

### Line 36:
```swift
// BEFORE (WRONG):
let targetDate = CalendarUtils.startOfDayUTC(for: date)

// AFTER (CORRECT):
let targetDate = CalendarUtils.startOfDayLocal(for: date)
```

### Line 64:
```swift
// BEFORE (WRONG):
CalendarUtils.areSameDayUTC(log.date, targetDate)

// AFTER (CORRECT):
CalendarUtils.areSameDayLocal(log.date, targetDate)
```

**Impact**: Widget will filter logs correctly, matching main app behavior

---

## 🚨 Fix #3: Widget Provider (2 changes)

**File**: `RitualistWidget/RitualistWidget.swift`

### Line 50:
```swift
// BEFORE (WRONG):
let isToday = CalendarUtils.areSameDayUTC(selectedDate, actualToday)

// AFTER (CORRECT):
let isToday = CalendarUtils.areSameDayLocal(selectedDate, actualToday)
```

### Line 84:
```swift
// BEFORE (WRONG):
let isToday = CalendarUtils.areSameDayUTC(selectedDate, actualToday)

// AFTER (CORRECT):
let isToday = CalendarUtils.areSameDayLocal(selectedDate, actualToday)
```

**Impact**: Widget "Today" indicator will be correct for all timezones

---

## 🚨 Fix #4: Future Date Validation (2 changes)

**File**: `RitualistCore/Sources/RitualistCore/Validation/LogValidation.swift`

### Lines 56-57:
```swift
// BEFORE (WRONG):
let todayUTC = CalendarUtils.startOfDayUTC(for: now)
let logDateUTC = CalendarUtils.startOfDayUTC(for: date)

// AFTER (CORRECT):
let todayLocal = CalendarUtils.startOfDayLocal(for: now)
let logDateLocal = CalendarUtils.startOfDayLocal(for: date)
```

### Line 58 (variable name update):
```swift
// BEFORE:
if logDateUTC > todayUTC {

// AFTER:
if logDateLocal > todayLocal {
```

**Impact**: Users in Asia/Australia can log habits late at night without "future date" errors

---

## ✅ Testing Checklist

After making all 8 fixes, test:

- [ ] Dashboard "This Week": Monday 8 AM in GMT+8 shows current week (not previous)
- [ ] Dashboard "This Month": 1st of month shows correct month start
- [ ] Widget completion matches main app for same habit
- [ ] Widget "Today" indicator correct in GMT+10
- [ ] Late-night logging at 11:59 PM succeeds (GMT-5, GMT+8, GMT+10)
- [ ] User can log habits before midnight without errors

---

## 📊 Summary

| File | Lines | Changes | Impact |
|------|-------|---------|--------|
| TimePeriod.swift | 43, 47 | 2 | Dashboard analytics accuracy |
| WidgetHabitsViewModel.swift | 36, 64 | 2 | Widget log filtering |
| RitualistWidget.swift | 50, 84 | 2 | Widget "Today" indicator |
| LogValidation.swift | 56-58 | 3 | Late-night logging access |
| **TOTAL** | | **9 changes** | **All timezone bugs fixed** |

---

## 🎯 Quick Commands

```bash
# Verify remaining UTC usages
grep -r "weekIntervalUTC\|monthIntervalUTC\|startOfDayUTC\|areSameDayUTC" \
  --include="*.swift" \
  --exclude-dir="RitualistTests" \
  RitualistCore/Sources/RitualistCore/Enums/TimePeriod.swift \
  RitualistWidget/ \
  RitualistCore/Sources/RitualistCore/Validation/LogValidation.swift

# Expected: 8 matches before fixes, 0 matches after
```

---

## 🔄 After Fixes

1. Build and test on iOS 26 simulator
2. Load test data scenario (Power User)
3. Verify dashboard shows correct week/month
4. Check widget matches app completion status
5. Try late-night logging (change device time to 11:59 PM)
6. Remove debug logging from StreakCalculationService and HabitCompletionService
7. Commit all fixes together

**Expected Result**: Zero timezone-related bugs, 100% LOCAL consistency
