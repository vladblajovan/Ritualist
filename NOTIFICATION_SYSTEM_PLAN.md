# Unified Notification Scheduling System

## Problem Summary

### Issue 1: Inconsistent Badge Numbering
Two scheduling paths cause inconsistent badge numbering:

| Path | Trigger | Badge Logic | Issue |
|------|---------|-------------|-------|
| `ScheduleHabitReminders` UseCase | Habit create/edit | `deliveredCount + 1` | Ignores other habits' positions |
| `DailyNotificationSchedulerService` | App launch/resume | Time-sorted, starts at 1 | ✅ Correct |

**Result:** User saw badge=3 on first notification because 2 delivered notifications existed when individual scheduling ran.

### Issue 2: Location Notifications Bugs
| Bug | Description |
|-----|-------------|
| 🐛 Not cancelled on completion | `cancel()` doesn't match `"{uuid}-location-"` pattern |
| 🐛 Not tracked in fired notifications | `syncFiredNotificationsFromDelivered()` misses them |

### What's Working Correctly
- **Personality notifications:** Properly excluded from badge (don't set badge, filtered out)
- **Location notifications:** Properly counted in badge (have `habitId` in userInfo)

## Solution

Route ALL habit notification scheduling through `DailyNotificationSchedulerService` as single source of truth.

## Implementation Plan

### Step 1: Modify `ScheduleHabitReminders` UseCase

**File:** `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Notifications/NotificationUseCases.swift`

Change from direct scheduling to triggering bulk reschedule:

```swift
public final class ScheduleHabitReminders: ScheduleHabitRemindersUseCase {
    private let dailyNotificationScheduler: DailyNotificationSchedulerService
    private let notificationService: NotificationService
    private let logger: DebugLogger

    public func execute(habit: Habit) async throws {
        // Cancel this habit's notifications immediately (for deleted reminders)
        await notificationService.cancel(for: habit.id)

        // Trigger full reschedule for correct badge ordering
        try await dailyNotificationScheduler.rescheduleAllHabitNotifications()
    }
}
```

### Step 2: Update DI Container for ScheduleHabitReminders

**File:** `Ritualist/DI/Container+NotificationUseCases.swift`

Update factory to inject `dailyNotificationScheduler` instead of individual dependencies.

### Step 3: Enhance DailyNotificationSchedulerService for Rich Notifications

**File:** `RitualistCore/Sources/RitualistCore/Services/DailyNotificationSchedulerService.swift`

Add support for personality-tailored and rich notifications:

1. Add dependencies:
   - `GetPersonalityProfileUseCase`
   - `CategoryRepository`
   - `LogRepository`
   - `CalculateCurrentStreakUseCase`

2. Add notification type selection:
```swift
private func scheduleNotificationWithAppropriateType(
    habit: Habit,
    time: ReminderTime,
    badgeNumber: Int,
    personalityProfile: PersonalityProfile?,
    categoryName: String?,
    currentStreak: Int
) async throws {
    if let profile = personalityProfile,
       PersonalityTailoredNotificationContentGenerator.hasRecentAnalysis(profile) {
        // Use personality-tailored
        try await notificationService.schedulePersonalityTailoredReminders(...)
    } else {
        // Use rich notifications
        try await notificationService.scheduleRichReminders(...)
    }
}
```

3. Modify `rescheduleAllHabitNotifications()` to:
   - Fetch user's personality profile
   - Preload categories for category names
   - Calculate streaks for each habit
   - Call `scheduleNotificationWithAppropriateType()` instead of `scheduleSingleNotification()`

### Step 4: Update DI Container for DailyNotificationScheduler

**File:** `Ritualist/DI/Container+Services.swift`

Add new dependencies to the factory.

### Step 5: Clean Up NotificationService

**File:** `RitualistCore/Sources/RitualistCore/Services/NotificationService.swift`

- Mark `scheduleWithActions()` as deprecated or remove (no longer needed)
- Keep `scheduleRichReminders()` and `schedulePersonalityTailoredReminders()` (used by bulk scheduler)
- Update these methods to accept `badgeNumber` parameter for consistency

### Step 6: Fix Badge Parameter in Rich/Tailored Methods

Both `scheduleRichReminders()` and `schedulePersonalityTailoredReminders()` need to accept badge number from caller instead of calculating internally (already partially done, but needs cleanup).

### Step 7: Fix Location Notification Cancellation Bug

**File:** `RitualistCore/Sources/RitualistCore/Services/NotificationService.swift`

In `cancel(for habitID:)` method, add location notification pattern to the filter:

```swift
// Current (missing location):
let ids = pending.map { $0.identifier }.filter { id in
    id.hasPrefix(prefix) ||
    id.hasPrefix("rich_\(prefix)") ||
    id.hasPrefix("tailored_\(prefix)") ||
    id.hasPrefix("today_\(prefix)") ||
    id.hasPrefix("streak_milestone_\(prefix)")
}

// Fixed (add location):
let ids = pending.map { $0.identifier }.filter { id in
    id.hasPrefix(prefix) ||
    id.hasPrefix("rich_\(prefix)") ||
    id.hasPrefix("tailored_\(prefix)") ||
    id.hasPrefix("today_\(prefix)") ||
    id.hasPrefix("streak_milestone_\(prefix)") ||
    id.contains("-location-") && id.hasPrefix(prefix)  // Location notifications
}
```

Also update the verification logging that checks remaining notifications.

### Step 8: Fix Location Notification Tracking

**File:** `RitualistCore/Sources/RitualistCore/Services/NotificationService.swift`

In `syncFiredNotificationsFromDelivered()`, add location notification tracking:

```swift
// Current:
if id.hasPrefix("today_") || id.hasPrefix("rich_") || id.hasPrefix("tailored_") {
    markNotificationFired(notificationId: id)
}

// Fixed:
if id.hasPrefix("today_") || id.hasPrefix("rich_") || id.hasPrefix("tailored_") || id.contains("-location-") {
    markNotificationFired(notificationId: id)
}
```

## Files to Modify

| File | Change |
|------|--------|
| `RitualistCore/.../NotificationUseCases.swift` | Redirect `ScheduleHabitReminders` to bulk scheduler |
| `RitualistCore/.../DailyNotificationSchedulerService.swift` | Add personality profile, categories, streaks; use rich/tailored notifications |
| `Ritualist/DI/Container+NotificationUseCases.swift` | Update DI for `ScheduleHabitReminders` |
| `Ritualist/DI/Container+Services.swift` | Update DI for `DailyNotificationScheduler` |
| `RitualistCore/.../NotificationService.swift` | Deprecate `scheduleWithActions()`, fix location cancellation, fix location tracking |

## Badge Flow After Changes

```
User saves habit
    ↓
ScheduleHabitReminders.execute()
    ↓
dailyNotificationScheduler.rescheduleAllHabitNotifications()
    ↓
1. Clear all existing habit notifications
2. Fetch ALL active habits with reminders
3. Fetch personality profile (for tailored notifications)
4. Sort by (hour, minute, secondOffset)
5. Limit to 54 slots (iOS 64 limit - 10 reserved)
6. For each notification in time order:
   - Check if habit completed today
   - Assign badge = nextBadgeNumber++
   - Schedule with personality-tailored OR rich content
7. Update app badge count
```

## Verification

### Badge Consistency Test
1. Create habit with 3 reminders 1 minute apart
2. Put app in background
3. Wait for notifications
4. Verify badges show 1, 2, 3 (not 3, 4, 5)
5. Verify notification content is rich (shows streak, category context)

### Location Notification Cancellation Test
1. Create habit with location trigger
2. Trigger location notification (enter geofence or simulate)
3. Complete the habit
4. Verify location notification is removed from notification center

### Automated Tests
- Run `DailyNotificationSchedulerServiceTests`
- Verify tests still pass after changes
