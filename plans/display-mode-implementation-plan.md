# Display Mode Feature - Investigation & Implementation Plan

**Status:** Infrastructure Complete, Not Yet Implemented
**Priority:** Future Enhancement
**Created:** 2025-11-14

---

## Executive Summary

The **Display Mode** setting exists in the app's Advanced Settings but is **not currently functional**. All infrastructure is in place (UI, data model, storage, helper methods), but nothing actually uses it to change how timestamps are displayed in the app.

This is a **prepared feature** ready to be activated when timezone-aware timestamp display becomes a requirement.

---

## Current Status: NOT IMPLEMENTED ❌

### What Exists ✅

1. **UI Setting**
   - Location: Settings → Advanced → Display Mode
   - Options: "Original Time" | "Current Time"
   - File: `AdvancedSettingsView.swift:13-23`
   - Fully functional picker with live updates

2. **Data Model**
   - Field: `UserProfile.displayTimezoneMode: String`
   - Values: `"original"`, `"current"`, `"home"`
   - Default: `"original"`
   - Persisted to SwiftData + synced to iCloud

3. **Supporting Infrastructure**
   ```swift
   // CalendarUtils.swift:14-18
   public enum DisplayTimezoneMode: String, CaseIterable {
       case original  // Show times as originally experienced
       case current   // Show times in user's current timezone
       case home      // Show times in designated home timezone
   }

   // CalendarUtils.swift:415-430
   public static func formatLogEntry(
       _ utcTimestamp: Date,
       _ originalTimezone: String,
       displayMode: DisplayTimezoneMode,
       userTimezone: TimeZone = .current,
       homeTimezone: TimeZone? = nil
   ) -> String
   ```

4. **Debug Visibility**
   - Debug Menu shows current setting value
   - Location: `DebugMenuView.swift:426-431`

### What's Missing ❌

1. **No Usage in Business Logic**
   - `formatLogEntry()` method is defined but **never called**
   - `DisplayTimezoneMode` enum is **never instantiated**
   - No code reads `profile.displayTimezoneMode` to make display decisions

2. **No Usage in UI**
   - Habit detail views don't use it
   - Habit log displays don't use it
   - Completion timestamps don't use it
   - Calendar views don't use it
   - Analytics screens don't use it

3. **No Conversion Layer**
   - String value from `UserProfile` never converted to `DisplayTimezoneMode` enum
   - No service connects user preference to formatting logic

---

## Use Case: Why This Feature Matters

### Scenario: Traveling User

**Situation:**
- User logs a workout at **7:00 AM in Paris** (CET timezone)
- User travels to **New York** (EST timezone)
- User views habit history in app

**With Display Mode (Future Behavior):**

| Mode | Display | Explanation |
|------|---------|-------------|
| **Original** | `7:00 AM` | Shows time as originally experienced |
| **Current** | `1:00 AM (was 7:00 AM CET)` | Converts to current timezone with context |
| **Home** | `7:00 AM` | Shows in designated home timezone (if set) |

**Current Behavior:**
- Just shows timestamp in current device timezone
- No context about original timezone
- Can be confusing for frequent travelers

---

## Implementation Plan

### Phase 1: Basic Infrastructure (MVP)

#### Step 1: Create Conversion Service
**File:** New `DisplayModeService.swift`

```swift
import RitualistCore

public struct DisplayModeService {
    private let profile: UserProfile

    public init(profile: UserProfile) {
        self.profile = profile
    }

    public func getDisplayMode() -> DisplayTimezoneMode {
        DisplayTimezoneMode(rawValue: profile.displayTimezoneMode) ?? .original
    }

    public func formatTimestamp(_ date: Date, originalTimezone: String) -> String {
        let displayMode = getDisplayMode()
        return CalendarUtils.formatLogEntry(
            date,
            originalTimezone,
            displayMode: displayMode,
            homeTimezone: homeTimezoneIfSet()
        )
    }

    private func homeTimezoneIfSet() -> TimeZone? {
        guard let homeTimezoneId = profile.homeTimezone,
              let timezone = TimeZone(identifier: homeTimezoneId) else {
            return nil
        }
        return timezone
    }
}
```

#### Step 2: Wire Up Habit Log Display
**Files to Modify:**
- `NumericHabitLogSheet.swift`
- Any view showing `HabitLog.completedAt`

**Before (current code):**
```swift
Text(log.completedAt.formatted())
```

**After (with Display Mode):**
```swift
Text(displayModeService.formatTimestamp(
    log.completedAt,
    originalTimezone: log.completionTimezone
))
```

#### Step 3: Update Habit Detail Views
**Files to Modify:**
- Habit history views
- Completion timestamp displays
- Any calendar-based views

**Pattern:**
```swift
// Inject service
@Injected(\.displayModeService) var displayModeService

// Use in view
Text(displayModeService.formatTimestamp(
    timestamp,
    originalTimezone: originalTz
))
```

---

### Phase 2: Enhanced Features

#### Feature 1: Add "Home Timezone" Option

**UI Update:** `AdvancedSettingsView.swift`
```swift
Section("Time Display") {
    // Existing Display Mode picker
    Picker("Display Mode", selection: $displayTimezoneMode) {
        Text("Original Time").tag("original")
        Text("Current Time").tag("current")
        Text("Home Time").tag("home")  // NEW
    }

    // NEW: Home timezone picker
    if displayTimezoneMode == "home" {
        Picker("Home Timezone", selection: $homeTimezone) {
            ForEach(TimeZone.knownTimeZoneIdentifiers, id: \.self) { tz in
                Text(tz).tag(tz)
            }
        }
    }
}
```

#### Feature 2: Visual Timezone Indicators

Add icon badges to show timezone context:

```swift
HStack {
    if isInDifferentTimezone {
        Image(systemName: "globe")
            .font(.caption)
            .foregroundColor(.secondary)
    }
    Text(formattedTime)
}
```

#### Feature 3: Timezone Context Sheet

Show detailed timezone info on tap:
```swift
.sheet(isPresented: $showingTimezoneDetails) {
    TimezoneContextView(
        originalTime: log.completedAt,
        originalTimezone: log.completionTimezone,
        currentTimezone: TimeZone.current
    )
}
```

---

### Phase 3: Analytics & Insights

#### Update Analytics Views
- **Streak calculations:** Already timezone-aware via `CalendarUtils`
- **Charts:** Add timezone context to data points
- **Export:** Include timezone information in CSV

#### Personality Analysis
- Update timestamp displays in personality insights
- Show habit patterns across timezones

---

## Technical Details

### Files to Modify

| File | Change | Priority |
|------|--------|----------|
| **New:** `DisplayModeService.swift` | Create conversion service | High |
| `Container+Services.swift` | Register DI for DisplayModeService | High |
| `NumericHabitLogSheet.swift` | Wire up formatted timestamps | High |
| Habit detail views | Update timestamp displays | Medium |
| `AdvancedSettingsView.swift` | Add "Home" option + timezone picker | Medium |
| Analytics screens | Format historical data | Low |
| Export features | Include timezone metadata | Low |

### Data Flow

```
User Setting (UserProfile.displayTimezoneMode: String)
    ↓
DisplayModeService.getDisplayMode() → DisplayTimezoneMode enum
    ↓
CalendarUtils.formatLogEntry() → Formatted string
    ↓
UI Display (Text view with formatted timestamp)
```

### Migration Strategy

1. **No database migration needed** - Field already exists
2. **Backward compatible** - Defaults to "original" mode
3. **Gradual rollout** - Update views one at a time
4. **Feature flag optional** - Could gate behind build config if desired

---

## Testing Plan

### Unit Tests
```swift
func testDisplayModeOriginal() {
    let service = DisplayModeService(profile: profileWithMode("original"))
    let formatted = service.formatTimestamp(testDate, originalTimezone: "Europe/Paris")
    XCTAssertEqual(formatted, "7:00 AM")
}

func testDisplayModeCurrent() {
    let service = DisplayModeService(profile: profileWithMode("current"))
    let formatted = service.formatTimestamp(testDate, originalTimezone: "Europe/Paris")
    XCTAssertTrue(formatted.contains("was"))  // Context indicator
}
```

### Manual Testing Checklist
- [ ] Change Display Mode in Settings
- [ ] Verify habit logs show correct timestamps
- [ ] Travel to different timezone (or simulate)
- [ ] Verify "Current" mode shows converted times
- [ ] Verify "Original" mode shows as-logged times
- [ ] Test with "Home" timezone set
- [ ] Export data and verify timezone metadata

---

## Performance Considerations

- **Minimal impact** - Formatting happens on-demand during render
- **No database queries** - UserProfile already loaded in memory
- **Caching opportunity** - Could cache formatted strings if needed
- **Calendar access** - `TimeZone` lookups are fast (system cache)

---

## User Experience Notes

### When to Show Timezone Context

**Always Show:**
- When user is in different timezone than when log was created
- In "Current" display mode

**Never Show:**
- In "Original" mode (show as-is)
- When timezones match (no need for context)

### Visual Design

**Subtle Context:**
```
Completed at 7:00 AM
```

**With Context (different timezone):**
```
Completed at 1:00 AM (was 7:00 AM CET)
```

**Alternative (icon-based):**
```
🌍 Completed at 1:00 AM · Originally 7:00 AM
```

---

## Dependencies & Prerequisites

### Required
- ✅ `UserProfile.displayTimezoneMode` field (exists)
- ✅ `DisplayTimezoneMode` enum (exists)
- ✅ `CalendarUtils.formatLogEntry()` (exists)
- ✅ `HabitLog.completionTimezone` field (exists)

### Optional (Future)
- Home timezone picker UI
- Timezone search/filter functionality
- User education (tooltip/onboarding)

---

## Alternatives Considered

### Option 1: Always Show Both Times
**Pros:** Maximum information
**Cons:** Cluttered UI, confusing for non-travelers

### Option 2: Auto-Detect Based on Location
**Pros:** Zero configuration
**Cons:** Privacy concerns, battery drain, complexity

### Option 3: Smart Context (Chosen Approach)
**Pros:** User control, clear intent, flexible
**Cons:** Requires implementation effort

---

## Success Metrics

Once implemented, track:
- **Adoption Rate:** % of users who change from "original" mode
- **Mode Distribution:** original vs current vs home usage
- **User Feedback:** Support tickets about timezone confusion
- **Engagement:** Time spent viewing habit history

---

## Related Features

- **Timezone Diagnostics** (Debug Menu) - Already exists
- **Location-Aware Habits** - Could integrate with this
- **Calendar Integration** - Would need timezone awareness
- **Multi-Device Sync** - Already handles timezone via iCloud

---

## Implementation Estimate

| Phase | Effort | Timeline |
|-------|--------|----------|
| **Phase 1: MVP** | 4-6 hours | 1-2 days |
| **Phase 2: Enhanced** | 6-8 hours | 2-3 days |
| **Phase 3: Analytics** | 4-6 hours | 1-2 days |
| **Testing & Polish** | 4-6 hours | 1-2 days |
| **Total** | 18-26 hours | 5-9 days |

---

## Conclusion

The Display Mode feature is **architecturally complete** but **functionally dormant**. All the hard work (data modeling, storage, sync, helper methods) is done. What remains is:

1. Creating a conversion service (2 hours)
2. Wiring up UI components (4-8 hours)
3. Testing across timezones (2-4 hours)

**Recommendation:** Implement when user feedback indicates timezone confusion is a pain point, or when planning a "travelers & nomads" marketing push.

---

## References

### Key Files
- `UserProfile.swift` - Data model
- `CalendarUtils.swift` - Formatting utilities
- `AdvancedSettingsView.swift` - Settings UI
- `DebugMenuView.swift` - Debug visibility

### Related Documentation
- [Timezone Architecture](../docs/timezone-architecture.md) (if exists)
- [SwiftData Migration Guide](../docs/swiftdata-migrations.md) (if exists)

### External Resources
- [Apple HIG: Date and Time](https://developer.apple.com/design/human-interface-guidelines/date-and-time)
- [Working with TimeZones in Swift](https://www.swiftbysundell.com/articles/working-with-time-zones/)
