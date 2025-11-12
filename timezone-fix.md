# Timezone Strategy for Ritualist

## Executive Summary

**Decision**: Use **LOCAL timezone** for all habit scheduling and business logic, with optional UTC timestamp + timezone storage for historical context.

**Why**: Habits are routine-based activities tied to the user's daily rhythm. A habit scheduled for "Monday morning" means Monday in the user's experienced time, not Monday UTC.

## Industry Best Practices Analysis

### What Top Apps Do

**Habit Tracking Apps (Streaks, Habitica, Productive):**
- Use LOCAL timezone for all scheduling
- Day boundaries at midnight LOCAL time
- Accept that users traveling across date lines could theoretically log twice (rare edge case)

**Event Logging Apps (Fitness trackers, Apple Health):**
- Store UTC + timezone for workout/event timestamps
- Display in original or current timezone based on user preference

**Why They Differ:**
- **Events** = Things that happened (absolute moments in time) → UTC makes sense
- **Routines** = Things that should happen (recurring schedules) → LOCAL makes sense

### The Philosophical Question: What is a "Day"?

**Calendar Day (UTC Approach)**:
- Astronomical day, same for everyone globally
- Log at 11 PM Monday NYC (4 AM Tuesday UTC) = counts for Tuesday UTC
- ❌ Unintuitive for users
- ❌ Doesn't match user's lived experience

**User's Day (LOCAL Approach)**:
- The day the user is experiencing
- Log at 11 PM Monday NYC = counts for Monday (user's day)
- ✅ Intuitive and matches mental model
- ✅ Habits tied to daily routines

**Research Finding**:
> "For user routines like daily habits, local time context is crucial for user experience."

## Implementation Strategy

### 1. **Habit Schedules** (What days is a habit active?)
```swift
// ✅ CORRECT - Use LOCAL timezone
func isActiveOn(date: Date) -> Bool {
    let calendarWeekday = CalendarUtils.weekdayComponentLocal(from: date)
    let habitWeekday = CalendarUtils.calendarWeekdayToHabitWeekday(calendarWeekday)

    switch self {
    case .daily:
        return true
    case .daysOfWeek(let days):
        return days.contains(habitWeekday)
    }
}
```

### 2. **Viewing Date** (What day is the user looking at?)
```swift
// ✅ CORRECT - Use LOCAL timezone
public var viewingDate = CalendarUtils.startOfDayLocal(for: Date())
```

### 3. **Log Storage** (When did user log a habit?)
```swift
// ✅ HYBRID APPROACH - Store UTC + timezone for context
struct HabitLog {
    var timestamp: Date              // UTC timestamp (absolute moment)
    var timezoneIdentifier: String   // Where user was when logging

    // Benefits:
    // - Can display in "original" or "current" timezone
    // - Preserves historical context when traveling
    // - Analytics can see patterns: "User always logs at 7 AM local"
}
```

### 4. **Day Boundaries** (Is log from "today"?)
```swift
// ✅ CORRECT - Use LOCAL timezone
func isLoggedToday(log: HabitLog, viewingDate: Date) -> Bool {
    return CalendarUtils.areSameDayLocal(log.timestamp, viewingDate)
}
```

### 5. **Display Settings** (How to show historical logs?)
```swift
// User preference: "original" or "current"
enum DisplayTimezoneMode {
    case original  // Show "7:00 AM" (as experienced)
    case current   // Show "8:00 PM" (converted to current timezone)
}

// This is DISPLAY ONLY, doesn't affect business logic
```

## Edge Cases & Tradeoffs

### ✅ Accepted Tradeoffs (Using LOCAL)

**1. Date Line Crossing**
- User logs habit Monday 11 PM in LA
- Flies to Sydney (crosses date line)
- Logs same habit Tuesday 11 PM in Sydney
- **Result**: Two logs (Monday LA, Tuesday Sydney)
- **Why acceptable**: Extremely rare, user actually did the habit twice in their experience

**2. DST Transitions**
- "Missing hour" during spring forward: Handled by Calendar framework
- "Extra hour" during fall back: Logs to first occurrence
- **Why acceptable**: Happens twice a year, minor inconvenience

### ❌ Avoided Problems (If using UTC)

**1. Midnight Confusion**
- User in GMT+8: Midnight local = 4 PM previous day UTC
- Habit scheduled for "Tuesday" would appear at 4 PM Monday UTC
- **Result**: Massive confusion for users

**2. Schedule Mismatch**
- "Run every Monday" would check against UTC Monday
- For user in GMT+8, Monday spans from Sunday 4 PM to Monday 4 PM UTC
- **Result**: Habit appears on "wrong" days from user perspective

**3. Historical Data Confusion**
- User logs "Morning Run 7 AM" in NYC
- Travels to Tokyo
- Historical view shows "Morning Run 8 PM" (UTC conversion)
- **Result**: User thinks "I never run at 8 PM, this is wrong!"

## Consistency is Key

The ONLY way timezone handling works is **complete consistency**:

### ✅ Current Implementation (Consistent LOCAL)
```
Schedule Check → Local Weekday ✅
Viewing Date   → Local Day     ✅
Day Navigation → Local Days    ✅
Log Query      → Local Day     ✅
Display        → Local Time    ✅
```

### ❌ Mixed Approach (CAUSES BUGS)
```
Schedule Check → Local Weekday ✅
Viewing Date   → Local Day     ✅
Day Navigation → UTC Days      ❌ BUG!
Log Query      → UTC Day       ❌ BUG!
```

## What About timezone-fix.md?

The extensive document advocating UTC + Timezone storage has merit for **event logging** but is **overkill for habit scheduling**.

**What it gets right:**
- Store timezone context with logs (good for historical display)
- Centralized CalendarUtils (excellent architecture)

**What's misguided for habit apps:**
- "Use UTC for all business logic" (wrong for recurring schedules)
- Complex timezone conversions everywhere (unnecessary complexity)

**The real bug** in the original issue:
- Not that we weren't using UTC
- But that we were **inconsistent** (mixing UTC and local in different places)

## Migration Assessment

Looking at our current codebase:

### ✅ Already Correct (Use LOCAL)
- `OverviewViewModel.viewingDate` - uses `startOfDayLocal()`
- `HabitSchedule.isActiveOn()` - NOW uses `weekdayComponentLocal()` (just fixed!)
- Day navigation (previous/next) - uses local days

### ⚠️ Need to Verify (Should use LOCAL)
Let me check if there are any remaining UTC usages in business logic...

```bash
# Check for UTC usage in business logic
grep -r "CalendarUtils.*UTC" --include="*.swift" Ritualist/Features/
grep -r "startOfDayUTC" --include="*.swift" Ritualist/Features/
```

**Hypothesis**: We might have mixed UTC/Local in some places, causing bugs.

## The Display Settings

Your Advanced Settings has `displayTimezoneMode`:
- **"original"**: Show times as originally experienced
- **"current"**: Show times in current device timezone

This is **CORRECT** and separate from business logic. Examples:

**Scenario**: User logged "Run" at 7 AM in NYC, now viewing in Tokyo

```
Display Mode "original":
└─ Shows: "7:00 AM" (preserves experience)

Display Mode "current":
└─ Shows: "8:00 PM (was 7:00 AM EST)" (shows timezone context)
```

This setting affects **DISPLAY ONLY**, not:
- Schedule checks (always local)
- Day boundaries (always local)
- Log creation (always local)

## Recommendations

### 1. **Keep Current Approach** ✅
The fix we just made (local weekday for schedules) is correct.

### 2. **Audit for Consistency**
Search codebase for any remaining UTC usage in business logic:
- Schedule validation
- Day boundary checks
- Log queries for "today"

### 3. **Update timezone-fix.md**
Clarify that:
- UTC is for event timestamps (optional)
- LOCAL is for all habit scheduling business logic
- Display settings are separate concern

### 4. **Simplify if Possible**
If we're not using the timezone storage feature yet, consider:
- Start with pure LOCAL everywhere
- Add timezone context later only if needed for travel use cases

### 5. **Timezone Change Detection** (NEW FEATURE IDEA)

Automatically detect when user travels and update their home timezone:

**On App Launch:**
```swift
// Check if device timezone changed since last launch
let currentTZ = TimeZone.current.identifier
let savedHomeTZ = userProfile.homeTimezone

if savedHomeTZ == nil {
    // First launch - set home timezone to current device timezone
    userProfile.homeTimezone = currentTZ
} else if savedHomeTZ != currentTZ {
    // Timezone changed - user has traveled!
    showTimezoneChangeNotice()
}
```

**Timezone Change Notice:**
```
┌─────────────────────────────────────┐
│  🌍 Timezone Changed                │
│                                     │
│  Home: America/New_York (EST)      │
│  Current: Asia/Tokyo (JST)         │
│                                     │
│  ⚙️ Update home timezone?          │
│                                     │
│  [Keep Home]  [Update to Tokyo]   │
└─────────────────────────────────────┘
```

**Benefits:**
- User awareness: "I've traveled, this might affect my habits"
- Choice: Update home or keep original (for short trips)
- Context: Historical logs can show "logged in Tokyo" vs "logged at home"

**Implementation:**
```swift
// RitualistApp.swift - Check on app launch
func checkTimezoneChange() {
    let currentTZ = TimeZone.current.identifier
    let lastKnownTZ = UserDefaults.standard.string(forKey: "lastKnownTimezone")

    if lastKnownTZ != currentTZ {
        // Timezone changed
        UserDefaults.standard.set(currentTZ, forKey: "lastKnownTimezone")

        // Show notice in Overview or Settings
        NotificationCenter.default.post(
            name: .timezoneChanged,
            object: nil,
            userInfo: [
                "from": lastKnownTZ ?? "unknown",
                "to": currentTZ
            ]
        )
    }
}
```

**UI/UX Options:**

**Option A: Banner in Overview**
```
┌──────────────────────────────────┐
│ 🌍 You're in a different timezone│
│ Asia/Tokyo (was America/New_York)│
│ [Dismiss] [Settings]             │
└──────────────────────────────────┘
```

**Option B: Settings Badge**
```
Settings
└─ Advanced Settings (1) 🔴
   └─ Timezone: Tokyo (Changed)
```

**Option C: Modal on First Open After Travel**
```
Welcome back! 🌍

We noticed you're now in:
Asia/Tokyo (GMT+9)

Your home timezone is:
America/New_York (GMT-5)

Would you like to:
• Update home timezone to Tokyo
• Keep home timezone as New York
• Remind me later

[This helps with habit scheduling and log display]
```

**User Stories:**

1. **Business Traveler** (Temporary Travel)
   - Flies NYC → London for 3 days
   - App notices timezone change
   - User chooses "Keep home timezone as NYC"
   - Habits continue as normal, logs show "logged in London"

2. **Relocating User** (Permanent Move)
   - Moves from LA → Berlin permanently
   - App notices timezone change
   - User chooses "Update home timezone to Berlin"
   - New baseline established, old logs retain LA context

3. **Digital Nomad** (Frequent Travel)
   - Travels every few weeks
   - App notices changes, user updates home timezone each time
   - Rich historical context: "Habit completed in 12 different timezones this year"

**Advanced: Travel Mode**
```
Toggle: 🌍 Travel Mode
When enabled:
- Keeps home timezone stable
- Shows timezone context on all logs
- Adds "Current Location" to Overview
```

**Settings Integration:**
```
Advanced Settings
├─ Display Timezone Mode: [Original/Current]
├─ Home Timezone: America/New_York
│  ├─ Current Device: Asia/Tokyo ⚠️
│  └─ [Update Home to Current Device]
└─ Travel Alerts: [On/Off]
   └─ Notify when timezone changes
```

**Implementation Priority:**

**Phase 1 (Immediate):**
- [ ] Set home timezone to device timezone on first launch
- [ ] Store lastKnownTimezone in UserDefaults
- [ ] Detect timezone changes on app launch

**Phase 2 (UX):**
- [ ] Show banner/notice when timezone changes
- [ ] Allow user to update home timezone
- [ ] Add to Debug Menu (Timezone Diagnostics section)

**Phase 3 (Advanced):**
- [ ] Travel mode toggle
- [ ] Timezone change history
- [ ] Analytics: "Habits completed across N timezones"

## Implementation Status

### ✅ Completed (Core Fixes)

**CalendarUtils Foundation:**
- ✅ `weekdayComponentLocal()` - Extract weekday in local timezone
- ✅ `startOfDayLocal()` - Get day boundaries in local timezone
- ✅ `areSameDayLocal()` - Compare dates in local timezone
- ✅ Comprehensive date math operations
- ✅ Timezone context storage helpers

**Critical Bug Fixes:**
- ✅ `HabitSchedule.isActiveOn()` - Changed from UTC to LOCAL weekday checking
- ✅ `OverviewViewModel.viewingDate` - Uses `startOfDayLocal()` correctly
- ✅ Day navigation (previous/next/today) - All use LOCAL operations
- ✅ **Bug confirmed fixed**: Habit scheduled for Mon/Wed/Fri no longer appears on Tuesday

**Debug Infrastructure:**
- ✅ Timezone Diagnostics section in Debug Menu showing:
  - Device timezone details (identifier, abbreviation, offset)
  - Current time in local and UTC
  - Day boundaries comparison
  - Weekday conversion (Calendar vs Habit numbering)
  - User display settings

### 🚨 AUDIT RESULTS - CRITICAL ISSUES FOUND

**Audit Date**: November 11, 2025

We performed a comprehensive audit of all analytics and calculation services. The results confirm **massive timezone inconsistencies** across the codebase.

#### **Audit Summary**

| Service | Status | UTC Usage Count | Impact Level |
|---------|---------|----------------|--------------|
| **StreakCalculationService** | ❌ BROKEN | 13 locations | 🔴 **CRITICAL** |
| **ScheduleAwareCompletionCalculator** | ❌ BROKEN | 8 locations | 🔴 **CRITICAL** |
| **PerformanceAnalysisService** | ❌ BROKEN | 8 locations | 🔴 **CRITICAL** |
| **HabitSchedule.isActiveOn()** | ✅ FIXED | 0 (was 1) | ✅ **RESOLVED** |
| **OverviewViewModel** | ✅ CORRECT | 0 | ✅ **OK** |

#### **1. StreakCalculationService.swift (13 UTC usages)**

**File**: `RitualistCore/Sources/RitualistCore/Services/StreakCalculationService.swift`

**Lines with issues:**
- Line 82, 83: `startOfDayUTC` in `getDailyBreakDates()`
- Line 108: `startOfDayUTC` in `getNextScheduledDate()`
- Line 135, 136: `startOfDayUTC` in `calculateDailyCurrentStreak()`
- Line 163, 164: `startOfDayUTC` in `calculateDaysOfWeekCurrentStreak()`
- Line 208: `startOfDayUTC` in `getCompliantDates()`
- Line 221: `daysBetweenUTC` in `findLongestConsecutiveSequence()`
- Line 246: `startOfDayUTC` in `findLongestScheduledSequence()`
- Line 272: `weekIntervalUTC` in `groupLogsByWeek()`
- Line 282: `weekdayComponentUTC` in `getHabitWeekday()`

**Impact:**
- ❌ Current streaks calculated incorrectly
- ❌ Longest streaks calculated incorrectly
- ❌ Streak break dates off by one day
- ❌ Next scheduled date calculation wrong

**Real-world scenario:**
```
User in GMT+2 at 11 PM Tuesday completes habit
├─ Streak counter sees it as Wednesday UTC
├─ Thinks user broke Tuesday's streak
└─ RESULT: Streak resets even though user completed it!
```

#### **2. ScheduleAwareCompletionCalculator.swift (8 UTC usages)**

**File**: `RitualistCore/Sources/RitualistCore/Services/ScheduleAwareCompletionCalculator.swift`

**Lines with issues:**
- Line 82: `daysBetweenUTC` in `calculateExpectedDays()`
- Line 161-162: `startOfDayUTC` in `calculateDailyCompletionRate()`
- Line 189-190: `startOfDayUTC` in `calculateDaysOfWeekCompletionRate()`
- Line 193: `weekdayComponentUTC` in `calculateDaysOfWeekCompletionRate()`
- Line 215-216: `startOfDayUTC` in `calculateExpectedDaysForSchedule()`
- Line 219: `weekdayComponentUTC` in `calculateExpectedDaysForSchedule()`

**Impact:**
- ❌ Completion rates calculated wrong
- ❌ Expected days count wrong
- ❌ Daily completion rate wrong
- ❌ Days of week completion rate wrong

**Real-world scenario:**
```
Habit scheduled for Mon/Wed/Fri, user in GMT+8
├─ Tuesday midnight local = Monday 4 PM UTC
├─ Completion calculator counts Tuesday log as Monday
└─ RESULT: Completion rate artificially inflated!
```

#### **3. PerformanceAnalysisService.swift (8 UTC usages)**

**File**: `RitualistCore/Sources/RitualistCore/Services/PerformanceAnalysisService.swift`

**Lines with issues:**
- Line 131, 142: `startOfDayUTC` in `analyzeWeeklyPatterns()`
- Line 143: `weekdayComponentUTC` in `analyzeWeeklyPatterns()`
- Line 219, 225, 227: `startOfDayUTC` in `calculatePerfectDayStreak()`
- Line 259: `daysBetweenUTC` in `calculatePerfectDayStreak()`
- Line 344: `weekdayComponentUTC` in `getDayCount()`

**Impact:**
- ❌ Weekly patterns analysis wrong
- ❌ Best/worst day calculations wrong
- ❌ Perfect day streak wrong
- ❌ Category performance aggregation wrong

**Real-world scenario:**
```
Analysis shows "Monday is your best day" but user is in GMT+10
├─ What looks like Monday UTC is actually Tuesday local
├─ User gets wrong insights about their behavior
└─ RESULT: Misleading personality/performance analysis!
```

#### **Cumulative Impact**

**For users in non-UTC timezones, ALL of these are broken:**

1. ✅ Habit scheduling - FIXED TODAY
2. ❌ Streak counting - BROKEN
3. ❌ Completion rates - BROKEN
4. ❌ Performance analytics - BROKEN
5. ❌ Weekly patterns - BROKEN
6. ❌ Personality insights (depends on completion rates) - INDIRECTLY BROKEN
7. ❌ Smart insights (depends on patterns) - INDIRECTLY BROKEN

#### **Root Cause**

Looking at code comments in `StreakCalculationService.swift:53`:
```swift
// Using CalendarUtils for UTC-based business logic consistency
```

The original architecture decision was "Use UTC for all business logic", which is **wrong for habit tracking** because:
- Habits are tied to user's daily routine (LOCAL time)
- Streaks are about consecutive LOCAL days
- "Monday" means Monday in user's life, not Monday UTC

#### **Fix Strategy**

**Required Changes:**

1. **Add/verify LOCAL helper methods in CalendarUtils:**
   - ✅ `weekdayComponentLocal()` - Already exists
   - ✅ `startOfDayLocal()` - Already exists
   - ✅ `areSameDayLocal()` - Already exists
   - ❓ `daysBetweenLocal()` - Need to verify/create
   - ❓ `weekIntervalLocal()` - Need to verify/create

2. **Systematic replacement across all services:**
   - `startOfDayUTC` → `startOfDayLocal`
   - `weekdayComponentUTC` → `weekdayComponentLocal`
   - `daysBetweenUTC` → `daysBetweenLocal`
   - `weekIntervalUTC` → `weekIntervalLocal`
   - `areSameDayUTC` → `areSameDayLocal`

3. **Test edge cases:**
   - User at midnight local time
   - User near date line (GMT+12, GMT-11)
   - DST transitions
   - Retroactive habit logging

**Estimated Effort:**

| Task | Time | Priority |
|------|------|----------|
| Verify/create LOCAL helper methods | 30 min | 🔴 P0 |
| Fix StreakCalculationService | 45 min | 🔴 P0 |
| Fix ScheduleAwareCompletionCalculator | 45 min | 🔴 P0 |
| Fix PerformanceAnalysisService | 30 min | 🔴 P0 |
| Test & validate | 60 min | 🔴 P0 |
| **TOTAL** | **3.5 hours** | |

### 📋 Future Enhancements

**Timezone Change Detection** (See Recommendation #5 above):
- Phase 1: Auto-detect timezone changes on launch
- Phase 2: Show user-friendly notice with options
- Phase 3: Travel mode and timezone history

## Testing Checklist

- [x] Habit scheduled for "Mon/Wed/Fri" appears only on those days (local) ✅
- [ ] Midnight local time is day boundary (not midnight UTC)
- [ ] User can log multiple habits before/after midnight local
- [ ] Day navigation shows correct local dates
- [ ] Display settings only affect historical log display, not scheduling

## Conclusion

**For Ritualist (a habit tracking app):**

✅ **Use LOCAL timezone for all business logic**
✅ **Optionally store timezone context for display**
✅ **Accept rare edge cases (date line crossing)**
✅ **Prioritize user experience over theoretical purity**

**The fix we just made is correct.** The bug was caused by inconsistency (mixing UTC and local), not by using local timezone.

**Key Principle**: "A habit scheduled for Monday means Monday in the user's life, not Monday UTC."

---

## Appendix: Previous Approach

An earlier version (`timezone-fix-OLD.md`) advocated UTC-based business logic. This was **reconsidered** based on:

1. **Industry research**: Top habit apps use local timezone for scheduling
2. **User experience**: Intuitive behavior trumps theoretical purity
3. **Root cause**: Bug was from inconsistency, not timezone choice

The comprehensive implementation details from that document remain valuable, but the core strategy has been updated to LOCAL-first.
