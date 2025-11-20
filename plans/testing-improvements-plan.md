# Testing Improvements Plan

**Created:** 2025-11-20
**Branch:** `feature/testing-improvements`
**Status:** 🟡 Planning

---

## 📋 Executive Summary

This plan outlines a comprehensive testing improvement initiative to strengthen test coverage for critical business logic, timezone handling, and notification services in the Ritualist iOS app. The focus is on untested services with high business impact and clear testing requirements.

**Current State:**
- ✅ 20 test files, 337 test cases, 8,143 lines of test code
- ✅ Excellent test infrastructure (Swift Testing, builders, fixtures)
- ❌ 10+ critical services untested
- ❌ No UI/ViewModel tests
- ❌ No CI/CD test automation

**Goals:**
- Add 133-154 new test cases across 10+ services
- Address code comments requesting regression tests (PerformanceAnalysisService)
- Strengthen notification reliability testing
- Improve timezone edge case coverage

---

## 🎯 Testing Priorities

### **🔴 HIGH PRIORITY - Critical Business Logic**

#### 1. HistoricalDateValidationService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/HistoricalDateValidationService.swift:82`
**Why Critical:** Validates date boundaries for historical logging (30-day limit)
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐⭐⭐

**Test Cases to Add:**
```swift
@Suite("HistoricalDateValidationService Tests")
struct HistoricalDateValidationServiceTests {

    // Boundary Tests
    @Test("Date within bounds is valid")
    @Test("Future date throws futureDate error")
    @Test("Date beyond history limit throws beyondHistoryLimit error")
    @Test("Invalid date string throws invalidDateFormat error")

    // Edge Cases
    @Test("Date exactly at boundary (today) is valid")
    @Test("Date exactly at boundary (30 days ago) is valid")
    @Test("Date 31 days ago is invalid")

    // API Tests
    @Test("isDateWithinBounds returns correct boolean")
    @Test("getEarliestAllowedDate returns correct date")

    // Configuration Tests
    @Test("Custom maxHistoryDays configuration works")
}
```

**Estimated Effort:** 1-2 hours
**Estimated Test Cases:** 10-12

---

#### 2. PerformanceAnalysisService Tests ⚠️ REGRESSION RISK
**File:** `RitualistCore/Sources/RitualistCore/Services/PerformanceAnalysisService.swift:76`
**Why Critical:** Powers Dashboard metrics; code explicitly requests regression tests
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐⭐⭐

**📝 Code Comment (Line 70-75):**
> "**Regression Test Recommendation:**
> Add tests verifying that partial progress (logValue < target) is NOT counted as complete"

**Test Cases to Add:**
```swift
@Suite("PerformanceAnalysisService Tests")
struct PerformanceAnalysisServiceTests {

    // CRITICAL BUG REGRESSION TESTS (requested in code)
    @Test("Partial numeric progress is NOT counted as complete")
    // Test: target=8, value=3 → should NOT count

    @Test("Full numeric progress IS counted as complete")
    // Test: target=5, value=5 → should count

    @Test("Binary habit with value 1.0 is counted as complete")
    @Test("Binary habit with value 0.0 is NOT counted as complete")

    // Habit Performance Calculations
    @Test("calculateHabitPerformance with no logs returns 0%")
    @Test("calculateHabitPerformance with all days completed returns 100%")
    @Test("calculateHabitPerformance handles retroactive logging")
    @Test("calculateHabitPerformance respects habit schedules")
    @Test("calculateHabitPerformance sorts by completion rate descending")

    // Weekly Patterns
    @Test("analyzeWeeklyPatterns identifies best day")
    @Test("analyzeWeeklyPatterns identifies worst day")
    @Test("analyzeWeeklyPatterns with no data returns zero averages")
    @Test("analyzeWeeklyPatterns calculates average weekly completion")

    // Perfect Day Streaks
    @Test("calculateStreakAnalysis finds current streak")
    @Test("calculateStreakAnalysis finds longest streak")
    @Test("Perfect day streak requires ALL habits completed")
    @Test("Streak broken when one habit incomplete")
    @Test("Streak trend is 'improving' when near longest")
    @Test("Streak trend is 'declining' when below 50% of longest")

    // Progress Chart Data
    @Test("generateProgressChartData sorts by date")
    @Test("generateProgressChartData maps completion stats correctly")

    // Category Performance
    @Test("aggregateCategoryPerformance groups habits correctly")
    @Test("aggregateCategoryPerformance handles uncategorized habits")
    @Test("aggregateCategoryPerformance skips suggestion-unknown group")
    @Test("aggregateCategoryPerformance sorts by completion rate")
}
```

**Estimated Effort:** 3-4 hours
**Estimated Test Cases:** 25-30

---

#### 3. HabitCompletionCheckService Tests - Orchestration Layer Only
**File:** `RitualistCore/Sources/RitualistCore/Services/HabitCompletionCheckService.swift:36`
**Why Critical:** Orchestrates notification decisions; fail-safe logic critical for reliability
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐⭐

**🎯 TESTING SCOPE CLARITY:**

This service is an **orchestration layer** that coordinates multiple services for notification decisions. It is fundamentally different from `HabitCompletionService`:

| Aspect | HabitCompletionService | HabitCompletionCheckService |
|--------|------------------------|----------------------------|
| **Purpose** | Pure completion logic | Notification orchestration |
| **Dependencies** | None (pure functions) | 4 dependencies (repositories, services) |
| **Test Coverage** | ✅ 25 test cases (656 lines) | ❌ None |
| **What it does** | Calculates if habit is completed | Decides if notification should show |
| **Layer** | Business logic | Application/Orchestration |

**What is ALREADY TESTED (HabitCompletionService):**
- ❌ Binary habit completion logic
- ❌ Numeric habit completion logic (target validation)
- ❌ Schedule-specific completion (daily, daysOfWeek)
- ❌ Progress calculations
- ❌ Timezone-aware date comparisons

**What NEEDS TESTING (HabitCompletionCheckService):**
- ✅ Lifecycle validation (isActive, startDate, endDate checks)
- ✅ Repository orchestration (async habit/log fetching)
- ✅ Timezone service integration (display timezone fetching)
- ✅ Fail-safe error handling (returns true on errors)
- ✅ Service coordination (calls HabitCompletionService correctly)

**Test Cases to Add (Orchestration-Only Focus):**
```swift
@Suite("HabitCompletionCheckService - Orchestration Layer Tests")
struct HabitCompletionCheckServiceTests {

    // CRITICAL: These tests validate ORCHESTRATION, not completion logic
    // Core completion logic is thoroughly tested in HabitCompletionServiceTests (25 tests)

    // 1. LIFECYCLE VALIDATIONS (Unique to this service - not in HabitCompletionService)
    @Test("shouldShowNotification returns false for inactive habit")
    // Tests that service checks habit.isActive before evaluating completion

    @Test("shouldShowNotification returns false before habit start date")
    // Tests date boundary: today < habit.startDate

    @Test("shouldShowNotification returns false after habit end date")
    // Tests date boundary: today >= habit.endDate

    @Test("shouldShowNotification returns false on habit end date boundary")
    // Tests edge case: exactly on endDate

    // 2. REPOSITORY ORCHESTRATION (Async coordination - not in HabitCompletionService)
    @Test("shouldShowNotification fetches habit from repository asynchronously")
    // Tests: await habitRepository.fetchHabit(by:)

    @Test("shouldShowNotification fetches logs from repository asynchronously")
    // Tests: await logRepository.logs(for:)

    @Test("shouldShowNotification fails safe when habit not found (returns true)")
    // Tests fail-safe: repository returns nil → return true (show notification)

    // 3. TIMEZONE SERVICE INTEGRATION (Service coordination - not in HabitCompletionService)
    @Test("shouldShowNotification uses display timezone from TimezoneService")
    // Tests: await timezoneService.getDisplayTimezone()

    @Test("shouldShowNotification falls back to current timezone on fetch error")
    // Tests fail-safe: timezone service throws → use TimeZone.current

    // 4. FAIL-SAFE ERROR HANDLING (Critical orchestration behavior)
    @Test("shouldShowNotification fails safe on repository error (returns true)")
    // Tests: repository throws → return true (safer to show notification)

    @Test("shouldShowNotification fails safe on completion check error (returns true)")
    // Tests: habitCompletionService throws → return true

    // 5. SERVICE DELEGATION (Validates correct HabitCompletionService usage)
    @Test("shouldShowNotification delegates completion check to HabitCompletionService")
    // Tests: Calls habitCompletionService.isCompleted() with correct parameters

    @Test("shouldShowNotification delegates schedule check to HabitCompletionService")
    // Tests: Calls habitCompletionService.isScheduledDay() for daysOfWeek habits
}
```

**Key Testing Principles:**
1. **No Duplication:** Do NOT re-test completion logic (already covered)
2. **Focus on Glue:** Test how services are coordinated together
3. **Async Behavior:** Test proper async/await orchestration
4. **Error Paths:** Test all fail-safe scenarios (critical for notifications)
5. **Integration Points:** Test service boundaries and handoffs

**Estimated Effort:** 2-3 hours
**Estimated Test Cases:** 12-15 (orchestration-focused, no logic duplication)

---

#### 4. TimezoneService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/TimezoneService.swift:144`
**Why Critical:** Manages three-timezone model (Current/Home/Display); complex logic
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐⭐⭐

**Test Cases to Add:**
```swift
@Suite("TimezoneService Tests")
struct TimezoneServiceTests {

    // Getters
    @Test("getCurrentTimezone returns device timezone")
    @Test("getHomeTimezone returns stored home timezone")
    @Test("getHomeTimezone falls back to current on invalid identifier")
    @Test("getDisplayTimezoneMode returns stored display mode")
    @Test("getDisplayTimezone resolves based on mode - current")
    @Test("getDisplayTimezone resolves based on mode - home")
    @Test("getDisplayTimezone resolves based on mode - custom")
    @Test("getDisplayTimezone falls back to current on invalid identifier")

    // Setters
    @Test("updateHomeTimezone updates profile")
    @Test("updateHomeTimezone logs timezone change")
    @Test("updateHomeTimezone throws on invalid identifier")
    @Test("updateHomeTimezone updates timestamps")
    @Test("updateDisplayTimezoneMode updates profile")
    @Test("updateDisplayTimezoneMode logs change when mode changes")
    @Test("updateDisplayTimezoneMode does not log when mode unchanged")

    // History Management
    @Test("Timezone change history is trimmed to 100 entries")
    @Test("Timezone change history preserves most recent entries")

    // Detection
    @Test("detectTimezoneChange returns nil when no change")
    @Test("detectTimezoneChange detects device timezone change")
    @Test("detectTimezoneChange returns correct previous and new timezones")
    @Test("detectTravelStatus returns nil when not traveling")
    @Test("detectTravelStatus detects travel (Current ≠ Home)")
    @Test("detectTravelStatus sets isTravel flag correctly")

    // Update Operations
    @Test("updateCurrentTimezone updates device timezone")
    @Test("updateCurrentTimezone logs timezone change")
    @Test("updateCurrentTimezone skips update if unchanged")
}
```

**Estimated Effort:** 3-4 hours
**Estimated Test Cases:** 28-30

---

### **🟡 MEDIUM PRIORITY - Important Features**

#### 5. DailyNotificationSchedulerService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/DailyNotificationSchedulerService.swift:18`
**Why Important:** Daily notification rescheduling reliability
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐⭐
**Challenge:** Requires protocol abstraction for `UNUserNotificationCenter` (see Infrastructure section)

**Test Cases to Add:**
```swift
@Suite("DailyNotificationSchedulerService Tests")
struct DailyNotificationSchedulerServiceTests {

    @Test("rescheduleAllHabitNotifications fetches active habits")
    @Test("rescheduleAllHabitNotifications filters habits with reminders")
    @Test("rescheduleAllHabitNotifications clears existing habit notifications")
    @Test("rescheduleAllHabitNotifications preserves non-habit notifications")
    @Test("rescheduleAllHabitNotifications identifies habit notifications by prefix")
    @Test("rescheduleAllHabitNotifications schedules for active habits with reminders")
    @Test("rescheduleAllHabitNotifications skips inactive habits")
    @Test("rescheduleAllHabitNotifications skips habits without reminders")
    @Test("rescheduleAllHabitNotifications handles scheduling errors gracefully")
    @Test("rescheduleAllHabitNotifications logs scheduling metrics")
}
```

**Estimated Effort:** 3-4 hours (protocol abstraction complexity)
**Estimated Test Cases:** 10-12

---

#### 6. HabitSuggestionsService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/HabitSuggestionsService.swift:25`
**Why Important:** Onboarding UX depends on suggestions
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐

**Test Cases to Add:**
```swift
@Suite("HabitSuggestionsService Tests")
struct HabitSuggestionsServiceTests {

    @Test("getSuggestions returns all suggestions")
    @Test("getSuggestions returns non-empty array")
    @Test("getSuggestions(for categoryId) filters by category")
    @Test("getSuggestions(for categoryId) returns only matching category")
    @Test("getSuggestions(for categoryId) returns empty for invalid category")
    @Test("getSuggestion(by id) returns specific suggestion")
    @Test("getSuggestion(by id) returns correct suggestion properties")
    @Test("getSuggestion(by id) returns nil for invalid id")
}
```

**Estimated Effort:** 1 hour
**Estimated Test Cases:** 8-10

---

#### 7. View Logic Tests - Additional Edge Cases
**Current Coverage:** ✅ 5 files tested
**Opportunity:** Add edge cases to existing tests

**Additional Tests for `ProgressColorViewLogicTests`:**
```swift
@Test("Color transitions smoothly across thresholds")
@Test("Edge case: exactly 0% completion")
@Test("Edge case: exactly 100% completion")
@Test("Edge case: negative completion (defensive)")
@Test("Edge case: completion > 100% (defensive)")
```

**Estimated Effort:** 1 hour
**Estimated Test Cases:** 5 per view logic file = 25 total

---

### **🟢 LOWER PRIORITY - Nice to Have**

#### 8. URLValidationService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/URLValidationService.swift`
**Why:** Simple validation logic, good for completeness
**Test Value:** ⭐⭐
**Estimated Effort:** 30 minutes

#### 9. CalculateConsecutiveTrackingDaysService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/CalculateConsecutiveTrackingDaysService.swift`
**Why:** Untested service for tracking consecutive days
**Test Value:** ⭐⭐⭐
**Estimated Effort:** 1-2 hours

#### 10. Location Services Tests
**Files:** `LocationMonitoringService.swift`, `LocationPermissionService.swift`
**Why:** Location-based features
**Test Value:** ⭐⭐
**Challenge:** Requires mocking CoreLocation
**Estimated Effort:** 3-4 hours

---

## 📅 Implementation Roadmap

### **Phase 0: Test Infrastructure Setup** (Before Phase 1)
**Focus:** Build reusable test infrastructure to support all subsequent phases

**Infrastructure Components:**

| Component | Purpose | Effort | Priority |
|-----------|---------|--------|----------|
| NotificationCenterProtocol | Protocol abstraction for notification testing | 1-1.5 hours | 🔴 Critical |
| SystemNotificationCenter | Production wrapper for UNUserNotificationCenter | 30 min | 🔴 Critical |
| InMemoryNotificationCenter | Test implementation with real in-memory behavior | 1 hour | 🔴 Critical |
| UserProfileBuilder | Simplify timezone/profile test data creation | 30-45 min | 🔴 Critical |
| Infrastructure Validation Tests | Meta-tests to validate test infrastructure behavior | 30-45 min | 🔴 Critical |

**Total Phase 0:** 3-4.5 hours

**Deliverables:**
- `RitualistTests/TestInfrastructure/NotificationTestHelpers.swift`
  - NotificationCenterProtocol definition
  - SystemNotificationCenter implementation
  - InMemoryNotificationCenter implementation
- `RitualistTests/TestInfrastructure/TestDataBuilders.swift` (extend existing)
  - UserProfileBuilder enum with helper methods
- `RitualistTests/TestInfrastructure/InfrastructureValidationTests.swift` (NEW)
  - Meta-tests validating test infrastructure behavior
  - 5-8 test cases ensuring infrastructure reliability

**Success Criteria:**
- ✅ NotificationCenterProtocol compiles and passes basic smoke test
- ✅ InMemoryNotificationCenter correctly stores/removes pending requests
- ✅ UserProfileBuilder creates valid UserProfile instances
- ✅ All infrastructure follows existing patterns (TestModelContainer, TestDataBuilders)
- ✅ No production code changes required (test-only infrastructure)

**Infrastructure Validation Tests:**
Create comprehensive meta-tests to validate test infrastructure before using it in Phase 1-3:

```swift
// File: RitualistTests/TestInfrastructure/InfrastructureValidationTests.swift
@Suite("Infrastructure Validation Tests")
struct InfrastructureValidationTests {

    // NOTIFICATION CENTER PROTOCOL VALIDATION (3-4 tests)
    @Test("InMemoryNotificationCenter stores and retrieves requests")
    func notificationCenterBasicBehavior() async throws {
        let center = InMemoryNotificationCenter()
        let request = UNNotificationRequest(
            identifier: "test",
            content: UNMutableNotificationContent(),
            trigger: nil
        )

        try await center.add(request)
        let pending = await center.pendingNotificationRequests()

        #expect(pending.count == 1)
        #expect(pending.first?.identifier == request.identifier)
    }

    @Test("InMemoryNotificationCenter removes requests by identifier")
    func notificationCenterRemoval() async throws {
        let center = InMemoryNotificationCenter()
        let request = UNNotificationRequest(identifier: "test", content: UNMutableNotificationContent(), trigger: nil)

        try await center.add(request)
        center.removePendingNotificationRequests(withIdentifiers: ["test"])
        let pending = await center.pendingNotificationRequests()

        #expect(pending.isEmpty)
    }

    @Test("InMemoryNotificationCenter isolates multiple requests")
    // Validates: Adding multiple requests doesn't cause overlap

    @Test("InMemoryNotificationCenter handles duplicate identifiers correctly")
    // Validates: Adding same identifier replaces previous request (matches UNUserNotificationCenter behavior)

    // USER PROFILE BUILDER VALIDATION (2-3 tests)
    @Test("UserProfileBuilder creates profile with home timezone")
    func userProfileBuilderHomeTimezone() throws {
        let profile = UserProfileBuilder.withHomeTimezone("America/New_York")

        #expect(profile.homeTimezone == "America/New_York")
        #expect(profile.currentTimezone == "UTC") // Default
    }

    @Test("UserProfileBuilder creates profile with display timezone mode")
    // Validates: DisplayTimezoneMode is correctly set

    @Test("UserProfileBuilder creates profile with travel status")
    // Validates: Can create profiles simulating travel (current ≠ home)
}
```

**Test Count:** 5-8 validation tests
**Effort:** 30-45 minutes
**Why Critical:** Ensures test infrastructure is reliable before building hundreds of tests on top of it

**Why Phase 0 is Critical:**
- Phase 2 (notifications) depends on NotificationCenterProtocol
- Phase 2 (timezone) depends on UserProfileBuilder
- Building infrastructure first prevents blocking during test implementation
- Allows early validation of "NO MOCKS" protocol abstraction approach

---

### **Phase 1: Critical Business Logic** (Week 1)
**Focus:** High-impact, pure logic tests

**Prerequisites:** ✅ Phase 0 complete (UserProfileBuilder available)

| Service | Effort | Test Cases | Priority |
|---------|--------|------------|----------|
| HistoricalDateValidationService | 1-2 hours | 10-12 | 🔴 High |
| PerformanceAnalysisService | 3-4 hours | 25-30 | 🔴 High |
| HabitCompletionCheckService | 2-3 hours | 12-15 | 🔴 High |

**Total Phase 1:** 6-9 hours, 47-57 test cases

**Success Criteria:**
- ✅ All high-priority services have test coverage
- ✅ Regression tests for PerformanceAnalysisService bug (commit edceada)
- ✅ Notification logic validated with edge cases

---

### **Phase 2: Timezone & Notification Logic** (Week 2)
**Focus:** Complex timezone handling and notification reliability

**Prerequisites:** ✅ Phase 0 complete (NotificationCenterProtocol + UserProfileBuilder available)

| Service | Effort | Test Cases | Priority |
|---------|--------|------------|----------|
| TimezoneService | 3-4 hours | 28-30 | 🔴 High |
| DailyNotificationSchedulerService | 3-4 hours | 10-12 | 🟡 Medium |

**Total Phase 2:** 6-8 hours, 38-42 test cases

**Success Criteria:**
- ✅ Three-timezone model fully tested
- ✅ Travel detection validated
- ✅ Notification scheduling logic covered

---

### **Phase 3: Feature Completeness** (Week 3)
**Focus:** Round out coverage with medium/low priority services

| Service | Effort | Test Cases | Priority |
|---------|--------|------------|----------|
| HabitSuggestionsService | 1 hour | 8-10 | 🟡 Medium |
| View Logic Edge Cases | 1 hour | 25 | 🟡 Medium |
| URLValidationService | 30 min | 5-8 | 🟢 Low |
| CalculateConsecutiveTrackingDaysService | 1-2 hours | 10-12 | 🟢 Low |

**Total Phase 3:** 3.5-4.5 hours, 48-55 test cases

**Success Criteria:**
- ✅ All medium-priority services covered
- ✅ Edge cases added to existing view logic tests
- ✅ Validation services tested

---

### **Phase 4: CI/CD Test Automation** (Future - Post-Implementation)
**Focus:** Automate test execution and enforce quality gates

**Scope:** CI/CD integration is **deferred to future work** but documented here for completeness.

**Proposed GitHub Actions Workflow:**

| Component | Purpose | Effort | Priority |
|-----------|---------|--------|----------|
| Test Execution Workflow | Run all tests on PR creation | 2-3 hours | 🟡 Medium |
| Coverage Reporting | Generate and upload code coverage reports | 1-2 hours | 🟡 Medium |
| Build Matrix Testing | Test all 4 build configurations | 1 hour | 🟡 Medium |
| Quality Gates | Enforce minimum coverage thresholds | 30 min | 🟡 Medium |

**Total Phase 4:** 4.5-6.5 hours

**Proposed Workflow Configuration (`.github/workflows/test.yml`):**
```yaml
name: Run Tests

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main, develop ]

jobs:
  test:
    name: Run Unit Tests
    runs-on: macos-latest
    strategy:
      matrix:
        configuration:
          - Debug-AllFeatures
          - Debug-Subscription
          - Release-AllFeatures
          - Release-Subscription

    steps:
      - uses: actions/checkout@v4

      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app

      - name: Run Tests (${{ matrix.configuration }})
        run: |
          xcodebuild test \
            -project Ritualist.xcodeproj \
            -scheme Ritualist-AllFeatures \
            -configuration ${{ matrix.configuration }} \
            -destination "platform=iOS Simulator,name=iPhone 16" \
            -enableCodeCoverage YES \
            -resultBundlePath TestResults-${{ matrix.configuration }}.xcresult

      - name: Generate Coverage Report
        if: matrix.configuration == 'Debug-AllFeatures'
        run: |
          xcrun xccov view --report --json TestResults-Debug-AllFeatures.xcresult > coverage.json
          # Parse and enforce minimum 80% coverage for tested services

      - name: Upload Coverage to Codecov
        if: matrix.configuration == 'Debug-AllFeatures'
        uses: codecov/codecov-action@v3
        with:
          files: ./coverage.json
          fail_ci_if_error: false

      - name: Archive Test Results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results-${{ matrix.configuration }}
          path: TestResults-${{ matrix.configuration }}.xcresult
```

**Quality Gates:**
- ✅ All tests must pass before merge
- ✅ Minimum 80% code coverage for services with tests
- ✅ Test execution time < 60s (allows headroom beyond 30s target)
- ✅ All 4 build configurations must build successfully

**Success Criteria:**
- ✅ Tests run automatically on every PR
- ✅ Coverage reports generated and uploaded
- ✅ Failed tests block PR merge
- ✅ Coverage trends tracked over time
- ✅ Build matrix validates all configurations

**Why Phase 4 is Deferred:**
- Focus first on writing high-quality tests (Phases 0-3)
- CI/CD setup requires infrastructure decisions (coverage tool, report hosting)
- Can be added incrementally after tests are stable
- Existing manual testing workflow is adequate during implementation

**Integration with Existing Workflows:**
The repository already has these GitHub Actions workflows:
- `codeql-analysis.yml` - Security scanning
- `i18n-validation.yml` - Localization validation
- `claude-code-review.yml` - AI code review

Phase 4 would add `test.yml` to complement these existing workflows.

---

## 📊 Expected Outcomes

### **Test Coverage Metrics**

| Metric | Current | Target | Change |
|--------|---------|--------|--------|
| Test Files | 20 | 27-30 | +35-50% |
| Test Cases | 337 | 470-491 | +39-46% |
| Lines of Test Code | 8,143 | 12,000-13,000 | +47-60% |
| Services Tested | 9 | 17-19 | +89-111% |
| Test Infrastructure Components | 4 | 8 | +100% (Phase 0) |

### **Coverage by Layer**

| Layer | Current | Target |
|-------|---------|--------|
| Core Services | 9 files | 15-17 files |
| View Logic | 5 files | 5-6 files |
| Integration Tests | 2 files | 3-4 files |
| UI Tests | 0 files | 0 files (future) |

---

## 🛠️ Testing Infrastructure

### **Existing Strengths to Leverage**
- ✅ **TestDataBuilders** - `HabitBuilder`, `HabitLogBuilder`, `OverviewDataBuilder`
- ✅ **TestModelContainer** - In-memory SwiftData containers
- ✅ **TimezoneTestHelpers** - Timezone fixtures and edge cases
- ✅ **Swift Testing Framework** - Modern `@Test` and `#expect()` syntax
- ✅ **No Mocks Philosophy** - Real domain entities ensure production-like tests

### **New Infrastructure Needed**

#### 1. Notification Test Infrastructure - Protocol Abstraction Approach

**Philosophy Note:** This project follows a strict "NO MOCKS" philosophy (see `MICRO-CONTEXTS/testing-strategy.md`). However, testing `UNUserNotificationCenter` presents a challenge as it's a system framework that cannot be instantiated for testing.

**Decision: Protocol Abstraction over Mocking**

Instead of creating mock objects, we'll use **protocol abstraction** to maintain real implementations while enabling testability:

**Location:** `RitualistTests/TestInfrastructure/NotificationTestHelpers.swift`

```swift
// Protocol abstraction (not a mock - real interface)
protocol NotificationCenterProtocol: Sendable {
    func add(_ request: UNNotificationRequest) async throws
    func pendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers: [String])
}

// Production wrapper (real implementation)
final class SystemNotificationCenter: NotificationCenterProtocol {
    private let center = UNUserNotificationCenter.current()

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

// Test implementation (in-memory, real behavior)
final class InMemoryNotificationCenter: NotificationCenterProtocol {
    var pendingRequests: [UNNotificationRequest] = []
    var removedIdentifiers: [String] = []

    func add(_ request: UNNotificationRequest) async throws {
        pendingRequests.append(request)
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        return pendingRequests
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) {
        removedIdentifiers.append(contentsOf: identifiers)
        pendingRequests.removeAll { identifiers.contains($0.identifier) }
    }
}
```

**Why This Approach:**
- ✅ **Maintains "NO MOCKS" philosophy** - Real implementations, not stubs
- ✅ **Production code uses real `UNUserNotificationCenter`**
- ✅ **Tests use real in-memory implementation** (not fake behavior)
- ✅ **Protocol provides compile-time safety**
- ✅ **Follows existing pattern** (similar to `TestModelContainer` for SwiftData)

**Exception Justification:** This is the ONLY acceptable exception to the "NO MOCKS" rule because:
1. Apple system frameworks cannot be instantiated for testing
2. Protocol abstraction maintains real implementation semantics
3. Test implementation provides actual notification scheduling behavior (not mocked returns)

#### 2. UserProfile Test Builder
**Purpose:** Simplify creating test user profiles with timezones
**Location:** `RitualistTests/TestInfrastructure/TestDataBuilders.swift`

```swift
enum UserProfileBuilder {
    static func standard() -> UserProfile
    static func traveling() -> UserProfile
    static func withTimezone(_ timezone: TimeZone) -> UserProfile
    static func withDisplayMode(_ mode: DisplayTimezoneMode) -> UserProfile
}
```

---

## 🗂️ Test Data Management Strategy

### **Test Data Lifecycle**

All tests in this plan follow the existing **test data management patterns** established in `RitualistTests/`:

**1. Test Data Creation:**
- **Use Builders (REQUIRED):** All test data created via `TestDataBuilders` (HabitBuilder, HabitLogBuilder, OverviewDataBuilder)
- **No Manual Construction:** Never manually create entities - use builders for consistency
- **Fixed Reference Dates:** Use `TestDates` helpers (today, yesterday, tomorrow) - never `Date()`

**2. Test Isolation:**
- **In-Memory Containers:** Each test gets a fresh `TestModelContainer` for complete isolation
- **Automatic Cleanup:** SwiftData containers are automatically discarded after each test
- **No Shared State:** Tests run independently with zero cross-test contamination

**3. Existing Test Fixtures (Leverage These):**

#### **TimezoneTestHelpers** (`RitualistTests/TestInfrastructure/TimezoneTestHelpers.swift`)
```swift
// Already available - use for timezone tests
static let utc, newYork, tokyo, sydney, london, losAngeles
static func createDate(year:month:day:hour:minute:timezone:)
static func createLateNightDate(timezone:)
static func createMidnightBoundaryDate(timezone:)
static func dstSpringForwardDate()
```

#### **TimezoneEdgeCaseFixtures** (`RitualistTests/TestInfrastructure/Fixtures/TimezoneEdgeCaseFixtures.swift`)
```swift
// Pre-built test scenarios - use for timezone edge cases
static func lateNightLoggingScenario(timezone:)
static func timezoneTransitionScenario()
static func weeklyScheduleScenario()
static func dstTransitionScenario()
static func midnightBoundaryScenario()
```

#### **TestDates** (`RitualistTests/TestInfrastructure/TestHelpers.swift`)
```swift
// Fixed reference dates - use to prevent timezone-dependent tests
static let today, yesterday, tomorrow
static func daysAgo(_ count: Int) -> Date
static func daysFromNow(_ count: Int) -> Date
static func dateRange() -> (start: Date, end: Date)
```

### **New Test Data Patterns for This Initiative**

#### **Historical Date Validation Tests:**
```swift
// Pattern: Use TestDates with offset calculations
let maxHistoryLimit = 30
let validDate = TestDates.daysAgo(29)  // Within limit
let invalidDate = TestDates.daysAgo(31)  // Beyond limit
let boundaryDate = TestDates.daysAgo(30)  // Exactly at limit
```

#### **Notification Scheduling Tests:**
```swift
// Pattern: Use InMemoryNotificationCenter for test data
let notificationCenter = InMemoryNotificationCenter()
let habit = HabitBuilder.binary()
// Test schedules notifications and verifies via notificationCenter.pendingRequests
```

#### **Timezone Service Tests:**
```swift
// Pattern: Use UserProfileBuilder with specific timezones
let profile = UserProfileBuilder.withTimezone(TimezoneTestHelpers.tokyo)
let travelingProfile = UserProfileBuilder.traveling()
// Test timezone operations with known timezone configurations
```

### **Test Data Cleanup Strategy**

**Automatic Cleanup (No Action Required):**
- ✅ SwiftData containers discarded after each test
- ✅ In-memory notification center reset per test
- ✅ User profiles created fresh per test

**No Manual Cleanup Needed:**
- ❌ No `tearDown()` methods required
- ❌ No state reset logic needed
- ❌ No shared fixtures to manage

### **Test Data Versioning for Regression Tests**

**PerformanceAnalysisService Regression Tests:**
These tests validate the specific bug mentioned in code comments (line 70-75):

```swift
// Regression test data: partial progress should NOT count as complete
let habitWithTarget8 = HabitBuilder.numeric(target: 8.0)
let partialLog = HabitLogBuilder.numeric(value: 3.0)  // 3/8 = incomplete
let completeLog = HabitLogBuilder.numeric(value: 8.0)  // 8/8 = complete

// Test that partialLog is NOT counted as complete (regression validation)
```

**Data Versioning Approach:**
- **No versioning needed** - Tests use current domain models
- **Regression captured in code comments** - Test names reference the bug being prevented
- **Future-proof** - If models change, tests will fail at compile time (type safety)

### **Test Data Best Practices**

**✅ Do:**
- Use `TestDataBuilders` for all entity creation
- Use `TestDates` for all date values
- Use `TimezoneTestHelpers` for timezone-specific tests
- Use `TestModelContainer` for SwiftData integration
- Leverage existing `TimezoneEdgeCaseFixtures` for complex scenarios

**❌ Don't:**
- Create entities manually (use builders)
- Use `Date()` in tests (use TestDates)
- Share state between tests
- Mock domain entities (use real builders)
- Create standalone test fixtures (use existing infrastructure)

---

## ⚠️ Risks & Mitigation

### **Risk 1: Notification Testing Complexity**
**Impact:** Medium
**Mitigation:** Use protocol abstraction (`NotificationCenterProtocol`) with `InMemoryNotificationCenter` implementation - maintains "NO MOCKS" philosophy while enabling testing

### **Risk 2: Timezone Test Flakiness**
**Impact:** Medium
**Mitigation:** Use existing `TimezoneTestHelpers` and fixed reference dates

### **Risk 3: Time Investment**
**Impact:** Low
**Mitigation:** Phased approach allows stopping after high-priority tests

---

## 🎓 Testing Best Practices

### **Patterns to Follow**
1. **Arrange-Act-Assert** structure
2. **Use TestDataBuilders** for consistent test data
3. **Fixed reference dates** (avoid `Date()` in tests)
4. **Real domain entities** (avoid mocks when possible)
5. **In-memory containers** for SwiftData tests
6. **Descriptive test names** (`@Test("Behavior description")`)

### **Patterns to Avoid**
1. ❌ Using `Date()` (creates timezone-dependent tests)
2. ❌ Manual entity construction (use builders)
3. ❌ Shared test state across tests
4. ❌ Testing implementation details instead of behavior
5. ❌ Overly complex test setup

---

## 📈 Success Metrics

### **Quantitative Metrics**
- ✅ 133-154 new test cases added
- ✅ 10+ previously untested services now covered
- ✅ Test suite execution time < 30 seconds
- ✅ 0 flaky tests (deterministic test suite)

### **Qualitative Metrics**
- ✅ Regression tests address code comments (PerformanceAnalysisService)
- ✅ Notification reliability validated
- ✅ Timezone edge cases comprehensively tested
- ✅ Test infrastructure reusable for future features

---

## 🚀 Future Improvements (Post-Plan)

### **Not Included in This Plan (Future Work)**

1. **UI/SwiftUI Testing**
   - ViewInspector integration
   - Snapshot testing
   - 13 untested ViewModels

2. **CI/CD Integration**
   - GitHub Actions workflow for test execution
   - Test coverage reporting
   - Automated test runs on PR

3. **Performance Testing**
   - Benchmark tests for performance-critical code
   - Memory leak detection
   - Launch time testing

4. **Integration Testing**
   - Real StoreKit integration tests
   - Network layer integration tests
   - Widget extension tests

---

## 📝 Notes

- This plan focuses on **unit and service layer tests** with high ROI
- **UI testing** is explicitly excluded (requires different infrastructure)
- **ViewModel testing** is deferred (requires view testing strategy)
- Tests should run **fast** (< 30s total) to maintain developer productivity
- All new tests must use **Swift Testing framework** (not XCTest)

---

## ✅ Definition of Done

A test suite is considered complete when:

1. ✅ All test cases outlined in this plan are implemented
2. ✅ Tests pass consistently (no flakiness)
3. ✅ Test execution time remains < 30 seconds
4. ✅ Code coverage for tested services > 80%
5. ✅ Test infrastructure documented in `RitualistTests/README.md`
6. ✅ Pull request includes test execution screenshot
7. ✅ All tests follow established patterns from existing test suite

---

**Last Updated:** 2025-11-20
**Document Version:** 1.0
**Author:** Claude Code
