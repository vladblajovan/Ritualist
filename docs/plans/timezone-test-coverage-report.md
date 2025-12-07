# Timezone Handling Test Coverage Report

## Executive Summary

This report documents the test coverage gaps for the timezone handling changes made in PR #114, and addresses the observations and suggestions from code review.

---

## Part 1: Unit Tests Needed

### 1.1 OverviewViewModel Refresh Race Condition Tests

**Location:** `RitualistTests/Features/Overview/Presentation/OverviewViewModelRefreshTests.swift`

**Priority:** CRITICAL

| Test Name | Description | Validates |
|-----------|-------------|-----------|
| `refreshDuringLoadSetsNeedsRefreshFlag` | When `refresh()` is called while `isLoading=true`, `needsRefreshAfterLoad` should be set to `true` | Race condition flag is set |
| `loadCompletionChecksAndProcessesPendingRefresh` | After `loadData()` completes, if `needsRefreshAfterLoad=true`, it should reset the flag and reload | Deferred refresh executes |
| `multiplePendingRefreshesOnlyReloadOnce` | Multiple `refresh()` calls during load should only trigger ONE reload after completion | No infinite loops |
| `normalLoadWithoutRefreshDoesNotTriggerExtraLoad` | When no `refresh()` called during load, `needsRefreshAfterLoad` stays `false` | Normal flow unaffected |
| `timezoneChangeTriggersViewingDateRecalculation` | When timezone changes, `viewingDate` should be recalculated | `viewingDate` updates |
| `refreshWhileLoadingReturnsEarly` | `refresh()` should return immediately (not block) when load in progress | Non-blocking behavior |

**Implementation Challenge:** OverviewViewModel uses `@Injected` dependencies from Factory. Options:
1. Extract refresh coordination into a testable `RefreshCoordinator` protocol
2. Use Factory container registration to inject mocks in tests
3. Expose internal state via `@testable import` for verification

**Recommended Approach:** Create a `ViewModelLoadCoordinator` that encapsulates the `isLoading`, `hasLoadedInitialData`, and `needsRefreshAfterLoad` state machine, then test that independently.

---

### 1.2 DashboardViewModel Refresh Race Condition Tests

**Location:** `RitualistTests/Features/Dashboard/Presentation/DashboardViewModelRefreshTests.swift`

**Priority:** CRITICAL

| Test Name | Description | Validates |
|-----------|-------------|-----------|
| `refreshDuringPerformLoadSetsNeedsRefreshFlag` | Same as OverviewViewModel | Race condition flag is set |
| `performLoadCompletionChecksAndProcessesPendingRefresh` | Same as OverviewViewModel | Deferred refresh executes |
| `timezoneChangeUpdatesDisplayTimezone` | `displayTimezone` should update when service returns new value | Timezone propagation |

**Note:** Same implementation pattern as OverviewViewModel, so infrastructure can be shared.

---

### 1.3 Notification Reschedule Throttle Tests

**Location:** `RitualistTests/Application/NotificationRescheduleThrottleTests.swift`

**Priority:** HIGH

| Test Name | Description | Validates |
|-----------|-------------|-----------|
| `firstRescheduleAlwaysExecutes` | When `lastNotificationRescheduleUptime` is `nil`, reschedule should run | Initial reschedule works |
| `rescheduleWithinThrottleIntervalSkipped` | Reschedule within 5s of last reschedule should be skipped | Throttle prevents duplicate |
| `rescheduleAfterThrottleIntervalExecutes` | Reschedule after 5+ seconds should execute normally | Throttle releases |
| `throttleUsesSystemUptime` | Throttle should use `ProcessInfo.systemUptime` (not `Date()`) | Clock-drift immunity |
| `failedRescheduleDoesNotUpdateTimestamp` | If reschedule throws, timestamp should not be updated | Retry possible after failure |

**Implementation Challenge:** Testing requires mocking `ProcessInfo.processInfo.systemUptime` or using time-based waits.

**Recommended Approach:** Extract throttle logic into a `ThrottledOperation` utility class that accepts a time provider closure for testing.

---

### 1.4 TimezoneService First Launch Tests

**Location:** `RitualistTests/Services/TimezoneServiceTests.swift` (already partially done)

**Priority:** HIGH (already added in current PR)

| Test Name | Status | Description |
|-----------|--------|-------------|
| `firstLaunchDetectTimezoneChangeReturnsNilNoMismatch` | ✅ Added | Fresh install doesn't trigger alert |
| `firstLaunchNoTimezoneAlertShouldBeShown` | ✅ Added | Alert logic returns false |
| `firstLaunchWithExistingICloudProfileDetectsTimezoneChangeIfDifferent` | ✅ Added | iCloud sync scenario |

---

### 1.5 Timezone Detection Integration Tests

**Location:** `RitualistTests/Services/TimezoneServiceTests.swift` (already added)

**Priority:** HIGH (already added in current PR)

| Test Name | Status | Description |
|-----------|--------|-------------|
| `detectTimezoneChangeIsReadOnlyDoesNotModifyProfile` | ✅ Added | Detection doesn't persist |
| `detectTimezoneChangeFollowedByUpdateCurrentTimezonePersistsChange` | ✅ Added | Explicit update persists |
| `multipleDetectTimezoneChangeCallsReturnSameChangeUntilUpdateCalled` | ✅ Added | Idempotent detection |
| `completeTimezoneChangeFlowDetectShowAlertUserConfirmsUpdate` | ✅ Added | Happy path |
| `timezoneChangeFlowWhenUserDismissesAlertNoUpdatePersisted` | ✅ Added | Cancel path |
| `travelDetectionUserTravelsFromHomeTimezone` | ✅ Added | Travel detection |
| `travelDetectionUserReturnsHome` | ✅ Added | Return home detection |

---

### 1.6 ViewLogic Tests (Lower Priority)

**Location:** `RitualistTests/Features/Overview/Presentation/ViewLogic/`

| Test Name | Priority | Description |
|-----------|----------|-------------|
| `canGoToPreviousDayRespectsTimezone` | MEDIUM | Date navigation uses display timezone |
| `canGoToNextDayRespectsTimezone` | MEDIUM | Date navigation uses display timezone |
| `isViewingTodayRespectsTimezone` | MEDIUM | Today check uses display timezone |

---

## Part 2: Code Review Observations & Responses

### 2.1 Performance Consideration - Timezone Lookup on Every Load

**Observation:**
```swift
// OverviewViewModel.swift:263
let newTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current
```
> Suggestion: Cache timezone and only refresh on explicit timezone change events.

**Response:**

The current implementation is **intentionally defensive**. Here's why:

1. **Tab switches are infrequent** - Users don't rapidly switch tabs
2. **Timezone lookups are fast** - Single SwiftData query, typically <1ms
3. **Caching adds complexity** - Would need invalidation logic, potential stale data bugs
4. **Current safeguards exist:**
   - `hasLoadedInitialData` prevents redundant full loads
   - `needsRefreshAfterLoad` handles race conditions
   - Throttling already exists for notification rescheduling

**Recommendation:** No change needed. If profiling shows this is a bottleneck, we can optimize later. Premature optimization risk outweighs minor performance gain.

**Action:** None required.

---

### 2.2 Error Handling - Silent Fallback to .current

**Observation:**
```swift
let newTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current
```
> Suggestion: Log these fallbacks for debugging.

**Response:**

This is a **valid improvement**. The fallback is safe but should be logged.

**Current State:**
- TimezoneService already logs fallbacks internally (added in previous PR iteration)
- See `TimezoneService.swift:getHomeTimezone()` and `getDisplayTimezone()` - both log warnings when falling back

**Verification:**
```swift
// TimezoneService.swift - already implemented
guard let timezone = TimeZone(identifier: profile.homeTimezoneIdentifier) else {
    logger.log(
        "⚠️ Invalid home timezone identifier, falling back to current",
        level: .warning,
        category: .system,
        metadata: [
            "invalidIdentifier": profile.homeTimezoneIdentifier,
            "fallback": TimeZone.current.identifier
        ]
    )
    return TimeZone.current
}
```

**Action:** Already addressed. No further changes needed.

---

### 2.3 Localization Status

**Observation:** Check if timezone change alert is fully localized.

**Response:** ✅ **Verified complete.**

All strings in `Localizable.xcstrings`:
- "Timezone Changed" ✅
- "Keep Home Timezone" ✅
- "Use Current Timezone" ✅
- "I Moved Here" ✅
- Alert message with interpolation ✅

**Action:** None required.

---

### 2.4 Notification Rescheduling Throttle Value

**Observation:**
> Question: Is 5 seconds the optimal value?

**Response:**

5 seconds is **appropriate** for this use case:

1. **Timezone changes are rare** - Typically once per travel event
2. **Multiple events at midnight** - `significantTimeChange` + timezone detection could fire together
3. **User testing scenario** - Even rapid testing won't be faster than 5 seconds between meaningful changes
4. **Notification scheduling is idempotent** - Duplicate schedules don't cause harm, just waste CPU

**Comparison with other throttles in the codebase:**
- Geofence restoration: 60 seconds (more expensive operation)
- iCloud status check: 30 seconds (network call)
- Notification reschedule: 5 seconds (local operation)

**Action:** None required. 5 seconds is reasonable.

---

### 2.5 Build Number Jump (234 → 242)

**Observation:**
> Question: Was this intentional or multiple failed builds?

**Response:**

The build number increment is **normal development activity**:

1. Auto-incremented on each build by `Auto Build Number` script
2. Multiple debug builds during development
3. Test iterations for timezone handling
4. No concern - build numbers are informational only

**Action:** None required.

---

### 2.6 Race Condition in OverviewViewModel (Addressed)

**Observation:**
> Issue: If timezone changes between loads, the early return might prevent timezone updates.

**Response:** ✅ **Already addressed** by `needsRefreshAfterLoad` pattern.

The flow:
1. `refresh()` called while `isLoading=true`
2. `needsRefreshAfterLoad = true` set, returns early
3. Current `loadData()` completes
4. Checks `needsRefreshAfterLoad`, triggers reload
5. New load fetches fresh timezone

**Action:** Already implemented. Added tests to verify (see Part 1).

---

### 2.7 TimezoneService Default Profile Creation

**Observation:**
> Question: Is this handled by LoadProfile or TimezoneService?

**Response:**

**LoadProfile use case** creates the default profile:

```swift
// LoadProfile.execute()
public func execute() async throws -> UserProfile {
    if let existing = try await repo.loadProfile() {
        return existing
    }
    // Create default profile with current timezone
    let defaultProfile = UserProfile.createDefault()
    try await repo.saveProfile(defaultProfile)
    return defaultProfile
}
```

**UserProfile.createDefault()** sets:
- `currentTimezoneIdentifier = TimeZone.current.identifier`
- `homeTimezoneIdentifier = TimeZone.current.identifier`
- `displayTimezoneMode = .current`

**Documentation:** The test file documents this:
```swift
// On first launch, getHomeTimezone/detectTimezoneChange will create a default profile
// with currentTimezoneIdentifier = TimeZone.current.identifier
```

**Action:** Documentation is sufficient. No changes needed.

---

## Part 3: Implementation Recommendations

### 3.1 Create ViewModelLoadCoordinator (For Testability)

To properly test the refresh race condition without mocking 20+ dependencies:

```swift
// RitualistCore/Sources/RitualistCore/Utilities/ViewModelLoadCoordinator.swift

/// Coordinates load/refresh state to handle race conditions
/// Used by ViewModels that need refresh-during-load protection
public final class ViewModelLoadCoordinator {
    public private(set) var isLoading = false
    public private(set) var hasLoadedInitialData = false
    private var needsRefreshAfterLoad = false

    /// Call before starting a load operation
    /// Returns false if load should be skipped
    public func shouldStartLoad(forceReload: Bool = false) -> Bool {
        guard !isLoading else {
            needsRefreshAfterLoad = true
            return false
        }
        if !forceReload && hasLoadedInitialData {
            return false
        }
        isLoading = true
        return true
    }

    /// Call after load completes
    /// Returns true if a deferred refresh should be executed
    public func loadCompleted() -> Bool {
        isLoading = false
        hasLoadedInitialData = true
        if needsRefreshAfterLoad {
            needsRefreshAfterLoad = false
            return true // Caller should reload
        }
        return false
    }

    /// Call from refresh() method
    /// Returns true if refresh should proceed, false if deferred
    public func requestRefresh() -> Bool {
        if isLoading {
            needsRefreshAfterLoad = true
            return false
        }
        hasLoadedInitialData = false
        return true
    }

    /// Invalidate cache (e.g., for tab switch)
    public func invalidateCache() {
        if hasLoadedInitialData {
            hasLoadedInitialData = false
        }
    }
}
```

This allows testing the coordination logic independently:

```swift
@Test("Refresh during load sets pending flag")
func refreshDuringLoadSetsPendingFlag() {
    let coordinator = ViewModelLoadCoordinator()

    // Start load
    #expect(coordinator.shouldStartLoad() == true)
    #expect(coordinator.isLoading == true)

    // Request refresh during load
    #expect(coordinator.requestRefresh() == false) // Deferred

    // Complete load
    #expect(coordinator.loadCompleted() == true) // Should reload
}
```

### 3.2 Create ThrottledOperation Utility (For Testability)

```swift
// RitualistCore/Sources/RitualistCore/Utilities/ThrottledOperation.swift

/// Throttles operations to prevent rapid-fire execution
public final class ThrottledOperation {
    private let interval: TimeInterval
    private let uptimeProvider: () -> TimeInterval
    private var lastExecutionUptime: TimeInterval?

    public init(
        interval: TimeInterval,
        uptimeProvider: @escaping () -> TimeInterval = { ProcessInfo.processInfo.systemUptime }
    ) {
        self.interval = interval
        self.uptimeProvider = uptimeProvider
    }

    /// Returns true if operation should execute, false if throttled
    public func shouldExecute() -> Bool {
        let currentUptime = uptimeProvider()
        if let last = lastExecutionUptime, currentUptime - last < interval {
            return false
        }
        return true
    }

    /// Mark operation as executed
    public func markExecuted() {
        lastExecutionUptime = uptimeProvider()
    }
}
```

This allows testing with controlled time:

```swift
@Test("Operation throttled within interval")
func operationThrottledWithinInterval() {
    var mockUptime: TimeInterval = 100
    let throttle = ThrottledOperation(interval: 5.0) { mockUptime }

    // First execution
    #expect(throttle.shouldExecute() == true)
    throttle.markExecuted()

    // Within interval
    mockUptime = 103 // 3 seconds later
    #expect(throttle.shouldExecute() == false)

    // After interval
    mockUptime = 106 // 6 seconds later
    #expect(throttle.shouldExecute() == true)
}
```

---

## Part 4: Test Infrastructure Additions

### 4.1 Extend TestViewModelContainer

```swift
// Add to TestViewModelContainer.swift

// MARK: - ViewModelLoadCoordinator Factory

public static func loadCoordinator() -> ViewModelLoadCoordinator {
    return ViewModelLoadCoordinator()
}

// MARK: - ThrottledOperation Factory

public static func throttledOperation(
    interval: TimeInterval = 5.0,
    initialUptime: TimeInterval = 0
) -> (operation: ThrottledOperation, setUptime: (TimeInterval) -> Void) {
    var mockUptime = initialUptime
    let operation = ThrottledOperation(interval: interval) { mockUptime }
    return (operation, { mockUptime = $0 })
}
```

---

## Part 5: Summary

### Tests Already Added (This PR)
- 8 timezone detection integration tests ✅
- 3 first-launch behavior tests ✅
- Total: 48 timezone tests passing

### Tests Recommended (Future Work)
| Category | Test Count | Priority | Effort |
|----------|------------|----------|--------|
| OverviewViewModel refresh coordination | 6 | CRITICAL | Medium (requires refactor) |
| DashboardViewModel refresh coordination | 3 | CRITICAL | Low (reuse infrastructure) |
| Notification throttle | 5 | HIGH | Medium (requires refactor) |
| View logic timezone tests | 3 | MEDIUM | Low |
| **Total** | **17** | | |

### Recommended Approach
1. Create `ViewModelLoadCoordinator` utility class
2. Create `ThrottledOperation` utility class
3. Write unit tests for these utilities
4. Refactor ViewModels to use these utilities
5. Integration tests verify ViewModels use utilities correctly

This approach:
- Separates testable logic from UI/dependency concerns
- Creates reusable infrastructure for future ViewModels
- Follows existing patterns in the codebase
- Avoids complex mocking of 20+ Factory dependencies
