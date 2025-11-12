# Timezone UTC Audit Results

**Date:** November 12, 2025
**Branch:** `feature/timezone-local-consistency-fixes`

## Executive Summary

Comprehensive audit identified **60+ remaining UTC usages** across the codebase after fixing the core analytics services. These remaining usages are in ViewModels, UseCases, and Repositories, affecting log filtering, date range queries, and UI display logic.

---

## ✅ Already Fixed (45 total fixes)

| Service | UTC→LOCAL Fixes | Status |
|---------|----------------|--------|
| **HabitCompletionService** | 15 | ✅ **FIXED** |
| **StreakCalculationService** | 13 | ✅ **FIXED** |
| **ScheduleAwareCompletionCalculator** | 9 | ✅ **FIXED** |
| **PerformanceAnalysisService** | 8 | ✅ **FIXED** |
| **TOTAL** | **45** | ✅ **COMPLETE** |

**Impact of fixes:**
- ✅ Mon/Wed/Fri habits now appear on correct days in Overview
- ✅ Streaks calculated correctly (no reset at 11 PM local time)
- ✅ Completion rates match actual user behavior
- ✅ Best/worst day analysis reflects true local patterns

---

## 🚨 Remaining UTC Usages (63 total)

### 🔴 **CRITICAL - High Impact on Business Logic**

#### 1. **OverviewViewModel.swift** - 24 UTC usages
**Location:** `Ritualist/Features/Overview/Presentation/OverviewViewModel.swift`

**Critical lines:**
- Line 82: `CalendarUtils.startOfDayUTC(for: viewingDate)` - Log boundary for 30-day lookback
- Line 83: `CalendarUtils.startOfDayUTC(for: thirtyDaysAgo)` - Boundary calculation
- Line 89-90: `startOfDayUTC` - Today/viewing date comparison
- Line 262, 317, 338: `startOfDayUTC(for: viewingDate)` - UseCase date parameters
- Line 287: `areSameDayUTC($0.date, viewingDate)` - **CRITICAL: Log filtering for current view**
- Line 613: `areSameDayUTC($0.date, yesterday)` - Streak bonus check
- Line 664: `weekdayComponentUTC(from: now)` - Weekend detection
- Line 667-668: `areSameDayUTC` + `daysBetweenUTC` - Session time validation
- Line 731: `startOfDayUTC(for: now)` - Last shown time tracking
- Line 882: `areSameDayUTC(log.date, date)` - Has log check
- Line 916: `startOfDayUTC(for: date)` - Log filter boundary
- Line 994: `startOfDayUTC(for: date)` - Daily summary calculation
- Line 1047: `weekIntervalUTC(for: today)` - **CRITICAL: Weekly progress**
- Line 1067: `areSameDayUTC($0.date, log.date)` - Unique days grouping
- Line 1072: `daysBetweenUTC(startOfWeek, log.date)` - **CRITICAL: Week position**
- Line 1223: `weekIntervalUTC(for: today)` - Weekly chart data
- Line 1250: `daysBetweenUTC(startOfWeek, log.date)` - Chart positioning
- Line 1323: `areSameDayUTC(lastResetDate, today)` - Reset tracking

**Potential bugs:**
- Logs might not show on correct days when viewing past dates
- Weekly progress chart might have off-by-one errors in GMT+ timezones
- "Yesterday" streak bonus might trigger on wrong day at midnight
- Weekend detection wrong for users in non-UTC timezones

**Priority:** 🔴 **P0 - CRITICAL**

---

#### 2. **LogUseCases.swift** - 8 UTC usages
**Location:** `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/LogUseCases.swift`

**Critical lines:**
- Lines 15-16: `startOfDayUTC` - Since date filtering
- Lines 20-21: `startOfDayUTC` - Until date filtering
- Lines 50-51: `startOfDayUTC` - Grouped logs since filtering
- Lines 55-56: `startOfDayUTC` - Grouped logs until filtering
- Line 144: `areSameDayUTC(log.date, date)` - Log deletion check

**Impact:**
- Date range queries (`since`/`until`) might miss logs near day boundaries
- Deleting logs for "today" might delete wrong day's logs

**Priority:** 🔴 **P0 - CRITICAL**

---

#### 3. **HabitScheduleAnalyzerProtocol.swift** - 4 UTC usages
**Location:** `RitualistCore/Sources/RitualistCore/Services/HabitScheduleAnalyzerProtocol.swift`

**Critical lines:**
- Line 27: `startOfDayUTC(for: startDate)` - Expected days calculation start
- Line 28: `startOfDayUTC(for: endDate)` - Expected days calculation end
- Line 39: `startOfDayUTC(for: habitEndDate)` - End date boundary check
- Line 53: `weekdayComponentUTC(from: date)` - **CRITICAL: Scheduled day check**

**Impact:**
- Expected days calculation wrong for date ranges spanning midnight
- `isHabitExpectedOnDate()` returns wrong result (used by analytics)

**Priority:** 🔴 **P0 - CRITICAL**

---

#### 4. **HabitCompletionCheckService.swift** - 4 UTC usages
**Location:** `RitualistCore/Sources/RitualistCore/Services/HabitCompletionCheckService.swift`

**Critical lines:**
- Line 76: `startOfDayUTC(for: date)` - Today boundary
- Line 77: `startOfDayUTC(for: habit.startDate)` - Habit start boundary
- Line 85: `startOfDayUTC(for: endDate)` - Habit end boundary

**Impact:**
- Habit might appear as "not started yet" when it should be active
- Habit might appear as "ended" when still active

**Priority:** 🔴 **P0 - CRITICAL**

---

#### 5. **AnalyticsUseCases.swift** - 2 UTC usages
**Location:** `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/AnalyticsUseCases.swift`

**Critical lines:**
- Line 88: `Dictionary(grouping: logs, by: { CalendarUtils.startOfDayUTC(for: $0.date) })`
- Line 97: `logsByDate[CalendarUtils.startOfDayUTC(for: currentDate)]`

**Impact:**
- Daily completion stats might group logs incorrectly
- Analytics dashboard shows wrong data

**Priority:** 🔴 **P0 - CRITICAL**

---

#### 6. **DashboardViewModel+UnifiedLoading.swift** - 2 UTC usages
**Location:** `Ritualist/Features/Dashboard/Presentation/DashboardViewModel+UnifiedLoading.swift`

**Critical lines:**
- Line 76: `startOfDayUTC(for: currentDate)` - Date iteration
- Line 249: `areSameDayUTC(log.date, currentDate)` - Log filtering

**Impact:**
- Dashboard monthly view might show logs on wrong days

**Priority:** 🔴 **P0 - CRITICAL**

---

### 🟡 **MEDIUM - Correctness Issues**

#### 7. **PersonalityAnalysisRepositoryImpl.swift** - 3 UTC usages
**Location:** `RitualistCore/Sources/RitualistCore/Repositories/Implementations/PersonalityAnalysisRepositoryImpl.swift`

**Lines:**
- Line 133: `startOfDayUTC(for: $0.date)` - Unique dates calculation
- Line 139: `startOfDayUTC(for: Date())` - Today boundary
- Line 142: `areSameDayUTC(date, currentDate)` - Consecutive day check

**Impact:**
- Personality analysis completion patterns might be slightly off
- Emotional stability scoring based on wrong day boundaries

**Priority:** 🟡 **P1 - HIGH**

---

#### 8. **HistoricalDateValidationService.swift** - 3 UTC usages
**Location:** `RitualistCore/Sources/RitualistCore/Services/HistoricalDateValidationService.swift`

**Lines:**
- Line 111: `startOfDayUTC(for: date)` - Date normalization
- Line 112: `startOfDayUTC(for: Date())` - Today boundary
- Line 155: `startOfDayUTC(for: Date())` - Validation check

**Impact:**
- Retroactive logging might reject valid dates near midnight
- Future date validation might allow/reject incorrectly

**Priority:** 🟡 **P1 - HIGH**

---

#### 9. **CalendarUseCases.swift** - 3 UTC usages
**Location:** `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/CalendarUseCases.swift`

**Lines:**
- Line 10: `startOfDayUTC(for: month)` - Month normalization
- Line 15: `startOfDayUTC(for: monthInterval.start)` - Date iteration start
- Line 31: `startOfDayUTC(for: month)` - Completion data grouping

**Impact:**
- Monthly calendar card might show data on wrong days
- Month boundaries might be off by one day

**Priority:** 🟡 **P1 - HIGH**

---

#### 10. **HabitScheduleUseCases.swift** - 1 UTC usage
**Location:** `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/HabitScheduleUseCases.swift`

**Line:**
- Line 73: `weekdayComponentUTC(from: logDate)` - Weekday validation

**Impact:**
- Schedule validation might reject valid logs on correct weekdays

**Priority:** 🟡 **P1 - HIGH**

---

#### 11. **HabitLoggingUseCases.swift** - 1 UTC usage
**Location:** `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/HabitLoggingUseCases.swift`

**Line:**
- Line 23: `startOfDayUTC(for: date)` - Date normalization for logging

**Impact:**
- Logs created near midnight might be assigned to wrong day

**Priority:** 🟡 **P1 - HIGH**

---

### 🟢 **LOW - UI/Debug/Test (Acceptable or Intentional)**

#### 12. **DebugMenuView.swift** - 5 UTC usages
**Location:** `Ritualist/Features/Settings/Presentation/DebugMenuView.swift`

**Lines:**
- Line 337: `startOfDayUTC(for: now)` - Debug display
- Line 342: `areSameDayUTC` - Intentional comparison of UTC vs LOCAL
- Line 372: `weekdayComponentUTC(from: now)` - Debug display (shown twice)

**Impact:** None - intentional for debugging timezone differences

**Priority:** 🟢 **P3 - LOW (Keep UTC intentionally for comparison)**

---

#### 13. **MonthlyCalendarCard.swift** - 2 UTC usages
**Location:** `Ritualist/Features/Overview/Presentation/Cards/MonthlyCalendarCard.swift`

**Lines:**
- Line 195: `startOfDayUTC(for: date)` - Date normalization
- Line 244: `startOfDayUTC(for: date)` - Sample data generation

**Impact:** Calendar card shows logs on wrong days

**Priority:** 🟢 **P2 - MEDIUM**

---

#### 14. **QuickActionsCard.swift** - 2 UTC usages
**Location:** `Ritualist/Features/Overview/Presentation/Cards/QuickActionsCard.swift`

**Lines:**
- Line 363: `weekdayComponentUTC(from: Date())` - Weekday check
- Line 367: `weekdayComponentUTC(from: Date())` - Schedule validation

**Impact:** Quick actions might show wrong schedule status

**Priority:** 🟢 **P2 - MEDIUM**

---

#### 15. **NumericHabitLogSheet.swift** - 1 UTC usage
**Location:** `Ritualist/Features/Shared/Presentation/NumericHabitLogSheet.swift`

**Line:**
- Line 362: `areSameDayUTC($0.date, viewingDate)` - Log filtering

**Impact:** Existing logs might not show when editing

**Priority:** 🟢 **P2 - MEDIUM**

---

#### 16. **TestDataPopulationService.swift** - 1 UTC usage ✅ FIXED
**Location:** `RitualistCore/Sources/RitualistCore/Services/TestDataPopulationService.swift`

**Line:**
- Line 150: `startOfDayUTC` → `startOfDayLocal` ✅

**Impact:** Test data now uses LOCAL timezone for realistic app testing

**Priority:** 🟢 **P3 - ADDITIONAL FIX**

**Reason for Fix:** User uses test data scenarios to populate the app with realistic data for manual testing. Test data should use LOCAL timezone to match production behavior and appear correctly in the UI, not UTC.

---

#### 17. **DebugUseCases.swift** - 3 UTC usages ✅ FIXED
**Location:** `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/DebugUseCases.swift`

**Lines:**
- Line 242: `startOfDayUTC` → `startOfDayLocal` ✅
- Line 314: `CalendarUtils.utcCalendar` → `CalendarUtils.currentLocalCalendar` ✅
- Line 330: `timezone: "UTC"` → `timezone: TimeZone.current.identifier` ✅

**Impact:** Test data generation now uses LOCAL timezone, matching PersonalityAnalysisRepositoryImpl

**Priority:** 🟢 **P3 - ADDITIONAL FIX**

**Reason for Fix:** Comments referenced OLD UTC code in PersonalityAnalysisRepositoryImpl. After P1 fixes, PersonalityAnalysisRepositoryImpl now uses LOCAL (lines 132-133, 139, 142-143), so test data MUST use LOCAL to match production behavior.

---

## 📊 Summary Statistics

| Priority | Files | UTC Usages | Business Impact | Status |
|----------|-------|------------|-----------------|--------|
| 🔴 **P0 - CRITICAL** | 6 | 44 | High - Core business logic bugs | ✅ FIXED |
| 🟡 **P1 - HIGH** | 5 | 11 | Medium - Correctness issues | ✅ FIXED |
| 🟢 **P2 - MEDIUM** | 3 | 5 | Low - UI display issues | ✅ FIXED |
| 🟢 **P3 - ADDITIONAL** | 2 | 4 | Test data realism | ✅ FIXED |
| 🔵 **Keep As-Is** | 1 | 5 | None - Debug diagnostic tool | 🔒 Intentional |
| **TOTAL** | **17** | **69** | | **64 Fixed, 5 Intentional** |

---

## 🎯 Recommended Fix Order

### Phase 1: Critical Business Logic (P0)
1. **OverviewViewModel** (24 fixes) - Most used ViewModel, affects main user flow
2. **LogUseCases** (8 fixes) - Core data access layer
3. **HabitScheduleAnalyzerProtocol** (4 fixes) - Used by many analytics services
4. **HabitCompletionCheckService** (4 fixes) - Habit active status validation
5. **AnalyticsUseCases** (2 fixes) - Dashboard stats
6. **DashboardViewModel** (2 fixes) - Monthly view

**Total P0 fixes:** 44

### Phase 2: Correctness Issues (P1)
7. **PersonalityAnalysisRepositoryImpl** (3 fixes)
8. **HistoricalDateValidationService** (3 fixes)
9. **CalendarUseCases** (3 fixes)
10. **HabitScheduleUseCases** (1 fix)
11. **HabitLoggingUseCases** (1 fix)

**Total P1 fixes:** 11

### Phase 3: UI Components (P2)
12. **MonthlyCalendarCard** (2 fixes)
13. **QuickActionsCard** (2 fixes)
14. **NumericHabitLogSheet** (1 fix)

**Total P2 fixes:** 5

### Phase 4: P3 Additional Fixes
- TestDataPopulationService - 1 fix (changed to LOCAL for realistic test data)
- DebugUseCases - 3 fixes (changed to LOCAL to match PersonalityAnalysisRepositoryImpl)

**Total P3 fixes:** 4

---

### Phase 5: Keep As-Is (Debug Diagnostics Only)
- DebugMenuView - Intentional UTC for timezone comparison tool (5 usages)

**Reason:** DebugMenuView shows UTC vs LOCAL side-by-side to diagnose timezone bugs. This is a feature, not a bug.

**Total Keep As-Is:** 5 (no fixes needed)

---

## 🧪 Testing Strategy After Fixes

### Critical Test Scenarios

**Test A: Late Night Logging (Timezone Boundary)**
- User in GMT+8 logs habit at 11 PM
- Expected: Counts for today (Monday)
- Bug if UTC: Would count for tomorrow (Tuesday)

**Test B: Weekly Progress Chart**
- User completes habits Mon/Wed/Fri in GMT+2
- Expected: Chart shows correct days
- Bug if UTC: Days might be off by one

**Test C: Retroactive Logging**
- User logs for "yesterday" at 1 AM (just after midnight)
- Expected: Log appears on yesterday's date
- Bug if UTC: Might appear on wrong day

**Test D: Dashboard Monthly View**
- View monthly calendar in GMT-5
- Expected: All logs show on correct dates
- Bug if UTC: Logs near midnight on wrong days

**Test E: Personality Analysis**
- Completion patterns analyzed over 30 days
- Expected: Consecutive days calculated correctly
- Bug if UTC: Might think user skipped days

---

## 🚩 Known Bugs (Likely Existing)

Based on this audit, the following bugs are **likely already present** in production:

1. **Weekly Progress Chart Off-by-One** (OverviewViewModel:1047, 1072)
   - Chart positions might be wrong in GMT+ timezones
   - Severity: Medium - Visual only

2. **Retroactive Logging Edge Cases** (LogUseCases:15-21)
   - Logs created near midnight might filter incorrectly
   - Severity: High - Data consistency

3. **Dashboard Monthly View** (DashboardViewModel:249)
   - Logs might appear on wrong days in calendar
   - Severity: High - User confusion

4. **Personality Analysis Accuracy** (PersonalityAnalysisRepositoryImpl:142)
   - Consecutive days might not be detected properly
   - Severity: Medium - Analytics accuracy

5. **Weekend Detection Wrong** (OverviewViewModel:664)
   - Weekend prompts might show on wrong days
   - Severity: Low - Minor UX issue

---

## 📝 Notes

- **CalendarUtils.swift** itself is correct - it has BOTH UTC and LOCAL methods
- The issue is **choosing the wrong method** at call sites
- Some UTC usages are **intentional** (DebugMenuView comparison)
- Test files can keep UTC for consistency with old test data

---

## 🔄 Next Steps

1. Review this audit with team
2. Prioritize Phase 1 (P0) fixes first
3. Create feature flag for gradual rollout
4. Add comprehensive timezone edge case tests
5. Document timezone strategy in CLAUDE.md
6. Add linting rule to prevent new UTC usages in business logic
