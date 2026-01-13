# Test Coverage Improvement Plan: 32% → 80%

## Goal
Increase Ritualist iOS app test coverage from ~32% to 80% through systematic testing of untested components.

---

## Current State

| Metric | Value |
|--------|-------|
| **Framework** | Apple Testing (`@Test`, `@Suite`, `#expect`) |
| **Current Coverage** | ~32% |
| **Existing Test Files** | 68 files |
| **Test Code** | ~26,900 lines |
| **Philosophy** | "Real Objects Over Mocks" - uses in-memory implementations |

### Recent Progress

| Date | Phase | Component | Tests Added | Status |
|------|-------|-----------|-------------|--------|
| 2026-01-12 | 2.1 | `SecurePremiumCacheTests.swift` | 20 | ✅ Complete |
| 2026-01-12 | 2.2 | `PersonalityAnalysisServiceTests.swift` | 36 | ✅ Complete |
| 2026-01-12 | 2.3 | `FeatureGatingServiceTests.swift` | 40 | ✅ Complete |
| 2026-01-12 | 2.4 | `NotificationServiceTests.swift` | 37 | ✅ Complete |
| 2026-01-12 | 5.2 | `HabitUseCasesTests.swift` | 33 | ✅ Complete |
| 2026-01-12 | 5.2 | `LogUseCasesTests.swift` | 29 | ✅ Complete |
| 2026-01-12 | 5.2 | `CategoryUseCasesTests.swift` | 26 | ✅ Complete |

### Test Infrastructure (Already Excellent)
- `MockRepositories.swift` - In-memory repository implementations
- `TestDataBuilders.swift` - HabitBuilder, HabitLogBuilder, UserProfileBuilder
- `TestModelContainer.swift` - SwiftData in-memory container
- `TestViewModelContainer.swift` - ViewModel factory methods
- `TestTags.swift` - Comprehensive test tagging system
- `TimezoneTestHelpers.swift` - Timezone edge case utilities

---

## Coverage Gap Analysis

### Critical Untested Components (by Lines of Code)

| Component | LOC | Type | Priority | Business Impact |
|-----------|-----|------|----------|-----------------|
| `NotificationService` | 1,456 | Service | CRITICAL | Core user feature |
| `OverviewViewModel` | 1,262 | ViewModel | CRITICAL | Main dashboard |
| `PersonalityAnalysisService` | 860 | Service | HIGH | Premium feature |
| `SettingsViewModel` | 753 | ViewModel | HIGH | User settings |
| `StatsViewModel` | 727 | ViewModel | HIGH | Analytics |
| `HabitsViewModel` | 660 | ViewModel | HIGH | Habit management |
| `LocationMonitoringService` | 458 | Service | MEDIUM | Geofencing |
| `SecurePremiumCache` | 437 | Service | HIGH | Subscription |
| 7 Repositories | ~1,500 | Data Layer | HIGH | Data persistence |
| 22 UseCases | ~3,000 | Business Logic | MEDIUM | Core operations |
| 6 Coordinators | ~1,200 | Orchestration | MEDIUM | App lifecycle |

### What's Already Well-Tested
- ViewLogic components (all covered)
- StreakCalculationService
- CloudKitCleanupService
- HabitCompletionService
- HabitDetailViewModel, OnboardingViewModel, RootTabViewModel
- HabitLocalDataSource, CategoryLocalDataSource
- Comprehensive timezone/DST handling

---

## Implementation Plan

### Phase 1: Test Infrastructure Extensions

**Goal**: Extend existing test infrastructure to support ViewModel and Service testing

#### 1.1 Extend MockRepositories.swift

Add mock implementations for:
```swift
// New mocks needed
MockNotificationService       // Protocol-based wrapper for UNUserNotificationCenter
MockLocationMonitoringService // Protocol-based wrapper for CLLocationManager
MockFeatureGatingService      // Feature flag testing
MockPaywallService            // StoreKit testing
MockICloudSyncCoordinator     // Sync testing
```

#### 1.2 Extend TestViewModelContainer.swift

Add factory methods and mock use cases for:

| ViewModel | Dependencies | Mock Use Cases Needed |
|-----------|--------------|----------------------|
| `OverviewViewModel` | 18 | GetActiveHabits, GetBatchLogs, LogHabit, DeleteLog, CalculateCurrentStreak, GetStreakStatus, IsHabitCompleted, CalculateDailyProgress, IsScheduledDay, RefreshWidget, GetMigrationStatus |
| `HabitsViewModel` | 12 | LoadHabitsData, CreateHabit, UpdateHabit, ArchiveHabit, RestoreHabit, DeleteHabit |
| `SettingsViewModel` | 15 | ExportData, ImportData, ClearAllData, GetCurrentUserProfile, UpdateUserProfile |
| `StatsViewModel` | 10 | GetStatistics, GetHeatmapData, GetPerformanceAnalysis |
| `PaywallViewModel` | 8 | GetProducts, PurchaseProduct, RestorePurchases |

#### 1.3 Create Protocol Abstractions (if needed)

For system services that are hard to test:
```swift
// NotificationCenterProtocol.swift
protocol NotificationCenterProtocol {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func removePendingNotificationRequests(withIdentifiers: [String])
    func getPendingNotificationRequests() async -> [UNNotificationRequest]
    func setBadgeCount(_ count: Int) async throws
}

// LocationManagerProtocol.swift
protocol LocationManagerProtocol {
    var monitoredRegions: Set<CLRegion> { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    func startMonitoring(for region: CLRegion)
    func stopMonitoring(for region: CLRegion)
    func requestState(for region: CLRegion)
}
```

**Files to create/modify**:
- `RitualistTests/TestInfrastructure/MockRepositories.swift` (extend as needed)
- `RitualistTests/TestInfrastructure/TestViewModelContainer.swift` (extend as needed)

**Note**: Per "Real Objects Over Mocks" philosophy, avoid creating MockServices.swift or MockUseCases.swift. Instead:
- Test real service implementations with controlled inputs
- Use in-memory repositories (MockHabitRepository, MockLogRepository)
- Use TestDataBuilders for test data setup
- Clear state between tests (e.g., `clearCache()` for singletons)

---

### Phase 2: Critical Services Testing

**Estimated Tests**: 95-115

#### 2.1 SecurePremiumCacheTests.swift ✅ COMPLETE

**Location**: `RitualistTests/Core/Services/SecurePremiumCacheTests.swift`

**Tests**: 20 (all passing)

**Key Implementation Notes**:
- Uses `.serialized` trait to prevent parallel test interference (shared Keychain singleton)
- Tests real Keychain operations (requires simulator)
- Each test calls `clearCacheForTest()` to ensure isolation

**Test Coverage**:
| Category | Tests | Description |
|----------|-------|-------------|
| Basic Operations | 5 | Fresh cache, update plans (monthly/annual/free), clear cache |
| Trial Behavior | 3 | Future expiry (no grace), past expiry (no grace), no expiry date |
| Paid Subscription | 2 | Future expiry, no expiry (uses cache age) |
| Cache Validity | 4 | Fresh valid, skip verification, stale checks, age tracking |
| Plan Transitions | 3 | Upgrade, downgrade, plan switch |
| Constants | 3 | Grace period (3d), staleness (7d), skip threshold (24h) |

**Critical Finding Documented**: Trials get NO offline grace period - even with future expiry date, `getCachedPremiumStatus()` returns `false`. Only paid subscriptions get the 3-day offline grace period.

#### 2.2 PersonalityAnalysisServiceTests.swift (NEW)

**Location**: `RitualistTests/Core/Services/PersonalityAnalysisServiceTests.swift`

**Tests**: ~25-30

```swift
@Suite("PersonalityAnalysisService", .tags(.businessLogic, .high))
struct PersonalityAnalysisServiceTests {
    // Test Scenarios:
    // - Big Five trait calculation from habit categories
    // - Insufficient data threshold detection
    // - Profile generation with various habit distributions
    // - Edge cases: empty habits, single category, balanced distribution
    // - Personality insights generation
    // - Trend detection (stable, increasing, decreasing)
    // - Confidence level calculation
}
```

#### 2.3 FeatureGatingServiceTests.swift (NEW)

**Location**: `RitualistTests/Core/Services/FeatureGatingServiceTests.swift`

**Tests**: ~10-15

```swift
@Suite("FeatureGatingService", .tags(.businessLogic, .critical))
struct FeatureGatingServiceTests {
    // Test Scenarios:
    // - Free tier habit limits (e.g., max 5 habits)
    // - Premium feature access checks
    // - Feature flag combinations
    // - Upgrade prompts triggering
}
```

#### 2.4 NotificationServiceTests.swift (NEW)

**Location**: `RitualistTests/Core/Services/NotificationServiceTests.swift`

**Tests**: ~50-60

```swift
@Suite("NotificationService - Authorization", .tags(.notifications, .system))
@Suite("NotificationService - Scheduling", .tags(.notifications, .scheduling))
@Suite("NotificationService - Personality Tailoring", .tags(.notifications, .businessLogic))
@Suite("NotificationService - Badge Management", .tags(.notifications))
@Suite("NotificationService - Location Triggers", .tags(.notifications, .location))

// Test Scenarios:
// - Authorization request flows (granted, denied, provisional)
// - Single notification scheduling
// - Batch notification scheduling
// - Rich reminder generation with personality tailoring
// - Streak milestone notifications
// - Badge count management
// - Catch-up notification deduplication
// - Notification action handling (complete, snooze, dismiss)
// - Location-triggered notifications
// - iOS 64-notification limit handling
```

---

### Phase 3: ViewModel Testing

**Estimated Tests**: 130-165

#### 3.1 OverviewViewModelTests.swift (NEW)

**Location**: `RitualistTests/Features/Overview/Presentation/OverviewViewModelTests.swift`

**Tests**: ~40-50

```swift
@Suite("OverviewViewModel - Data Loading", .tags(.dashboard, .critical))
@Suite("OverviewViewModel - Habit Completion", .tags(.habits, .habitLogging))
@Suite("OverviewViewModel - Date Navigation", .tags(.dashboard))
@Suite("OverviewViewModel - Streak Display", .tags(.streaks))
@Suite("OverviewViewModel - Migration State", .tags(.dataLayer))
@Suite("OverviewViewModel - Notification Handling", .tags(.notifications))

// Test Scenarios:
// - Initial data loading with empty/populated habits
// - Date navigation (previous/next day boundaries)
// - Habit completion via quick actions
// - Numeric habit logging sheet flow
// - Streak calculation and display
// - Migration state observation
// - Tab switch vs initial appear behavior
// - Timezone-aware date calculations
// - Refresh on notification received
// - Error state handling
```

#### 3.2 HabitsViewModelTests.swift (NEW)

**Location**: `RitualistTests/Features/Habits/Presentation/HabitsViewModelTests.swift`

**Tests**: ~30-35

```swift
@Suite("HabitsViewModel - List Management", .tags(.habits, .high))
@Suite("HabitsViewModel - CRUD Operations", .tags(.habits, .habitCreation))
@Suite("HabitsViewModel - Filtering", .tags(.habits, .categories))

// Test Scenarios:
// - Habit list loading and sorting (by priority, alphabetical, creation date)
// - Create habit flow with validation
// - Update habit flow
// - Archive/restore habit
// - Delete habit with confirmation
// - Search and text filtering
// - Category filtering
// - Pinned habits ordering
// - Empty state handling
```

#### 3.3 SettingsViewModelTests.swift (NEW)

**Location**: `RitualistTests/Features/Settings/Presentation/SettingsViewModelTests.swift`

**Tests**: ~25-30

```swift
@Suite("SettingsViewModel - Profile", .tags(.settings, .profile))
@Suite("SettingsViewModel - Data Management", .tags(.settings, .dataLayer))
@Suite("SettingsViewModel - Sync", .tags(.settings, .network))

// Test Scenarios:
// - Profile data loading
// - Profile update (name, avatar)
// - Export data flow (JSON generation)
// - Import data flow (validation, conflict resolution)
// - Sync status display
// - Premium status display
// - Timezone settings changes
// - Appearance settings (dark mode)
// - Clear data confirmation flow
// - iCloud account status
```

#### 3.4 StatsViewModelTests.swift (NEW)

**Location**: `RitualistTests/Features/Stats/Presentation/StatsViewModelTests.swift`

**Tests**: ~25-30

```swift
@Suite("StatsViewModel - Statistics", .tags(.stats, .businessLogic))
@Suite("StatsViewModel - Charts", .tags(.stats, .ui))
@Suite("StatsViewModel - Premium", .tags(.stats, .premium))

// Test Scenarios:
// - Statistics calculation for different time ranges
// - Time range selection (week, month, 6 months, year, all time)
// - Chart data generation
// - Consistency heatmap data
// - Export statistics functionality
// - Premium feature gating
// - Empty state for new users
// - Performance with large datasets
```

#### 3.5 PaywallViewModelTests.swift (NEW)

**Location**: `RitualistTests/Features/Paywall/Presentation/PaywallViewModelTests.swift`

**Tests**: ~15-20

```swift
@Suite("PaywallViewModel - Products", .tags(.paywall, .premium))
@Suite("PaywallViewModel - Purchase", .tags(.paywall, .critical))

// Test Scenarios:
// - Product loading from StoreKit
// - Product display formatting
// - Purchase flow (success, cancelled, failed)
// - Restore purchases flow
// - Error handling (network, StoreKit errors)
// - Premium state updates after purchase
// - Trial period display
```

---

### Phase 4: Coordinator & Location Testing

**Estimated Tests**: 70-90

#### 4.1 AppLifecycleCoordinatorTests.swift (NEW)

**Location**: `RitualistTests/Application/Coordinators/AppLifecycleCoordinatorTests.swift`

**Tests**: ~20-25

```swift
@Suite("AppLifecycleCoordinator - Launch", .tags(.infrastructure, .critical))
@Suite("AppLifecycleCoordinator - Background", .tags(.infrastructure, .system))

// Test Scenarios:
// - Initial launch task sequencing
// - Did become active handling
// - Significant time change handling
// - Remote change handling (iCloud)
// - Geofence restoration throttling
// - Notification rescheduling throttling
// - iCloud identity change handling
// - Memory warning handling
// - Termination cleanup
```

#### 4.2 ICloudSyncCoordinatorTests.swift (NEW)

**Location**: `RitualistTests/Core/Coordinators/ICloudSyncCoordinatorTests.swift`

**Tests**: ~15-20

```swift
@Suite("ICloudSyncCoordinator - Sync", .tags(.sync, .network))

// Test Scenarios:
// - Sync availability checks
// - Remote change handling
// - Conflict resolution strategies
// - Status caching
// - Error recovery
// - Offline queue management
// - Sync progress reporting
```

#### 4.3 LocationMonitoringServiceTests.swift (NEW)

**Location**: `RitualistTests/Core/Services/LocationMonitoringServiceTests.swift`

**Tests**: ~20-25

```swift
@Suite("LocationMonitoringService - Monitoring", .tags(.location, .premium))
@Suite("LocationMonitoringService - Geofencing", .tags(.location, .geofencing))

// Test Scenarios:
// - Start monitoring with valid configuration
// - Stop monitoring cleanup
// - Authorization status checks
// - Geofence limit (20 regions) handling
// - Region state determination (inside, outside, unknown)
// - Event handler callbacks (enter, exit)
// - Permission denied handling
// - Location accuracy configuration
```

#### 4.4 PermissionCoordinatorTests.swift (NEW)

**Location**: `RitualistTests/Core/Coordinators/PermissionCoordinatorTests.swift`

**Tests**: ~15-20

```swift
@Suite("PermissionCoordinator - Permissions", .tags(.permissions, .system))

// Test Scenarios:
// - Notification permission request flow
// - Location permission request flow (when in use, always)
// - Permission status checking
// - Combined permission checks
// - Settings redirect for denied permissions
// - First-time vs repeat requests
```

---

### Phase 5: Repository & UseCase Testing

**Estimated Tests**: 80-100

#### 5.1 Repository Tests (7 files)

**Location**: `RitualistTests/Repositories/`

| Repository | Test File | Est. Tests |
|------------|-----------|------------|
| `HabitRepositoryImpl` | `HabitRepositoryTests.swift` | ~15 |
| `LogRepositoryImpl` | `LogRepositoryTests.swift` | ~15 |
| `CategoryRepositoryImpl` | `CategoryRepositoryTests.swift` | ~10 |
| `ProfileRepositoryImpl` | `ProfileRepositoryTests.swift` | ~10 |
| `OnboardingRepositoryImpl` | `OnboardingRepositoryTests.swift` | ~8 |
| `TipRepositoryImpl` | `TipRepositoryTests.swift` | ~8 |
| `PersonalityAnalysisRepositoryImpl` | `PersonalityAnalysisRepositoryTests.swift` | ~10 |

**Common Test Scenarios for Repositories**:
- Create entity
- Read entity (by ID, all, filtered)
- Update entity
- Delete entity
- Error handling (not found, constraint violation)
- Batch operations

#### 5.2 UseCase Tests (Priority Selection)

**Location**: `RitualistTests/Core/UseCases/`

| UseCase | Test File | Est. Tests |
|---------|-----------|------------|
| `HabitUseCases` | `HabitUseCasesTests.swift` | ~15 |
| `HabitCompletionUseCases` | `HabitCompletionUseCasesTests.swift` | ~12 |
| `NotificationUseCases` | `NotificationUseCasesTests.swift` | ~10 |
| `ProfileUseCases` | `ProfileUseCasesTests.swift` | ~10 |
| `CategoryUseCases` | `CategoryUseCasesTests.swift` | ~10 |

---

### Phase 6: Edge Cases & Integration

**Estimated Tests**: 45-60

#### 6.1 Error Handling Test Suite

**Location**: `RitualistTests/Core/ErrorHandling/ErrorHandlingTests.swift`

**Tests**: ~20-25

```swift
@Suite("Error Handling - Recovery", .tags(.errorHandling, .critical))

// Test Scenarios:
// - Network failure recovery
// - Database error handling
// - StoreKit error handling (cancelled, failed, pending)
// - Notification permission denial graceful degradation
// - Location permission denial graceful degradation
// - CloudKit quota exceeded
// - iCloud account unavailable
// - Data migration failures
```

#### 6.2 Integration Tests

**Location**: `RitualistTests/Integration/`

| Test File | Tests | Description |
|-----------|-------|-------------|
| `HabitLifecycleIntegrationTests.swift` | ~10 | Create → Log → Complete → Archive flow |
| `NotificationIntegrationTests.swift` | ~10 | Schedule → Deliver → Action flow |
| `SyncIntegrationTests.swift` | ~10 | Local → Cloud → Conflict resolution |

---

## Implementation Summary

| Phase | Focus Area | New Test Files | Estimated Tests |
|-------|------------|----------------|-----------------|
| 1 | Test Infrastructure | 4 | - |
| 2 | Critical Services | 4 | 100-125 |
| 3 | ViewModels | 5 | 135-165 |
| 4 | Coordinators/Location | 4 | 70-90 |
| 5 | Repositories/UseCases | 12 | 80-100 |
| 6 | Edge Cases/Integration | 4 | 45-60 |
| **Total** | | **~33 files** | **~430-540 tests** |

---

## Coverage Progression Targets

| Milestone | Target Coverage | Verification |
|-----------|-----------------|--------------|
| After Phase 2 | ~45% | `./Scripts/coverage-report.sh` |
| After Phase 3 | ~58% | `./Scripts/coverage-report.sh` |
| After Phase 4 | ~65% | `./Scripts/coverage-report.sh` |
| After Phase 5 | ~75% | `./Scripts/coverage-report.sh` |
| After Phase 6 | **~80%** | `./Scripts/coverage-report.sh` |

---

## Verification Plan

### After Each Phase

```bash
# 1. Run all tests
xcodebuild test -scheme Ritualist -destination 'platform=iOS Simulator,name=iPhone 16'

# 2. Generate coverage report
./Scripts/coverage-report.sh

# 3. Quick coverage check
./Scripts/quick-coverage.sh
```

### Final Verification

```bash
# Run full test suite
xcodebuild test \
  -scheme Ritualist \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -enableCodeCoverage YES

# Generate detailed report
./Scripts/coverage-report.sh

# Verify 80% threshold met
# Expected output: "Overall: 80%+"
```

---

## Testing Patterns Reference

### ViewModel Testing Pattern

Based on existing `HabitDetailViewModelTests.swift`:

```swift
@Suite("ViewModel - Feature", .tags(.feature, .isolated, .fast))
@MainActor
struct ViewModelFeatureTests {

    @Test("Description of expected behavior")
    @MainActor
    func behaviorDescription() async throws {
        // Arrange
        let (viewModel, mocks) = TestViewModelContainer.viewModel(
            // configuration
        )

        // Act
        await viewModel.loadInitialData()

        // Assert
        #expect(viewModel.property == expectedValue)
        #expect(mocks.useCase.executeCallCount == 1)
    }
}
```

### Service Testing Pattern

Based on existing `StreakCalculationServiceTests.swift`:

```swift
@Suite("Service - Calculation", .tags(.businessLogic, .streaks))
struct ServiceCalculationTests {

    @Test("Description")
    func testDescription() async throws {
        // Use real objects where possible
        let service = DefaultServiceImpl()
        let habit = HabitBuilder.binary(schedule: .daily)
        let logs = HabitLogBuilder.multipleLogs(
            habitId: habit.id,
            dates: TestDates.pastDays(5)
        )

        let result = try await service.calculate(habit: habit, logs: logs)

        #expect(result.value == expected)
    }
}
```

### Mock Repository Pattern

Based on existing `MockRepositories.swift`:

```swift
public final class MockServiceRepository: ServiceRepository, @unchecked Sendable {
    public var returnValue: ReturnType
    public var shouldFail = false
    public var failureError: Error = TestError.mock
    public private(set) var executeCallCount = 0

    public func execute() async throws -> ReturnType {
        executeCallCount += 1
        if shouldFail { throw failureError }
        return returnValue
    }
}
```

---

## Critical File Paths

### Test Infrastructure (to extend)
```
RitualistTests/TestInfrastructure/
├── MockRepositories.swift        # Add new mock services
├── TestViewModelContainer.swift  # Add ViewModel factories
├── TestDataBuilders.swift        # Reference for building test data
├── TestModelContainer.swift      # SwiftData container for tests
├── TestTags.swift                # Tag definitions for filtering
└── TimezoneTestHelpers.swift     # Timezone utilities
```

### Highest Priority Source Files (to test)
```
RitualistCore/Sources/RitualistCore/Services/
├── NotificationService.swift           # 1,456 LOC - CRITICAL
├── PersonalityAnalysisService.swift    # 860 LOC - HIGH
├── LocationMonitoringService.swift     # 458 LOC - MEDIUM
└── SecurePremiumCache.swift            # 437 LOC - HIGH

Ritualist/Features/
├── Overview/Presentation/OverviewViewModel.swift    # 1,262 LOC - CRITICAL
├── Settings/Presentation/SettingsViewModel.swift    # 753 LOC - HIGH
├── Stats/Presentation/StatsViewModel.swift          # 727 LOC - HIGH
├── Habits/Presentation/HabitsViewModel.swift        # 660 LOC - HIGH
└── Paywall/Presentation/PaywallViewModel.swift      # 295 LOC - MEDIUM
```

---

## Concurrency Testing Guidelines

### MainActor Isolation Testing

Given Swift Concurrency requirements, all ViewModel and View callback tests should verify proper MainActor isolation:

```swift
@Suite("SettingsView - Callbacks", .tags(.settings, .concurrency))
@MainActor
struct SettingsViewCallbackTests {

    @Test("Appearance change triggers MainActor-isolated save")
    func appearanceChange_triggersMainActorSave() async throws {
        // All @Observable property updates must happen on MainActor
        // The callback pattern: Task { @MainActor in ... }
        let vm = await TestViewModelContainer.settingsViewModel()

        // Simulate picker change (like .onChange callback)
        await vm.updateAppearance(1)  // This should run on MainActor

        #expect(vm.profile.appearance == 1)
    }
}
```

### Key Concurrency Patterns to Test

**Pattern**: `Task { @MainActor in }` in View callbacks

Files with this pattern (all require MainActor tests):
- `SettingsView.swift` - appearance picker, avatar save, paywall dismissal
- `AdvancedSettingsView.swift` - timezone mode/home timezone updates
- `DataManagementSectionView.swift` - export, import, delete flows
- `LocationConfigurationSection.swift` - permission requests, paywall
- `HabitDetail/*.swift` - various async operations

**Test Scenario Template**:
```swift
@Test("Callback updates @Observable state on MainActor")
@MainActor
func callbackUpdatesState() async throws {
    let vm = await createViewModel()

    // Act: Simulate the callback action
    await vm.performAction()

    // Assert: State was updated (would crash if not on MainActor)
    #expect(vm.observableProperty == expectedValue)
}
```

### SwiftUI Callback Testing

When testing View callbacks that spawn Tasks:

```swift
// DON'T test the Task directly - test the ViewModel method
// The Task { @MainActor in } pattern ensures correct isolation

@Test("Button action updates state correctly")
@MainActor
func buttonAction_updatesState() async throws {
    let vm = await TestViewModelContainer.viewModel()

    // Directly test the ViewModel method the Task calls
    await vm.handleButtonTap()

    #expect(vm.isProcessing == false)
    #expect(vm.result != nil)
}
```

---

## Notes

- **Philosophy**: Continue using "Real Objects Over Mocks" where possible
- **Priority**: Business-critical features first (notifications, main dashboard)
- **Tags**: Use existing TestTags for consistent test organization
- **Builders**: Leverage HabitBuilder, HabitLogBuilder for test data
- **Container**: Use TestModelContainer for SwiftData-dependent tests
- **Concurrency**: All ViewModel tests must use `@MainActor` annotation
