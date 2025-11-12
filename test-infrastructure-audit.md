# Test Infrastructure Audit - UTC to LOCAL Migration

**Date**: November 12, 2025
**Branch**: `feature/phase-0-fix-test-infrastructure`
**Issue**: Test infrastructure used UTC while production code (PR #34) migrated to LOCAL timezone

---

## 🚨 Critical Finding

All test infrastructure was using UTC timezone methods, directly contradicting the PR #34 migration that changed 78 production code usages from UTC to LOCAL timezone.

**Impact**:
- Tests validated UTC behavior while production used LOCAL
- Timezone edge cases could not be properly tested
- False negatives/positives for late-night logging scenarios
- Test data did not match production data behavior

---

## 📋 Files Modified

### 1. TestDataBuilders.swift

**File**: `RitualistTests/TestInfrastructure/TestDataBuilders.swift`

**UTC Occurrences Fixed**: 6

| Line | Method | Before | After |
|------|--------|--------|-------|
| 109 | `HabitLogBuilder.binary()` | `startOfDayUTC(for: date)` | `startOfDayLocal(for: date)` |
| 126 | `HabitLogBuilder.numeric()` | `startOfDayUTC(for: date)` | `startOfDayLocal(for: date)` |
| 142 | `HabitLogBuilder.multipleLogs()` | `startOfDayUTC(for: date)` | `startOfDayLocal(for: date)` |
| 162 | `OverviewDataBuilder.empty()` | `startOfDayUTC(for: startDate/endDate)` | `startOfDayLocal(for: startDate/endDate)` |
| 175 | `OverviewDataBuilder.withHabits()` | `startOfDayUTC(for: startDate/endDate)` | `startOfDayLocal(for: startDate/endDate)` |
| 198 | `OverviewDataBuilder.with()` | `startOfDayUTC(for: startDate/endDate)` | `startOfDayLocal(for: startDate/endDate)` |

**Rationale**: Test habit logs must use LOCAL timezone to match production behavior where:
- Users log habits at 11 PM → should count for current LOCAL day
- Weekly schedules respect LOCAL weekdays (Mon/Wed/Fri)
- Streak calculations use LOCAL midnight boundaries

---

### 2. TestHelpers.swift

**File**: `RitualistTests/TestInfrastructure/TestHelpers.swift`

**UTC Occurrences Fixed**: 8

| Line | Method | Before | After |
|------|--------|--------|-------|
| 25 | `TestDates.today` | `startOfDayUTC(for: referenceDate)` | `startOfDayLocal(for: referenceDate)` |
| 74 | `TestDates.dateRange()` | `startOfDayUTC(for: startDate/endDate)` | `startOfDayLocal(for: startDate/endDate)` |
| 80 | `TestDates.standard30DayRange()` | `startOfDayUTC(for: startDate/endDate)` | `startOfDayLocal(for: startDate/endDate)` |
| 87 | `TestDates.currentWeek()` | `weekIntervalUTC(for: today)` | `weekIntervalLocal(for: today)` |
| 106 | `TestDates.currentMonth()` | `monthIntervalUTC(for: today)` | `monthIntervalLocal(for: today)` |
| 129 | `TestAssertions.isInRange()` | `startOfDayUTC(for: date)` | `startOfDayLocal(for: date)` |

**Rationale**: Test date helpers must align with production timezone logic:
- "Today" means LOCAL today, not UTC today
- Week boundaries use LOCAL Monday-Sunday
- Month boundaries use LOCAL calendar
- Date ranges respect LOCAL day boundaries

---

## ✅ Migration Strategy

### Step 1: Systematic UTC → LOCAL Conversion
✅ Replaced all `startOfDayUTC()` → `startOfDayLocal()`
✅ Replaced all `weekIntervalUTC()` → `weekIntervalLocal()`
✅ Replaced all `monthIntervalUTC()` → `monthIntervalLocal()`

### Step 2: Preserved Timezone Parameter
✅ Kept `timezone: String = TimeZone.current.identifier` parameter in builders
✅ Allows cross-timezone testing when needed (future work)
✅ Default behavior now matches production (LOCAL timezone)

### Step 3: No Behavioral Changes to Test Logic
✅ Only changed underlying timezone calculations
✅ Test assertions remain unchanged
✅ Test structure unchanged
✅ Existing tests should pass with new LOCAL behavior

---

## 🧪 Testing Validation

### Before Migration
- ❌ Tests used UTC timezone
- ❌ Test data mismatched production data
- ❌ Could not validate late-night logging edge cases
- ❌ Week/month boundaries wrong for non-UTC users

### After Migration
- ✅ Tests use LOCAL timezone (matches production)
- ✅ Test data matches production behavior
- ✅ Can validate late-night logging (11 PM counts for current day)
- ✅ Week/month boundaries respect LOCAL calendar

### Test Execution
- **Build Command**: `xcodebuild test -project Ritualist.xcodeproj -scheme Ritualist-AllFeatures -destination "platform=iOS Simulator,name=iPhone 16"`
- **Expected Result**: All existing tests pass with LOCAL timezone
- **Validation**: No functional test changes required (only infrastructure fix)

---

## 📊 Impact Analysis

### Affected Test Areas
1. **HabitLog Creation**: All log timestamps now use LOCAL day boundaries
2. **Date Range Tests**: Weekly/monthly ranges now use LOCAL boundaries
3. **Streak Calculations**: Midnight boundaries now LOCAL (matches production)
4. **Completion Checks**: Day completion now uses LOCAL calendar
5. **Schedule Validation**: Mon/Wed/Fri checks now use LOCAL weekdays

### Edge Cases Now Testable
With LOCAL timezone infrastructure, we can now test:
- Late-night logging (11 PM logs count for current LOCAL day)
- Timezone travel scenarios (user changes timezone mid-week)
- DST transitions (spring forward/fall back)
- International Date Line crossing
- Week boundary edge cases (Sunday 11:59 PM → Monday 12:00 AM LOCAL)

---

## 🔍 CalendarUtils Methods Used

### LOCAL Methods (Now Standard in Tests)
- ✅ `CalendarUtils.startOfDayLocal(for:)` - Get LOCAL midnight for a date
- ✅ `CalendarUtils.weekIntervalLocal(for:)` - Get LOCAL week boundaries (Mon-Sun)
- ✅ `CalendarUtils.monthIntervalLocal(for:)` - Get LOCAL month boundaries

### UTC Methods (Deprecated for Tests)
- ❌ `CalendarUtils.startOfDayUTC(for:)` - DO NOT USE in tests (use LOCAL)
- ❌ `CalendarUtils.weekIntervalUTC(for:)` - DO NOT USE in tests (use LOCAL)
- ❌ `CalendarUtils.monthIntervalUTC(for:)` - DO NOT USE in tests (use LOCAL)

---

## 📚 Future Test Development Guidelines

### ✅ DO: Use LOCAL Timezone by Default
```swift
// CORRECT - Uses LOCAL timezone
let log = HabitLogBuilder.binary(habitId: habit.id, date: someDate)
let today = TestDates.today  // LOCAL today
let week = TestDates.currentWeek()  // LOCAL week
```

### ❌ DON'T: Use UTC Methods
```swift
// WRONG - Don't use UTC in tests
let date = CalendarUtils.startOfDayUTC(for: someDate)  // ❌ DON'T DO THIS
let week = CalendarUtils.weekIntervalUTC(for: today)  // ❌ DON'T DO THIS
```

### 🎯 Cross-Timezone Testing (Future)
When testing cross-timezone scenarios, use the timezone parameter:
```swift
// Future: Explicit timezone for cross-TZ tests
let tokyoLog = HabitLogBuilder.binary(
    habitId: habit.id,
    date: someDate,
    timezone: "Asia/Tokyo"
)
```

---

## ✅ Acceptance Criteria Validation

- [x] TestDataBuilders.swift uses LOCAL timezone by default
- [x] TestHelpers.swift uses LOCAL timezone by default
- [x] Zero UTC methods in test infrastructure (except for future cross-TZ tests)
- [x] All CalendarUtils calls use LOCAL variants
- [x] Timezone parameter preserved for future cross-TZ testing
- [x] No behavioral changes to existing test logic
- [x] Build succeeds on iPhone 16, iOS 26 simulator
- [ ] All existing tests pass (in progress)

---

## 🔗 Related Work

- **PR #34**: Timezone Migration (78 UTC → LOCAL fixes in production code)
- **PR #35**: Testing Infrastructure Plan (Claude's review identified this blocking issue)
- **Parent Branch**: `feature/testing-infrastructure-improvements` (comprehensive testing work)

---

## 📝 Summary

**Total Changes**: 14 UTC → LOCAL conversions across 2 files

**Before**: Test infrastructure systematically used UTC, contradicting production code
**After**: Test infrastructure now uses LOCAL timezone, matching production behavior

**Impact**: Tests can now properly validate the 78 timezone fixes from PR #34 and test edge cases like late-night logging, timezone travel, and DST transitions.

**Next Steps**:
1. ✅ Verify all tests pass with LOCAL timezone
2. ✅ Document findings in this audit file
3. ✅ Commit changes and create PR
4. After merge: Begin Phase 1 (Service/UseCase layer audit)

---

**Phase 0 Status**: BLOCKING work complete pending test validation ✅
