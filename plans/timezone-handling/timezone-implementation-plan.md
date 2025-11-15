# Timezone Handling Implementation Plan

**Branch:** `feature/timezone-handling`
**Status:** Planning Phase
**Created:** 2025-11-15

## Executive Summary

Implement comprehensive timezone handling to support global users who:
- Travel across timezones
- Experience Daylight Saving Time transitions
- Want to maintain consistent habit tracking regardless of location
- Need accurate historical data display when timezone changes

## Problem Statement

### Current Behavior (Issues Identified by Tests)
1. **No Home Timezone Concept**: App uses device's current timezone without user preference
2. **Timezone Change Issues**: When user travels, habit completion dates may shift
3. **DST Transitions**: Daylight Saving Time changes can cause data display inconsistencies
4. **Late-Night Logging**: Logging at 11:30 PM may count for wrong day if timezone handling is naive
5. **Historical Data**: Past completions may show incorrect dates when timezone changes

### User Scenarios
1. **Traveler**: User in New York travels to Tokyo
   - Logs habit at 11 PM Tokyo time
   - Should count for the correct day in their "home" timezone

2. **DST Transition**: User experiences Daylight Saving Time change
   - Spring forward: 2 AM becomes 3 AM (lose 1 hour)
   - Fall back: 2 AM becomes 1 AM (gain 1 hour)
   - Habit data should remain consistent

3. **Permanent Move**: User permanently relocates
   - Historical data should remain accurate
   - Future tracking uses new timezone
   - Clear transition point

## Requirements

### Functional Requirements
1. **FR-1**: User can set a "home timezone" preference
2. **FR-2**: App detects when device timezone differs from home timezone
3. **FR-3**: App shows notification when timezone mismatch detected
4. **FR-4**: User can update home timezone (confirm dialog for permanent moves)
5. **FR-5**: Habit completion dates are calculated relative to home timezone
6. **FR-6**: Historical data remains correct when timezone changes
7. **FR-7**: App handles DST transitions automatically
8. **FR-8**: Late-night logging (e.g., 11:30 PM) counts for correct day
9. **FR-9**: Streak calculations work correctly across timezone changes
10. **FR-10**: Calendar view shows correct completion status across timezones

### Non-Functional Requirements
1. **NFR-1**: Zero data loss during timezone transitions
2. **NFR-2**: Backward compatible with existing data (no migration needed)
3. **NFR-3**: Performance: Timezone calculations add < 10ms overhead
4. **NFR-4**: User experience: Timezone changes require explicit confirmation
5. **NFR-5**: Testing: All 73 tests pass (including timezone edge cases)

## Architecture Design

### Data Model Changes

#### 1. User Profile Enhancement
```swift
// RitualistCore/Sources/RitualistCore/Models/UserProfile.swift
struct UserProfile {
    // ... existing fields

    // NEW: Home timezone (where user primarily lives)
    var homeTimezoneIdentifier: String  // e.g., "America/New_York"

    // NEW: Last known device timezone (for detecting changes)
    var lastKnownTimezoneIdentifier: String?

    // NEW: Timezone change history (for auditing)
    var timezoneChangeHistory: [TimezoneChange] = []
}

struct TimezoneChange: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let fromTimezone: String
    let toTimezone: String
    let reason: TimezoneChangeReason
}

enum TimezoneChangeReason: String, Codable {
    case initialSetup       // First time user sets timezone
    case userUpdated        // User manually changed
    case permanentMove      // User confirmed moving permanently
    case travel             // Temporary travel (not implemented in v1)
}
```

#### 2. SwiftData Schema Update
```swift
// Add to ActiveUserProfileModel (SchemaV9)
@Model
final class ActiveUserProfileModel {
    // ... existing properties

    @Attribute(.unique) var homeTimezoneIdentifier: String
    var lastKnownTimezoneIdentifier: String?
    @Relationship(deleteRule: .cascade) var timezoneChanges: [TimezoneChangeModel] = []
}

@Model
final class TimezoneChangeModel {
    var id: UUID
    var timestamp: Date
    var fromTimezone: String
    var toTimezone: String
    var reasonRaw: String  // TimezoneChangeReason.rawValue
}
```

### Service Layer Changes

#### 1. TimezoneService (NEW)
```swift
protocol TimezoneService {
    /// Get user's home timezone
    func getHomeTimezone() -> TimeZone

    /// Update home timezone (prompts confirmation dialog)
    func updateHomeTimezone(_ timezone: TimeZone, reason: TimezoneChangeReason) async throws

    /// Detect if device timezone differs from home timezone
    func detectTimezoneMismatch() -> TimezoneMismatch?

    /// Get timezone to use for date calculations
    func getTimezoneForDateCalculations() -> TimeZone
}

struct TimezoneMismatch {
    let homeTimezone: TimeZone
    let deviceTimezone: TimeZone
    let detectedAt: Date
}
```

#### 2. CalendarUtils Enhancement
```swift
// Add timezone-aware methods
extension CalendarUtils {
    /// Start of day in user's home timezone
    static func startOfDayInHomeTimezone(for date: Date) -> Date

    /// Is date today in user's home timezone?
    static func isTodayInHomeTimezone(_ date: Date) -> Bool

    /// Days between in user's home timezone
    static func daysBetweenInHomeTimezone(_ start: Date, _ end: Date) -> Int
}
```

#### 3. HabitCompletionService Enhancement
```swift
// Use home timezone for completion calculations
class DefaultHabitCompletionService: HabitCompletionService {
    private let timezoneService: TimezoneService

    func getCompletionStatus(for habit: Habit, on date: Date) async throws -> CompletionStatus {
        let homeTimezone = timezoneService.getHomeTimezone()
        // Use homeTimezone for all date calculations
    }
}
```

### UI Changes

#### 1. Onboarding: Timezone Selection
```swift
// New onboarding step: Select home timezone
struct TimezoneSelectionView: View {
    @State private var selectedTimezone: TimeZone = .current
    @State private var searchText: String = ""

    var body: some View {
        List {
            // Common timezones at top
            Section("Common Timezones") {
                ForEach(CommonTimezones.list) { timezone in
                    TimezoneRow(timezone: timezone, isSelected: selectedTimezone == timezone)
                }
            }

            // All timezones (searchable)
            Section("All Timezones") {
                ForEach(filteredTimezones) { timezone in
                    TimezoneRow(timezone: timezone, isSelected: selectedTimezone == timezone)
                }
            }
        }
        .searchable(text: $searchText)
    }
}
```

#### 2. Settings: Timezone Management
```swift
// Settings > Timezone
struct TimezoneSettingsView: View {
    @State private var showingChangeDialog = false
    @State private var newTimezone: TimeZone?

    var body: some View {
        Form {
            Section("Current Timezone") {
                LabeledContent("Home Timezone", value: userProfile.homeTimezone.identifier)
                LabeledContent("Device Timezone", value: TimeZone.current.identifier)

                if timezoneMismatch {
                    Label("Timezone Mismatch Detected", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                }
            }

            Section {
                Button("Update Home Timezone") {
                    showingChangeDialog = true
                }
            }

            Section("Timezone Change History") {
                ForEach(userProfile.timezoneChangeHistory) { change in
                    TimezoneChangeRow(change: change)
                }
            }
        }
        .confirmationDialog("Change Home Timezone?", isPresented: $showingChangeDialog) {
            Button("Permanent Move") {
                // Update timezone with .permanentMove reason
            }
            Button("Temporary Change") {
                // Update timezone with .userUpdated reason
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you permanently moving, or is this a temporary change?")
        }
    }
}
```

#### 3. Dashboard: Timezone Indicator
```swift
// Show timezone indicator if mismatch detected
struct TimezoneIndicatorBanner: View {
    let mismatch: TimezoneMismatch

    var body: some View {
        HStack {
            Image(systemName: "globe")
            Text("You're in \(mismatch.deviceTimezone.identifier)")
            Spacer()
            Button("Update") {
                // Navigate to timezone settings
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}
```

## Implementation Plan

### Phase 1: Core Infrastructure (Week 1)
**Objective**: Implement data model and timezone service

**Tasks**:
1. Create `TimezoneService` protocol and `DefaultTimezoneService`
2. Update `UserProfile` with timezone fields
3. Create SchemaV9 with `ActiveUserProfileModel` timezone fields
4. Implement schema migration from V8 → V9
5. Add timezone change history tracking
6. Write unit tests for `TimezoneService`

**Success Criteria**:
- Can store/retrieve user's home timezone
- Timezone change history persists correctly
- Migration from V8 → V9 works without data loss

### Phase 2: Calendar & Date Utilities (Week 1)
**Objective**: Make all date calculations timezone-aware

**Tasks**:
1. Add timezone-aware methods to `CalendarUtils`
2. Update `HabitCompletionService` to use home timezone
3. Update `StreakCalculationService` to use home timezone
4. Update `HabitScheduleAnalyzer` to use home timezone
5. Write tests for timezone-aware date calculations
6. Verify all 73 tests pass

**Success Criteria**:
- All date calculations use home timezone
- Tests pass (including timezone edge cases)
- Late-night logging works correctly

### Phase 3: Timezone Detection & Alerts (Week 2)
**Objective**: Detect timezone mismatches and notify user

**Tasks**:
1. Implement timezone mismatch detection in `TimezoneService`
2. Create background task to check timezone on app launch
3. Create `TimezoneIndicatorBanner` UI component
4. Show banner on dashboard when mismatch detected
5. Write tests for detection logic

**Success Criteria**:
- App detects when device timezone ≠ home timezone
- User sees notification when traveling
- Can dismiss notification

### Phase 4: Onboarding Integration (Week 2)
**Objective**: Add timezone selection to onboarding

**Tasks**:
1. Create `TimezoneSelectionView`
2. Add to onboarding flow (after subscription step)
3. Implement timezone search/filtering
4. Pre-select device's current timezone
5. Save timezone selection to user profile
6. Write UI tests for onboarding flow

**Success Criteria**:
- New users select timezone during onboarding
- Default to device timezone
- Can search and select any timezone

### Phase 5: Settings & Management (Week 3)
**Objective**: Allow users to update timezone in settings

**Tasks**:
1. Create `TimezoneSettingsView`
2. Implement timezone update confirmation dialog
3. Show timezone change history
4. Add timezone mismatch indicator
5. Write UI tests for settings flow

**Success Criteria**:
- Users can update timezone from settings
- Confirmation dialog prevents accidental changes
- Change history is visible

### Phase 6: Testing & Refinement (Week 3)
**Objective**: Ensure all tests pass and edge cases work

**Tasks**:
1. Run full test suite (all 73 tests)
2. Fix any failing timezone edge case tests
3. Manual testing:
   - Change device timezone, verify detection
   - Log habits at 11:30 PM, verify correct day
   - Travel across timezones, verify streaks
   - DST transition, verify data consistency
4. Performance testing (ensure < 10ms overhead)
5. Documentation updates

**Success Criteria**:
- All 73 tests pass ✅
- Manual testing scenarios work correctly
- Performance acceptable
- Documentation updated

## Edge Cases & Considerations

### 1. First-Time Users
- **Solution**: Onboarding flow asks for timezone selection
- **Default**: Pre-select device's current timezone
- **Validation**: Show confirmation before proceeding

### 2. Existing Users (Migration)
- **Solution**: V8 → V9 migration sets `homeTimezoneIdentifier` to device timezone
- **Notification**: Show one-time prompt to confirm timezone
- **History**: Record as `initialSetup` reason

### 3. Late-Night Logging (11:30 PM)
- **Problem**: User logs at 11:30 PM - which day does it count for?
- **Solution**: Use home timezone to determine "today"
- **Example**: 11:30 PM EST on Monday = counts for Monday (not Tuesday)

### 4. Frequent Travelers
- **Problem**: User travels often, doesn't want to update timezone constantly
- **Solution V1**: Keep home timezone fixed, detect mismatches
- **Solution V2 (Future)**: "Travel mode" with temporary timezone override

### 5. Daylight Saving Time Transitions
- **Problem**: 2 AM → 3 AM (spring) or 2 AM → 1 AM (fall)
- **Solution**: Use `TimeZone` class which handles DST automatically
- **Testing**: Verify tests pass for DST edge cases

### 6. Timezone Data Updates
- **Problem**: Timezone rules change (rare but happens)
- **Solution**: iOS handles this automatically via system updates
- **Action**: No special handling needed

### 7. Historical Data Display
- **Problem**: User changed timezone, old completions show wrong dates
- **Solution**: Store `timezone` field in `HabitLog` (already done!)
- **Display**: Use log's timezone for historical display

### 8. Streaks Across Timezone Changes
- **Problem**: User's streak breaks when changing timezone
- **Solution**: Streak calculation uses home timezone consistently
- **Validation**: Test with timezone change fixtures

## Testing Strategy

### Unit Tests
- `TimezoneService`: Timezone CRUD operations
- `CalendarUtils`: Timezone-aware date calculations
- `HabitCompletionService`: Completion status with various timezones
- `StreakCalculationService`: Streaks across timezone changes

### Integration Tests
- Schema migration: V8 → V9
- Onboarding flow: Timezone selection
- Settings flow: Timezone update
- Detection flow: Mismatch detection

### Manual Testing Scenarios
1. **New User**: Complete onboarding, select timezone
2. **Existing User**: Open app, verify migration
3. **Travel**: Change device timezone, verify detection
4. **Late Night**: Log at 11:30 PM, verify correct day
5. **DST**: Simulate DST transition, verify data consistency
6. **Permanent Move**: Update timezone, verify historical data intact

### Performance Testing
- Measure date calculation overhead
- Test with 1000+ habit logs
- Ensure < 10ms added latency

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Data loss during migration | High | Low | Thorough testing, rollback plan |
| Performance degradation | Medium | Low | Performance testing, optimization |
| User confusion about timezone | Medium | Medium | Clear UI, onboarding guidance |
| Timezone detection false positives | Low | Low | Smart detection logic, user control |
| Breaking existing functionality | High | Low | Comprehensive test suite |

## Success Metrics

1. **Test Coverage**: All 73 tests pass (100% pass rate)
2. **Performance**: Timezone calculations add < 10ms overhead
3. **User Adoption**: 90%+ of users complete timezone onboarding
4. **Data Integrity**: Zero reports of lost/incorrect habit data
5. **User Satisfaction**: No timezone-related support tickets

## Open Questions

1. **Travel Mode**: Should we support temporary timezone overrides for travelers?
   - **Decision**: Defer to v2. V1 keeps home timezone fixed.

2. **Automatic Detection**: Should we automatically update timezone when user travels?
   - **Decision**: No. Always require user confirmation to prevent accidents.

3. **Multiple Timezones**: Support for users with multiple locations?
   - **Decision**: Defer to v2. V1 supports single home timezone only.

4. **Historical Display**: Show historical data in original timezone or home timezone?
   - **Decision**: Use log's stored timezone (already in data model).

## Next Steps

1. ✅ Create this planning document
2. ⏭️ Review plan with stakeholders
3. ⏭️ Begin Phase 1: Core Infrastructure
4. ⏭️ Implement iteratively, phase by phase
5. ⏭️ Test after each phase
6. ⏭️ Final integration testing before PR

## References

- iOS TimeZone Documentation: https://developer.apple.com/documentation/foundation/timezone
- Swift Testing Framework: https://developer.apple.com/documentation/testing
- Existing Tests: `RitualistTests/TestInfrastructure/TimezoneTestHelpers.swift`
- Edge Case Fixtures: `RitualistTests/TestInfrastructure/Fixtures/TimezoneEdgeCaseFixtures.swift`

---

**Last Updated**: 2025-11-15
**Document Owner**: Development Team
**Status**: Planning → Ready for Implementation
