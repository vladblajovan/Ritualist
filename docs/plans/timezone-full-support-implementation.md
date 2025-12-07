# Full Timezone Support Implementation Plan

**Created**: December 6, 2025
**Status**: Planning
**Estimated Effort**: 2-3 days

---

## Executive Summary

The timezone infrastructure is **85-90% complete**. The remaining work is wiring up services and ViewModels to use `getDisplayTimezone()` instead of hardcoded `.current`.

### What's Done
- TimezoneService with three-timezone model (Current/Home/Display)
- DisplayTimezoneMode enum with `.current`, `.home`, `.custom(String)`
- CalendarUtils with timezone-aware methods
- Settings UI (AdvancedSettingsView) for timezone selection
- Travel detection
- Database schema (V9+) with all timezone fields
- HabitCompletionCheckService already uses `getDisplayTimezone()`

### What's Missing
- Most services/ViewModels still use `.current` directly
- No travel notification banner on Dashboard
- Custom timezone picker UI not implemented

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    DISPLAY TIMEZONE FLOW                     │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  User selects mode in Settings:                              │
│  ┌─────────────────────────────────────────────┐            │
│  │ AdvancedSettingsView                        │            │
│  │  - Current Location (uses device TZ)        │            │
│  │  - Home Location (uses stored home TZ)      │            │
│  │  - Custom (TODO: not yet in UI)             │            │
│  └─────────────────────────────────────────────┘            │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────┐            │
│  │ TimezoneService.getDisplayTimezone()        │            │
│  │  - Reads displayTimezoneMode from profile   │            │
│  │  - Resolves to actual TimeZone              │            │
│  └─────────────────────────────────────────────┘            │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────┐            │
│  │ All Services & ViewModels                    │            │
│  │  - DashboardViewModel                        │            │
│  │  - OverviewViewModel                         │            │
│  │  - StreakCalculationService                  │            │
│  │  - HabitCompletionService                    │            │
│  │  - etc.                                      │            │
│  └─────────────────────────────────────────────┘            │
│                          │                                   │
│                          ▼                                   │
│  ┌─────────────────────────────────────────────┐            │
│  │ CalendarUtils.*Local() methods               │            │
│  │  - Pass display timezone to all calculations │            │
│  └─────────────────────────────────────────────┘            │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Implementation Tasks

### Phase 1: Core Services (High Priority)

These services directly affect habit tracking accuracy.

#### 1.1 StreakCalculationService

**File**: `RitualistCore/Sources/RitualistCore/Services/StreakCalculationService.swift`

**Current State**: Uses `.current` as default in convenience methods (lines 94-114)

**Changes Needed**:
- Inject `TimezoneService`
- Create async versions that fetch display timezone
- Keep sync versions with explicit timezone parameter for tests

```swift
// BEFORE (convenience methods)
public func calculateCurrentStreak(habit: Habit, logs: [HabitLog], asOf date: Date) -> Int {
    return calculateCurrentStreak(habit: habit, logs: logs, asOf: date, timezone: .current)
}

// AFTER (add TimezoneService dependency)
public final class DefaultStreakCalculationService: StreakCalculationService {
    private let timezoneService: TimezoneService

    public func calculateCurrentStreakWithDisplayTimezone(habit: Habit, logs: [HabitLog], asOf date: Date) async -> Int {
        let tz = (try? await timezoneService.getDisplayTimezone()) ?? .current
        return calculateCurrentStreak(habit: habit, logs: logs, asOf: date, timezone: tz)
    }
}
```

**Affected Methods**:
- `calculateCurrentStreak`
- `calculateLongestStreak`
- `getStreakBreakDates`
- `getNextScheduledDate`
- `getStreakStatus`

---

#### 1.2 HabitCompletionService

**File**: `RitualistCore/Sources/RitualistCore/Services/HabitCompletionService.swift`

**Current State**: Uses `.current` as default (lines 49-69)

**Changes Needed**:
- Inject `TimezoneService`
- Add async convenience methods

**Affected Methods**:
- `isCompleted`
- `isScheduledDay`
- `calculateDailyProgress`
- `calculateProgress`
- `getExpectedCompletions`

---

#### 1.3 HabitScheduleAnalyzerProtocol

**File**: `RitualistCore/Sources/RitualistCore/Services/HabitScheduleAnalyzerProtocol.swift`

**Current State**: Uses `.current` as default (lines 35-40)

**Affected Methods**:
- `calculateExpectedDays`
- `isHabitExpectedOnDate`

---

### Phase 2: ViewModels (High Priority)

ViewModels display data to users - they must use display timezone.

#### 2.1 OverviewViewModel

**File**: `Ritualist/Features/Overview/Presentation/OverviewViewModel.swift`

**Current State**: Extensive use of `.current` throughout (lines 107, 341, 404, 425, 601, 622, 712, 1225, 1470, 1774)

**Changes Needed**:
- Inject `TimezoneService`
- Fetch display timezone once on load, store as property
- Replace all `.current` references with stored display timezone
- Refresh timezone when view appears (user may have changed settings)

```swift
@Observable
public final class OverviewViewModel {
    @ObservationIgnored @Injected(\.timezoneService) private var timezoneService

    private var displayTimezone: TimeZone = .current

    public func load() async {
        displayTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current
        // ... rest of load
    }
}
```

---

#### 2.2 DashboardViewModel

**File**: `Ritualist/Features/Dashboard/Presentation/DashboardViewModel+UnifiedLoading.swift`

**Current State**: Uses `.current` (line 219)

**Changes Needed**: Same pattern as OverviewViewModel

---

#### 2.3 MonthlyCalendarCard

**File**: `Ritualist/Features/Overview/Presentation/Cards/MonthlyCalendarCard.swift`

**Current State**: Uses `.current` (line 243)

**Changes Needed**: Pass timezone from parent OverviewViewModel

---

#### 2.4 TodaysSummaryCard

**File**: `Ritualist/Features/Overview/Presentation/Cards/TodaysSummaryCard.swift`

**Current State**: Uses `TimeZone.current` (lines 83, 90)

**Changes Needed**: Accept timezone as parameter

---

### Phase 3: Data Layer (Medium Priority)

#### 3.1 OverviewData

**File**: `RitualistCore/Sources/RitualistCore/Entities/Overview/OverviewData.swift`

**Current State**: Uses `.current` in computed properties (lines 65, 98, 148)

**Problem**: These are computed properties - can't be async

**Solution Options**:
A. Make OverviewData accept timezone in initializer
B. Create factory method that accepts timezone
C. Use extension with explicit timezone parameter

**Recommended**: Option A - pass timezone when creating OverviewData

```swift
// BEFORE
public var weekdayData: [WeekdayData] {
    let endOfWeek = CalendarUtils.addDaysLocal(-1, to: weekInterval.end, timezone: .current)
    // ...
}

// AFTER
public struct OverviewData {
    public let timezone: TimeZone

    public var weekdayData: [WeekdayData] {
        let endOfWeek = CalendarUtils.addDaysLocal(-1, to: weekInterval.end, timezone: timezone)
        // ...
    }
}
```

---

#### 3.2 DashboardData

**File**: `RitualistCore/Sources/RitualistCore/Entities/Dashboard/DashboardData.swift`

**Current State**: Uses `.current` (lines 117, 230)

**Solution**: Same as OverviewData - accept timezone in initializer

---

#### 3.3 TimePeriod Enum

**File**: `RitualistCore/Sources/RitualistCore/Enums/TimePeriod.swift`

**Current State**: Uses `.current` in `dateRange(from:)` (lines 67, 74)

**Problem**: Enum computed properties can't be async

**Solution**: Add explicit timezone parameter

```swift
// BEFORE
public func dateRange(from referenceDate: Date = Date()) -> ClosedRange<Date>

// AFTER
public func dateRange(from referenceDate: Date = Date(), timezone: TimeZone = .current) -> ClosedRange<Date>
```

---

### Phase 4: Background Services (Medium Priority)

#### 4.1 PersonalityAnalysisScheduler

**File**: `RitualistCore/Sources/RitualistCore/Services/PersonalityAnalysisScheduler.swift`

**Current State**: Uses `.current` (lines 207-211)

**Note**: Personality analysis runs in background - may want to keep using device timezone here since it's about *when* to analyze, not *what timezone to display*

**Decision Needed**: Should background tasks use device timezone or display timezone?

---

#### 4.2 PerformanceAnalysisService

**File**: `RitualistCore/Sources/RitualistCore/Services/PerformanceAnalysisService.swift`

**Current State**: Uses `.current` and `TimeZone.current` (lines 118, 163, 258, 453)

**Changes Needed**: Inject TimezoneService

---

### Phase 5: Use Cases (Medium Priority)

#### 5.1 DashboardUseCases

**File**: `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Dashboard/DashboardUseCases.swift`

**Current State**: Uses `.current` (lines 78, 88)

**Changes Needed**: Inject TimezoneService and pass display timezone

---

#### 5.2 AnalyticsUseCases

**File**: `RitualistCore/Sources/RitualistCore/UseCases/Implementations/Core/AnalyticsUseCases.swift`

**Current State**: Uses `.current` (line 100)

**Changes Needed**: Inject TimezoneService

---

#### 5.3 PersonalityAnalysisUseCases

**File**: `RitualistCore/Sources/RitualistCore/UseCases/Implementations/PersonalityAnalysis/PersonalityAnalysisUseCases.swift`

**Current State**: Uses `.current` (lines 33, 530)

**Note**: Same decision as PersonalityAnalysisScheduler

---

### Phase 6: UI Enhancements (Low Priority)

#### 6.1 Travel Notification Banner

**Location**: Dashboard

**Current State**: Not implemented (commented out in RitualistApp.swift line 887)

**Implementation**:
1. Create `TravelNotificationBanner` component
2. Show when `detectTravelStatus()` returns travel detected
3. Offer quick action to sync display timezone

```swift
// In DashboardView
if viewModel.isTraveling {
    TravelNotificationBanner(
        currentTimezone: viewModel.currentTimezone,
        homeTimezone: viewModel.homeTimezone,
        onSyncToCurrentTimezone: {
            await viewModel.syncDisplayToCurrentTimezone()
        }
    )
}
```

---

#### 6.2 Custom Timezone Picker

**Location**: AdvancedSettingsView

**Current State**: Only "Current Location" / "Home Location" segmented picker

**Implementation**: Add third option for Custom with timezone picker

---

## Implementation Order

### Sprint 1 (Day 1): Core Services
1. StreakCalculationService
2. HabitCompletionService
3. HabitScheduleAnalyzerProtocol
4. TimePeriod enum

### Sprint 2 (Day 2): ViewModels
1. OverviewViewModel
2. DashboardViewModel
3. Card components (MonthlyCalendarCard, TodaysSummaryCard)

### Sprint 3 (Day 2-3): Data Layer & Use Cases
1. OverviewData
2. DashboardData
3. DashboardUseCases
4. PerformanceAnalysisService

### Sprint 4 (Optional): UI Enhancements
1. Travel notification banner
2. Custom timezone picker

---

## Testing Strategy

### Unit Tests
- Each service change needs tests with different display timezone modes
- Use `MockTimezoneService` from `TimezoneTestHelpers.swift`
- Test edge cases: midnight boundaries, DST transitions

### Integration Tests
- End-to-end flow: Settings change → Service recalculates → UI updates
- Travel detection → Notification shown

### Manual Testing
1. Change display timezone in Settings
2. Verify Dashboard shows correct "today"
3. Verify streaks recalculate correctly
4. Verify statistics use new timezone

---

## Files to Modify Summary

### High Priority (Must Do)
| File | Changes |
|------|---------|
| `StreakCalculationService.swift` | Inject TimezoneService, add async methods |
| `HabitCompletionService.swift` | Inject TimezoneService, add async methods |
| `HabitScheduleAnalyzerProtocol.swift` | Inject TimezoneService |
| `OverviewViewModel.swift` | Fetch & store display timezone |
| `DashboardViewModel+UnifiedLoading.swift` | Use display timezone |
| `OverviewData.swift` | Accept timezone parameter |
| `DashboardData.swift` | Accept timezone parameter |
| `TimePeriod.swift` | Add timezone parameter |

### Medium Priority (Should Do)
| File | Changes |
|------|---------|
| `DashboardUseCases.swift` | Pass display timezone |
| `AnalyticsUseCases.swift` | Inject TimezoneService |
| `PerformanceAnalysisService.swift` | Inject TimezoneService |
| `ScheduleAwareCompletionCalculator.swift` | Accept timezone |
| `MonthlyCalendarCard.swift` | Accept timezone from parent |
| `TodaysSummaryCard.swift` | Accept timezone parameter |

### Low Priority (Nice to Have)
| File | Changes |
|------|---------|
| `PersonalityAnalysisScheduler.swift` | Consider display timezone |
| `PersonalityAnalysisUseCases.swift` | Consider display timezone |
| `RitualistApp.swift` | Enable travel notification |
| `AdvancedSettingsView.swift` | Add custom timezone picker |

---

## Rollout Plan

1. **Phase 1**: Implement core services with feature flag (optional)
2. **Phase 2**: Update ViewModels
3. **Phase 3**: Internal testing with different timezones
4. **Phase 4**: Beta testing (TestFlight)
5. **Phase 5**: Production release

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Breaking existing streaks | Warn user before timezone change (already implemented) |
| Performance impact of async calls | Cache display timezone in ViewModels |
| Complex merge conflicts | Do in focused PRs per phase |
| Regression in date calculations | Comprehensive test coverage |

---

## Success Criteria

- [ ] User can set display timezone to Current/Home
- [ ] Dashboard shows correct "today" based on display timezone
- [ ] Streaks calculate using display timezone
- [ ] Statistics use display timezone
- [ ] Late-night logging counts for correct day
- [ ] Travel detection works and shows notification (stretch goal)
