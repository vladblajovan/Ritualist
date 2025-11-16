# Timezone Handling Implementation Plan

**Branch:** `feature/timezone-handling`
**Status:** Planning Phase - REFINED MODEL
**Created:** 2025-11-15
**Updated:** 2025-11-15

## Executive Summary

Implement comprehensive timezone handling using a **Three-Timezone Model** to support global users who:
- Travel across timezones
- Experience Daylight Saving Time transitions
- Want to maintain consistent habit tracking regardless of location
- Need accurate historical data display when timezone changes
- Prefer flexible viewing options (current location vs. home location)

## Core Design Principles

### The Seven Pillars of Timezone Handling

1. **Three timezone concepts (all serve distinct purposes)**
   - **Current** (auto-detected, informational) - "Where is device now?"
   - **Home** (user-set, semantic) - "Where do I live?"
   - **Display** (user-set, functional) - "How do I view my data?"

2. **Display timezone controls ALL calculations and views**
   - "Today", streaks, statistics, calendar all use Display timezone
   - Provides consistency across entire app
   - User chooses their perspective

3. **Logs store original timezone forever**
   - No data transformation on timezone changes
   - Preserves historical context
   - Allows viewing from any perspective

4. **Auto-detect timezone changes, update Current only**
   - Never auto-change Home or Display without user consent
   - Respect user's explicit choices
   - Maintain data stability

5. **Show notification when Current ≠ Home**
   - Non-intrusive awareness
   - Offers quick action to sync if desired
   - User remains in control

6. **DST: No special UI, just use TimeZone class**
   - iOS `TimeZone` class handles all DST complexity
   - Transparent to users
   - No special logic needed

7. **Migration: Set all three to device timezone initially**
   - Safe, sensible default
   - Users can customize later
   - Zero disruption to existing users

## The Trinity of Timezones

### Visual Model

```
┌─────────────────────────────────────────────────────────┐
│                    TIMEZONE TRINITY                      │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  CURRENT [🌍]         HOME [🏠]         DISPLAY [👁️]      │
│  Auto-detected        User-defined      User chooses    │
│  "Where am I?"        "Where do I live?" "How to view?"  │
│                                                          │
│  Asia/Tokyo    →     America/New_York  → Current/Home   │
│  [Read-only]         [User edits]        [User selects] │
│  Updates on          Stable unless       Controls all   │
│  device change       user changes        calculations   │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Timezone Roles

| Timezone | Purpose | Updates | User Control | Affects |
|----------|---------|---------|--------------|---------|
| **Current** | Information | Automatic | None (read-only) | Nothing (display only) |
| **Home** | Semantic meaning | Manual | Full control | Default for Display |
| **Display** | Functional calculations | Manual | Full control | ALL app data/views |

## Problem Statement

### Current Behavior (Issues Identified by Tests)
1. **No Display Timezone Concept**: App doesn't let users choose viewing perspective
2. **No Current Timezone Tracking**: App doesn't show where device currently is
3. **Timezone Change Issues**: When user travels, no clear way to handle data display
4. **DST Transitions**: Need automatic handling without user intervention
5. **Late-Night Logging**: Logging at 11:30 PM may count for wrong day
6. **Historical Data**: Past completions need to remain accurate when timezone changes
7. **Flexible Viewing**: Users need different viewing modes (current location vs. home)

### User Scenarios (Refined)

#### Scenario 1: New User Install
```
User: Sarah installs app in New York
Auto-set:
  Current Timezone:  America/New_York
  Home Timezone:     America/New_York
  Display In:        Home Timezone

Result: Everything "just works" with NYC time
```

#### Scenario 2: Business Traveler
```
User: John lives in NYC, travels to Tokyo for work
When in Tokyo:
  Current Timezone:  Asia/Tokyo [auto-updated]
  Home Timezone:     America/New_York [unchanged]
  Display In:        Home Timezone [unchanged]

Notification shows: "You're in Tokyo. Data shown in New York time."
  [Dismiss] [Use Tokyo Time Instead]

John logs habit at 11 PM Tokyo time
→ Counts for correct NYC day ✅
→ Streak continues unbroken ✅

When John returns home:
  Current Timezone:  America/New_York [auto-updated]
  Notification dismissed automatically
```

#### Scenario 3: Permanent Relocation
```
User: Maria moves from NYC to San Francisco
Updates Home timezone in settings
App prompts: "Update Display timezone too?"
  [Yes - Use SF time] [No - Keep NYC view]

Maria chooses "Yes"
  Current Timezone:  America/Los_Angeles [auto-updated]
  Home Timezone:     America/Los_Angeles [user updated]
  Display In:        Home Timezone [follows Home]

Historical data: Remains accurate (logs stored original timezone)
Future tracking: Uses SF time
Streaks: Recalculated in SF time (user warned before change)
```

#### Scenario 4: Frequent Flyer
```
User: David travels constantly for work
Prefers to see data in current location time

Settings:
  Current Timezone:  [varies with travel]
  Home Timezone:     America/New_York
  Display In:        Current Timezone [chosen for flexibility]

When in London:
  Everything shows London time
When in Singapore:
  Everything shows Singapore time

Data adapts automatically to current location ✅
```

#### Scenario 5: Expat Community
```
User: Yuki lives in LA but wants to see data in Tokyo time
   (staying connected with family timezone)

Settings:
  Current Timezone:  America/Los_Angeles
  Home Timezone:     America/Los_Angeles
  Display In:        Custom (Asia/Tokyo)

All data shown in Tokyo time:
  "Today" = today in Tokyo
  Streaks calculated in Tokyo time
  Late-night logging counts for Tokyo day
```

## Requirements

### Functional Requirements

1. **FR-1**: App auto-detects and displays current timezone (read-only)
2. **FR-2**: User can set home timezone (default: current timezone on install)
3. **FR-3**: User can choose display mode: Current / Home / Custom
4. **FR-4**: App detects when Current ≠ Home and shows notification
5. **FR-5**: Notification offers quick action to sync Display to Current
6. **FR-6**: All date calculations use Display timezone (Today, streaks, stats)
7. **FR-7**: Logs store original timezone and can be viewed in any timezone
8. **FR-8**: App handles DST transitions automatically (no user action)
9. **FR-9**: Late-night logging (11:30 PM) counts for correct day in Display timezone
10. **FR-10**: Changing Display timezone shows warning about streak recalculation
11. **FR-11**: Settings show all three timezones with clear labels and icons
12. **FR-12**: Historical data remains accurate when any timezone changes

### Non-Functional Requirements

1. **NFR-1**: Zero data loss during timezone changes
2. **NFR-2**: Backward compatible (existing users get sensible defaults)
3. **NFR-3**: Performance: Timezone calculations add < 10ms overhead
4. **NFR-4**: UX: Display timezone changes require explicit confirmation
5. **NFR-5**: Testing: All 73 tests pass (including timezone edge cases)
6. **NFR-6**: Clarity: UI makes three timezone roles obvious and understandable

## Architecture Design

### Data Model Changes

#### 1. User Profile Enhancement
```swift
// RitualistCore/Sources/RitualistCore/Models/UserProfile.swift
struct UserProfile {
    // ... existing fields

    // ══════════════════════════════════════════════════════════
    // TIMEZONE TRINITY
    // ══════════════════════════════════════════════════════════

    /// Current timezone (auto-detected from device)
    /// - Read-only for user
    /// - Updates automatically when device timezone changes
    /// - Purpose: "Where am I right now?"
    var currentTimezoneIdentifier: String  // e.g., "Asia/Tokyo"

    /// Home timezone (user-defined semantic location)
    /// - User can edit in settings
    /// - Represents where user primarily lives
    /// - Purpose: "Where do I live?"
    /// - Default: Copied from currentTimezoneIdentifier on first install
    var homeTimezoneIdentifier: String  // e.g., "America/New_York"

    /// Display timezone mode (user chooses viewing perspective)
    /// - Controls ALL date calculations and views
    /// - Can follow Current, Home, or be Custom
    /// - Purpose: "How do I want to view my data?"
    /// - Default: .home
    var displayTimezoneMode: DisplayTimezoneMode

    // ══════════════════════════════════════════════════════════
    // CHANGE TRACKING
    // ══════════════════════════════════════════════════════════

    /// Track timezone changes for auditing
    var timezoneChangeHistory: [TimezoneChange] = []
}

/// Display timezone mode - controls how user views data
enum DisplayTimezoneMode: Codable, Equatable {
    /// Follow current device timezone (auto-updates with travel)
    case current

    /// Use home timezone (stable, doesn't change with travel)
    case home

    /// Use a specific custom timezone
    case custom(String)  // e.g., "Europe/London"

    /// Get the effective timezone for calculations
    var effectiveTimezone: TimeZone {
        switch self {
        case .current:
            return .current
        case .home:
            // Access via dependency injection, not global state
            return TimeZone(identifier: userProfile.homeTimezoneIdentifier)!
        case .custom(let identifier):
            return TimeZone(identifier: identifier)!
        }
    }

    /// Display string for UI
    var displayString: String {
        switch self {
        case .current:
            return "Current Timezone (\(TimeZone.current.identifier))"
        case .home:
            return "Home Timezone"
        case .custom(let identifier):
            return "Custom (\(identifier))"
        }
    }
}

/// Record of timezone changes for auditing
struct TimezoneChange: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let changeType: TimezoneChangeType
    let fromValue: String
    let toValue: String
}

enum TimezoneChangeType: String, Codable {
    case currentAutoUpdate      // Device timezone changed (auto)
    case homeUserUpdate         // User changed home timezone
    case displayModeChange      // User changed display mode
}
```

#### 2. SwiftData Schema Update (V9)
```swift
// Add to ActiveUserProfileModel (SchemaV9)
@Model
final class ActiveUserProfileModel {
    // ... existing properties

    // Timezone trinity
    @Attribute var currentTimezoneIdentifier: String
    @Attribute var homeTimezoneIdentifier: String
    @Attribute var displayTimezoneModeRaw: String  // JSON of DisplayTimezoneMode

    // Change tracking
    @Relationship(deleteRule: .cascade)
    var timezoneChanges: [TimezoneChangeModel] = []
}

@Model
final class TimezoneChangeModel {
    var id: UUID
    var timestamp: Date
    var changeTypeRaw: String  // TimezoneChangeType.rawValue
    var fromValue: String
    var toValue: String
}
```

#### 3. Migration V8 → V9
```swift
// Migration logic
func migrateV8ToV9(context: ModelContext) {
    let currentDeviceTimezone = TimeZone.current.identifier

    // For existing users:
    // - Set all three to device timezone (safe default)
    // - Display defaults to Home mode
    userProfile.currentTimezoneIdentifier = currentDeviceTimezone
    userProfile.homeTimezoneIdentifier = currentDeviceTimezone
    userProfile.displayTimezoneMode = .home

    // Record migration
    let change = TimezoneChange(
        id: UUID(),
        timestamp: Date(),
        changeType: .homeUserUpdate,
        fromValue: "none",
        toValue: currentDeviceTimezone
    )
    userProfile.timezoneChangeHistory.append(change)
}
```

### Service Layer Changes

#### 1. TimezoneService (NEW)
```swift
protocol TimezoneService {
    // ══════════════════════════════════════════════════════════
    // GETTERS
    // ══════════════════════════════════════════════════════════

    /// Get current device timezone (auto-detected)
    func getCurrentTimezone() -> TimeZone

    /// Get user's home timezone
    func getHomeTimezone() -> TimeZone

    /// Get display timezone mode
    func getDisplayTimezoneMode() -> DisplayTimezoneMode

    /// Get effective timezone for calculations (based on display mode)
    func getDisplayTimezone() -> TimeZone

    // ══════════════════════════════════════════════════════════
    // SETTERS
    // ══════════════════════════════════════════════════════════

    /// Update home timezone
    /// - Parameter timezone: New home timezone
    /// - Returns: true if should also update display mode
    func updateHomeTimezone(_ timezone: TimeZone) async throws -> Bool

    /// Update display timezone mode
    /// - Parameter mode: New display mode
    /// - Shows warning if changing (affects calculations)
    func updateDisplayTimezoneMode(_ mode: DisplayTimezoneMode) async throws

    // ══════════════════════════════════════════════════════════
    // DETECTION & NOTIFICATIONS
    // ══════════════════════════════════════════════════════════

    /// Check if current device timezone differs from stored current
    /// Call this on app launch to detect travel
    func detectTimezoneChange() -> TimezoneChangeDetection?

    /// Check if Current ≠ Home (user is traveling)
    func detectTravelStatus() -> TravelStatus?

    /// Update stored current timezone (when device timezone changes)
    func updateCurrentTimezone() async throws
}

struct TimezoneChangeDetection {
    let previousTimezone: TimeZone
    let newTimezone: TimeZone
    let detectedAt: Date
}

struct TravelStatus {
    let currentTimezone: TimeZone
    let homeTimezone: TimeZone
    let isTravel: Bool  // Current ≠ Home
}
```

#### 2. CalendarUtils Enhancement
```swift
// Add display-timezone-aware methods
extension CalendarUtils {
    /// Start of day in display timezone
    static func startOfDayInDisplayTimezone(for date: Date, timezone: TimeZone) -> Date

    /// Is date today in display timezone?
    static func isTodayInDisplayTimezone(_ date: Date, timezone: TimeZone) -> Bool

    /// Days between in display timezone
    static func daysBetweenInDisplayTimezone(_ start: Date, _ end: Date, timezone: TimeZone) -> Int

    /// Convert date to display timezone (for showing in UI)
    static func convertToDisplayTimezone(_ date: Date, from originalTimezone: TimeZone, to displayTimezone: TimeZone) -> Date
}
```

#### 3. Core Services Enhancement
```swift
// Update all services to use display timezone
class DefaultHabitCompletionService: HabitCompletionService {
    private let timezoneService: TimezoneService

    func getCompletionStatus(for habit: Habit, on date: Date) async throws -> CompletionStatus {
        let displayTimezone = timezoneService.getDisplayTimezone()
        // Use displayTimezone for ALL date calculations
    }
}

class DefaultStreakCalculationService: StreakCalculationService {
    private let timezoneService: TimezoneService

    func calculateCurrentStreak(for habit: Habit, logs: [HabitLog]) -> Int {
        let displayTimezone = timezoneService.getDisplayTimezone()
        // Calculate streak in displayTimezone
    }
}
```

### UI Changes

#### 1. Settings: Timezone Management (REVISED)
```swift
// Settings > Advanced Settings > Timezone
struct TimezoneSettingsView: View {
    @StateObject private var viewModel: TimezoneSettingsViewModel
    @State private var showingHomeTimezonePicker = false
    @State private var showingDisplayModeSheet = false

    var body: some View {
        Form {
            // ══════════════════════════════════════════════════════
            // CURRENT TIMEZONE (Auto-detected, Read-only)
            // ══════════════════════════════════════════════════════
            Section {
                HStack {
                    Image(systemName: "globe")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Current Timezone")
                            .font(.headline)
                        Text(viewModel.currentTimezone.identifier)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Auto")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Where You Are")
            } footer: {
                Text("Auto-detected from your device. Updates when you travel.")
            }

            // ══════════════════════════════════════════════════════
            // HOME TIMEZONE (User-defined)
            // ══════════════════════════════════════════════════════
            Section {
                HStack {
                    Image(systemName: "house.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading) {
                        Text("Home Timezone")
                            .font(.headline)
                        Text(viewModel.homeTimezone.identifier)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Edit") {
                        showingHomeTimezonePicker = true
                    }
                }
            } header: {
                Text("Where You Live")
            } footer: {
                Text("Your primary location. Use this for default data viewing.")
            }

            // ══════════════════════════════════════════════════════
            // DISPLAY IN (User chooses viewing mode)
            // ══════════════════════════════════════════════════════
            Section {
                Button {
                    showingDisplayModeSheet = true
                } label: {
                    HStack {
                        Image(systemName: "eye.fill")
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading) {
                            Text("Display In")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(viewModel.displayModeDescription)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
            } header: {
                Text("How You View Data")
            } footer: {
                Text("All dates, streaks, and statistics are calculated in this timezone. Changing this will recalculate your data.")
            }

            // ══════════════════════════════════════════════════════
            // TRAVEL STATUS (If Current ≠ Home)
            // ══════════════════════════════════════════════════════
            if viewModel.isTravel {
                Section {
                    HStack {
                        Image(systemName: "airplane")
                            .foregroundStyle(.orange)
                        Text("You're in \(viewModel.currentTimezone.identifier)")
                        Spacer()
                        Button("Use Current") {
                            viewModel.syncDisplayToCurrent()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                } header: {
                    Text("Travel Detected")
                }
            }

            // ══════════════════════════════════════════════════════
            // CHANGE HISTORY
            // ══════════════════════════════════════════════════════
            if !viewModel.changeHistory.isEmpty {
                Section("Change History") {
                    ForEach(viewModel.changeHistory) { change in
                        TimezoneChangeRow(change: change)
                    }
                }
            }
        }
        .navigationTitle("Timezone")
        .sheet(isPresented: $showingHomeTimezonePicker) {
            TimezonePickerView(
                selectedTimezone: viewModel.homeTimezone,
                onSelect: { timezone in
                    Task {
                        await viewModel.updateHomeTimezone(timezone)
                    }
                }
            )
        }
        .sheet(isPresented: $showingDisplayModeSheet) {
            DisplayModePickerView(
                currentMode: viewModel.displayMode,
                currentTimezone: viewModel.currentTimezone,
                homeTimezone: viewModel.homeTimezone,
                onSelect: { mode in
                    Task {
                        await viewModel.updateDisplayMode(mode)
                    }
                }
            )
        }
    }
}
```

#### 2. Display Mode Picker
```swift
struct DisplayModePickerView: View {
    let currentMode: DisplayTimezoneMode
    let currentTimezone: TimeZone
    let homeTimezone: TimeZone
    let onSelect: (DisplayTimezoneMode) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMode: DisplayTimezoneMode
    @State private var customTimezone: TimeZone?
    @State private var showingCustomPicker = false

    init(currentMode: DisplayTimezoneMode, currentTimezone: TimeZone, homeTimezone: TimeZone, onSelect: @escaping (DisplayTimezoneMode) -> Void) {
        self.currentMode = currentMode
        self.currentTimezone = currentTimezone
        self.homeTimezone = homeTimezone
        self.onSelect = onSelect
        _selectedMode = State(initialValue: currentMode)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Current Timezone option
                    Button {
                        selectedMode = .current
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Current Timezone")
                                    .foregroundColor(.primary)
                                Text(currentTimezone.identifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Follows device (auto-updates when traveling)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            if case .current = selectedMode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    // Home Timezone option
                    Button {
                        selectedMode = .home
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Home Timezone")
                                    .foregroundColor(.primary)
                                Text(homeTimezone.identifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text("Stable (doesn't change when traveling)")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }
                            Spacer()
                            if case .home = selectedMode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    // Custom option
                    Button {
                        showingCustomPicker = true
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Custom...")
                                    .foregroundColor(.primary)
                                if case .custom(let identifier) = selectedMode {
                                    Text(identifier)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if case .custom = selectedMode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                } footer: {
                    Text("⚠️ Changing display timezone will recalculate streaks and statistics.")
                        .foregroundStyle(.orange)
                }
            }
            .navigationTitle("Display In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        onSelect(selectedMode)
                        dismiss()
                    }
                    .disabled(selectedMode == currentMode)
                }
            }
            .sheet(isPresented: $showingCustomPicker) {
                TimezonePickerView(
                    selectedTimezone: customTimezone ?? .current,
                    onSelect: { timezone in
                        selectedMode = .custom(timezone.identifier)
                        customTimezone = timezone
                    }
                )
            }
        }
    }
}
```

#### 3. Dashboard: Travel Notification Banner
```swift
// Show on dashboard when Current ≠ Home
struct TravelNotificationBanner: View {
    let currentTimezone: TimeZone
    let homeTimezone: TimeZone
    let onDismiss: () -> Void
    let onUseCurrentTimezone: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "airplane.circle.fill")
                .font(.title2)
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("You're in \(currentTimezone.identifier)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("Data shown in \(homeTimezone.identifier)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Use \(currentTimezone.abbreviation() ?? "Current")") {
                onUseCurrentTimezone()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
```

#### 4. Onboarding Integration (Optional for V1)
```swift
// Could be added to onboarding, but not strictly necessary
// Default behavior (all three = device timezone) is sensible
// Users can adjust in settings if needed

// If we do add it:
struct OnboardingTimezoneView: View {
    @State private var selectedTimezone: TimeZone = .current

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "globe")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("Set Your Timezone")
                .font(.title)
                .fontWeight(.bold)

            Text("We've detected your timezone as \(TimeZone.current.identifier). Is this correct?")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            // Timezone picker here

            Button("Continue") {
                // Save and continue
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
```

## Implementation Plan (REVISED)

### Phase 1: Core Infrastructure & Data Model (Week 1)
**Objective**: Implement three-timezone model and services

**Tasks**:
1. Create `DisplayTimezoneMode` enum with `.current`, `.home`, `.custom`
2. Update `UserProfile` with trinity fields
3. Create `TimezoneService` protocol and `DefaultTimezoneService`
4. Create SchemaV9 with timezone trinity
5. Implement migration V8 → V9 (set all to device timezone)
6. Add timezone change tracking
7. Write unit tests for `TimezoneService`

**Success Criteria**:
- Can store/retrieve all three timezone values
- DisplayTimezoneMode correctly determines effective timezone
- Migration works without data loss
- Tests pass

### Phase 2: Display Timezone Integration (Week 1-2)
**Objective**: Make all calculations use Display timezone

**Tasks**:
1. Add display-timezone-aware methods to `CalendarUtils`
2. Update `HabitCompletionService` to use display timezone
3. Update `StreakCalculationService` to use display timezone
4. Update `HabitScheduleAnalyzer` to use display timezone
5. Add timezone conversion utilities
6. Write tests for all timezone-aware calculations

**Success Criteria**:
- All date calculations use Display timezone
- Can change Display mode and see data update
- Late-night logging works correctly
- All 73 tests pass

### Phase 3: Timezone Detection & Updates (Week 2)
**Objective**: Auto-detect timezone changes, never auto-change user settings

**Tasks**:
1. Implement `detectTimezoneChange()` in TimezoneService
2. Implement `detectTravelStatus()` (Current ≠ Home check)
3. Add app launch handler to detect timezone changes
4. Update Current timezone automatically when detected
5. Never auto-update Home or Display
6. Write tests for detection logic

**Success Criteria**:
- Current timezone updates when device changes
- Home and Display never change automatically
- Detection works reliably
- Tests pass

### Phase 4: Settings UI (Week 2)
**Objective**: Build comprehensive timezone settings

**Tasks**:
1. Create `TimezoneSettingsView` with trinity display
2. Create `DisplayModePickerView`
3. Create `TimezonePickerView` (reusable)
4. Show travel status banner when Current ≠ Home
5. Show change history
6. Add warning when changing Display mode
7. Write UI tests

**Success Criteria**:
- Can view all three timezones
- Can edit Home timezone
- Can change Display mode
- Warning shown before Display change
- UI is clear and understandable

### Phase 5: Dashboard Integration (Week 3)
**Objective**: Show travel notification on dashboard

**Tasks**:
1. Create `TravelNotificationBanner` component
2. Show banner when Current ≠ Home
3. Quick action to sync Display to Current
4. Dismissible notification
5. Write UI tests

**Success Criteria**:
- Banner appears when traveling
- Quick action works
- Can dismiss
- Reappears appropriately

### Phase 6: Testing & Edge Cases (Week 3)
**Objective**: Ensure all tests pass and edge cases work

**Tasks**:
1. Run full test suite (all 73 tests)
2. Fix any failing timezone edge case tests
3. Manual testing scenarios:
   - Change device timezone, verify Current updates
   - Change Home, verify Display can sync
   - Change Display mode, verify calculations update
   - Travel scenario (Current ≠ Home)
   - DST transition
   - Late-night logging
4. Performance testing
5. Documentation

**Success Criteria**:
- All 73 tests pass ✅
- Manual scenarios work
- Performance < 10ms overhead
- Documentation complete

## Edge Cases & Solutions

### 1. First-Time Users
**Behavior:**
```
On install:
  Current = device timezone
  Home = device timezone
  Display = Home mode

User sees: Normal app, everything in their timezone
No special onboarding needed
```

### 2. Existing Users (Migration)
**Behavior:**
```
On migration to V9:
  Current = device timezone
  Home = device timezone
  Display = Home mode

Zero disruption, sensible defaults
Users can customize in settings
```

### 3. Late-Night Logging
**Example:**
```
User in Tokyo, Display = NYC
Logs at 11:30 PM Wednesday Tokyo time

Display timezone = NYC
Wednesday 11:30 PM Tokyo = Wednesday 9:30 AM NYC
Counts for Wednesday ✅

If Display = Tokyo:
Counts for Wednesday in Tokyo ✅

User's Display choice determines the day
```

### 4. Changing Display Mode
**Warning Flow:**
```
User changes Display from Home (NYC) to Current (Tokyo)

Show dialog:
  "⚠️ Change Display Timezone?

  This will recalculate:
  - Today's date
  - Streaks (may increase or decrease)
  - Statistics
  - Calendar view

  Your habit logs are safe and won't change.

  [Cancel] [Change to Tokyo Time]"

If confirmed:
  - Update Display mode
  - Recalculate everything
  - Show success message
```

### 5. DST Transitions
**Automatic Handling:**
```
Spring Forward (2 AM → 3 AM):
  iOS TimeZone handles automatically
  No invalid times created
  No user action needed

Fall Back (2 AM happens twice):
  iOS Date includes UTC offset
  Disambiguation automatic
  No user action needed

Our handling:
  Just use TimeZone class correctly
  Works transparently ✅
```

### 6. Historical Data Integrity
**Guaranteed:**
```
HabitLog stores:
  date: Date (absolute point in time)
  timezone: String (original timezone)

When viewing:
  Original: "Wednesday 10 PM JST"
  Display in NYC: "Wednesday 9 AM EST"
  Display in London: "Wednesday 2 PM GMT"

Original context preserved ✅
Can view from any perspective ✅
```

### 7. Frequent Travelers
**Solution:**
```
Settings:
  Current = [auto-updates with travel]
  Home = NYC (stable)
  Display = Current Timezone

Result:
  - Data always shows in current location
  - Adapts automatically
  - No manual updates needed
  - Flexible viewing ✅
```

### 8. Streak Stability
**Trade-off:**
```
Display = Home (stable):
  - Streaks don't change when traveling
  - Consistent calculation reference
  - Recommended for most users

Display = Current (flexible):
  - Streaks may change when timezone changes
  - Always shows in current context
  - Good for frequent travelers

User chooses their preference ✅
```

## Testing Strategy

### Unit Tests
- `TimezoneService`: All three timezone getters/setters
- `DisplayTimezoneMode`: Effective timezone calculation
- `CalendarUtils`: Display timezone calculations
- `HabitCompletionService`: Completion in various display timezones
- `StreakCalculationService`: Streaks across timezone changes

### Integration Tests
- Schema migration V8 → V9
- Display mode changes affecting calculations
- Current timezone auto-updates
- Travel detection logic

### Manual Testing Scenarios
1. **New Install**: Verify defaults (all = device timezone)
2. **Existing User**: Verify migration (all = device timezone)
3. **Travel**: Change device timezone, verify Current updates
4. **Display Change**: Change Display mode, verify recalculation
5. **Late Night**: Log at 11:30 PM, verify correct day in Display timezone
6. **DST**: Simulate DST transition, verify automatic handling
7. **Streak Stability**: Change Display, verify streak recalculation warning

### Performance Testing
- Measure overhead of Display timezone calculations
- Test with 1000+ habit logs
- Ensure < 10ms added latency
- Profile timezone conversions

## Risk Assessment

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| User confusion about three timezones | Medium | Medium | Clear UI with icons, tooltips, help text |
| Streaks change unexpectedly | Medium | Low | Warning dialog before Display change |
| Data loss during migration | High | Low | Thorough testing, rollback plan |
| Performance degradation | Medium | Low | Performance testing, optimization |
| Breaking existing functionality | High | Low | Comprehensive test suite (73 tests) |

## Success Metrics

1. **Test Coverage**: All 73 tests pass (100% pass rate)
2. **Performance**: Timezone calculations add < 10ms overhead
3. **User Understanding**: Settings page analytics show low confusion (< 5% support tickets)
4. **Data Integrity**: Zero reports of lost/incorrect habit data
5. **Adoption**: > 80% of users keep default settings (showing good defaults)

## FAQ & User Education

### Q: Why three timezones?
**A:** Each serves a different purpose:
- **Current** = Information (where you are)
- **Home** = Semantic (where you live)
- **Display** = Functional (how you view data)

### Q: Which should I use for Display?
**A:**
- **Most users**: Home Timezone (stable, doesn't change)
- **Frequent travelers**: Current Timezone (adapts automatically)
- **Special cases**: Custom (e.g., staying connected with family timezone)

### Q: What happens to my streaks when I travel?
**A:** Depends on your Display setting:
- **Display = Home**: Streaks stay stable (recommended)
- **Display = Current**: Streaks recalculate in new timezone

### Q: Can I see my data in a different timezone?
**A:** Yes! Change Display mode anytime. Your logs are safe and preserve original context.

### Q: What about Daylight Saving Time?
**A:** Handled automatically by iOS. No action needed!

## References

- iOS TimeZone Documentation: https://developer.apple.com/documentation/foundation/timezone
- Swift Testing Framework: https://developer.apple.com/documentation/testing
- Existing Tests: `RitualistTests/TestInfrastructure/TimezoneTestHelpers.swift`
- Edge Case Fixtures: `RitualistTests/TestInfrastructure/Fixtures/TimezoneEdgeCaseFixtures.swift`

---

**Last Updated**: 2025-11-15
**Document Owner**: Development Team
**Status**: Planning → REFINED MODEL → Ready for Implementation
