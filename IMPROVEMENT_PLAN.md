# Ritualist Codebase Improvement Plan

**Date:** January 8, 2026
**Branch:** feature/ux-enhancements-batch
**Status:** Pending Approval

---

## Executive Summary

Analysis of the entire Ritualist codebase for deferred/intention patterns, TipKit issues, and other improvement opportunities. This document outlines findings organized by priority and impact.

---

## Critical Issues

### Issue 1: TipKit Chain Breaking - CircleProgressTip Never Shows

**Files Affected:**
- `Ritualist/Features/Shared/Presentation/HabitTips.swift`
- `Ritualist/Features/Overview/Presentation/Cards/TodaysSummaryCard.swift`

**Problem:**
The 4th tip (`CircleProgressTip`) requires `longPressTipDismissed` event to be donated, but this event is never donated anywhere in the codebase.

**Tip Chain Analysis:**
1. `TapHabitTip` - triggers on `habitsAssistantClosed` + `firstHabitAdded`
2. `TapCompletedHabitTip` - triggers on `firstHabitCompleted`, donates `shouldShowLongPressTip` on "Got it"
3. `LongPressLogTip` - triggers on `shouldShowLongPressTip`, donates `wasDismissed` on "Got it"
4. `CircleProgressTip` - triggers on `longPressTipDismissed` - **NEVER DONATED**

**Root Cause:**
The `LongPressLogTip` donates to `LongPressLogTip.wasDismissed` but `CircleProgressTip` listens for `CircleProgressTip.longPressTipDismissed`. These are different event instances with different namespaces.

**Recommended Fix:**
In the `LongPressLogTip` "Got it" action handler, also donate the `CircleProgressTip.longPressTipDismissed` event to properly chain to the 4th tip.

---

### Issue 2: Duplicate LongPressLogTip Display

**File:** `Ritualist/Features/Overview/Presentation/Cards/TodaysSummaryCard.swift:615-670`

**Problem:**
`LongPressLogTip` is displayed in both:
- Incomplete habits section (lines 615-626)
- Completed habits section (lines 664-670)

If user has habits in both sections, the tip could appear twice in quick succession.

**Recommended Fix:**
Only show `LongPressLogTip` in the incomplete section where user would actually perform a long-press to complete a habit.

---

## Medium Priority Issues

### Issue 3: MigrationStatusService Singleton in @State

**File:** `Ritualist/Application/RootTabView.swift:21`

**Current Code:**
```swift
@State private var migrationService = MigrationStatusService.shared
```

**Problem:**
Storing an `@Observable` singleton in `@State` creates duplicate state ownership. The singleton already manages its own state, and wrapping it in `@State` can cause observation issues.

**Recommended Fix:**
```swift
private let migrationService = MigrationStatusService.shared
```

---

### Issue 4: Missing Tracking Call in removeHabit

**File:** `Ritualist/Features/Shared/Presentation/HabitsAssistant/HabitsAssistantSheetViewModel.swift:370-376`

**Problem:**
`trackHabitRemoved(habitId:habitName:category:)` method is defined but never called when a habit is removed via `removeHabit()`.

**Current removeHabit success path (lines 313-322):**
```swift
if success {
    addedSuggestionIds.remove(suggestionId)
    suggestionToHabitMappings.removeValue(forKey: suggestionId)
    logger.log(...)
    await refreshLimitStatus()
    return true
}
```

**Recommended Fix:**
Add tracking call in the success path of `removeHabit()`. Need to look up suggestion details to get habitName and category.

---

## Low Priority Improvements

### Improvement 1: Animation Timing Consistency

**File:** `Ritualist/Features/Overview/Presentation/Cards/TodaysSummaryCard.swift`

**Current State:**
Animation timing constants are well-defined in `AnimationTiming` enum (lines 62-68), but some `Task.sleep` calls use raw nanoseconds instead of the enum values.

**Recommended Fix:**
Audit all `Task.sleep` calls and ensure they use `AnimationTiming` constants for consistency and maintainability.

---

### Improvement 2: Task Cancellation Safety on Appear

**File:** `Ritualist/Features/Overview/Presentation/Cards/TodaysSummaryCard.swift`

**Current State:**
`cancelAllAnimationTasks()` is called in `onDisappear` (line 249), but if view reappears quickly while tasks were mid-flight, state could be inconsistent.

**Recommended Fix:**
Also call `cancelAllAnimationTasks()` at the start of `onAppear` to ensure clean state when view appears.

---

## Patterns Reviewed - No Changes Needed

These patterns were analyzed and determined to be well-implemented:

### Pattern 1: Pending Notification Habit Processing
**File:** `OverviewViewModel.swift:34-42`

Uses `pendingNumericHabitFromNotification` and `pendingBinaryHabitFromNotification` with processing flags. This is necessary for async notification handling and is correctly implemented.

### Pattern 2: Sheet Dismiss-Then-Reshow Choreography
**File:** `RootTabView.swift:18-29, 130-377`

Uses 4 boolean flags for sheet choreography. This works around SwiftUI's single-sheet limitation and is correctly implemented with proper state management.

### Pattern 3: Paywall Dismiss-Reopen Assistant
**Files:** `HabitsAssistantSheet.swift:101-186`, `HabitsViewModel.swift:46-49`

Uses Task delays (500ms, 1000ms) for animation timing with proper task cancellation. Well-implemented pattern.

### Pattern 4: Animation Tasks with Sleep
**File:** `TodaysSummaryCard.swift`

Animation tasks use `@State` references for proper cancellation. Well-implemented with `cancelAllAnimationTasks()` cleanup.

---

## Summary Table

| Priority | Issue | File(s) | Action |
|----------|-------|---------|--------|
| Critical | CircleProgressTip never shows | HabitTips.swift, TodaysSummaryCard.swift | Add missing `longPressTipDismissed` donation |
| Critical | Duplicate LongPressLogTip | TodaysSummaryCard.swift | Remove from completed section |
| Medium | Singleton in @State | RootTabView.swift | Change `@State private var` to `private let` |
| Medium | Missing tracking call | HabitsAssistantSheetViewModel.swift | Add `trackHabitRemoved` call in success path |
| Low | Animation timing consistency | TodaysSummaryCard.swift | Use `AnimationTiming` enum everywhere |
| Low | Task cancellation safety | TodaysSummaryCard.swift | Add `cancelAllAnimationTasks()` in `onAppear` |

---

## Implementation Order

Recommended order of implementation:

1. **Fix TipKit chain** (Critical) - Enables all 4 tips to show properly
2. **Remove duplicate tip display** (Critical) - Prevents confusing UX
3. **Fix singleton @State** (Medium) - Improves state management correctness
4. **Add missing tracking** (Medium) - Completes analytics coverage
5. **Animation timing cleanup** (Low) - Code quality improvement
6. **Task cancellation safety** (Low) - Edge case protection

---

## Approval

- [ ] Approved by: _______________
- [ ] Date: _______________
- [ ] Notes: _______________
